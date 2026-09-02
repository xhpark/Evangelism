import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'license_token_store.dart';

enum LicenseStatus { unactivated, active, blocked }

enum RemoteSyncResult {
  none,
  approved,
  blocked,
  activationDenied,
  serverError,
  tokenRejected,
  networkError,
  notConfigured,
  reactivationRequired,
}

class LicenseService extends ChangeNotifier {
  static const String _prefKeyDeviceId = 'just_ee_device_uuid';
  static const String _prefKeyStatus = 'just_ee_license_status';
  static const String _prefKeyUserName = 'just_ee_user_name';
  static const String _prefKeyUserAffiliation = 'just_ee_user_affiliation';
  static const String _prefKeyLastApprovedAt =
      'just_ee_license_last_approved_at';

  static const String _configuredApiUrl = String.fromEnvironment(
    'LICENSE_API_URL',
  );
  static const Duration _requestTimeout = Duration(seconds: 20);

  final http.Client _httpClient;
  final LicenseTokenStore _tokenStore;
  final String _apiUrl;
  final Future<String> Function() _appVersionLoader;
  final bool _ownsHttpClient;

  String _deviceId = '';
  String _deviceToken = '';
  String _appVersion = 'unknown';
  LicenseStatus _status = LicenseStatus.unactivated;
  String _userName = '';
  String _userAffiliation = '';
  String _blockReason = '권리자의 승인이 취소되었거나 비인가 단말기로 등록되었습니다.';
  bool _isChecking = false;
  bool _requiresReactivation = false;
  RemoteSyncResult _lastSyncResult = RemoteSyncResult.none;
  DateTime? _lastSyncAt;
  DateTime? _lastApprovedAt;

  LicenseService({
    http.Client? httpClient,
    LicenseTokenStore? tokenStore,
    String? apiUrl,
    Future<String> Function()? appVersionLoader,
  }) : _httpClient = httpClient ?? http.Client(),
       _tokenStore = tokenStore ?? SecureLicenseTokenStore(),
       _apiUrl = (apiUrl ?? _configuredApiUrl).trim(),
       _appVersionLoader = appVersionLoader ?? _loadInstalledVersion,
       _ownsHttpClient = httpClient == null;

  LicenseStatus get status => _status;
  String get deviceId => _deviceId;
  String get userName => _userName;
  String get userAffiliation => _userAffiliation;
  String get appVersion => _appVersion;
  String get blockReason => _blockReason;
  bool get isChecking => _isChecking;
  bool get isActivated => _status == LicenseStatus.active;
  bool get isBlocked => _status == LicenseStatus.blocked;
  bool get requiresReactivation => _requiresReactivation;
  bool get isRemoteConfigured => _validatedEndpoint() != null;
  RemoteSyncResult get lastSyncResult => _lastSyncResult;
  DateTime? get lastSyncAt => _lastSyncAt;
  DateTime? get lastApprovedAt => _lastApprovedAt;

  String get lastSyncMessage {
    switch (_lastSyncResult) {
      case RemoteSyncResult.approved:
        return '✅ 서버에서 이 기기의 승인 상태를 확인했습니다.';
      case RemoteSyncResult.blocked:
        return '⚠️ 이 단말기는 원격 차단된 상태입니다.';
      case RemoteSyncResult.activationDenied:
        return '❌ 활성화 코드가 유효하지 않거나 이미 사용되었습니다.';
      case RemoteSyncResult.serverError:
        return '❌ 라이선스 서버가 요청을 처리하지 못했습니다. 잠시 후 다시 시도하거나 관리자에게 문의해 주세요.';
      case RemoteSyncResult.tokenRejected:
        return '❌ 기기 인증 토큰이 만료되었거나 취소되었습니다. 새 활성화 코드가 필요합니다.';
      case RemoteSyncResult.networkError:
        return '❌ 서버에 연결하지 못했습니다. 인터넷 연결을 확인해 주세요.';
      case RemoteSyncResult.notConfigured:
        return '❌ 라이선스 서버 주소가 빌드에 설정되지 않았습니다.';
      case RemoteSyncResult.reactivationRequired:
        return 'ℹ️ 보안 방식이 변경되어 한 번의 재인증이 필요합니다. 사용자 대본과 기록은 유지됩니다.';
      case RemoteSyncResult.none:
        return '아직 원격 확인을 하지 않았습니다.';
    }
  }

  static Future<String> _loadInstalledVersion() async {
    final info = await PackageInfo.fromPlatform();
    return '${info.version}+${info.buildNumber}';
  }

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _deviceId = (prefs.getString(_prefKeyDeviceId) ?? '').trim().toUpperCase();
    if (_legacyDeviceIdPattern.hasMatch(_deviceId)) {
      // 1.0.0 이하에서는 마지막 4자리 그룹이 빠진 기기 코드를 저장했다.
      // 사용자 데이터는 유지하면서 새 서버가 허용하는 형식으로 한 번만 확장한다.
      _deviceId = '$_deviceId-${_randomHex(2)}';
      await prefs.setString(_prefKeyDeviceId, _deviceId);
    } else if (!_currentDeviceIdPattern.hasMatch(_deviceId)) {
      _deviceId = _generateUniqueDeviceId();
      await prefs.setString(_prefKeyDeviceId, _deviceId);
    }

    _userName = prefs.getString(_prefKeyUserName) ?? '';
    _userAffiliation = prefs.getString(_prefKeyUserAffiliation) ?? '';
    _lastApprovedAt = DateTime.tryParse(
      prefs.getString(_prefKeyLastApprovedAt) ?? '',
    );
    _deviceToken = (await _tokenStore.read())?.trim() ?? '';

    try {
      _appVersion = await _appVersionLoader();
    } catch (_) {
      _appVersion = 'unknown';
    }

    final savedStatus = prefs.getString(_prefKeyStatus) ?? 'unactivated';
    if (savedStatus == 'blocked') {
      _status = LicenseStatus.blocked;
    } else if (savedStatus == 'active' && _deviceToken.isNotEmpty) {
      _status = LicenseStatus.active;
    } else if (savedStatus == 'active') {
      _status = LicenseStatus.unactivated;
      _requiresReactivation = true;
      _lastSyncResult = RemoteSyncResult.reactivationRequired;
      await prefs.setString(_prefKeyStatus, 'unactivated');
    } else {
      _status = LicenseStatus.unactivated;
    }

    notifyListeners();

    if (_status == LicenseStatus.active) {
      await checkRemoteKillSwitch();
    }
  }

  String _generateUniqueDeviceId() {
    final hex = _randomHex(8);
    return 'EE-${hex.substring(0, 4)}-${hex.substring(4, 8)}-${hex.substring(8, 12)}-${hex.substring(12, 16)}';
  }

  static final RegExp _currentDeviceIdPattern = RegExp(
    r'^EE-(?:[0-9A-F]{4}-){3}[0-9A-F]{4}$',
  );
  static final RegExp _legacyDeviceIdPattern = RegExp(
    r'^EE-(?:[0-9A-F]{4}-){2}[0-9A-F]{4}$',
  );

  String _randomHex(int byteCount) {
    final random = Random.secure();
    return List<int>.generate(byteCount, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join()
        .toUpperCase();
  }

  Uri? _validatedEndpoint() {
    final uri = Uri.tryParse(_apiUrl);
    if (uri == null ||
        !uri.isScheme('https') ||
        uri.host != 'script.google.com' ||
        !uri.path.startsWith('/macros/s/') ||
        !uri.path.endsWith('/exec')) {
      return null;
    }
    return uri;
  }

  Future<bool> activateWithCode(
    String activationCode, {
    required String userName,
    required String affiliation,
  }) async {
    if (_isChecking) return false;
    final endpoint = _validatedEndpoint();
    if (endpoint == null) {
      _lastSyncResult = RemoteSyncResult.notConfigured;
      _lastSyncAt = DateTime.now();
      notifyListeners();
      return false;
    }

    _isChecking = true;
    _lastSyncResult = RemoteSyncResult.none;
    notifyListeners();

    try {
      final response = await _postFollowingRedirect(endpoint, {
        'action': 'activate',
        'device_id': _deviceId,
        'activation_code': activationCode.trim(),
        'user_name': userName.trim(),
        'affiliation': affiliation.trim(),
        'os': Platform.operatingSystem,
        'os_version': Platform.operatingSystemVersion,
        'app_version': _appVersion,
      });
      _lastSyncAt = DateTime.now();

      if (response.statusCode != 200 || response.body.isEmpty) {
        _lastSyncResult = RemoteSyncResult.networkError;
        return false;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final remoteStatus = data['status']?.toString().toUpperCase();
      if (remoteStatus == 'BLOCKED' || remoteStatus == 'REVOKED') {
        await _persistBlocked(data['message']?.toString());
        return false;
      }

      final issuedToken = data['device_token']?.toString().trim() ?? '';
      if (remoteStatus == 'DENIED') {
        _lastSyncResult = RemoteSyncResult.activationDenied;
        return false;
      }
      if (remoteStatus != 'APPROVED' || issuedToken.isEmpty) {
        _lastSyncResult = RemoteSyncResult.serverError;
        return false;
      }

      await _tokenStore.write(issuedToken);
      _deviceToken = issuedToken;
      _status = LicenseStatus.active;
      _requiresReactivation = false;
      _userName = userName.trim();
      _userAffiliation = affiliation.trim();
      _lastSyncResult = RemoteSyncResult.approved;
      _lastApprovedAt = DateTime.now();

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyStatus, 'active');
      await prefs.setString(_prefKeyUserName, _userName);
      await prefs.setString(_prefKeyUserAffiliation, _userAffiliation);
      await prefs.setString(
        _prefKeyLastApprovedAt,
        _lastApprovedAt!.toIso8601String(),
      );
      return true;
    } catch (error) {
      _lastSyncResult = RemoteSyncResult.networkError;
      _lastSyncAt = DateTime.now();
      debugPrint('License activation failed: $error');
      return false;
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> checkRemoteKillSwitch() async {
    if (_isChecking || _status == LicenseStatus.unactivated) return;
    final endpoint = _validatedEndpoint();
    if (endpoint == null) {
      _lastSyncResult = RemoteSyncResult.notConfigured;
      _lastSyncAt = DateTime.now();
      notifyListeners();
      return;
    }
    if (_deviceToken.isEmpty) {
      await _invalidateLocalLicense(RemoteSyncResult.reactivationRequired);
      return;
    }

    _isChecking = true;
    notifyListeners();
    try {
      final response = await _postFollowingRedirect(endpoint, {
        'action': 'check_status',
        'device_id': _deviceId,
        'device_token': _deviceToken,
        'app_version': _appVersion,
      });
      _lastSyncAt = DateTime.now();

      if (response.statusCode != 200 || response.body.isEmpty) {
        _lastSyncResult = RemoteSyncResult.networkError;
        return;
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final remoteStatus = data['status']?.toString().toUpperCase();
      if (remoteStatus == 'BLOCKED' || remoteStatus == 'REVOKED') {
        await _persistBlocked(data['message']?.toString());
      } else if (remoteStatus == 'APPROVED') {
        _status = LicenseStatus.active;
        _lastSyncResult = RemoteSyncResult.approved;
        _lastApprovedAt = DateTime.now();
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          _prefKeyLastApprovedAt,
          _lastApprovedAt!.toIso8601String(),
        );
        await prefs.setString(_prefKeyStatus, 'active');
      } else if (remoteStatus == 'DENIED' || remoteStatus == 'UNREGISTERED') {
        await _invalidateLocalLicense(RemoteSyncResult.tokenRejected);
      } else {
        _lastSyncResult = RemoteSyncResult.networkError;
      }
    } catch (error) {
      _lastSyncResult = RemoteSyncResult.networkError;
      _lastSyncAt = DateTime.now();
      debugPrint('License status check failed: $error');
    } finally {
      _isChecking = false;
      notifyListeners();
    }
  }

  Future<void> _persistBlocked(String? reason) async {
    _lastSyncResult = RemoteSyncResult.blocked;
    _status = LicenseStatus.blocked;
    if (reason != null && reason.trim().isNotEmpty) {
      _blockReason = reason.trim();
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyStatus, 'blocked');
  }

  Future<void> _invalidateLocalLicense(RemoteSyncResult result) async {
    _lastSyncResult = result;
    _status = LicenseStatus.unactivated;
    _requiresReactivation = true;
    _deviceToken = '';
    await _tokenStore.delete();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyStatus, 'unactivated');
  }

  Future<http.Response> _postFollowingRedirect(
    Uri uri,
    Map<String, dynamic> payload,
  ) async {
    final response = await _httpClient
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(_requestTimeout);

    if (response.statusCode == 302 ||
        response.statusCode == 303 ||
        response.statusCode == 307 ||
        response.statusCode == 308) {
      final location = response.headers['location'];
      final redirectUri = location == null ? null : Uri.tryParse(location);
      if (redirectUri != null &&
          redirectUri.isScheme('https') &&
          (redirectUri.host.endsWith('.googleusercontent.com') ||
              redirectUri.host == 'script.google.com')) {
        return _httpClient.get(redirectUri).timeout(_requestTimeout);
      }
    }
    return response;
  }

  @visibleForTesting
  Future<void> setBlocked(bool blocked, {String? reason}) async {
    _status = blocked ? LicenseStatus.blocked : LicenseStatus.active;
    if (reason != null) _blockReason = reason;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKeyStatus, blocked ? 'blocked' : 'active');
    notifyListeners();
  }

  @visibleForTesting
  Future<void> resetLicense() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_prefKeyStatus);
    await prefs.remove(_prefKeyUserName);
    await prefs.remove(_prefKeyUserAffiliation);
    await prefs.remove(_prefKeyLastApprovedAt);
    await _tokenStore.delete();
    _deviceToken = '';
    _status = LicenseStatus.unactivated;
    _userName = '';
    _userAffiliation = '';
    _lastApprovedAt = null;
    notifyListeners();
  }

  @override
  void dispose() {
    if (_ownsHttpClient) _httpClient.close();
    super.dispose();
  }
}
