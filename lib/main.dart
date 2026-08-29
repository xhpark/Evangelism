import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'data/script_repository.dart';
import 'providers/study_provider.dart';
import 'providers/quick_trigger_provider.dart';
import 'providers/follow_up_provider.dart';
import 'providers/scripture_provider.dart';
import 'providers/voice_exam_provider.dart';
import 'providers/script_manage_provider.dart';
import 'screens/welcome_terms_screen.dart';
import 'theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final repository = ScriptRepository();
  await repository.loadSections();

  runApp(
    MultiProvider(
      providers: [
        Provider<ScriptRepository>.value(value: repository),
        ChangeNotifierProvider(create: (_) => StudyProvider(repository)),
        ChangeNotifierProvider(create: (_) => QuickTriggerProvider(repository)),
        ChangeNotifierProvider(create: (_) => FollowUpProvider()),
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
      home: const WelcomeTermsScreen(),
    );
  }
}
