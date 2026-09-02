import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_ee_master/data/script_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ScriptRepository TXT Import Tests (TS-IMPO-001)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('TS-IMPO-001: 외부 TXT 전문 파싱 및 8대 섹션 자동 분류 검증', () async {
      final repo = ScriptRepository();

      const sampleRawTxt = '''
1. 서론
1.1 일반 대화: 안녕하세요 오늘 날씨가 참 좋습니다.
1.2 영적 대화: 선생님은 평소에 영적인 생활에 관심이 있으십니까?
1.3 나의 간증: 저는 예전에 참된 평안이 없었으나 예수님을 만나 변화되었습니다.
1.4 두 가지 질문: 오늘 밤 세상을 떠나신다면 천국에 갈 확신이 있으십니까?

2.1 은혜
2.1.1 영생은 선물: 영생은 값없이 주시는 하나님의 선물입니다.
2.1.2 공로가 아님: 영생은 돈이나 공로로 얻는 것이 아닙니다.
2.1.3 성경 구절: 에베소서 2장 8절로 9절 말씀입니다.
2.1.4 선물 예화: 친구가 값비싼 선물을 줄 때 돈을 내면 모욕입니다.
2.1.5 전환 문장: 그런데 성경은 인간에 대해 무엇이라고 말씀할까요?

2.2 인간
2.2.1 핵심 진리: 인간은 모두 죄인이며 스스로 구원할 수 없습니다.

2.3 하나님
2.3.1 핵심 진리: 하나님은 자비로우시며 의로우십니다.

2.4 그리스도
2.4.1 핵심 진리: 예수 그리스도는 참 하나님이며 참 인간이십니다.

2.5 믿음
2.5.1 핵심 진리: 구원받는 믿음은 예수 그리스도만 신뢰하는 것입니다.

3. 결신
3.1 결신 질문: 이 영생의 선물을 지금 받기를 원하십니까?

4. 양육
4.1 생일 축하: 하나님의 자녀가 되신 것을 축하합니다!
''';

      final ok = await repo.importFromPlainText(sampleRawTxt);
      expect(ok, isTrue);

      final sections = await repo.loadSections();
      final grace = sections.firstWhere((s) => s.id == 'grace');
      expect(sections.length, equals(8));

      // 서론 확인
      final intro = sections.firstWhere((s) => s.id == 'intro');
      expect(intro.steps[0].effectiveScript, contains("날씨가 참 좋습니다"));
      expect(intro.steps[1].effectiveScript, contains("영적인 생활"));

      // 은혜 확인
      expect(grace.steps[0].effectiveScript, contains("영생은 값없이 주시는"));
      expect(grace.steps[1].effectiveScript, contains("돈이나 공로"));
      expect(grace.steps[2].effectiveScript, contains("에베소서 2장"));

      // 결신 확인
      final commit = sections.firstWhere((s) => s.id == 'commitment');
      expect(commit.steps[0].effectiveScript, contains("이 영생의 선물을 지금 받기를"));

      // 양육 확인
      final follow = sections.firstWhere((s) => s.id == 'follow_up');
      expect(follow.steps[0].effectiveScript, contains("하나님의 자녀가 되신 것을 축하합니다"));
    });

    test('TS-IMPO-002: 구조 없는 텍스트는 기존 대본을 덮어쓰지 않는다', () async {
      final repo = ScriptRepository();
      await repo.updateStepScript('grace_1', '기존 사용자 문장');

      expect(await repo.importFromPlainText('일반 메모 한 줄입니다.'), isFalse);
      final sections = await repo.loadSections();
      final grace = sections.firstWhere((section) => section.id == 'grace');
      expect(grace.steps.first.effectiveScript, '기존 사용자 문장');
    });

    test('TS-IMPO-003: 가져오기 직전 사용자 대본으로 되돌릴 수 있다', () async {
      final repo = ScriptRepository();
      await repo.updateStepScript('intro_1', '가져오기 전 문장');
      const structured = '''
1. 서론
1.1 일반 대화: 가져온 서론
2.1 은혜
2.1.1 영생은 선물: 가져온 은혜
2.2 인간
2.2.1 핵심 진리: 가져온 인간
2.3 하나님
2.3.1 핵심 진리: 가져온 하나님
2.4 그리스도
2.4.1 핵심 진리: 가져온 그리스도
2.5 믿음
2.5.1 핵심 진리: 가져온 믿음
3. 결신
3.1 결신 질문: 가져온 결신
4. 양육
4.1 생일 축하: 가져온 양육
''';

      expect(await repo.importFromPlainText(structured), isTrue);
      expect(await repo.undoLastImport(), isTrue);
      final sections = await repo.loadSections();
      final intro = sections.firstWhere((section) => section.id == 'intro');
      expect(intro.steps.first.effectiveScript, '가져오기 전 문장');
      expect(await repo.undoLastImport(), isFalse);
    });
  });
}
