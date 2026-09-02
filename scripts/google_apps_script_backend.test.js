const assert = require('node:assert/strict');
const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');

class Range {
  constructor(sheet, row, column, rowCount = 1, columnCount = 1) {
    this.sheet = sheet;
    this.row = row;
    this.column = column;
    this.rowCount = rowCount;
    this.columnCount = columnCount;
  }

  getValue() {
    return this.sheet.valueAt(this.row, this.column);
  }

  setValue(value) {
    this.sheet.setValueAt(this.row, this.column, value);
    return this;
  }

  setValues(values) {
    for (let row = 0; row < this.rowCount; row += 1) {
      for (let column = 0; column < this.columnCount; column += 1) {
        this.sheet.setValueAt(
          this.row + row,
          this.column + column,
          values[row][column],
        );
      }
    }
    return this;
  }

  createTextFinder(expected) {
    let entireCell = false;
    return {
      matchEntireCell(value) {
        entireCell = value;
        return this;
      },
      findNext: () => {
        for (let offset = 0; offset < this.rowCount; offset += 1) {
          const actual = String(
            this.sheet.valueAt(this.row + offset, this.column) ?? '',
          );
          const matched = entireCell
            ? actual === String(expected)
            : actual.includes(String(expected));
          if (matched) {
            const foundRow = this.row + offset;
            return {getRow: () => foundRow};
          }
        }
        return null;
      },
    };
  }

  setBackground() { return this; }
  setFontColor() { return this; }
  setFontWeight() { return this; }
}

class Sheet {
  constructor() {
    this.rows = [];
  }

  getLastRow() { return this.rows.length; }
  setFrozenRows() {}

  appendRow(values) {
    this.rows.push([...values]);
  }

  getRange(row, column, rowCount = 1, columnCount = 1) {
    return new Range(this, row, column, rowCount, columnCount);
  }

  valueAt(row, column) {
    return this.rows[row - 1]?.[column - 1] ?? '';
  }

  setValueAt(row, column, value) {
    while (this.rows.length < row) this.rows.push([]);
    while (this.rows[row - 1].length < column) this.rows[row - 1].push('');
    this.rows[row - 1][column - 1] = value;
  }
}

function createRuntime() {
  const sheets = new Map();
  let uuidCounter = 0;
  const workbook = {
    getSheetByName: (name) => sheets.get(name) ?? null,
    insertSheet: (name) => {
      const sheet = new Sheet();
      sheets.set(name, sheet);
      return sheet;
    },
  };
  const context = vm.createContext({
    console: {error() {}},
    SpreadsheetApp: {
      getActiveSpreadsheet: () => workbook,
      flush() {},
    },
    LockService: {
      getScriptLock: () => ({waitLock() {}, releaseLock() {}}),
    },
    ContentService: {
      MimeType: {JSON: 'application/json'},
      createTextOutput: (content) => ({
        content,
        setMimeType() { return this; },
      }),
    },
    Utilities: {
      DigestAlgorithm: {SHA_256: 'sha256'},
      Charset: {UTF_8: 'utf8'},
      computeDigest: (_, value) => [...crypto.createHash('sha256').update(value).digest()],
      getUuid: () => {
        uuidCounter += 1;
        return `${uuidCounter.toString(16).padStart(8, '0')}-0000-4000-8000-000000000000`;
      },
      formatDate: () => '2026-09-02 12:00:00',
    },
    JSON,
    Date,
    Math,
    Number,
    RegExp,
    String,
    Array,
    Object,
  });
  const source = fs.readFileSync(
    path.join(__dirname, 'google_apps_script_backend.js'),
    'utf8',
  );
  vm.runInContext(source, context);
  return {context, sheets};
}

function post(context, body) {
  const output = context.doPost({postData: {contents: JSON.stringify(body)}});
  return JSON.parse(output.content);
}

function activationBody(code, overrides = {}) {
  return {
    action: 'activate',
    device_id: 'EE-1111-2222-3333-4444',
    activation_code: code,
    user_name: '테스트 사용자',
    affiliation: '테스트 소속',
    os: 'android',
    os_version: 'test',
    app_version: '1.0.0+1',
    ...overrides,
  };
}

function run() {
  const {context, sheets} = createRuntime();
  assert.deepEqual(JSON.parse(context.doGet().content), {
    status: 'OK',
    protocol: 'device_token_v2',
    message: 'License service is available.',
  });

  assert.equal(context.createActivationCodes(1), 1);
  const codeSheet = sheets.get('activation_codes');
  const code = codeSheet.rows[1][0];

  const invalidDevice = post(
    context,
    activationBody(code, {device_id: 'invalid-device'}),
  );
  assert.equal(invalidDevice.status, 'DENIED');
  assert.equal(codeSheet.rows[1][1], 'UNUSED');

  const legacyDeviceFormat = post(
    context,
    activationBody('FFFF-FFFF-FFFF-FFFF', {device_id: 'EE-1111-2222-3333'}),
  );
  assert.equal(legacyDeviceFormat.status, 'DENIED');
  assert.equal(legacyDeviceFormat.message, '유효하지 않거나 이미 사용된 활성화 코드입니다.');

  const activated = post(
    context,
    activationBody(code.toLowerCase().replaceAll('-', ' '), {
      user_name: '=IMPORTXML("bad")',
    }),
  );
  assert.equal(activated.status, 'APPROVED');
  assert.ok(activated.device_token.length >= 72);
  assert.equal(codeSheet.rows[1][1], 'USED');

  const licenseSheet = sheets.get('licenses');
  assert.equal(licenseSheet.rows.length, 2);
  assert.ok(String(licenseSheet.rows[1][2]).startsWith("'="));
  assert.match(licenseSheet.rows[1][8], /^[0-9a-f]{64}$/);
  assert.notEqual(licenseSheet.rows[1][8], activated.device_token);

  const reused = post(context, activationBody(code));
  assert.equal(reused.status, 'DENIED');

  const approved = post(context, {
    action: 'check_status',
    device_id: 'EE-1111-2222-3333-4444',
    device_token: activated.device_token,
  });
  assert.equal(approved.status, 'APPROVED');

  const wrongToken = post(context, {
    action: 'check_status',
    device_id: 'EE-1111-2222-3333-4444',
    device_token: 'wrong-token',
  });
  assert.equal(wrongToken.status, 'DENIED');

  licenseSheet.rows[1][3] = 'BLOCKED';
  const blocked = post(context, {
    action: 'check_status',
    device_id: 'EE-1111-2222-3333-4444',
    device_token: activated.device_token,
  });
  assert.equal(blocked.status, 'BLOCKED');

  licenseSheet.rows[1][3] = 'APPROVED';
  const unblocked = post(context, {
    action: 'check_status',
    device_id: 'EE-1111-2222-3333-4444',
    device_token: activated.device_token,
  });
  assert.equal(unblocked.status, 'APPROVED');

  const malformed = context.doPost({postData: {contents: '{'}});
  assert.deepEqual(JSON.parse(malformed.content), {
    status: 'ERROR',
    message: '요청을 처리하지 못했습니다.',
  });

  console.log('Apps Script backend integration tests passed (12 assertion groups).');
}

run();
