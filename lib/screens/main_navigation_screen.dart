import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/study_provider.dart';
import '../providers/quick_trigger_provider.dart';
import '../providers/voice_exam_provider.dart';
import '../services/license_service.dart';
import 'study_screen.dart';
import 'quick_trigger_screen.dart';
import 'scripture_deck_screen.dart';
import 'voice_exam_screen.dart';
import 'settings_screen.dart';
import 'blocked_screen.dart';
import 'license_activation_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({
    super.key,
    this.licenseCheckInterval = const Duration(minutes: 5),
  });

  final Duration? licenseCheckInterval;

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _licenseTimer;

  final List<Widget> _screens = const [
    StudyScreen(),
    QuickTriggerScreen(),
    ScriptureDeckScreen(),
    VoiceExamScreen(),
    SettingsScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(context.read<LicenseService>().checkRemoteKillSwitch());
    });
    final interval = widget.licenseCheckInterval;
    if (interval != null) {
      _licenseTimer = Timer.periodic(interval, (_) {
        if (!mounted) return;
        unawaited(context.read<LicenseService>().checkRemoteKillSwitch());
      });
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _licenseTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // 앱이 다시 포그라운드로 올라올 때마다 원격 승인 상태를 재확인한다.
      unawaited(context.read<LicenseService>().checkRemoteKillSwitch());
    } else if (state == AppLifecycleState.paused) {
      // 백그라운드로 내려가면 재생/수음을 정지해 배터리와 오인식을 방지한다.
      _stopAllAudioSessions();
    }
  }

  /// 탭 이동/백그라운드 전환 시 TTS 재생과 STT 수음을 모두 정지한다.
  /// (IndexedStack 특성상 이전 탭이 살아 있어 학습 재생과 시험 수음이 겹칠 수 있음)
  void _stopAllAudioSessions() {
    context.read<StudyProvider>().stopAudio();
    final quick = context.read<QuickTriggerProvider>();
    if (quick.isListening) quick.abortListening();
    final exam = context.read<VoiceExamProvider>();
    if (exam.isListening) exam.cancelExam();
  }

  @override
  Widget build(BuildContext context) {
    // 사용 중 원격 차단이 걸리면 즉시 차단 화면으로 전환된다.
    final license = context.watch<LicenseService>();
    if (license.isBlocked) {
      return const BlockedScreen();
    }
    if (!license.isActivated) {
      return const LicenseActivationScreen();
    }

    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index != _currentIndex) {
            _stopAllAudioSessions();
          }
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.headphones_outlined),
            activeIcon: Icon(Icons.headphones),
            label: "학습/청취",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bolt_outlined),
            activeIcon: Icon(Icons.bolt),
            label: "순발력/전환",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            activeIcon: Icon(Icons.menu_book),
            label: "성경덱",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mic_none_outlined),
            activeIcon: Icon(Icons.mic),
            label: "실전시험",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: "설정",
          ),
        ],
      ),
    );
  }
}
