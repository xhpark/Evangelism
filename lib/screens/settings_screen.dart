import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/script_manage_provider.dart';
import '../providers/quick_trigger_provider.dart';
import '../providers/voice_exam_provider.dart';
import '../providers/study_provider.dart';
import '../services/license_service.dart';
import '../models/step_item_model.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _testimonyController = TextEditingController();
  final _churchController = TextEditingController();
  final _importController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final provider = context.read<ScriptManageProvider>();
    _testimonyController.text = provider.userTestimony;
    _churchController.text = provider.userChurch;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<StudyProvider>().reloadVoices();
      }
    });
  }

  @override
  void dispose() {
    _testimonyController.dispose();
    _churchController.dispose();
    _importController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ScriptManageProvider>();
    final study = context.read<StudyProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("⚙️ 대본 보기 및 수정 설정"),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. 안내 배너
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: AppTheme.primaryBlue, size: 22),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      "이곳에서 수정하여 저장하신 대본은 전문 학습 탭의 모든 화면, 실시간 TTS 배속 음성 듣기, 그리고 STT 시험 채점에 즉시 100% 반영됩니다.",
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1E3A8A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // 2. TTS 음성 목소리(Voice) 및 톤 설정 카드
            Consumer<StudyProvider>(
              builder: (context, study, _) {
                final voices = study.availableVoices;
                final selectedVoice = study.selectedVoiceName;
                final matched = voices.any((v) => v.name == selectedVoice);
                final currentVoiceValue = matched
                    ? selectedVoice
                    : (voices.isNotEmpty ? voices.first.name : null);

                return Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.record_voice_over, color: AppTheme.primaryBlue),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "🎙️ TTS 음성 목소리(Voice) & 톤 설정",
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          "스마트폰에 설치된 다양한 남성/여성 한국어 보이스 중 마음에 드는 목소리와 음높이를 선택하세요.",
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 14),

                        // 보이스 선택 드롭다운
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "한국어 목소리 종류",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                "선택 가능: ${voices.length}개",
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.primaryBlue),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade300),
                            borderRadius: BorderRadius.circular(8),
                            color: const Color(0xFFF8FAFC),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: currentVoiceValue,
                              hint: const Text("보이스를 불러오는 중..."),
                              items: voices.map((v) {
                                return DropdownMenuItem<String>(
                                  value: v.name,
                                  child: Text(
                                    v.displayName,
                                    style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w500),
                                  ),
                                );
                              }).toList(),
                              onChanged: (val) async {
                                if (val == null) return;
                                final target = voices.firstWhere((v) => v.name == val);
                                await study.setTtsVoice(target);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // 음높이 (Pitch) 조절
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              "음높이 (톤 조절)",
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              study.pitch <= 0.85
                                  ? "차분한 저음 (${study.pitch.toStringAsFixed(2)})"
                                  : study.pitch >= 1.15
                                      ? "밝은 고음 (${study.pitch.toStringAsFixed(2)})"
                                      : "표준 톤 (${study.pitch.toStringAsFixed(2)})",
                              style: const TextStyle(fontSize: 12, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        Slider(
                          value: study.pitch.clamp(0.7, 1.3),
                          min: 0.7,
                          max: 1.3,
                          divisions: 12,
                          label: study.pitch.toStringAsFixed(2),
                          activeColor: AppTheme.primaryBlue,
                          onChanged: (newPitch) {
                            study.setTtsPitch(newPitch);
                          },
                        ),
                        const SizedBox(height: 4),

                        // 3가지 원터치 톤 프리셋 버튼
                        Row(
                          children: [
                            _buildPitchPresetChip(
                              label: "차분한 저음",
                              targetPitch: 0.85,
                              currentPitch: study.pitch,
                              onTap: () => study.setTtsPitch(0.85),
                            ),
                            const SizedBox(width: 8),
                            _buildPitchPresetChip(
                              label: "표준 톤",
                              targetPitch: 1.0,
                              currentPitch: study.pitch,
                              onTap: () => study.setTtsPitch(1.0),
                            ),
                            const SizedBox(width: 8),
                            _buildPitchPresetChip(
                              label: "밝은 고음",
                              targetPitch: 1.15,
                              currentPitch: study.pitch,
                              onTap: () => study.setTtsPitch(1.15),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // 미리듣기 버튼 & 안드로이드 고음질 팁
                        Row(
                          children: [
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => study.previewTtsVoice(),
                              icon: const Icon(Icons.volume_up, size: 18),
                              label: const Text("🔊 변경된 목소리 즉시 미리듣기"),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.amber.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.amber.shade200),
                          ),
                          child: const Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.tips_and_updates, color: Color(0xFFB45309), size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "💡 더욱 자연스러운 사람 목소리를 원하시면 스마트폰 [설정 ➔ 일반 ➔ 글자 읽어주기(TTS) ➔ 기본 엔진(Google/삼성) 설정 ➔ 음성 데이터 설치]에서 '고음질 보이스'를 다운로드하시면 감탄할 만큼 부드러운 목소리로 들으실 수 있습니다.",
                                  style: TextStyle(fontSize: 11.5, height: 1.4, color: Color(0xFF78350F)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 3. 8대 챕터별 문장 목록 및 개별 대본 편집기
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.format_list_bulleted, color: AppTheme.primaryBlue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "📖 8대 챕터별 대본 보기 및 개별 수정",
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "각 챕터를 펼쳐서 문장을 확인하고, [✏️ 수정] 버튼을 눌러 나만의 대본으로 수정할 수 있습니다.",
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 12),

                    if (provider.sections.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: provider.sections.length,
                        itemBuilder: (ctx, secIdx) {
                          final sec = provider.sections[secIdx];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            color: const Color(0xFFF8FAFC),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                              side: BorderSide(color: Colors.grey.shade200),
                            ),
                            child: ExpansionTile(
                              title: Text(
                                sec.title,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                              subtitle: Text(
                                "총 ${sec.steps.length}개 문장",
                                style: const TextStyle(fontSize: 11, color: AppTheme.textMuted),
                              ),
                              children: sec.steps.map((step) {
                                return Container(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(color: Colors.grey.shade200),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              step.name,
                                              style: const TextStyle(
                                                fontSize: 13,
                                                fontWeight: FontWeight.bold,
                                                color: AppTheme.primaryBlue,
                                              ),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(
                                              Icons.edit_note,
                                              color: AppTheme.primaryBlue,
                                              size: 22,
                                            ),
                                            tooltip: "이 문장 수정",
                                            onPressed: () => _showStepEditDialog(
                                              context,
                                              step,
                                              provider,
                                              study,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        step.effectiveScript,
                                        style: const TextStyle(
                                          fontSize: 13.5,
                                          height: 1.45,
                                          color: Color(0xFF334155),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 3. 외부 텍스트(TXT) 직접 붙여넣기 / 전체 일괄 수정 (Import)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.file_upload_outlined, color: AppTheme.primaryBlue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "📋 전체 대본 TXT 붙여넣기 및 일괄 반영",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "전체 대본 텍스트를 한 번에 붙여넣어 8대 챕터 전체를 자동으로 갱신합니다.",
                      style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _importController,
                      maxLines: 6,
                      style: const TextStyle(fontSize: 13, height: 1.4),
                      decoration: const InputDecoration(
                        hintText: "여기에 전도폭발 복음제시 전문 텍스트를 붙여넣으세요...",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(12),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.spaceBetween,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () {
                            // 현재 대본 전체 텍스트 추출 후 붙여넣기 창에 로드
                            final buffer = StringBuffer();
                            for (final sec in provider.sections) {
                              buffer.writeln(sec.title);
                              for (final st in sec.steps) {
                                buffer.writeln("${st.name}: ${st.effectiveScript}");
                              }
                              buffer.writeln();
                            }
                            _importController.text = buffer.toString().trim();
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("현재 대본 전체를 편집기에 불러왔습니다.")),
                            );
                          },
                          icon: const Icon(Icons.copy_all, size: 16),
                          label: const Text("현재 대본 불러오기"),
                        ),
                        ElevatedButton.icon(
                          onPressed: () async {
                            final text = _importController.text.trim();
                            if (text.isEmpty) return;
                            final ok = await provider.importText(text);
                            if (!context.mounted) return;
                            await _propagateScriptChange(context);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(ok
                                      ? "대본 전체가 성공적으로 반영되어 저장되었습니다."
                                      : "텍스트 형식을 확인해 주세요."),
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text("텍스트 적용 및 저장"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 4. 개인 간증 & 소속 교회 설정 카드
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.person_pin, color: AppTheme.primaryBlue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "나의 개인 간증 (서론 1.2)",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _testimonyController,
                      maxLines: 3,
                      style: const TextStyle(fontSize: 13),
                      decoration: const InputDecoration(
                        hintText: "개인 간증 문구를 입력하세요...",
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.all(10),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: () async {
                          await provider.saveTestimony(_testimonyController.text.trim());
                          if (!context.mounted) return;
                          await _propagateScriptChange(context);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("개인 간증이 저장되었습니다.")),
                            );
                          }
                        },
                        child: const Text("간증 저장"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // 5. 라이선스 및 기기 보안 관리 카드
            Consumer<LicenseService>(
              builder: (context, license, _) {
                return Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.blue.shade100),
                  ),
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.security, color: AppTheme.primaryBlue),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                "기기 라이선스 및 보안 관리",
                                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: license.isActivated
                                    ? AppTheme.accentEmerald.withValues(alpha: 0.12)
                                    : AppTheme.accentRed.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                license.isActivated ? "정식 승인 (Active)" : "미인증",
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: license.isActivated ? AppTheme.accentEmerald : AppTheme.accentRed,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Expanded(
                                    child: Text(
                                      "기기 고유 코드 (Device UUID)",
                                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF64748B)),
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: license.deviceId));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text("📋 기기 코드가 복사되었습니다.")),
                                      );
                                    },
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.copy, size: 13, color: AppTheme.primaryBlue),
                                          SizedBox(width: 2),
                                          Text("복사", style: TextStyle(fontSize: 11, color: AppTheme.primaryBlue, fontWeight: FontWeight.bold)),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              SelectableText(
                                license.deviceId,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'monospace',
                                  color: AppTheme.primaryNavy,
                                ),
                              ),
                              if (license.userName.isNotEmpty || license.userAffiliation.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  "등록 훈련생: ${license.userName}${license.userAffiliation.isNotEmpty ? ' (${license.userAffiliation})' : ''}",
                                  style: const TextStyle(fontSize: 11.5, color: Color(0xFF475569), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                await license.checkRemoteKillSwitch();
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        license.isBlocked ? "⚠️ 비인가 차단 상태입니다." : "✅ 승인 상태가 정상 확인되었습니다.",
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.sync, size: 16),
                              label: const Text("원격 승인 동기화", style: TextStyle(fontSize: 12)),
                            ),
                            OutlinedButton.icon(
                              onPressed: () async {
                                final allowed =
                                    await _confirmDeveloperAccess(context, license);
                                if (allowed && context.mounted) {
                                  _showWebhookConfigDialog(context, license);
                                }
                              },
                              icon: const Icon(Icons.link, size: 16),
                              label: const Text("구글 시트 연동 설정", style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 16),

            // 6. 저작권 고지 및 개발자 정보 카드
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.blue.shade100),
              ),
              color: const Color(0xFFF8FAFC),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.verified_user_outlined, color: AppTheme.primaryBlue),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            "저작권 고지 및 개발자 정보",
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.primaryNavy),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildLegalInfoRow(
                      icon: Icons.person_outline,
                      title: "개발자 (시스템 설계 및 개발)",
                      content: "박상환 (xhpark@naver.com)",
                    ),
                    const SizedBox(height: 8),
                    _buildLegalInfoRow(
                      icon: Icons.copyright,
                      title: "복음 전문 텍스트 저작권",
                      content: "사단법인 한국전도폭발본부 (EE International)",
                    ),
                    const SizedBox(height: 8),
                    _buildLegalInfoRow(
                      icon: Icons.security,
                      title: "이용 및 법적 면책",
                      content: "본 앱은 개인 훈련 전용이며 무단 배포를 금지합니다. 무단 사용/배포 및 기능 품질에 대해 개발자는 법적 책임을 지지 않습니다.",
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildLegalInfoRow({
    required IconData icon,
    required String title,
    required String content,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppTheme.primaryBlue),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryNavy,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                content,
                style: const TextStyle(
                  fontSize: 12,
                  color: Color(0xFF475569),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPitchPresetChip({
    required String label,
    required double targetPitch,
    required double currentPitch,
    required VoidCallback onTap,
  }) {
    final isSelected = (currentPitch - targetPitch).abs() < 0.05;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryBlue : const Color(0xFFF1F5F9),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? AppTheme.primaryBlue : Colors.grey.shade300,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.bold,
            color: isSelected ? Colors.white : const Color(0xFF334155),
          ),
        ),
      ),
    );
  }

  void _showStepEditDialog(
    BuildContext context,
    StepItem step,
    ScriptManageProvider provider,
    StudyProvider study,
  ) {
    final controller = TextEditingController(text: step.effectiveScript);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.edit_note, color: AppTheme.primaryBlue),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                "${step.name} 수정",
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: TextField(
            controller: controller,
            maxLines: 8,
            style: const TextStyle(fontSize: 14, height: 1.45),
            decoration: const InputDecoration(
              hintText: "수정할 대본 텍스트를 입력하세요.",
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.all(12),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () async {
              final newText = controller.text.trim();
              if (newText.isNotEmpty) {
                await provider.updateStep(step.stepId, newText);
                if (!context.mounted) return;
                await _propagateScriptChange(context);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("문장이 성공적으로 수정되어 저장되었습니다.")),
                  );
                }
              }
              if (context.mounted) Navigator.pop(ctx);
            },
            child: const Text("저장 및 즉시 반영"),
          ),
        ],
      ),
    );
  }

  /// 대본이 바뀌면 학습 탭뿐 아니라 순발력 덱과 실전시험 문항까지 함께 갱신한다.
  /// (2026-08-29: 순발력 덱이 수정 전 문장 객체를 붙들고 있어 옛 대본으로 채점되던 문제 수정)
  static Future<void> _propagateScriptChange(BuildContext context) async {
    await context.read<StudyProvider>().refresh();
    if (!context.mounted) return;
    await context.read<QuickTriggerProvider>().refreshFromRepository();
    if (!context.mounted) return;
    await context.read<VoiceExamProvider>().generateNewQuestion();
  }

  /// 웹훅 URL 변경은 개발자 전용 기능이므로 마스터 인증키를 다시 확인한다.
  Future<bool> _confirmDeveloperAccess(BuildContext context, LicenseService license) async {
    final controller = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.admin_panel_settings_outlined, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Expanded(child: Text("개발자 확인", style: TextStyle(fontSize: 16))),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "구글 시트 연동 주소는 원격 승인·차단에 직접 연결되는 개발자 설정입니다.\n"
              "변경하려면 마스터 인증키를 입력해 주세요.",
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              decoration: const InputDecoration(
                hintText: "마스터 인증키",
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, license.verifyMasterPin(controller.text)),
            child: const Text("확인"),
          ),
        ],
      ),
    );

    if (ok != true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("마스터 인증키가 일치하지 않아 변경할 수 없습니다."),
          backgroundColor: AppTheme.accentRed,
        ),
      );
    }
    return ok == true;
  }

  void _showWebhookConfigDialog(BuildContext context, LicenseService license) {
    final controller = TextEditingController(text: license.webhookUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.link, color: AppTheme.primaryBlue),
            SizedBox(width: 8),
            Text("구글 시트 웹앱 URL 설정", style: TextStyle(fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "개발자용 Google Apps Script 웹앱 배포 URL을 입력하면 원격 킬스위치 및 실시간 등록 텔레메트리가 연동됩니다.",
              style: TextStyle(fontSize: 12, color: Color(0xFF64748B), height: 1.4),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "https://script.google.com/macros/s/.../exec",
                hintStyle: TextStyle(fontSize: 11),
                border: OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
              style: const TextStyle(fontSize: 12),
              maxLines: 2,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("취소"),
          ),
          ElevatedButton(
            onPressed: () async {
              final url = controller.text.trim();
              final uri = Uri.tryParse(url);
              final isValid = url.isNotEmpty &&
                  uri != null &&
                  uri.isScheme('https') &&
                  uri.host.endsWith('google.com');

              if (!isValid) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  const SnackBar(
                    content: Text("https://script.google.com/... 형식의 주소만 저장할 수 있습니다."),
                    backgroundColor: AppTheme.accentRed,
                  ),
                );
                return;
              }

              await license.setWebhookUrl(url);
              if (context.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("✅ 구글 웹앱 URL이 저장되었습니다.")),
                );
              }
            },
            child: const Text("저장"),
          ),
        ],
      ),
    );
  }
}
