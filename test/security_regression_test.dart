import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:just_ee_master/services/license_service.dart';
import 'package:just_ee_master/services/license_token_store.dart';

const _endpoint = 'https://script.google.com/macros/s/test/exec';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('TS-SEC-001: 코드 형태만으로는 활성화되지 않는다', () async {
    var requestCount = 0;
    final service = LicenseService(
      httpClient: MockClient((_) async {
        requestCount++;
        return http.Response('{"status":"DENIED"}', 200);
      }),
      tokenStore: MemoryLicenseTokenStore(),
      apiUrl: _endpoint,
      appVersionLoader: () async => 'test',
    );
    await service.initialize();

    for (final attempt in ['PREFIX-ABCD', 'ARBITRARY-CODE', '12345678']) {
      expect(
        await service.activateWithCode(
          attempt,
          userName: '테스트',
          affiliation: '테스트',
        ),
        isFalse,
      );
    }
    expect(requestCount, 3);
    expect(service.isActivated, isFalse);
  });

  test('TS-SEC-002: 승인 상태 확인에는 저장된 기기 토큰을 사용한다', () async {
    final tokens = MemoryLicenseTokenStore(token: 'issued-token');
    SharedPreferences.setMockInitialValues({
      'just_ee_license_status': 'active',
      'just_ee_device_uuid': 'EE-1111-2222-3333-4444',
    });
    final service = LicenseService(
      httpClient: MockClient((request) async {
        final body = jsonDecode(request.body) as Map<String, dynamic>;
        expect(body['device_token'], 'issued-token');
        expect(body.containsKey('activation_code'), isFalse);
        return http.Response('{"status":"APPROVED"}', 200);
      }),
      tokenStore: tokens,
      apiUrl: _endpoint,
      appVersionLoader: () async => 'test',
    );
    await service.initialize();
    expect(service.lastSyncResult, RemoteSyncResult.approved);
  });

  test('TS-SEC-003: 서버가 토큰을 거부하면 로컬 승인도 해제한다', () async {
    final tokens = MemoryLicenseTokenStore(token: 'revoked-token');
    SharedPreferences.setMockInitialValues({
      'just_ee_license_status': 'active',
      'just_ee_device_uuid': 'EE-1111-2222-3333-4444',
    });
    final service = LicenseService(
      httpClient: MockClient(
        (_) async => http.Response('{"status":"DENIED"}', 200),
      ),
      tokenStore: tokens,
      apiUrl: _endpoint,
      appVersionLoader: () async => 'test',
    );
    await service.initialize();

    expect(service.isActivated, isFalse);
    expect(service.lastSyncResult, RemoteSyncResult.tokenRejected);
    expect(await tokens.read(), isNull);
  });

  test('TS-SEC-004: 허용된 Apps Script HTTPS 주소만 사용한다', () async {
    final service = LicenseService(
      httpClient: MockClient((_) async => http.Response('{}', 200)),
      tokenStore: MemoryLicenseTokenStore(),
      apiUrl: 'https://example.com/macros/s/test/exec',
      appVersionLoader: () async => 'test',
    );
    await service.initialize();
    expect(service.isRemoteConfigured, isFalse);
    expect(
      await service.activateWithCode(
        'CODE',
        userName: '테스트',
        affiliation: '테스트',
      ),
      isFalse,
    );
    expect(service.lastSyncResult, RemoteSyncResult.notConfigured);
  });
}
