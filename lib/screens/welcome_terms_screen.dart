import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';

class WelcomeTermsScreen extends StatefulWidget {
  const WelcomeTermsScreen({super.key});

  @override
  State<WelcomeTermsScreen> createState() => _WelcomeTermsScreenState();
}

class _WelcomeTermsScreenState extends State<WelcomeTermsScreen> {
  bool _isAgreed = false;

  void _onStartLearning() {
    if (!_isAgreed) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 10),

                    // 1. 앱 로고 및 타이틀
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.primaryNavy.withValues(alpha: 0.18),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Image.asset(
                          'assets/images/app_logo.png',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: AppTheme.primaryNavy,
                            child: const Icon(Icons.menu_book, color: AppTheme.accentGold, size: 44),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    const Text(
                      "전도폭발 JUST EE 훈련 마스터",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryNavy,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      "Evangelism Explosion Personal Training System",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textMuted,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),

                    // 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.primaryBlue.withValues(alpha: 0.2)),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.lock_outline, size: 13, color: AppTheme.primaryBlue),
                          SizedBox(width: 4),
                          Text(
                            "개인 학습 전용 비공개 훈련 도구",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),

                    // 버전 및 배포 날짜
                    const Text(
                      "Version 2.0.0 (2026.08.29)",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2. 저작권 고지 및 면책 약관 전문 카드
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade300),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 섹션 1: 저작권 및 프로그램 소유권
                          _buildTermSection(
                            icon: Icons.copyright,
                            iconColor: AppTheme.primaryBlue,
                            title: "저작권 및 프로그램 소유권 고지",
                            content:
                                "• 복음 제시 전문 텍스트 및 전도폭발 훈련 체계의 지적재산권과 저작권은 사단법인 한국전도폭발본부(Evangelism Explosion International)에 있습니다.\n"
                                "• 본 모바일 훈련 애플리케이션의 아키텍처 설계, 알고리즘 및 프로그램 소유권은 개발자 박상환(xhpark@naver.com)에게 있습니다.",
                          ),
                          const Divider(height: 24, thickness: 0.8),

                          // 섹션 2: 이용 목적 및 배포 제한
                          _buildTermSection(
                            icon: Icons.pan_tool_outlined,
                            iconColor: Colors.amber.shade800,
                            title: "이용 목적 및 무단 배포 금지",
                            content:
                                "• 본 프로그램은 개인 훈련생의 순수한 복음 암송 및 1:1 구두 훈련 역량 강화를 위해 제작된 개인용 학습 보조 도구입니다.\n"
                                "• 권리자의 사전 서면 허락 없는 무단 복제, 상업적 이용, 제3자 배포, 역공학 및 2차 저작물 제작을 엄격히 금지합니다.",
                          ),
                          const Divider(height: 24, thickness: 0.8),

                          // 섹션 3: 법적 책임의 한계 및 면책
                          _buildTermSection(
                            icon: Icons.gavel_outlined,
                            iconColor: Colors.red.shade700,
                            title: "면책 조항 (Disclaimer of Liability)",
                            content:
                                "• 본 프로그램의 무단 사용이나 권리자 허락 없는 외부 배포로 인해 발생하는 모든 민·형사상 법적 분쟁에 대해 개발자는 일체의 보증이나 책임을 부담하지 않습니다.\n"
                                "• 기기 환경에 따른 음성인식(STT) 정확도, 음성합성(TTS) 품질 및 소프트웨어의 무결성에 대한 법적 책임을 보증하지 않습니다.",
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // 3. 하단 동의 체크박스 및 진입 버튼
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -3),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 동의 체크박스
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      setState(() {
                        _isAgreed = !_isAgreed;
                      });
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _isAgreed,
                              activeColor: AppTheme.primaryBlue,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _isAgreed = val ?? false;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              "위 저작권 고지, 이용 규정 및 면책 사항을 모두 확인하였으며 이에 동의합니다. (필수)",
                              style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textDark,
                                height: 1.35,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // 시작 버튼
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isAgreed ? _onStartLearning : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryBlue,
                        disabledBackgroundColor: Colors.grey.shade300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: _isAgreed ? 2 : 0,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "동의하고 훈련 시작하기",
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: _isAgreed ? Colors.white : Colors.grey.shade500,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            Icons.arrow_forward,
                            size: 18,
                            color: _isAgreed ? Colors.white : Colors.grey.shade500,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTermSection({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String content,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 17, color: iconColor),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(
          content,
          style: const TextStyle(
            fontSize: 11.5,
            color: AppTheme.textDark,
            height: 1.45,
          ),
        ),
      ],
    );
  }
}
