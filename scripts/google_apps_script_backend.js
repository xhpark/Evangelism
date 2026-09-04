/**
 * JUST EE 라이선스 서버 (Google Apps Script)
 *
 * 관리자가 private activation_codes 시트에서 일회용 코드를 발급한다.
 * 앱은 코드를 한 번 교환하여 기기별 토큰을 받고, 이후에는 토큰으로
 * 상태를 확인한다. 시트에는 토큰 원문 대신 SHA-256 해시만 저장한다.
 * 실제 코드, 토큰, 배포 URL은 소스 저장소에 기록하지 않는다.
 */

const LICENSE_SHEET = "licenses";
const CODE_SHEET = "activation_codes";
const APPROVED = "APPROVED";
const BLOCKED = "BLOCKED";

function doGet() {
  return json_({
    status: "OK",
    protocol: "device_token_v2",
    message: "License service is available.",
  });
}

function doPost(e) {
  const lock = LockService.getScriptLock();
  try {
    lock.waitLock(20000);
  } catch (_) {
    return json_({ status: "ERROR", message: "서버가 혼잡합니다. 잠시 후 다시 시도해 주세요." });
  }
  try {
    const body = parseBody_(e);
    if (body.action === "activate") return activate_(body);
    if (body.action === "check_status") return checkStatus_(body);
    return json_({ status: "DENIED", message: "지원하지 않는 요청입니다." });
  } catch (error) {
    console.error("License request failed", error);
    return json_({ status: "ERROR", message: "요청을 처리하지 못했습니다." });
  } finally {
    lock.releaseLock();
  }
}

function activate_(body) {
  const deviceId = requiredText_(body.device_id, 80);
  const activationCode = normalizeCode_(body.activation_code);
  const userName = requiredText_(body.user_name, 80);
  const affiliation = requiredText_(body.affiliation, 120);
  // 1.0.0 이하에서 발급된 3그룹 기기 코드도 기존 설치 호환을 위해 허용한다.
  if (!/^EE-(?:[0-9A-F]{4}-){2,3}[0-9A-F]{4}$/.test(deviceId) ||
      !activationCode || !userName || !affiliation) {
    return json_({ status: "DENIED", message: "기기 코드와 활성화 코드를 확인해 주세요." });
  }

  const licenseSheet = licenseSheet_();
  const existingRow = findRow_(licenseSheet, 2, deviceId);
  if (existingRow > 0) {
    const currentStatus = normalizedStatus_(licenseSheet.getRange(existingRow, 4).getValue());
    if (currentStatus === BLOCKED || currentStatus === "REVOKED") {
      return json_({ status: BLOCKED, message: "차단된 단말기입니다." });
    }
  }

  const codeSheet = codeSheet_();
  const codeRow = findRow_(codeSheet, 1, activationCode);
  if (codeRow < 2 || normalizedStatus_(codeSheet.getRange(codeRow, 2).getValue()) !== "UNUSED") {
    return json_({ status: "DENIED", message: "유효하지 않거나 이미 사용된 활성화 코드입니다." });
  }

  const token = newToken_();
  const tokenHash = sha256_(token);
  const stamp = now_();
  const userDisplay = safeCell_(
    userName + " (" + affiliation + ")"
  );
  const environment = safeCell_(
    requiredText_(body.os, 30) + " (" + requiredText_(body.os_version, 80) + ")"
  );
  const appVersion = safeCell_(requiredText_(body.app_version, 40));

  if (existingRow > 0) {
    licenseSheet.getRange(existingRow, 3, 1, 7).setValues([[
      userDisplay, APPROVED, environment, appVersion, stamp, "재활성화", tokenHash
    ]]);
  } else {
    licenseSheet.appendRow([
      stamp, safeCell_(deviceId), userDisplay, APPROVED,
      environment, appVersion, stamp, "신규 활성화", tokenHash
    ]);
  }

  codeSheet.getRange(codeRow, 2, 1, 3).setValues([["USED", safeCell_(deviceId), stamp]]);
  SpreadsheetApp.flush();
  return json_({
    status: APPROVED,
    message: "기기 활성화가 완료되었습니다.",
    device_token: token
  });
}

function checkStatus_(body) {
  const deviceId = requiredText_(body.device_id, 80);
  const token = requiredText_(body.device_token, 300);
  if (!deviceId || !token) {
    return json_({ status: "DENIED", message: "기기 인증 정보가 없습니다." });
  }

  const sheet = licenseSheet_();
  const row = findRow_(sheet, 2, deviceId);
  if (row < 2) {
    return json_({ status: "UNREGISTERED", message: "등록되지 않은 단말기입니다." });
  }

  const storedHash = String(sheet.getRange(row, 9).getValue() || "").trim().toLowerCase();
  if (!storedHash || !constantTimeEquals_(storedHash, sha256_(token))) {
    return json_({ status: "DENIED", message: "기기 인증 토큰이 유효하지 않습니다." });
  }

  const status = normalizedStatus_(sheet.getRange(row, 4).getValue());
  sheet.getRange(row, 7).setValue(now_());
  if (status === BLOCKED || status === "REVOKED") {
    return json_({ status: BLOCKED, message: "이 단말기의 승인이 회수되었습니다." });
  }
  if (status !== APPROVED) {
    return json_({ status: "DENIED", message: "승인되지 않은 단말기입니다." });
  }
  return json_({ status: APPROVED, message: "정상 승인 단말기입니다." });
}

/** 관리자가 Apps Script 편집기에서 직접 실행해 일회용 코드를 생성한다. */
function createActivationCodes(count) {
  const amount = Math.max(1, Math.min(Number(count) || 1, 100));
  const sheet = codeSheet_();
  const rows = [];
  for (let i = 0; i < amount; i += 1) rows.push([newActivationCode_(), "UNUSED", "", ""]);
  sheet.getRange(sheet.getLastRow() + 1, 1, rows.length, 4).setValues(rows);
  return amount;
}

/** 20개의 일회용 활성화 코드를 원클릭으로 생성하는 관리자 함수 */
function create20ActivationCodes() {
  return createActivationCodes(20);
}

/** 10개의 일회용 활성화 코드를 원클릭으로 생성하는 관리자 함수 */
function create10ActivationCodes() {
  return createActivationCodes(10);
}

/** 스프레드시트 열릴 때 상단 메뉴 자동 등록 */
function onOpen() {
  try {
    const ui = SpreadsheetApp.getUi();
    ui.createMenu("🔐 JUST EE 라이선스 관리")
      .addItem("일회용 활성화 코드 20개 생성", "create20ActivationCodes")
      .addItem("일회용 활성화 코드 10개 생성", "create10ActivationCodes")
      .addToUi();
  } catch (_) {
    // 트리거 환경에 따라 getUi가 없는 경우 무시
  }
}

function licenseSheet_() {
  return ensureSheet_(LICENSE_SHEET, [
    "등록일시", "기기 코드", "훈련생/소속", "상태",
    "운영체제", "앱 버전", "최근 접속", "비고", "토큰 해시"
  ]);
}

function codeSheet_() {
  return ensureSheet_(CODE_SHEET, ["활성화 코드", "상태", "사용 기기", "사용일시"]);
}

function ensureSheet_(name, headers) {
  const workbook = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = workbook.getSheetByName(name);
  if (!sheet) sheet = workbook.insertSheet(name);
  if (sheet.getLastRow() === 0) {
    sheet.appendRow(headers);
    sheet.getRange(1, 1, 1, headers.length)
      .setBackground("#0F172A").setFontColor("#FFFFFF").setFontWeight("bold");
    sheet.setFrozenRows(1);
  }
  return sheet;
}

function findRow_(sheet, column, value) {
  if (sheet.getLastRow() < 2) return -1;
  const match = sheet.getRange(2, column, sheet.getLastRow() - 1, 1)
    .createTextFinder(String(value)).matchEntireCell(true).findNext();
  return match ? match.getRow() : -1;
}

function parseBody_(e) {
  if (!e || !e.postData || !e.postData.contents) throw new Error("Missing body");
  const value = JSON.parse(e.postData.contents);
  if (!value || typeof value !== "object" || Array.isArray(value)) throw new Error("Invalid body");
  return value;
}

function requiredText_(value, maxLength) {
  return String(value || "").trim().slice(0, maxLength);
}

function normalizeCode_(value) {
  const raw = String(value || "").replace(/[^A-Za-z0-9]/g, "").toUpperCase();
  return raw.length === 16 ? raw.match(/.{1,4}/g).join("-") : "";
}

function normalizedStatus_(value) {
  return String(value || "").trim().toUpperCase();
}

function safeCell_(value) {
  const valueText = String(value || "");
  return /^[=+\-@]/.test(valueText) ? "'" + valueText : valueText;
}

function sha256_(value) {
  return Utilities.computeDigest(
    Utilities.DigestAlgorithm.SHA_256, String(value), Utilities.Charset.UTF_8
  ).map(function (byte) {
    return ("0" + (byte & 0xff).toString(16)).slice(-2);
  }).join("");
}

function constantTimeEquals_(left, right) {
  if (left.length !== right.length) return false;
  let difference = 0;
  for (let i = 0; i < left.length; i += 1) {
    difference |= left.charCodeAt(i) ^ right.charCodeAt(i);
  }
  return difference === 0;
}

function newToken_() {
  return Utilities.getUuid() + Utilities.getUuid();
}

function newActivationCode_() {
  const raw = Utilities.getUuid().replace(/-/g, "").toUpperCase().slice(0, 16);
  return raw.match(/.{1,4}/g).join("-");
}

function now_() {
  return Utilities.formatDate(new Date(), "Asia/Seoul", "yyyy-MM-dd HH:mm:ss");
}

function json_(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
