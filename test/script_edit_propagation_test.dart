import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_ee_master/data/script_repository.dart';
import 'package:just_ee_master/providers/study_provider.dart';
import 'package:just_ee_master/providers/script_manage_provider.dart';
import 'package:just_ee_master/services/scoring_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Script Edit & Propagation Tests (TS-EDIT-001)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('TS-EDIT-001: 문장 개별 수정 시 StudyProvider 및 채점 엔진 즉시 반영 검증', () async {
      final repo = ScriptRepository();
      final studyProvider = StudyProvider(repo);
      final manageProvider = ScriptManageProvider(repo);

      await Future.delayed(const Duration(milliseconds: 100));

      // 1. 초기 텍스트 확인 (은혜 1번 문장)
      final sectionsInitial = await repo.loadSections();
      final graceInitial = sectionsInitial.firstWhere((s) => s.id == 'grace');
      expect(graceInitial.steps[0].effectiveScript, contains("영생은 값없이"));

      // 2. 사용자가 앱에서 문구를 직접 수정 및 저장
      const modifiedText = "영생은 하나님께서 우리 모두에게 아낌없이 선물로 베풀어 주시는 가장 소중한 은혜입니다.";
      await studyProvider.updateStepScript('grace_1', modifiedText);
      await manageProvider.loadData();

      // 3. StudyProvider에 즉시 반영되었는지 확인
      final graceUpdated = studyProvider.sections.firstWhere((s) => s.id == 'grace');
      expect(graceUpdated.steps[0].effectiveScript, equals(modifiedText));

      // 4. STT 채점 엔진이 수정된 문장을 기준으로 정상 채점하는지 검증
      final scoreResult = ScoringEngine.calculateScore(
        examId: 'test_grace_1',
        title: '은혜 1',
        originalText: graceUpdated.steps[0].effectiveScript,
        spokenText: "영생은 하나님께서 우리 모두에게 아낌없이 선물로 베풀어 주시는 가장 소중한 은혜입니다",
      );

      expect(scoreResult.totalScore, greaterThanOrEqualTo(95.0));
      expect(scoreResult.isPassed, isTrue);
    });
  });
}
