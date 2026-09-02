import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/script_repository.dart';
import 'providers/study_provider.dart';
import 'providers/quick_trigger_provider.dart';
import 'providers/scripture_provider.dart';
import 'providers/voice_exam_provider.dart';
import 'providers/script_manage_provider.dart';
import 'services/license_service.dart';
import 'screens/blocked_screen.dart';
import 'screens/welcome_terms_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = ScriptRepository();
  final licenseService = LicenseService();

  // 교재 데이터나 저장소 초기화가 실패해도 흰 화면으로 죽지 않고
  // 원인을 알려주는 화면을 띄운다.
  try {
    await repository.loadSections();
    await licenseService.initialize();
  } catch (e) {
    runApp(StartupErrorApp(message: e.toString()));
    return;
  }

  runApp(
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
      child: const JustEEMasterApp(),
    ),
  );
}

class JustEEMasterApp extends StatelessWidget {
  const JustEEMasterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'JUST EE 마스터',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Consumer<LicenseService>(
        builder: (context, license, _) {
          if (license.isBlocked) {
            return const BlockedScreen();
          }
          return const WelcomeTermsScreen();
        },
      ),
    );
  }
}

/// 기동 실패 시 원인을 안내하는 최소 화면
class StartupErrorApp extends StatelessWidget {
  final String message;
  const StartupErrorApp({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 56,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "교재 데이터를 불러오지 못했습니다",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    "앱을 완전히 종료한 뒤 다시 실행해 주세요.\n"
                    "문제가 계속되면 앱을 재설치하시거나 개발자(xhpark@naver.com)에게 아래 내용을 알려주세요.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF475569),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      message,
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
