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

    test('TS-EDIT-001: 학습(StudyProvider)에서 수정 시 설정(ScriptManageProvider) 및 채점 엔진 자동 동기화 검증', () async {
      final repo = ScriptRepository();
      final studyProvider = StudyProvider(repo);
      final manageProvider = ScriptManageProvider(repo);

      await Future.delayed(const Duration(milliseconds: 100));

      // 1. 초기 텍스트 확인 (은혜 1번 문장)
      final sectionsInitial = await repo.loadSections();
      final graceInitial = sectionsInitial.firstWhere((s) => s.id == 'grace');
      expect(graceInitial.steps[0].effectiveScript, contains("영생은 값없이"));

      // 2. 사용자가 학습 화면에서 문구를 직접 수정 및 저장 (수동 manageProvider.loadData 호출 없음!)
      const modifiedText = "영생은 하나님께서 우리 모두에게 아낌없이 선물로 베풀어 주시는 가장 소중한 은혜입니다.";
      await studyProvider.updateStepScript('grace_1', modifiedText);
      await Future.delayed(const Duration(milliseconds: 50));

      // 3. StudyProvider뿐 아니라 ScriptManageProvider에도 자동 반영되었는지 검증 (SSOT 자동 동기화)
      final graceStudy = studyProvider.sections.firstWhere(
        (s) => s.id == 'grace',
      );
      expect(graceStudy.steps[0].effectiveScript, equals(modifiedText));

      final graceManage = manageProvider.sections.firstWhere(
        (s) => s.id == 'grace',
      );
      expect(graceManage.steps[0].effectiveScript, equals(modifiedText));

      // 4. STT 채점 엔진이 수정된 문장을 기준으로 정상 채점하는지 검증
      final scoreResult = ScoringEngine.calculateScore(
        examId: 'test_grace_1',
        title: '은혜 1',
        originalText: graceStudy.steps[0].effectiveScript,
        spokenText: "영생은 하나님께서 우리 모두에게 아낌없이 선물로 베풀어 주시는 가장 소중한 은혜입니다",
      );

      expect(scoreResult.totalScore, greaterThanOrEqualTo(95.0));
      expect(scoreResult.isPassed, isTrue);

      studyProvider.dispose();
      manageProvider.dispose();
      repo.dispose();
    });

    test('TS-EDIT-002: 설정(ScriptManageProvider)에서 수정 시 학습(StudyProvider)에 수동 호출 없이 실시간 자동 동기화 검증', () async {
      final repo = ScriptRepository();
      final studyProvider = StudyProvider(repo);
      final manageProvider = ScriptManageProvider(repo);

      await Future.delayed(const Duration(milliseconds: 100));

      // 1. 초기 텍스트 확인 (인간 1번 문장)
      final humanityInitial = studyProvider.sections.firstWhere((s) => s.id == 'humanity');
      expect(humanityInitial.steps[0].effectiveScript, contains("인간은 죄인입니다"));

      // 2. 설정 화면에서 문장 수정 및 저장 (수동 studyProvider.refresh 호출 없음!)
      const modifiedHumanity = "성경은 모든 사람이 죄를 범하였으매 하나님의 영광에 이르지 못한다고 분명히 선언합니다.";
      await manageProvider.updateStep('human_1', modifiedHumanity);
      await Future.delayed(const Duration(milliseconds: 50));

      // 3. ScriptManageProvider뿐 아니라 StudyProvider에도 즉시 자동 반영되었는지 검증
      final humanityManage = manageProvider.sections.firstWhere(
        (s) => s.id == 'humanity',
      );
      expect(humanityManage.steps[0].effectiveScript, equals(modifiedHumanity));

      final humanityStudy = studyProvider.sections.firstWhere(
        (s) => s.id == 'humanity',
      );
      expect(humanityStudy.steps[0].effectiveScript, equals(modifiedHumanity));

      studyProvider.dispose();
      manageProvider.dispose();
      repo.dispose();
    });
  });
}
