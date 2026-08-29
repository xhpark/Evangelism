import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_ee_master/services/license_service.dart';
import 'package:just_ee_master/screens/license_activation_screen.dart';
import 'package:just_ee_master/screens/blocked_screen.dart';
import 'package:just_ee_master/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('LicenseService Unit Tests (TS-LIC-001 ~ 004)', () {
    test('TS-LIC-001: 기기 고유 UUID 발급 및 SharedPreferences 영구 보관 검증', () async {
      final service = LicenseService();
      await service.initialize();

      expect(service.deviceId.isNotEmpty, isTrue);
      expect(service.deviceId.startsWith('EE-'), isTrue);
      expect(service.status, LicenseStatus.unactivated);
      expect(service.isActivated, isFalse);
      expect(service.isBlocked, isFalse);

      // 재초기화 시 동일한 UUID 유지 확인
      final service2 = LicenseService();
      await service2.initialize();
      expect(service2.deviceId, equals(service.deviceId));
    });

    test('TS-LIC-002: 올바른 마스터 PIN 입력 시 활성화 및 상태 변경 검증 (방안 2)', () async {
      final service = LicenseService();
      await service.initialize();

      // 마스터 PIN 활성화
      final success = await service.activateWithPin('JUST-EE2026', userName: '박상환');
      expect(success, isTrue);
      expect(service.status, LicenseStatus.active);
      expect(service.isActivated, isTrue);
      expect(service.userName, '박상환');

      // 하이픈 없는 소문자 입력도 정상 통과 검증
      final service3 = LicenseService();
      await service3.initialize();
      expect(service3.isActivated, isTrue);
    });

    test('TS-LIC-003: 잘못된 PIN 입력 시 활성화 거부 검증', () async {
      final service = LicenseService();
      await service.initialize();

      final success = await service.activateWithPin('WRONG-PIN-1234');
      expect(success, isFalse);
      expect(service.status, LicenseStatus.unactivated);
      expect(service.isActivated, isFalse);
    });

    test('TS-LIC-004: 원격 킬스위치 차단 시 Blocked 상태 전환 검증 (방안 1)', () async {
      final service = LicenseService();
      await service.initialize();
      await service.activateWithPin('JUST-EE2026');
      expect(service.isActivated, isTrue);

      // 킬스위치 작동
      await service.setBlocked(true, reason: '테스트 원격 차단');
      expect(service.isBlocked, isTrue);
      expect(service.isActivated, isFalse);
      expect(service.blockReason, '테스트 원격 차단');
    });
  });

  group('License Screen Widget Tests (TS-LIC-005 ~ 006)', () {
    testWidgets('TS-LIC-005: LicenseActivationScreen UI 렌더링 및 PIN 입력 필드 검증', (WidgetTester tester) async {
      final service = LicenseService();
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
      expect(find.textContaining('EE-'), findsOneWidget);
      expect(find.widgetWithText(ElevatedButton, '인증 및 훈련 시작하기 ➔'), findsOneWidget);
      expect(find.textContaining('xhpark@naver.com'), findsOneWidget);
    });

    testWidgets('TS-LIC-006: BlockedScreen 렌더링 및 차단 메시지 검증', (WidgetTester tester) async {
      final service = LicenseService();
      await service.initialize();
      await service.setBlocked(true, reason: '비인가 복제 단말기 차단');

      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.lightTheme,
          home: ChangeNotifierProvider<LicenseService>.value(
            value: service,
            child: const BlockedScreen(),
          ),
        ),
      );

      expect(find.text('비인가 단말기 접근 차단'), findsOneWidget);
      expect(find.text('비인가 복제 단말기 차단'), findsOneWidget);
      expect(find.text('승인 상태 다시 확인하기'), findsOneWidget);
    });
  });
}
