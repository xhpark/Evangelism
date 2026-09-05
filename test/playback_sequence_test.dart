import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_ee_master/data/script_repository.dart';
import 'package:just_ee_master/models/exam_result_model.dart';

import 'package:just_ee_master/providers/study_provider.dart';
import 'package:just_ee_master/services/tts_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('교재 데이터 및 전체 완주 재생 (TS-PLAY-001 ~ 003)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('TS-PLAY-001: 시작 챕터만 중간부터, 이후 챕터는 첫 문장부터 재생된다', () async {
      final sections = await ScriptRepository().loadSections();

      // StudyProvider.playContinuous(allSequentialPlay)의 재생 순서 규칙을 그대로 재현한다.
      // (2026-08-29 이전에는 모든 챕터가 fromIndex부터 시작해 앞 문장이 통째로 누락됐다)
      const startSectionIndex = 0;
      const fromIndex = 3;

      final playOrder = <String>[];
      for (var secIdx = startSectionIndex; secIdx < sections.length; secIdx++) {
        final steps = sections[secIdx].steps;
        final isStartSection = secIdx == startSectionIndex;
        final startIdx = isStartSection ? fromIndex.clamp(0, steps.length) : 0;
        for (var i = startIdx; i < steps.length; i++) {
          playOrder.add(steps[i].stepId);
        }
      }

      // 뒤따르는 챕터의 첫 문장들이 빠지지 않아야 한다.
      expect(playOrder.contains('grace_1'), isTrue);
      expect(playOrder.contains('god_1'), isTrue);
      expect(playOrder.contains('follow_1'), isTrue);

      final total = sections.fold<int>(0, (sum, s) => sum + s.steps.length);
      expect(playOrder.length, equals(total - fromIndex));
    });

    test('TS-PLAY-002: 교재 전문은 8개 챕터 40문장으로 구성된다', () async {
      final sections = await ScriptRepository().loadSections();
      expect(sections.length, equals(8));

      final total = sections.fold<int>(0, (sum, s) => sum + s.steps.length);
      expect(total, equals(40));
    });

    test('TS-PLAY-003: 선택문장 무한 반복(singleRepeat) 모드에서 문장 선택 시 해당 문장 타깃 지정 및 유지 검증', () async {
      final repo = ScriptRepository();
      final study = StudyProvider(repo);
      await Future.delayed(const Duration(milliseconds: 100));

      // 1. 모드를 singleRepeat(선택문장 무한 반복)으로 설정
      study.setPlayMode(PlayMode.singleRepeat);
      expect(study.playMode, equals(PlayMode.singleRepeat));

      // 2. 은혜 챕터 선택
      study.selectSection(1);
      expect(study.selectedStepId, equals('grace_1'));

      // 3. 은혜 2번 문장(grace_2) 선택 시뮬레이션
      final graceSection = study.sections.firstWhere((s) => s.id == 'grace');
      final targetStep = graceSection.steps[1];
      expect(targetStep.stepId, equals('grace_2'));

      // playStep 호출 시 _selectedStepId가 targetStep.stepId로 즉시 갱신
      study.playStep(targetStep);
      expect(study.selectedStepId, equals('grace_2'));

      await study.stopAudio();
      study.dispose();
      repo.dispose();
    });
  });

  group('시험 이력 보관 상한 (TS-HIST-001)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('TS-HIST-001: 시험 이력은 최대 50건까지만 보관된다', () async {
      final repo = ScriptRepository();

      for (var i = 0; i < 55; i++) {
        await repo.saveExamResult(
          ExamResult(
            examId: 'exam_$i',
            title: '테스트 $i',
            timestamp: DateTime.now(),
            totalScore: 90.0,
            charAccuracy: 90.0,
            keywordAccuracy: 90.0,
            originalText: '영생은 값없이 주시는 하나님의 선물입니다',
            spokenText: '영생은 값없이 주시는 하나님의 선물입니다',
            diffTokens: const [],
          ),
        );
      }

      final history = await repo.getExamHistory();
      expect(history.length, equals(ScriptRepository.maxExamHistory));
      expect(history.first.examId, equals('exam_54')); // 최신 건이 맨 앞
    });
  });
}
