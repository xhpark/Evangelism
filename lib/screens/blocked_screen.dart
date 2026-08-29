import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/license_service.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';

class BlockedScreen extends StatefulWidget {
  const BlockedScreen({super.key});

  @override
  State<BlockedScreen> createState() => _BlockedScreenState();
}

class _BlockedScreenState extends State<BlockedScreen> {
  bool _isRetrying = false;

  Future<void> _handleRetry() async {
    setState(() {
      _isRetrying = true;
    });

    final license = Provider.of<LicenseService>(context, listen: false);
    await license.checkRemoteKillSwitch();

    setState(() {
      _isRetrying = false;
    });

    if (license.isActivated && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚠️ 여전히 차단된 상태입니다. 개발자에게 문의하세요.'),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final license = Provider.of<LicenseService>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 1. 빨간색 차단 쉴드 아이콘
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppTheme.accentRed.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.accentRed, width: 2),
                  ),
                  child: const Icon(
                    Icons.gpp_bad_rounded,
                    color: AppTheme.accentRed,
                    size: 52,
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  '비인가 단말기 접근 차단',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        license.blockReason,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFFCBD5E1),
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 14),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 14),
                      const Text(
                        '단말기 고유 식별 코드 (Device ID):',
                        style: TextStyle(fontSize: 11, color: Colors.white60),
                      ),
                      const SizedBox(height: 4),
                      SelectableText(
                        license.deviceId,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                          color: AppTheme.accentGold,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // 2. 상태 재확인 버튼
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton.icon(
                    onPressed: _isRetrying ? null : _handleRetry,
                    icon: _isRetrying
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh, size: 20),
                    label: const Text(
                      '승인 상태 다시 확인하기',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryBlue,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 3. 개발자 문의 버튼
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(
                      text: '기기코드: ${license.deviceId}\n개발자 문의: xhpark@naver.com',
                    ));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('📧 기기코드 및 문의 이메일이 복사되었습니다.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.mail_outline, size: 18, color: Colors.white70),
                  label: const Text(
                    '개발자(xhpark@naver.com)에게 문의',
                    style: TextStyle(fontSize: 13, color: Colors.white),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.white30),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
