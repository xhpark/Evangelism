import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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
import 'package:just_ee_master/services/license_token_store.dart';
import 'package:just_ee_master/theme/app_theme.dart';
import 'package:just_ee_master/widgets/audio_control_bar.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('App smoke test: BottomNavigationBar 5개 탭 렌더링 확인', (
    WidgetTester tester,
  ) async {
    final repository = ScriptRepository();
    final licenseService = _testLicenseService();
    await licenseService.initialize();
    await licenseService.setBlocked(false);

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ScriptRepository>.value(value: repository),
          ChangeNotifierProvider<LicenseService>.value(value: licenseService),
          ChangeNotifierProvider(create: (_) => StudyProvider(repository)),
          ChangeNotifierProvider(
            create: (_) => QuickTriggerProvider(repository),
          ),
          ChangeNotifierProvider(create: (_) => ScriptureProvider()),
          ChangeNotifierProvider(create: (_) => VoiceExamProvider(repository)),
          ChangeNotifierProvider(
            create: (_) => ScriptManageProvider(repository),
          ),
        ],
        child: MaterialApp(
          theme: AppTheme.lightTheme,
          home: const MainNavigationScreen(licenseCheckInterval: null),
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

  testWidgets(
    'WelcomeTermsScreen: 저작권, 개발자 정보(박상환, xhpark@naver.com) 및 동의 체크 게이트 검증',
    (WidgetTester tester) async {
      final licenseService = _testLicenseService();
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
      expect(find.text('Version test'), findsOneWidget);
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
      expect(checkboxFinder, findsNWidgets(2));
      await tester.tap(checkboxFinder.at(0));
      await tester.tap(checkboxFinder.at(1));
      await tester.pump();

      // 체크 후 버튼 활성화
      startBtn = tester.widget(buttonFinder);
      expect(startBtn.onPressed, isNotNull);
    },
  );

  testWidgets(
    'AudioControlBar: 1.2x 배속 추가 및 2.5x 삭제 확인 (TS-STUDY-007)',
    (WidgetTester tester) async {
      final repository = ScriptRepository();
      final studyProvider = StudyProvider(repository);

      await tester.pumpWidget(
        ChangeNotifierProvider<StudyProvider>.value(
          value: studyProvider,
          child: const MaterialApp(
            home: Scaffold(
              bottomNavigationBar: AudioControlBar(),
            ),
          ),
        ),
      );

      // 배속 버튼 0.8x, 1.0x, 1.2x, 1.5x, 2.0x 렌더링 확인
      expect(find.text('0.8x'), findsOneWidget);
      expect(find.text('1.0x'), findsOneWidget);
      expect(find.text('1.2x'), findsOneWidget);
      expect(find.text('1.5x'), findsOneWidget);
      expect(find.text('2.0x'), findsOneWidget);

      // 2.5x 미존재 확인
      expect(find.text('2.5x'), findsNothing);

      // 기본 배속은 1.0x
      expect(studyProvider.speedRate, equals(1.0));

      // 1.2x 터치 시 배속 1.2로 변경 확인
      await tester.tap(find.text('1.2x'));
      await tester.pump();
      expect(studyProvider.speedRate, equals(1.2));
    },
  );
}

LicenseService _testLicenseService() => LicenseService(
  httpClient: MockClient((_) async => http.Response('{}', 500)),
  tokenStore: MemoryLicenseTokenStore(),
  apiUrl: '',
  appVersionLoader: () async => 'test',
);
