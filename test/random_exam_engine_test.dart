import 'package:flutter_test/flutter_test.dart';
import 'package:just_ee_master/data/script_repository.dart';
import 'package:just_ee_master/services/random_exam_engine.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('RandomExamEngine Chain-Recitation Tests (TS-RAND-001 ~ 005)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('TS-RAND-001: 전환 ➔ 다음 단락 연계 암송 출제 검증', () async {
      final repo = ScriptRepository();
      final sections = await repo.loadSections();
      final engine = RandomExamEngine();

      final q = engine.generateQuestion(ExamMode.transitionChain, sections);

      expect(q.triggerPrompt, isNotEmpty);
      expect(q.instruction, contains("암송"));
      expect(q.originalText, isNotEmpty);
      expect(q.sourceSections.isNotEmpty, isTrue);
    });

    test('TS-RAND-002: 예화 집중 완주 출제 검증', () async {
      final repo = ScriptRepository();
      final sections = await repo.loadSections();
      final engine = RandomExamEngine();

      final q = engine.generateQuestion(ExamMode.illustrationChain, sections);

      expect(q.triggerPrompt, isNotEmpty);
      expect(q.instruction, contains("예화"));
      expect(q.originalText, isNotEmpty);
    });

    test('TS-RAND-003: 실전시험에서 순수 성경 구절 제외 검증', () async {
      final repo = ScriptRepository();
      final sections = await repo.loadSections();
      final engine = RandomExamEngine();

      final q = engine.generateQuestion(ExamMode.fullSequential, sections);

      final allSteps = q.sourceSections.expand((s) => s.steps).toList();
      // 40문장 중 6개 순수 성경 구절 제외 -> 총 34문장
      expect(allSteps.length, equals(34));
      // 성경 구절 step_id가 포함되지 않아야 함
      const scriptureStepIds = [
        'intro_4',
        'grace_2',
        'human_2',
        'god_2',
        'christ_3',
        'faith_2',
      ];
      for (final step in allSteps) {
        expect(scriptureStepIds.contains(step.stepId), isFalse);
      }
    });

    test('TS-RAND-004: 즉석 양육 항목별 출제 검증', () async {
      final repo = ScriptRepository();
      final sections = await repo.loadSections();
      final engine = RandomExamEngine();

      final q = engine.generateQuestion(ExamMode.followUpChain, sections);

      expect(q.triggerPrompt, isNotEmpty);
      expect(q.instruction, contains("암송"));
      expect(q.originalText, isNotEmpty);
    });

    test('TS-RAND-005: 실전시험 4대 영역별 세부 성적표 산출 검증', () {
      const orig = "영생은 선물입니다. 인간에 관하여. 가르시아 장군. 영접 기도 성경.";
      const spoken = "영생은 선물입니다. 인간에 관하여. 가르시아 장군. 영접 기도 성경.";

      final breakdown = RandomExamEngine.calculate5AreaBreakdown(orig, spoken);
      expect(breakdown.length, equals(4));

      final areaNames = breakdown.map((a) => a.areaName).toList();
      expect(areaNames.any((n) => n.contains("교리")), isTrue);
      expect(areaNames.any((n) => n.contains("전환")), isTrue);
      expect(areaNames.any((n) => n.contains("예화")), isTrue);
      expect(areaNames.any((n) => n.contains("양육")), isTrue);
      // 성경 구절 영역은 제외됨
      expect(areaNames.any((n) => n.contains("성경 구절")), isFalse);
    });

    test('TS-RAND-006: 성경 구절 암송 모드 예외적 성경 구절 출제 검증', () async {
      final repo = ScriptRepository();
      final sections = await repo.loadSections();
      final engine = RandomExamEngine();

      final q = engine.generateQuestion(ExamMode.scriptureChain, sections);

      expect(q.triggerPrompt, isNotEmpty);
      expect(q.instruction, contains("암송"));
      expect(q.originalText, isNotEmpty);
      expect(q.title, contains("성경 암송"));
    });
  });
}
