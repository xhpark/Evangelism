import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

enum LicenseStatus {
  unactivated,
  active,
  blocked,
}

/// 원격 승인 서버(Apps Script)와의 마지막 통신 결과.
/// 화면이 "정상 확인"을 임의로 단정하지 않고 실제 응답을 표시하기 위해 사용한다.
enum RemoteSyncResult {
  /// 아직 한 번도 조회하지 않음
  none,

  /// 서버가 승인 상태로 응답
  approved,

  /// 서버가 차단 상태로 응답
  blocked,

  /// 관리 시트에 기록이 없어 재등록을 시도함
  unregistered,

  /// 서명이 거부됨 — 앱 버전과 백엔드 버전이 어긋난 상태
  signatureRejected,

  /// 네트워크 오류 또는 응답 없음 (오프라인 포함)
  networkError,

  /// 연동 주소가 비어 있어 조회하지 않음
  notConfigured,
}

class LicenseService extends ChangeNotifier {
  static const String _prefKeyDeviceId = 'just_ee_device_uuid';
  static const String _prefKeyStatus = 'just_ee_license_status';
  static const String _prefKeyActivatedPin = 'just_ee_activated_pin';
  static const String _prefKeyUserName = 'just_ee_user_name';
  static const String _prefKeyUserAffiliation = 'just_ee_user_affiliation';
  static const String _prefKeyWebhookUrl = 'just_ee_gas_webhook_url';

  // 기본 마스터 인증키 목록 (대소문자/하이픈 무관)
  static const List<String> _masterPins = [
    'JUST-EE2026',
    'JUST-2026-EE77',
    'EE-MASTER-2026',
    'PARK-7788-9900',
  ];

  /// 백엔드(Apps Script)와 공유하는 요청 서명용 시크릿.
  /// 원문을 그대로 보내지 않고 `sha256(deviceId + secret)` 서명만 전송한다.
  /// ⚠️ 값을 바꾸면 Apps Script의 SHARED_SECRET도 함께 바꿔 재배포해야 한다.
  static const String _sharedSecret = 'JUSTEE-2026-GATEWAY-8f31c7';

  /// 텔레메트리에 기록되는 앱 버전. pubspec.yaml의 version과 함께 갱신할 것.
  static const String appVersion = '1.0.0+1';

  /// Apps Script 웹앱은 콜드 스타트 때문에 응답이 5초를 넘는 일이 잦다.
  /// (2026-08-29 실측: 승인 조회 5,024ms — 기존 5초 제한에 걸려 매번 조용히 실패했다)
  static const Duration _requestTimeout = Duration(seconds: 20);

  // 개발자 구글 앱스 스크립트 웹앱 기본 엔드포인트 (설정에서 변경 가능)
  String _webhookUrl =
      'https://script.google.com/macros/s/AKfycbxTv-TsaHH1c5iTCueHREF-c469i31b8KZM1AtRg_BS72kRSyNJ2yInrRFosas_SXM/exec';
  String _deviceId = '';
  LicenseStatus _status = LicenseStatus.unactivated;
  String _userName = '';
  String _userAffiliation = '';
  String _blockReason = '권리자의 승인이 취소되었거나 비인가 단말기로 등록되었습니다.';
  bool _isChecking = false;
  RemoteSyncResult _lastSyncResult = RemoteSyncResult.none;
  DateTime? _lastSyncAt;

  LicenseStatus get status => _status;
  String get deviceId => _deviceId;
  String get userName => _userName;
  String get userAffiliation => _userAffiliation;
  String get blockReason => _blockReason;
  bool get isChecking => _isChecking;
  bool get isActivated => _status == LicenseStatus.active;
  bool get isBlocked => _status == LicenseStatus.blocked;
  String get webhookUrl => _webhookUrl;

  /// 마지막 원격 조회 결과 (화면 표시용)
  RemoteSyncResult get lastSyncResult => _lastSyncResult;
  DateTime? get lastSyncAt => _lastSyncAt;

  /// 마지막 원격 조회 결과를 사용자에게 보여줄 문구로 변환한다.
  String get lastSyncMessage {
    switch (_lastSyncResult) {
      case RemoteSyncResult.approved:
        return '✅ 서버에서 승인 상태를 확인했습니다.';
      case RemoteSyncResult.blocked:
        return '⚠️ 이 단말기는 원격 차단된 상태입니다.';
      case RemoteSyncResult.unregistered:
        return 'ℹ️ 관리 목록에 없어 이 기기를 다시 등록했습니다. 잠시 후 한 번 더 눌러 확인해 주세요.';
      case RemoteSyncResult.signatureRejected:
        return '❌ 서버가 이 앱 버전을 거부했습니다. 최신 APK로 업데이트해야 원격 승인·차단이 동작합니다.';
      case RemoteSyncResult.networkError:
        return '❌ 서버에 연결하지 못했습니다. 인터넷 연결을 확인해 주세요. (승인 상태는 확인되지 않았습니다)';
      case RemoteSyncResult.notConfigured:
        return '❌ 구글 시트 연동 주소가 비어 있어 확인할 수 없습니다.';
      case RemoteSyncResult.none:
        return '아직 원격 확인을 하지 않았습니다.';
    }
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. 기기 고유 UUID 로드 또는 최초 발급
    _deviceId = prefs.getString(_prefKeyDeviceId) ?? '';
    if (_deviceId.isEmpty) {
      _deviceId = _generateUniqueDeviceId();
      await prefs.setString(_prefKeyDeviceId, _deviceId);
    }

    // 2. 저장된 라이선스 상태 로드
    final statusStr = prefs.getString(_prefKeyStatus) ?? 'unactivated';
    if (statusStr == 'active') {
      _status = LicenseStatus.active;
    } else if (statusStr == 'blocked') {
      _status = LicenseStatus.blocked;
    } else {
      _status = LicenseStatus.unactivated;
    }

    _userName = prefs.getString(_prefKeyUserName) ?? '';
    _userAffiliation = prefs.getString(_prefKeyUserAffiliation) ?? '';
    final savedWebhook = prefs.getString(_prefKeyWebhookUrl) ?? '';
    if (savedWebhook.isNotEmpty) {
      _webhookUrl = savedWebhook;
    }

    notifyListeners();

    // 3. 백그라운드에서 원격 킬 스위치 (상태 조회) 실행
    if (_status != LicenseStatus.unactivated) {
      checkRemoteKillSwitch();
    }
  }

  /// 기기 고유 식별자 생성 (형식: EE-XXXX-XXXX-XXXX)
  String _generateUniqueDeviceId() {
    final random = Random.secure();
    final bytes = List<int>.generate(8, (_) => random.nextInt(256));
    final hex = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join().toUpperCase();
    return 'EE-${hex.substring(0, 4)}-${hex.substring(4, 8)}-${hex.substring(8, 12)}';
  }

  /// 요청 서명 생성 (기기 UUID + 공유 시크릿의 SHA-256)
  String _requestSignature() =>
      sha256.convert(utf8.encode('$_deviceId|$_sharedSecret')).toString();

  /// 입력값이 유효한 마스터 인증키인지 검증만 수행 (활성화하지 않음).
  /// 설정 화면의 개발자 전용 기능(웹훅 URL 변경) 진입 게이트에 사용한다.
  bool verifyMasterPin(String inputPin) {
    final normalized =
        inputPin.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
    if (normalized.isEmpty) return false;
    for (final master in _masterPins) {
      final normMaster =
          master.replaceAll('-', '').replaceAll(' ', '').toUpperCase();
      if (normalized == normMaster) return true;
    }
    return false;
  }

  /// 마스터 PIN 검증 및 활성화 (방안 2 & 4)
  Future<bool> activateWithPin(
    String inputPin, {
    String userName = '',
    String affiliation = '',
  }) async {
    _isChecking = true;
    notifyListeners();

    // 내장 마스터 인증키 목록과 정확히 일치할 때만 활성화한다.
    // (2026-08-29: "JUST"로 시작하면 통과시키던 우회 분기를 제거)
    final isPinValid = verifyMasterPin(inputPin);

    if (!isPinValid) {
      _isChecking = false;
      notifyListeners();
      return false;
    }

    // 3. 인증 성공 시 로컬 상태 저장
    final prefs = await SharedPreferences.getInstance();
    _status = LicenseStatus.active;
    _userName = userName;
    _userAffiliation = affiliation;
    await prefs.setString(_prefKeyStatus, 'active');
    await prefs.setString(_prefKeyActivatedPin, inputPin);
    await prefs.setString(_prefKeyUserName, userName);
    await prefs.setString(_prefKeyUserAffiliation, affiliation);

    _isChecking = false;
    notifyListeners();

    // 4. 신규 기기 활성화 실시간 텔레메트리 전송 (방안 4)
    _sendTelemetry(
      action: 'activate',
      pin: inputPin,
      userName: userName,
      affiliation: affiliation,
    );

    return true;
  }

  /// 원격 킬 스위치 상태 점검 (방안 1)
  ///
  /// 조회 결과를 [lastSyncResult]에 기록한다. 화면은 이 값을 보고 안내해야 하며,
  /// 로컬 상태(isBlocked)만 보고 "정상"이라고 단정해서는 안 된다.
  /// (2026-08-29: 통신 실패·서명 거부까지 "정상 확인"으로 표시되던 문제)
  Future<void> checkRemoteKillSwitch() async {
    if (_webhookUrl.isEmpty) {
      _lastSyncResult = RemoteSyncResult.notConfigured;
      _lastSyncAt = DateTime.now();
      notifyListeners();
      return;
    }

    try {
      final uri = Uri.parse(_webhookUrl).replace(queryParameters: {
        'action': 'check_status',
        'device_id': _deviceId,
        'sig': _requestSignature(),
      });

      final response = await http.get(uri).timeout(_requestTimeout);
      _lastSyncAt = DateTime.now();

      if (response.statusCode != 200) {
        _lastSyncResult = RemoteSyncResult.networkError;
        notifyListeners();
        return;
      }

      {
        final data = jsonDecode(response.body);
        final remoteStatus = data['status']?.toString().toUpperCase();

        final prefs = await SharedPreferences.getInstance();
        if (remoteStatus == 'BLOCKED' || remoteStatus == 'REVOKED') {
          _lastSyncResult = RemoteSyncResult.blocked;
          _status = LicenseStatus.blocked;
          _blockReason = data['message'] ?? '권리자에 의해 사용이 원격 차단되었습니다.';
          await prefs.setString(_prefKeyStatus, 'blocked');
          notifyListeners();
        } else if (remoteStatus == 'DENIED') {
          // 서명 거부: 앱이 구버전이거나 공유 시크릿이 어긋난 상태.
          // 이 상태에서는 원격 차단이 동작하지 않으므로 반드시 사용자에게 알린다.
          _lastSyncResult = RemoteSyncResult.signatureRejected;
          notifyListeners();
        } else if (remoteStatus == 'APPROVED') {
          _lastSyncResult = RemoteSyncResult.approved;
          if (_status == LicenseStatus.blocked) {
            _status = LicenseStatus.active;
            await prefs.setString(_prefKeyStatus, 'active');
          }
          notifyListeners();
        } else if (remoteStatus == 'UNREGISTERED' &&
            _status == LicenseStatus.active) {
          _lastSyncResult = RemoteSyncResult.unregistered;
          // 활성 상태인데 관리 시트에 기록이 없는 경우(앱 데이터 삭제 후 재설치 등)
          // 스스로 재등록하여 항상 원격 차단 대상이 되도록 한다.
          final savedPin = prefs.getString(_prefKeyActivatedPin) ?? '';
          final registered = await _sendTelemetry(
            action: 'activate',
            pin: savedPin,
            userName: _userName,
            affiliation: _userAffiliation,
          );
          if (!registered) {
            _lastSyncResult = RemoteSyncResult.networkError;
          }
          notifyListeners();
        } else {
          _lastSyncResult = RemoteSyncResult.networkError;
          notifyListeners();
        }
      }
    } catch (e) {
      _lastSyncResult = RemoteSyncResult.networkError;
      _lastSyncAt = DateTime.now();
      notifyListeners();
      debugPrint('Kill-switch remote check offline/skipped: $e');
    }
  }

  /// Apps Script 웹앱은 POST에도 302 리다이렉트로 응답한다.
  /// dart:io HttpClient는 GET/HEAD만 자동으로 따라가므로 직접 한 번 더 요청해야
  /// 서버가 실제로 무엇이라 답했는지(등록 성공/인증키 거부 등)를 읽을 수 있다.
  Future<http.Response> _postFollowingRedirect(
      Uri uri, Map<String, dynamic> payload) async {
    final response = await http
        .post(uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload))
        .timeout(_requestTimeout);

    if (response.statusCode == 302 ||
        response.statusCode == 303 ||
        response.statusCode == 307) {
      final location = response.headers['location'];
      if (location != null && location.isNotEmpty) {
        return await http.get(Uri.parse(location)).timeout(_requestTimeout);
      }
    }
    return response;
  }

  /// 신규 기기 등록 및 텔레메트리 알림 전송 (방안 4)
  ///
  /// 서버가 등록을 확인하면 true. 거부되거나 통신에 실패하면 false.
  Future<bool> _sendTelemetry({
    required String action,
    required String pin,
    required String userName,
    required String affiliation,
  }) async {
    if (_webhookUrl.isEmpty) return false;

    try {
      final payload = {
        'action': action,
        'device_id': _deviceId,
        'user_name': userName.isEmpty ? '훈련생' : userName,
        'affiliation': affiliation.isEmpty ? '미입력' : affiliation,
        'pin': pin,
        'os': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': appVersion,
        'sig': _requestSignature(),
      };

      final response =
          await _postFollowingRedirect(Uri.parse(_webhookUrl), payload);

      if (response.statusCode != 200 || response.body.isEmpty) {
        debugPrint('Telemetry: 응답을 확인하지 못했습니다 (${response.statusCode})');
        return false;
      }

      final data = jsonDecode(response.body);
      final status = data['status']?.toString().toUpperCase();
      debugPrint('Telemetry 등록 결과: $status');
      return status == 'APPROVED' || status == 'BLOCKED';
    } catch (e) {
      debugPrint('Telemetry send failed (non-blocking): $e');
      return false;
    }
  }

  /// 웹훅 URL 업데이트 (개발자 원격 연동용)
  Future<void> setWebhookUrl(String url) async {
    _webhookUrl = url.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyWebhookUrl, _webhookUrl);
    notifyListeners();
    if (_webhookUrl.isNotEmpty) {
      checkRemoteKillSwitch();
    }
  }

  /// 강제 차단 (테스트 및 로컬 킬스위치 시뮬레이션용)
  Future<void> setBlocked(bool blocked, {String? reason}) async {
    _status = blocked ? LicenseStatus.blocked : LicenseStatus.active;
    if (reason != null) _blockReason = reason;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyStatus, blocked ? 'blocked' : 'active');
    notifyListeners();
  }

  /// 라이선스 초기화 (재인증 테스트용)
  Future<void> resetLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyStatus);
    await prefs.remove(_prefKeyActivatedPin);
    await prefs.remove(_prefKeyUserName);
    await prefs.remove(_prefKeyUserAffiliation);
    _status = LicenseStatus.unactivated;
    _userName = '';
    _userAffiliation = '';
    notifyListeners();
  }
}
