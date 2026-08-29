/**
 * ==============================================================================
 * 전도폭발 JUST EE 훈련 마스터 - Google Apps Script 보안 백엔드 (Code.gs)
 * ==============================================================================
 *
 * [기능]
 * 1. 방안 1: 원격 킬 스위치 (Google Sheet에서 APPROVED / BLOCKED 실시간 제어)
 * 2. 방안 2: 마스터 인증키(PIN) 서버측 재검증
 * 3. 방안 4: 신규 기기 활성화 시 개발자에게 자동 이메일 통보
 *
 * [2026-08-29 보안 개정]
 * - 앱이 보내는 서명(sig)을 검증해 무단 호출을 차단한다.
 *   서명 = SHA-256("<기기UUID>|<SHARED_SECRET>") 의 16진 문자열.
 *   ⚠️ SHARED_SECRET 값은 앱의 LicenseService._sharedSecret 과 반드시 같아야 한다.
 * - MASTER_PINS 를 실제로 검증한다. (이전에는 선언만 하고 쓰지 않아 아무 PIN이나 등록됐다)
 * - LockService 로 동시 등록 시 중복 행이 생기지 않게 한다.
 * - 시트를 이름(SHEET_NAME)으로 고정한다. (getActiveSheet 는 탭을 추가하면 엉뚱한 곳에 쓴다)
 *
 * [구글 시트 배포 방법]
 * 1. Google Drive에서 [새로 만들기 ➔ Google 스프레드시트] 생성.
 * 2. 하단 시트 탭 이름을 "licenses" 로 변경.
 * 3. 상단 메뉴 [확장 프로그램 ➔ Apps Script] 클릭.
 * 4. 기존 코드를 지우고 본 스크립트 전체를 붙여넣기 후 저장 (Ctrl+S).
 * 5. [배포 ➔ 새 배포] ➔ 유형 [웹 앱] ➔ 실행 [나] ➔ 액세스 [모든 사용자] ➔ 배포.
 * 6. 발급된 웹 앱 URL을 앱 설정(개발자 인증 후)에 등록.
 * ==============================================================================
 */

const DEVELOPER_EMAIL = "xhpark@naver.com";
const SHEET_NAME = "licenses";

// 앱과 공유하는 요청 서명용 시크릿 (앱의 LicenseService._sharedSecret 과 동일해야 함)
const SHARED_SECRET = "JUSTEE-2026-GATEWAY-8f31c7";

// 서버측에서도 인증키를 재검증한다.
const MASTER_PINS = ["JUST-EE2026", "JUST-2026-EE77", "EE-MASTER-2026", "PARK-7788-9900"];

/** 시트 핸들 (없으면 만들고 헤더까지 세팅) */
function getSheet_() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName(SHEET_NAME);
  if (!sheet) {
    sheet = ss.insertSheet(SHEET_NAME);
  }
  if (sheet.getLastRow() === 0) {
    sheet.appendRow([
      "등록일시",
      "기기 고유 코드 (UUID)",
      "훈련생 성명/소속",
      "입력 인증키",
      "승인 상태 (APPROVED / BLOCKED)",
      "운영체제 (OS)",
      "앱 버전",
      "최근 접속 일시",
      "비고"
    ]);
    sheet.getRange(1, 1, 1, 9).setBackground("#0F172A").setFontColor("#FFFFFF").setFontWeight("bold");
    sheet.setFrozenRows(1);
  }
  return sheet;
}

/** 요청 서명 검증: sha256(deviceId + "|" + SHARED_SECRET) */
function isValidSignature_(deviceId, signature) {
  if (!deviceId || !signature) return false;
  const raw = Utilities.computeDigest(
    Utilities.DigestAlgorithm.SHA_256,
    deviceId + "|" + SHARED_SECRET,
    Utilities.Charset.UTF_8
  );
  const hex = raw.map(function (b) {
    return ("0" + (b & 0xff).toString(16)).slice(-2);
  }).join("");
  return hex === String(signature).toLowerCase();
}

function isValidPin_(pin) {
  const normalized = String(pin || "").replace(/[-\s]/g, "").toUpperCase();
  if (!normalized) return false;
  return MASTER_PINS.some(function (p) {
    return p.replace(/[-\s]/g, "").toUpperCase() === normalized;
  });
}

function nowStr_() {
  return new Date().toLocaleString("ko-KR", { timeZone: "Asia/Seoul" });
}

/**
 * GET: 원격 킬 스위치 상태 점검 (action = check_status)
 */
function doGet(e) {
  const params = (e && e.parameter) || {};
  const action = params.action;
  const deviceId = String(params.device_id || "").trim();

  if (action !== "check_status") {
    return createJsonResponse({ status: "OK", message: "JUST EE Security Server Active" });
  }

  if (!isValidSignature_(deviceId, params.sig)) {
    return createJsonResponse({ status: "DENIED", message: "유효하지 않은 요청 서명입니다." });
  }

  const sheet = getSheet_();
  const data = sheet.getDataRange().getValues();

  for (let i = 1; i < data.length; i++) {
    if (String(data[i][1]).trim() !== deviceId) continue;

    const status = String(data[i][4]).trim().toUpperCase();
    sheet.getRange(i + 1, 8).setValue(nowStr_()); // 최근 접속일 갱신

    if (status === "BLOCKED" || status === "REVOKED") {
      return createJsonResponse({
        status: "BLOCKED",
        message: "권리자의 권한 회수로 인해 해당 단말기의 이용이 원격 차단되었습니다."
      });
    }
    return createJsonResponse({ status: "APPROVED", message: "정상 승인 단말기입니다." });
  }

  // 목록에 없는 기기 — 앱이 스스로 재등록을 시도한다.
  return createJsonResponse({ status: "UNREGISTERED", message: "등록되지 않은 단말기입니다." });
}

/**
 * POST: 신규 기기 활성화 등록 및 텔레메트리 이메일 발송
 */
function doPost(e) {
  const lock = LockService.getScriptLock();
  try {
    lock.waitLock(20000); // 동시 등록 시 중복 행 방지
  } catch (lockErr) {
    return createJsonResponse({ status: "ERROR", message: "서버가 혼잡합니다. 잠시 후 다시 시도해 주세요." });
  }

  try {
    const contents = JSON.parse(e.postData.contents);
    const action = contents.action;
    const deviceId = String(contents.device_id || "").trim();

    if (!isValidSignature_(deviceId, contents.sig)) {
      return createJsonResponse({ status: "DENIED", message: "유효하지 않은 요청 서명입니다." });
    }

    if (action !== "activate") {
      return createJsonResponse({ status: "ERROR", message: "Unknown action" });
    }

    const pin = String(contents.pin || "").trim().toUpperCase();
    if (!isValidPin_(pin)) {
      return createJsonResponse({ status: "DENIED", message: "유효하지 않은 인증키입니다." });
    }

    const userName = String(contents.user_name || "미입력").trim();
    const affiliation = String(contents.affiliation || "미입력").trim();
    const os = contents.os || "Android";
    const osVersion = contents.os_version || "";
    const appVersion = contents.app_version || "";
    const stamp = nowStr_();
    const userDisplay = userName + " (" + affiliation + ")";

    const sheet = getSheet_();
    const data = sheet.getDataRange().getValues();
    let rowIndex = -1;
    for (let i = 1; i < data.length; i++) {
      if (String(data[i][1]).trim() === deviceId) {
        rowIndex = i + 1;
        break;
      }
    }

    if (rowIndex > 0) {
      // 기존 기기 업데이트 (승인 상태는 개발자가 정한 값을 건드리지 않는다)
      sheet.getRange(rowIndex, 3).setValue(userDisplay);
      sheet.getRange(rowIndex, 4).setValue(pin);
      sheet.getRange(rowIndex, 8).setValue(stamp);

      const currentStatus = String(data[rowIndex - 1][4]).trim().toUpperCase();
      if (currentStatus === "BLOCKED" || currentStatus === "REVOKED") {
        return createJsonResponse({ status: "BLOCKED", message: "차단된 단말기입니다." });
      }
      return createJsonResponse({ status: "APPROVED", message: "기기 정보가 갱신되었습니다." });
    }

    sheet.appendRow([
      stamp, deviceId, userDisplay, pin, "APPROVED",
      os + " (" + osVersion + ")", appVersion, stamp, "신규 활성화 완료"
    ]);

    try {
      const subject = "🔔 [JUST EE] 신규 기기 인증 활성화 알림: " + userName + " (" + affiliation + ")";
      const body =
        "전도폭발 JUST EE 훈련 마스터 앱에서 새로운 기기가 활성화되었습니다.\n\n" +
        "• 훈련생 성명: " + userName + "\n" +
        "• 소속: " + affiliation + "\n" +
        "• 기기 고유 코드: " + deviceId + "\n" +
        "• 단말기 환경: " + os + " (" + osVersion + ")\n" +
        "• 앱 버전: " + appVersion + "\n" +
        "• 일시: " + stamp + "\n\n" +
        "※ 차단하려면 '" + SHEET_NAME + "' 시트의 '승인 상태' 셀을 BLOCKED 로 바꾸세요.\n" +
        "※ 보안상 입력된 인증키 값은 메일에 담지 않습니다. 시트에서 확인하세요.";
      MailApp.sendEmail(DEVELOPER_EMAIL, subject, body);
    } catch (mailErr) {
      Logger.log("Email send failed: " + mailErr);
    }

    return createJsonResponse({ status: "APPROVED", message: "기기 인증 및 활성화가 완료되었습니다." });
  } catch (err) {
    return createJsonResponse({ status: "ERROR", message: err.toString() });
  } finally {
    lock.releaseLock();
  }
}

function createJsonResponse(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
