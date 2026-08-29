import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_ee_master/data/script_repository.dart';
import 'package:just_ee_master/providers/study_provider.dart';
import 'package:just_ee_master/providers/quick_trigger_provider.dart';
import 'package:just_ee_master/providers/scripture_provider.dart';
import 'package:just_ee_master/providers/voice_exam_provider.dart';
import 'package:just_ee_master/providers/script_manage_provider.dart';
import 'package:just_ee_master/screens/main_navigation_screen.dart';
import 'package:just_ee_master/screens/welcome_terms_screen.dart';
import 'package:just_ee_master/services/license_service.dart';
import 'package:just_ee_master/theme/app_theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test: BottomNavigationBar 5개 탭 렌더링 확인', (WidgetTester tester) async {
    final repository = ScriptRepository();
    final licenseService = LicenseService();
    await licenseService.initialize();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<ScriptRepository>.value(value: repository),
          ChangeNotifierProvider<LicenseService>.value(value: licenseService),
          ChangeNotifierProvider(create: (_) => StudyProvider(repository)),
          ChangeNotifierProvider(create: (_) => QuickTriggerProvider(repository)),
          ChangeNotifierProvider(create: (_) => ScriptureProvider()),
          ChangeNotifierProvider(create: (_) => VoiceExamProvider(repository)),
          ChangeNotifierProvider(create: (_) => ScriptManageProvider(repository)),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationScreen(),
        ),
      ),
    );

    // 하단 내비게이션 5개 핵심 탭 아이템 확인
    expect(find.text('학습/청취'), findsOneWidget);
    expect(find.text('순발력/전환'), findsOneWidget);
    expect(find.text('성경덱'), findsOneWidget);
    expect(find.text('실전시험'), findsOneWidget);
    expect(find.text('설정'), findsOneWidget);
  });

  testWidgets('WelcomeTermsScreen: 저작권, 개발자 정보(박상환, xhpark@naver.com) 및 동의 체크 게이트 검증', (WidgetTester tester) async {
    final licenseService = LicenseService();
    await licenseService.initialize();

    await tester.pumpWidget(
      ChangeNotifierProvider<LicenseService>.value(
        value: licenseService,
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const WelcomeTermsScreen(),
        ),
      ),
    );

    // 첫 화면 렌더링 확인
    expect(find.text('전도폭발 JUST EE 훈련 마스터'), findsOneWidget);
    expect(find.text('Version 2.0.0 (2026.08.29)'), findsOneWidget);
    expect(find.textContaining('박상환(xhpark@naver.com)'), findsOneWidget);
    expect(find.textContaining('사단법인 한국전도폭발본부'), findsOneWidget);
    expect(find.textContaining('면책 조항'), findsOneWidget);

    // 동의 전에는 버튼 비활성화 상태
    final buttonFinder = find.widgetWithText(ElevatedButton, '동의하고 훈련 시작하기');
    expect(buttonFinder, findsOneWidget);
    ElevatedButton startBtn = tester.widget(buttonFinder);
    expect(startBtn.onPressed, isNull);

    // 체크박스 클릭
    final checkboxFinder = find.byType(Checkbox);
    expect(checkboxFinder, findsOneWidget);
    await tester.tap(checkboxFinder);
    await tester.pump();

    // 체크 후 버튼 활성화
    startBtn = tester.widget(buttonFinder);
    expect(startBtn.onPressed, isNotNull);
  });
}
