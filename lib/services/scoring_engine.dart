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

    // 1. 문자 단위 유사도 (Levenshtein Distance)
    final charDist = _levenshteinDistance(normOrig, normSpoken);
    final maxLen = max(normOrig.length, normSpoken.length);
    final charAcc = maxLen == 0 ? 1.0 : max(0.0, 1.0 - (charDist / maxLen));

    // 2. 단어/토큰 단위 일치도
    final origWords = normOrig.split(' ').where((w) => w.isNotEmpty).toList();
    final spokenWords = normSpoken
        .split(' ')
        .where((w) => w.isNotEmpty)
        .toList();

    // 순서와 반복 횟수를 보존하는 최장 공통 부분수열 길이로 계산한다.
    // Set 기반 계산은 한 번 말한 단어로 원문의 모든 반복을 맞힌 것으로 처리했다.
    final matchedWordCount = _orderedMatchedWordCount(origWords, spokenWords);
    final tokenAcc = origWords.isEmpty
        ? 1.0
        : min(1.0, matchedWordCount / origWords.length);

    // 3. 핵심 키워드 가중치 검사
    double keywordAcc = 1.0;
    if (keywords.isNotEmpty) {
      int kwMatched = 0;
      for (final kw in keywords) {
        final normKw = KoreanTextNormalizer.normalize(kw);
        if (normSpoken.contains(normKw) ||
            spokenWords.any((w) => w.contains(normKw))) {
          kwMatched++;
        }
      }
      keywordAcc = kwMatched / keywords.length;
    }

    // 4. 최종 종합 점수 산출
    double finalScore =
        (0.35 * charAcc + 0.35 * tokenAcc + 0.30 * keywordAcc) * 100.0;
    if (charAcc >= 0.95 && keywordAcc >= 0.95) {
      finalScore = 100.0; // 사소한 띄어쓰기 차이는 만점 처리
    }
    finalScore = finalScore.clamp(0.0, 100.0);

    // 5. Diff 토큰 생성 (어절 단위 lookahead 정렬 방식)
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

  /// 한국어 조사 목록 (긴 것부터 검사)
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
    '으로',
    '와의',
    '과의',
    '들이',
    '들을',
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
  /// - 한쪽이 다른 쪽의 접두(앞부분)이고 길이 차가 2 이하이면 참 ("주시" ↔ "주시는")
  /// - 조사만 떼어낸 어간이 같으면 참 ("영생은" ↔ "영생을")
  /// 그 외에는 서로 다른 단어로 본다. ("선물입니다" ↔ "선반입니다"는 오답)
  static bool isSameWordStem(String a, String b) {
    if (a.isEmpty || b.isEmpty) return false;
    if (a == b) return true;

    final shorter = a.length <= b.length ? a : b;
    final longer = a.length <= b.length ? b : a;
    if (shorter.length >= 2 &&
        longer.startsWith(shorter) &&
        longer.length - shorter.length <= 2) {
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

  /// 단어별 Diff 토큰 정렬 생성
  ///
  /// 정통 Myers Diff가 아니라, 앞으로 3어절까지 살펴보며 맞춰가는 그리디 정렬이다.
  /// (문서·UI 표기도 '어절 대조'로 통일했다 — 2026-08-29)
  static List<DiffToken> _generateDiffTokens(
    List<String> origWords,
    List<String> spokenWords,
  ) {
    final tokens = <DiffToken>[];
    int oIdx = 0;
    int sIdx = 0;

    while (oIdx < origWords.length && sIdx < spokenWords.length) {
      final oWord = origWords[oIdx];
      final sWord = spokenWords[sIdx];

      if (oWord == sWord) {
        tokens.add(DiffToken(text: oWord, type: DiffType.matched));
        oIdx++;
        sIdx++;
      } else if (isSameWordStem(oWord, sWord)) {
        tokens.add(
          DiffToken(text: sWord, type: DiffType.matched, originalText: oWord),
        );
        oIdx++;
        sIdx++;
      } else {
        // 다음 몇 단어 내에서 매칭 탐색
        int lookaheadO = -1;
        for (int i = oIdx + 1; i < min(oIdx + 4, origWords.length); i++) {
          if (origWords[i] == sWord) {
            lookaheadO = i;
            break;
          }
        }

        if (lookaheadO != -1) {
          // 중간의 원문 단어들은 누락(Missing) 처리
          while (oIdx < lookaheadO) {
            tokens.add(
              DiffToken(text: origWords[oIdx], type: DiffType.missing),
            );
            oIdx++;
          }
          tokens.add(DiffToken(text: sWord, type: DiffType.matched));
          oIdx++;
          sIdx++;
        } else {
          // 사용자 추가/대체 발화
          tokens.add(
            DiffToken(text: sWord, type: DiffType.extra, originalText: oWord),
          );
          sIdx++;
          oIdx++;
        }
      }
    }

    // 남아있는 원문 단어들 -> missing
    while (oIdx < origWords.length) {
      tokens.add(DiffToken(text: origWords[oIdx], type: DiffType.missing));
      oIdx++;
    }

    // 남아있는 발화 단어들 -> extra
    while (sIdx < spokenWords.length) {
      tokens.add(DiffToken(text: spokenWords[sIdx], type: DiffType.extra));
      sIdx++;
    }

    return tokens;
  }
}
