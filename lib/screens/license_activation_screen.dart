import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../services/license_service.dart';
import '../theme/app_theme.dart';
import 'main_navigation_screen.dart';

class LicenseActivationScreen extends StatefulWidget {
  const LicenseActivationScreen({super.key});

  @override
  State<LicenseActivationScreen> createState() =>
      _LicenseActivationScreenState();
}

class _LicenseActivationScreenState extends State<LicenseActivationScreen> {
  final _codeController = TextEditingController();
  final _nameController = TextEditingController();
  final _affiliationController = TextEditingController();
  String? _errorMessage;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _codeController.dispose();
    _nameController.dispose();
    _affiliationController.dispose();
    super.dispose();
  }

  Future<void> _handleActivation() async {
    final name = _nameController.text.trim();
    final affiliation = _affiliationController.text.trim();
    final code = _codeController.text.trim();
    if (name.isEmpty || affiliation.isEmpty || code.isEmpty) {
      setState(() => _errorMessage = '성명, 소속, 일회용 활성화 코드를 모두 입력해 주세요.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final license = context.read<LicenseService>();
    final success = await license.activateWithCode(
      code,
      userName: name,
      affiliation: affiliation,
    );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (!success) {
      setState(() => _errorMessage = license.lastSyncMessage);
      return;
    }
    _codeController.clear();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('기기 인증과 라이선스 활성화가 완료되었습니다.'),
        backgroundColor: AppTheme.accentEmerald,
      ),
    );
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainNavigationScreen()),
    );
  }

  void _copyDeviceId(String deviceId) {
    Clipboard.setData(ClipboardData(text: deviceId));
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('기기 코드가 복사되었습니다.')));
  }

  @override
  Widget build(BuildContext context) {
    final license = context.watch<LicenseService>();
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: AppBar(
        title: const Text('기기 인증 및 라이선스 활성화'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 28),
          child: Column(
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.verified_user_outlined,
                  color: AppTheme.primaryBlue,
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '정식 훈련생 기기 인증',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                '관리자에게 기기 코드를 전달해 일회용 활성화 코드를 발급받으세요. '
                '입력한 코드는 서버에서 한 번 사용된 뒤 다시 쓸 수 없습니다.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppTheme.textMuted, height: 1.4),
              ),
              const SizedBox(height: 24),
              _Card(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '이 단말기의 기기 코드',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: SelectableText(
                            license.deviceId,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: '기기 코드 복사',
                          onPressed: () => _copyDeviceId(license.deviceId),
                          icon: const Icon(Icons.copy),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _Card(
                child: AutofillGroup(
                  child: Column(
                    children: [
                      TextField(
                        controller: _nameController,
                        autofillHints: const [AutofillHints.name],
                        decoration: const InputDecoration(
                          labelText: '훈련생 성명 *',
                          prefixIcon: Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _affiliationController,
                        decoration: const InputDecoration(
                          labelText: '소속 *',
                          prefixIcon: Icon(Icons.business_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: _codeController,
                        autocorrect: false,
                        enableSuggestions: false,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          labelText: '일회용 활성화 코드 *',
                          hintText: 'XXXX-XXXX-XXXX-XXXX',
                          prefixIcon: Icon(Icons.key_outlined),
                        ),
                      ),
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 12),
                        Semantics(
                          liveRegion: true,
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: AppTheme.accentRed),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _handleActivation,
                  child: _isSubmitting
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Text('인증 및 훈련 시작하기'),
                ),
              ),
              if (!license.isRemoteConfigured) ...[
                const SizedBox(height: 12),
                const Text(
                  '현재 빌드에는 라이선스 서버가 설정되지 않았습니다. 관리자에게 문의해 주세요.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.accentRed, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _Card extends StatelessWidget {
  const _Card({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: child,
    );
  }
}
