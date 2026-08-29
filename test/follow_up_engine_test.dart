import 'package:flutter_test/flutter_test.dart';
import 'package:just_ee_master/services/follow_up_engine.dart';

void main() {
  group('FollowUpEngine Tests (TS-FOLL-001, TS-FOLL-002, TS-FOLL-004)', () {
    test('TS-FOLL-001: 요한복음 6:47 확신 4문답 구어체 의도 매칭 검증 (Q2 영생)', () {
      // Q2: "지금 무엇이 있습니까?"
      final res1 = FollowUpEngine.evaluateAssuranceResponse(1, "영생이요!");
      expect(res1.isPassed, isTrue);

      final res2 = FollowUpEngine.evaluateAssuranceResponse(1, "영원한 생명을 얻었습니다.");
      expect(res2.isPassed, isTrue);

      final res3 = FollowUpEngine.evaluateAssuranceResponse(1, "돈이 있습니다."); // 오답
      expect(res3.isPassed, isFalse);
    });

    test('TS-FOLL-002: 5손가락 영적 성장 수단 매핑 무결성 검증', () {
      final principles = FollowUpEngine.getGrowthPrinciples();
      expect(principles.length, equals(5));

      // 엄지=성경, 검지=기도, 중지=예배, 약지=교제, 소지=전도
      expect(principles[0].principleName, contains("성경"));
      expect(principles[1].principleName, contains("기도"));
      expect(principles[2].principleName, contains("예배"));
      expect(principles[3].principleName, contains("교제"));
      expect(principles[4].principleName, contains("전도"));
    });

    test('TS-FOLL-004: 확신 질문 Q3(천국) 및 Q4(십자가/약속) 의도 매칭', () {
      // Q3: 어디에 들어갑니까?
      final resQ3 = FollowUpEngine.evaluateAssuranceResponse(2, "천국에 들어갑니다!");
      expect(resQ3.isPassed, isTrue);

      // Q4: 근거는 무엇입니까?
      final resQ4 = FollowUpEngine.evaluateAssuranceResponse(3, "예수님의 십자가 대속과 하나님의 약속의 말씀 때문입니다.");
      expect(resQ4.isPassed, isTrue);
    });
  });
}
