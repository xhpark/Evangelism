import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_ee_master/services/license_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('License PIN 게이트 회귀 테스트 (TS-SEC-001 ~ 003)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('TS-SEC-001: "JUST"로 시작하는 임의 문자열은 활성화되지 않는다', () async {
      // 2026-08-29 이전에는 JUST로 시작하고 8자 이상이면 무조건 통과하는 우회로가 있었다.
      const bypassAttempts = [
        'JUSTABCD',
        'JUST1234',
        'JUSTINBIEBER',
        'JUST-XXXX-YYYY',
        'JUSTEE9999',
      ];

      for (final pin in bypassAttempts) {
        SharedPreferences.setMockInitialValues({});
        final service = LicenseService();
        await service.initialize();

        final ok = await service.activateWithPin(pin, userName: '테스트', affiliation: '테스트');
        expect(ok, isFalse, reason: '$pin 이(가) 통과되면 안 됩니다.');
        expect(service.isActivated, isFalse);
      }
    });

    test('TS-SEC-002: 발급된 마스터 인증키만 활성화된다 (하이픈/대소문자 무관)', () async {
      final service = LicenseService();
      await service.initialize();

      expect(service.verifyMasterPin('JUST-EE2026'), isTrue);
      expect(service.verifyMasterPin('justee2026'), isTrue);
      expect(service.verifyMasterPin(''), isFalse);
      expect(service.verifyMasterPin('JUST-EE2027'), isFalse);
    });

    test('TS-SEC-003: 기기 고유 코드는 EE-XXXX-XXXX-XXXX 형식으로 발급된다', () async {
      final service = LicenseService();
      await service.initialize();

      expect(
        RegExp(r'^EE-[0-9A-F]{4}-[0-9A-F]{4}-[0-9A-F]{4}$').hasMatch(service.deviceId),
        isTrue,
        reason: '발급된 코드: ${service.deviceId}',
      );
    });
  });

  group('원격 동기화 결과 표시 (TS-SEC-004)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('TS-SEC-004: 통신하지 못하면 "정상"이 아니라 실패로 보고한다', () async {
      final service = LicenseService();
      await service.initialize();

      // 테스트 환경에서는 실제 HTTP 호출이 실패한다.
      // 이때 결과가 approved로 남으면 화면이 거짓 양성을 보여주게 된다.
      await service.checkRemoteKillSwitch();

      expect(service.lastSyncResult, isNot(RemoteSyncResult.approved));
      expect(service.lastSyncMessage, isNot(contains('승인 상태를 확인했습니다')));
    });

    test('TS-SEC-005: 연동 주소가 비면 미설정으로 보고한다', () async {
      final service = LicenseService();
      await service.initialize();
      await service.setWebhookUrl('');

      await service.checkRemoteKillSwitch();
      expect(service.lastSyncResult, equals(RemoteSyncResult.notConfigured));
    });
  });
}
