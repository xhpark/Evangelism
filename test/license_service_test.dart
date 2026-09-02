import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:just_ee_master/screens/blocked_screen.dart';
import 'package:just_ee_master/screens/license_activation_screen.dart';
import 'package:just_ee_master/services/license_service.dart';
import 'package:just_ee_master/services/license_token_store.dart';
import 'package:just_ee_master/theme/app_theme.dart';

const _endpoint = 'https://script.google.com/macros/s/test/exec';

LicenseService _service(MockClient client, MemoryLicenseTokenStore tokens) =>
    LicenseService(
      httpClient: client,
      tokenStore: tokens,
      apiUrl: _endpoint,
      appVersionLoader: () async => 'test',
    );

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('TS-LIC-001: 기기 코드가 영구 보관된다', () async {
    final client = MockClient((_) async => http.Response('{}', 500));
    final tokens = MemoryLicenseTokenStore();
    final first = _service(client, tokens);
    await first.initialize();
    final second = _service(client, tokens);
    await second.initialize();

    expect(first.deviceId, matches(r'^EE-(?:[0-9A-F]{4}-){3}[0-9A-F]{4}$'));
    expect(second.deviceId, first.deviceId);
    expect(first.status, LicenseStatus.unactivated);
  });

  test('TS-LIC-007: 구형 3그룹 기기 코드는 데이터 삭제 없이 4그룹으로 확장된다', () async {
    SharedPreferences.setMockInitialValues({
      'just_ee_device_uuid': 'EE-1111-2222-3333',
      'unrelated_user_data': 'preserved',
    });
    final client = MockClient((_) async => http.Response('{}', 500));
    final service = _service(client, MemoryLicenseTokenStore());

    await service.initialize();

    expect(service.deviceId, matches(r'^EE-1111-2222-3333-[0-9A-F]{4}$'));
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getString('just_ee_device_uuid'), service.deviceId);
    expect(prefs.getString('unrelated_user_data'), 'preserved');
  });

  test('TS-LIC-002: 서버 승인과 토큰이 있어야 활성화된다', () async {
    final tokens = MemoryLicenseTokenStore();
    final client = MockClient((request) async {
      final body = jsonDecode(request.body) as Map<String, dynamic>;
      expect(body['activation_code'], 'TEST-CODE');
      return http.Response(
        jsonEncode({'status': 'APPROVED', 'device_token': 'device-token'}),
        200,
      );
    });
    final service = _service(client, tokens);
    await service.initialize();

    expect(
      await service.activateWithCode(
        'TEST-CODE',
        userName: '테스트 사용자',
        affiliation: '테스트 소속',
      ),
      isTrue,
    );
    expect(service.isActivated, isTrue);
    expect(await tokens.read(), 'device-token');
  });

  test('TS-LIC-003: 서버가 거부한 코드는 로컬 활성화되지 않는다', () async {
    final service = _service(
      MockClient((_) async => http.Response('{"status":"DENIED"}', 200)),
      MemoryLicenseTokenStore(),
    );
    await service.initialize();

    final success = await service.activateWithCode(
      'REJECTED',
      userName: '테스트',
      affiliation: '테스트',
    );
    expect(success, isFalse);
    expect(service.isActivated, isFalse);
    expect(service.lastSyncResult, RemoteSyncResult.activationDenied);
  });

  test('TS-LIC-008: 서버 처리 오류를 코드 거부로 오표시하지 않는다', () async {
    final service = _service(
      MockClient((_) async => http.Response('{"status":"ERROR"}', 200)),
      MemoryLicenseTokenStore(),
    );
    await service.initialize();

    final success = await service.activateWithCode(
      'VALID-FORMAT-CODE',
      userName: '테스트',
      affiliation: '테스트',
    );

    expect(success, isFalse);
    expect(service.lastSyncResult, RemoteSyncResult.serverError);
    expect(service.lastSyncMessage, contains('서버가 요청을 처리하지 못했습니다'));
    expect(service.lastSyncMessage, isNot(contains('이미 사용')));
  });

  test('TS-LIC-004: 서버에서 차단을 해제하면 같은 토큰으로 다시 활성화된다', () async {
    SharedPreferences.setMockInitialValues({
      'just_ee_license_status': 'blocked',
      'just_ee_device_uuid': 'EE-1111-2222-3333-4444',
    });
    final service = _service(
      MockClient((_) async => http.Response('{"status":"APPROVED"}', 200)),
      MemoryLicenseTokenStore(token: 'device-token'),
    );
    await service.initialize();
    expect(service.isBlocked, isTrue);

    await service.checkRemoteKillSwitch();
    expect(service.isActivated, isTrue);
    expect(service.lastSyncResult, RemoteSyncResult.approved);
  });

  testWidgets('TS-LIC-005: 활성화 화면은 일회용 코드 입력을 안내한다', (tester) async {
    final service = _service(
      MockClient((_) async => http.Response('{}', 500)),
      MemoryLicenseTokenStore(),
    );
    await service.initialize();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ChangeNotifierProvider<LicenseService>.value(
          value: service,
          child: const LicenseActivationScreen(),
        ),
      ),
    );

    expect(find.text('정식 훈련생 기기 인증'), findsOneWidget);
    expect(find.text('일회용 활성화 코드 *'), findsOneWidget);
    expect(find.text('인증 및 훈련 시작하기'), findsOneWidget);
  });

  testWidgets('TS-LIC-006: 차단 화면에 서버 사유가 표시된다', (tester) async {
    final service = _service(
      MockClient((_) async => http.Response('{}', 500)),
      MemoryLicenseTokenStore(),
    );
    await service.initialize();
    await service.setBlocked(true, reason: '테스트 원격 차단');
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: ChangeNotifierProvider<LicenseService>.value(
          value: service,
          child: const BlockedScreen(),
        ),
      ),
    );
    expect(find.text('테스트 원격 차단'), findsOneWidget);
  });
}
