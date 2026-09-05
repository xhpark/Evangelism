import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/diff_token.dart';
import '../models/exam_result_model.dart';
import 'korean_text_normalizer.dart';

/// 별도 아이솔레이트로 넘길 채점 요청 묶음
class ScoreRequest {
  final String examId;
  final String title;
  final String originalText;
  final String spokenText;
  final List<String> keywords;
  final List<ExamAreaScore>? areaScores;

  const ScoreRequest({
    required this.examId,
    required this.title,
    required this.originalText,
    required this.spokenText,
    this.keywords = const [],
    this.areaScores,
  });
}

ExamResult _scoreInIsolate(ScoreRequest req) => ScoringEngine.calculateScore(
  examId: req.examId,
  title: req.title,
  originalText: req.originalText,
  spokenText: req.spokenText,
  keywords: req.keywords,
  areaScores: req.areaScores,
);

class ScoringEngine {
  /// 긴 지문은 편집거리 계산이 O(n×m)이라 UI 스레드를 수 초간 멈춘다.
  /// 이 길이를 넘으면 별도 아이솔레이트에서 채점한다.
  static const int _isolateThresholdChars = 800;

  /// 화면을 멈추지 않는 채점 진입점. 짧은 지문은 그대로, 긴 지문은 아이솔레이트에서 계산한다.
  static Future<ExamResult> calculateScoreAsync({
    required String examId,
    required String title,
    required String originalText,
    required String spokenText,
    List<String> keywords = const [],
    List<ExamAreaScore>? areaScores,
  }) async {
    final req = ScoreRequest(
      examId: examId,
      title: title,
      originalText: originalText,
      spokenText: spokenText,
      keywords: keywords,
      areaScores: areaScores,
    );

    if (originalText.length + spokenText.length <= _isolateThresholdChars) {
      return _scoreInIsolate(req);
    }
    return compute(_scoreInIsolate, req);
  }

  /// 종합 점수 및 Diff 토큰 생성
  static ExamResult calculateScore({
    required String examId,
    required String title,
    required String originalText,
    required String spokenText,
    List<String> keywords = const [],
    List<ExamAreaScore>? areaScores,
  }) {
    final normOrig = KoreanTextNormalizer.normalize(originalText);
    final normSpoken = KoreanTextNormalizer.normalize(spokenText);

    if (normSpoken.isEmpty) {
      final missingTokens = normOrig
          .split(' ')
          .map((w) => DiffToken(text: w, type: DiffType.missing))
          .toList();
      return ExamResult(
        examId: examId,
        title: title,
        timestamp: DateTime.now(),
        totalScore: 0.0,
        charAccuracy: 0.0,
        keywordAccuracy: 0.0,
        originalText: originalText,
        spokenText: spokenText,
        diffTokens: missingTokens,
        areaScores: areaScores,
      );
    }

    // 1. 문자 단위 유사도 (Levenshtein Distance: 공백 포함 및 공백 제거 CER 상호 보정)
    final charDist = _levenshteinDistance(normOrig, normSpoken);
    final maxLen = max(normOrig.length, normSpoken.length);
    final charAccWithSpaces =
        maxLen == 0 ? 1.0 : max(0.0, 1.0 - (charDist / maxLen));

    final normOrigNoSpace = normOrig.replaceAll(' ', '');
    final normSpokenNoSpace = normSpoken.replaceAll(' ', '');
    final charDistNoSpace =
        _levenshteinDistance(normOrigNoSpace, normSpokenNoSpace);
    final maxLenNoSpace =
        max(normOrigNoSpace.length, normSpokenNoSpace.length);
    final charAccNoSpace = maxLenNoSpace == 0
        ? 1.0
        : max(0.0, 1.0 - (charDistNoSpace / maxLenNoSpace));

    // STT 호흡 공백 오차에 의해 부당하게 감점되지 않도록 두 지표 중 우수한 정확도 채택
    final charAcc = max(charAccWithSpaces, charAccNoSpace);

    // 2. 단어/토큰 단위 일치도
    final origWords = normOrig.split(' ').where((w) => w.isNotEmpty).toList();
    final spokenWords =
        normSpoken.split(' ').where((w) => w.isNotEmpty).toList();

    // 순서와 반복 횟수를 보존하는 최장 공통 부분수열 길이로 계산
    final matchedWordCount = _orderedMatchedWordCount(origWords, spokenWords);
    double tokenAcc = origWords.isEmpty
        ? 1.0
        : min(1.0, matchedWordCount / origWords.length);

    // 비공백 텍스트가 사실상 일치하면 띄어쓰기 파편화에 관계없이 토큰 일치도를 보정
    if (charAccNoSpace >= 0.98) {
      tokenAcc = max(tokenAcc, 1.0);
    } else if (charAccNoSpace >= 0.90) {
      tokenAcc = max(tokenAcc, charAccNoSpace);
    }

    // 3. 핵심 키워드 가중치 검사
    double keywordAcc = 1.0;
    if (keywords.isNotEmpty) {
      // 출제 원문에 실제로 존재하는(또는 포함된) 키워드만 필터링하여 분모로 삼는다.
      // (원문에 없는 개념 목차 라벨 등으로 인한 부당한 감점 원천 차단)
      final validKeywords = keywords.where((kw) {
        final normKwNoSpace =
            KoreanTextNormalizer.normalize(kw).replaceAll(' ', '');
        return normKwNoSpace.isNotEmpty &&
            normOrigNoSpace.contains(normKwNoSpace);
      }).toList();

      final effectiveKeywords =
          validKeywords.isNotEmpty ? validKeywords : keywords;
      int kwMatched = 0;
      for (final kw in effectiveKeywords) {
        final normKw = KoreanTextNormalizer.normalize(kw);
        final normKwNoSpace = normKw.replaceAll(' ', '');
        if (normSpokenNoSpace.contains(normKwNoSpace) ||
            normSpoken.contains(normKw) ||
            spokenWords.any(
              (w) => isSameWordStem(normKw, w) || w.contains(normKw),
            )) {
          kwMatched++;
        }
      }
      keywordAcc = kwMatched / effectiveKeywords.length;
    }

    // 4. 최종 종합 점수 산출
    double finalScore =
        (0.35 * charAcc + 0.35 * tokenAcc + 0.30 * keywordAcc) * 100.0;
    if (charAcc >= 0.95 && keywordAcc >= 0.95) {
      finalScore = 100.0; // 사소한 띄어쓰기 차이는 만점 처리
    }
    finalScore = finalScore.clamp(0.0, 100.0);

    // 5. Diff 토큰 생성 (LCS 동적계획법 역추적 정렬 방식)
    final diffTokens = _generateDiffTokens(origWords, spokenWords);

    return ExamResult(
      examId: examId,
      title: title,
      timestamp: DateTime.now(),
      totalScore: double.parse(finalScore.toStringAsFixed(1)),
      charAccuracy: double.parse((charAcc * 100).toStringAsFixed(1)),
      keywordAccuracy: double.parse((keywordAcc * 100).toStringAsFixed(1)),
      originalText: originalText,
      spokenText: spokenText,
      diffTokens: diffTokens,
      areaScores: areaScores,
    );
  }

  /// 한국어 조사 및 빈출 어미 목록 (긴 것부터 검사)
  static const List<String> _josa = [
    '으로서',
    '으로써',
    '이라고',
    '라고는',
    '에게서',
    '으로',
    '에서',
    '에게',
    '한테',
    '까지',
    '부터',
    '보다',
    '처럼',
    '마다',
    '이라',
    '라도',
    '이나',
    '나마',
    '조차',
    '만을',
    '만은',
    '와의',
    '과의',
    '들이',
    '들을',
    '하셨습니까',
    '하셨어요',
    '하셨습니다',
    '하셨다',
    '하십니다',
    '하세요',
    '합니다',
    '입니다',
    '습니까',
    '습니다',
    '이에요',
    '였어요',
    '은',
    '는',
    '이',
    '가',
    '을',
    '를',
    '에',
    '의',
    '도',
    '만',
    '과',
    '와',
    '로',
    '야',
  ];

  /// 어간이 같은 단어인지 판정한다.
  /// - 완전히 같으면 참
  /// - 한쪽이 다른 쪽의 접두(앞부분)이고 길이 차가 3 이하이면 참 ("선물" ↔ "선물입니다", "주시" ↔ "주시는")
  /// - 조사/어미만 떼어낸 어간이 같으면 참 ("영생은" ↔ "영생을", "하셨어요" ↔ "하셨습니까")
  /// 그 외에는 서로 다른 단어로 본다. ("선물입니다" ↔ "선반입니다"는 오답)
  static bool isSameWordStem(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;

    final shorter = a.length <= b.length ? a : b;
    final longer = a.length <= b.length ? b : a;
    if (shorter.length >= 2 &&
        longer.startsWith(shorter) &&
        longer.length - shorter.length <= 3) {
      return true;
    }

    final stemA = _stripJosa(a);
    final stemB = _stripJosa(b);
    if (stemA.length >= 2 && stemA == stemB) return true;

    return false;
  }

  static String _stripJosa(String word) {
    for (final j in _josa) {
      if (word.length > j.length + 1 && word.endsWith(j)) {
        return word.substring(0, word.length - j.length);
      }
    }
    return word;
  }

  static int _orderedMatchedWordCount(
    List<String> original,
    List<String> spoken,
  ) {
    var previous = List<int>.filled(spoken.length + 1, 0);
    for (final originalWord in original) {
      final current = List<int>.filled(spoken.length + 1, 0);
      for (var index = 1; index <= spoken.length; index++) {
        if (isSameWordStem(originalWord, spoken[index - 1])) {
          current[index] = previous[index - 1] + 1;
        } else {
          current[index] = max(previous[index], current[index - 1]);
        }
      }
      previous = current;
    }
    return previous.last;
  }

  /// Levenshtein Distance
  static int _levenshteinDistance(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i <= t.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s[i] == t[j]) ? 0 : 1;
        v1[j + 1] = min(v1[j] + 1, min(v0[j + 1] + 1, v0[j] + cost));
      }

      for (int j = 0; j <= t.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }

  /// 단어별 Diff 토큰 정렬 생성 (LCS 동적계획법 역추적 방식)
  ///
  /// 정통 LCS(최장 공통 부분수열) DP 역추적을 사용하여
  /// 문장 통째 누락(Missing), 추가/에코(Extra), 어간 일치(Matched)를
  /// 단어 건너뜀 크기와 무관하게 100% 정밀하게 정렬 복원한다.
  static List<DiffToken> _generateDiffTokens(
    List<String> origWords,
    List<String> spokenWords,
  ) {
    final m = origWords.length;
    final n = spokenWords.length;
    if (m == 0 && n == 0) return [];
    if (m == 0) {
      return spokenWords
          .map((w) => DiffToken(text: w, type: DiffType.extra))
          .toList();
    }
    if (n == 0) {
      return origWords
          .map((w) => DiffToken(text: w, type: DiffType.missing))
          .toList();
    }

    // DP 테이블 구성
    final dp = List.generate(m + 1, (_) => List<int>.filled(n + 1, 0));

    for (int i = 1; i <= m; i++) {
      for (int j = 1; j <= n; j++) {
        if (isSameWordStem(origWords[i - 1], spokenWords[j - 1])) {
          dp[i][j] = dp[i - 1][j - 1] + 1;
        } else {
          dp[i][j] = max(dp[i - 1][j], dp[i][j - 1]);
        }
      }
    }

    // 역추적(Backtracking)하여 Diff 토큰 복원
    final tokens = <DiffToken>[];
    int i = m;
    int j = n;

    while (i > 0 || j > 0) {
      if (i > 0 &&
          j > 0 &&
          isSameWordStem(origWords[i - 1], spokenWords[j - 1])) {
        final isExact = origWords[i - 1] == spokenWords[j - 1];
        tokens.add(DiffToken(
          text: spokenWords[j - 1],
          type: DiffType.matched,
          originalText: isExact ? null : origWords[i - 1],
        ));
        i--;
        j--;
      } else if (j > 0 && (i == 0 || dp[i][j - 1] >= dp[i - 1][j])) {
        // 발화에 추가된 잉여/반복 단어
        tokens.add(DiffToken(text: spokenWords[j - 1], type: DiffType.extra));
        j--;
      } else {
        // 원문에서 누락된 단어
        tokens.add(DiffToken(text: origWords[i - 1], type: DiffType.missing));
        i--;
      }
    }

    return tokens.reversed.toList();
  }
}
