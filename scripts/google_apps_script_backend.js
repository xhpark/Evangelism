/**
 * ==============================================================================
 * 전도폭발 JUST EE 훈련 마스터 - Google Apps Script 보안 백엔드 (Code.gs)
 * ==============================================================================
 * 
 * [기능]
 * 1. 방안 1: 원격 킬 스위치 (Google Sheet에서 APPROVED / BLOCKED 상태 실시간 제어)
 * 2. 방안 2: 마스터 인증키(PIN) 원격 검증 및 등록
 * 3. 방안 4: 신규 기기 활성화 시 개발자(xhpark@naver.com)에게 자동 이메일 통보
 * 
 * [구글 시트 배포 방법 (3분 소요)]
 * 1. Google Drive (drive.google.com)에서 [새로 만들기 ➔ Google 스프레드시트] 생성.
 * 2. 상단 메뉴 [확장 프로그램 ➔ Apps Script] 클릭.
 * 3. 기존 코드를 지우고 본 스크립트 전체를 복사하여 붙여넣기 후 저장 (Ctrl+S).
 * 4. 상단 [배포 ➔ 새 배포] 클릭:
 *    - 유형: [웹 앱 (Web App)] 선택
 *    - 설명: JUST EE Security Backend
 *    - 다음 사용자 권한으로 실행: [나 (내 이메일)]
 *    - 액세스 권한: [모든 사용자 (Anyone)] 선택 ➔ [배포] 클릭
 * 5. 발급된 "웹 앱 URL" (https://script.google.com/macros/s/.../exec)을 복사하여 앱 설정에 등록.
 * ==============================================================================
 */

const DEVELOPER_EMAIL = "xhpark@naver.com";
const MASTER_PINS = ["JUST-EE2026", "JUST-2026-EE77", "EE-MASTER-2026", "PARK-7788-9900"];

/**
 * 최초 1회 실행하여 시트 헤더를 세팅하는 함수
 */
function setupSheetHeaders() {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
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
}

/**
 * GET 요청 처리: 원격 킬 스위치 상태 점검 (action = check_status)
 */
function doGet(e) {
  setupSheetHeaders();
  const params = e.parameter || {};
  const action = params.action;
  const deviceId = (params.device_id || "").trim();

  if (action === "check_status") {
    const sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
    const data = sheet.getDataRange().getValues();

    for (let i = 1; i < data.length; i++) {
      const rowDeviceId = String(data[i][1]).trim();
      if (rowDeviceId === deviceId) {
        const status = String(data[i][4]).trim().toUpperCase();
        
        // 최근 접속일 갱신
        sheet.getRange(i + 1, 8).setValue(new Date().toLocaleString("ko-KR", { timeZone: "Asia/Seoul" }));

        if (status === "BLOCKED" || status === "REVOKED") {
          return createJsonResponse({
            status: "BLOCKED",
            message: "권리자의 권한 회수로 인해 해당 단말기의 이용이 원격 차단되었습니다."
          });
        } else {
          return createJsonResponse({
            status: "APPROVED",
            message: "정상 승인 단말기입니다."
          });
        }
      }
    }

    // 목록에 없는 기기
    return createJsonResponse({
      status: "UNREGISTERED",
      message: "등록되지 않은 단말기입니다."
    });
  }

  return createJsonResponse({ status: "OK", message: "JUST EE Security Server Active" });
}

/**
 * POST 요청 처리: 신규 기기 활성화 등록 및 텔레메트리 이메일 발송
 */
function doPost(e) {
  setupSheetHeaders();
  try {
    const contents = JSON.parse(e.postData.contents);
    const action = contents.action;
    const deviceId = (contents.device_id || "").trim();
    const userName = (contents.user_name || "미입력").trim();
    const pin = (contents.pin || "").trim().toUpperCase();
    const os = contents.os || "Android";
    const osVersion = contents.os_version || "";
    const appVersion = contents.app_version || "2.0.0";
    const nowStr = new Date().toLocaleString("ko-KR", { timeZone: "Asia/Seoul" });

    if (action === "activate") {
      const sheet = SpreadsheetApp.getActiveSpreadsheet().getActiveSheet();
      const data = sheet.getDataRange().getValues();
      let rowIndex = -1;

      for (let i = 1; i < data.length; i++) {
        if (String(data[i][1]).trim() === deviceId) {
          rowIndex = i + 1;
          break;
        }
      }

      if (rowIndex > 0) {
        // 기존 기기 업데이트
        sheet.getRange(rowIndex, 3).setValue(userName);
        sheet.getRange(rowIndex, 4).setValue(pin);
        sheet.getRange(rowIndex, 8).setValue(nowStr);
      } else {
        // 신규 기기 등록 (기본값 APPROVED)
        sheet.appendRow([
          nowStr,
          deviceId,
          userName,
          pin,
          "APPROVED",
          os + " (" + osVersion + ")",
          appVersion,
          nowStr,
          "신규 활성화 완료"
        ]);

        // 📧 개발자에게 실시간 이메일 알림 전송 (방안 4)
        try {
          const subject = "🔔 [JUST EE] 신규 기기 인증 활성화 알림 (" + userName + ")";
          const body = "전도폭발 JUST EE 훈련 마스터 앱에서 새로운 기기가 활성화되었습니다.\n\n" +
            "• 훈련생 성명: " + userName + "\n" +
            "• 기기 고유 코드: " + deviceId + "\n" +
            "• 입력된 인증키: " + pin + "\n" +
            "• 단말기 환경: " + os + " (" + osVersion + ")\n" +
            "• 앱 버전: " + appVersion + "\n" +
            "• 일시: " + nowStr + "\n\n" +
            "※ 해당 기기의 접근을 차단하려면 스프레드시트의 '승인 상태' 셀을 'BLOCKED'로 변경하세요.";

          MailApp.sendEmail(DEVELOPER_EMAIL, subject, body);
        } catch (mailErr) {
          Logger.log("Email send failed: " + mailErr);
        }
      }

      return createJsonResponse({
        status: "APPROVED",
        message: "기기 인증 및 활성화가 완료되었습니다."
      });
    }

    return createJsonResponse({ status: "ERROR", message: "Unknown action" });
  } catch (err) {
    return createJsonResponse({ status: "ERROR", message: err.toString() });
  }
}

function createJsonResponse(data) {
  return ContentService.createTextOutput(JSON.stringify(data))
    .setMimeType(ContentService.MimeType.JSON);
}
