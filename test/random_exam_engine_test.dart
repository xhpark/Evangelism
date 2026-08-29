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

    test('TS-RAND-003: 성경 구절 암송 출제 검증', () async {
      final repo = ScriptRepository();
      final sections = await repo.loadSections();
      final engine = RandomExamEngine();

      final q = engine.generateQuestion(ExamMode.scriptureChain, sections);

      expect(q.triggerPrompt, isNotEmpty);
      expect(q.instruction, contains("말씀"));
      expect(q.originalText, isNotEmpty);
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

    test('TS-RAND-005: 모의 구두시험 5대 영역별 세부 성적표 산출 검증', () {
      const orig = "영생은 선물입니다. 로마서 3장 23절. 인간에 관하여. 가르시아 장군. 영접 기도 성경.";
      const spoken = "영생은 선물입니다. 로마서 3장 23절. 인간에 관하여. 가르시아 장군. 영접 기도 성경.";

      final breakdown = RandomExamEngine.calculate5AreaBreakdown(orig, spoken);
      expect(breakdown.length, equals(5));

      final areaNames = breakdown.map((a) => a.areaName).toList();
      expect(areaNames.any((n) => n.contains("교리")), isTrue);
      expect(areaNames.any((n) => n.contains("성경")), isTrue);
      expect(areaNames.any((n) => n.contains("전환")), isTrue);
      expect(areaNames.any((n) => n.contains("예화")), isTrue);
      expect(areaNames.any((n) => n.contains("양육")), isTrue);
    });
  });
}
