import 'dart:math';
import '../models/diff_token.dart';
import '../models/exam_result_model.dart';
import 'korean_text_normalizer.dart';

class ScoringEngine {
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
    final spokenWords = normSpoken.split(' ').where((w) => w.isNotEmpty).toList();

    int matchedWordCount = 0;
    final spokenSet = spokenWords.toSet();
    for (final w in origWords) {
      if (spokenSet.contains(w)) {
        matchedWordCount++;
      } else {
        // 형태소/어근 부분 일치 검사 (3자 이상 시 2글자 겹침)
        bool partialMatch = spokenWords.any((sw) =>
            (w.length >= 3 && sw.contains(w.substring(0, 2))) ||
            (sw.length >= 3 && w.contains(sw.substring(0, 2))));
        if (partialMatch) matchedWordCount++;
      }
    }
    final tokenAcc = origWords.isEmpty
        ? 1.0
        : min(1.0, matchedWordCount / origWords.length);

    // 3. 핵심 키워드 가중치 검사
    double keywordAcc = 1.0;
    if (keywords.isNotEmpty) {
      int kwMatched = 0;
      for (final kw in keywords) {
        final normKw = KoreanTextNormalizer.normalize(kw);
        if (normSpoken.contains(normKw) || spokenWords.any((w) => w.contains(normKw))) {
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

    // 5. Diff 토큰 생성 (Myers Diff 기반 정렬)
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
  static List<DiffToken> _generateDiffTokens(
      List<String> origWords, List<String> spokenWords) {
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
      } else if (oWord.contains(sWord) || sWord.contains(oWord)) {
        tokens.add(DiffToken(
            text: sWord,
            type: DiffType.matched,
            originalText: oWord));
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
            tokens.add(DiffToken(text: origWords[oIdx], type: DiffType.missing));
            oIdx++;
          }
          tokens.add(DiffToken(text: sWord, type: DiffType.matched));
          oIdx++;
          sIdx++;
        } else {
          // 사용자 추가/대체 발화
          tokens.add(DiffToken(
              text: sWord,
              type: DiffType.extra,
              originalText: oWord));
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
