import 'dart:math';
import '../models/section_model.dart';
import '../models/step_item_model.dart';
import '../models/exam_result_model.dart';
import 'korean_text_normalizer.dart';
import 'quick_trigger_engine.dart';

enum ExamMode {
  transitionChain('전환 ➔ 다음 단락 연계', '전환문장 시작부를 제시하면 전환 완성 후 다음 단락 전체를 연계 암송'),
  illustrationChain('예화 집중 완주', '예화의 시작부를 제시하면 예화 단락 전체를 끝까지 암송'),
  introAndCommitChain('서론/결신 핵심 문답', '진단질문, 영접기도, 확신기도 시작부를 제시하면 해당 단락을 암송'),
  followUpChain('즉석 양육 항목별', '성경, 기도, 예배, 교제, 전도, 마침기도 시작부를 제시하면 단락 전체를 암송'),
  randomMix('실전 무작위 출제', '전체 전환/예화/서론/결신/양육 시작부 중 무작위 1문제 출제'),
  fullSequential('전체 전문 100% 완주', '서론부터 즉석 양육까지 전문 전체(34문장, 성경 구절 제외)를 완주하는 실전 모의시험');

  final String title;
  final String description;
  const ExamMode(this.title, this.description);
}

class ExamQuestion {
  final String title;
  final String category;
  final String leadingScript;
  final String instruction;
  final String originalText;
  final List<String> keywords;
  final List<Section> sourceSections;

  ExamQuestion({
    required this.title,
    required this.category,
    required this.leadingScript,
    required this.instruction,
    required this.originalText,
    required this.keywords,
    required this.sourceSections,
  });

  /// 난이도별(고급 3단어 / 중급 4단어 / 초급 5단어) 문두 동적 추출
  String getTriggerPrompt([
    TriggerDifficulty difficulty = TriggerDifficulty.master,
  ]) {
    if (leadingScript.isEmpty) return "";
    return QuickTriggerEngine.extractLeadIn(
      leadingScript,
      difficulty: difficulty,
    );
  }

  /// 기본 문두 (3단어)
  String get triggerPrompt => getTriggerPrompt(TriggerDifficulty.master);
}

class RandomExamEngine {
  final Random _random = Random();

  /// 모드별 시험 문제 생성 (성경 구절 암송은 실전시험에서 제외)
  ExamQuestion generateQuestion(ExamMode mode, List<Section> allSections) {
    if (allSections.isEmpty) {
      return ExamQuestion(
        title: "데이터 없음",
        category: "알림",
        leadingScript: "",
        instruction: "교재 데이터가 로드되지 않았습니다.",
        originalText: "",
        keywords: [],
        sourceSections: [],
      );
    }

    final secMap = {for (var s in allSections) s.id: s};
    final stepMap = <String, StepItem>{};
    for (var s in allSections) {
      for (var st in s.steps) {
        stepMap[st.stepId] = st;
      }
    }

    switch (mode) {
      case ExamMode.transitionChain:
        return _pickRandomTransitionChain(secMap, stepMap, allSections);

      case ExamMode.illustrationChain:
        return _pickRandomIllustration(stepMap, allSections);

      case ExamMode.introAndCommitChain:
        return _pickRandomIntroOrCommit(secMap, stepMap, allSections);

      case ExamMode.followUpChain:
        return _pickRandomFollowUp(stepMap, allSections);

      case ExamMode.randomMix:
        final generators = [
          () => _pickRandomTransitionChain(secMap, stepMap, allSections),
          () => _pickRandomIllustration(stepMap, allSections),
          () => _pickRandomIntroOrCommit(secMap, stepMap, allSections),
          () => _pickRandomFollowUp(stepMap, allSections),
        ];
        return generators[_random.nextInt(generators.length)]();

      case ExamMode.fullSequential:
        final filteredSections = allSections.map((sec) {
          final validSteps = sec.steps
              .where((st) => st.type != StepType.verse || st.stepId == 'commit_5')
              .toList();
          return sec.copyWith(steps: validSteps);
        }).where((sec) => sec.steps.isNotEmpty).toList();

        final nonScriptureSteps =
            filteredSections.expand((s) => s.steps).toList();
        final fullText =
            nonScriptureSteps.map((s) => s.effectiveScript).join(' ');
        final allKw =
            nonScriptureSteps.expand((s) => s.keywords).toSet().toList();
        final firstLead = nonScriptureSteps.first.effectiveScript;
        return ExamQuestion(
          title: "👑 전체 전문 100% 완주 시험 (성경 구절 제외)",
          category: "전체 완주",
          leadingScript: firstLead,
          instruction:
              "서론부터 즉석 양육 마침 기도까지 전체 전문(34문장, 성경 구절 암송 제외)을 처음부터 끝까지 빠짐없이 암송하세요.",
          originalText: fullText,
          keywords: allKw,
          sourceSections: filteredSections,
        );
    }
  }

  // 1. 전환 ➔ 다음 단락 연계 암송 생성 (순수 성경구절 단계는 암송 제외)
  ExamQuestion _pickRandomTransitionChain(
    Map<String, Section> secMap,
    Map<String, StepItem> stepMap,
    List<Section> allSections,
  ) {
    final list = [
      // 1) 은혜 ➔ 인간 (롬 3:23 성경 구절 제외)
      _makeChain(
        title: "🔗 전환 연계: 은혜 ➔ [2.2 인간] 전체",
        instruction:
            "위 전환 문장을 완성하고, 이어서 [2.2 인간] 대지 전체(인간은 죄인, 죄의 정의 3가지, 9만 번 죄 예화, 하나님 전환문장)를 이어서 암송하세요. (성경 구절 제외)",
        steps: [
          stepMap['grace_4'],
          stepMap['human_1'],
          stepMap['human_3'],
          stepMap['human_4'],
          stepMap['human_5'],
        ],
        sourceSections: [
          secMap['grace'] ?? allSections.first,
          secMap['humanity'] ?? allSections.first,
        ],
      ),
      // 2) 인간 ➔ 하나님 (요일 4:8/출 34:7 성경 구절 제외)
      _makeChain(
        title: "🔗 전환 연계: 인간 ➔ [2.3 하나님] 전체",
        instruction:
            "위 전환 문장을 완성하고, 이어서 [2.3 하나님] 대지 전체(자비와 공의, 가르시아 장군 어머니 채찍 예화, 그리스도 전환문장)를 이어서 암송하세요. (성경 구절 제외)",
        steps: [
          stepMap['human_5'],
          stepMap['god_1'],
          stepMap['god_3'],
          stepMap['god_4'],
        ],
        sourceSections: [
          secMap['humanity'] ?? allSections.first,
          secMap['god'] ?? allSections.first,
        ],
      ),
      // 3) 하나님 ➔ 그리스도 (사 53:6 성경 구절 제외)
      _makeChain(
        title: "🔗 전환 연계: 하나님 ➔ [2.4 그리스도] 전체",
        instruction:
            "위 전환 문장을 완성하고, 이어서 [2.4 예수 그리스도] 대지 전체(참하나님 참인간, 죄의 책 예화, 다 이루었다 부활·승천, 믿음 전환문장)를 이어서 암송하세요. (성경 구절 제외)",
        steps: [
          stepMap['god_4'],
          stepMap['christ_1'],
          stepMap['christ_2'],
          stepMap['christ_4'],
          stepMap['christ_5'],
        ],
        sourceSections: [
          secMap['god'] ?? allSections.first,
          secMap['christ'] ?? allSections.first,
        ],
      ),
      // 4) 그리스도 ➔ 믿음 (행 16:31 성경 구절 제외)
      _makeChain(
        title: "🔗 전환 연계: 그리스도 ➔ [2.5 믿음] 전체",
        instruction:
            "위 전환 문장을 완성하고, 이어서 [2.5 믿음] 대지 전체(참 믿음 정의, 의자 예화, 신뢰 이전 동기부여 질문)를 이어서 암송하세요. (성경 구절 제외)",
        steps: [
          stepMap['christ_5'],
          stepMap['faith_1'],
          stepMap['faith_3'],
          stepMap['faith_4'],
        ],
        sourceSections: [
          secMap['christ'] ?? allSections.first,
          secMap['faith'] ?? allSections.first,
        ],
      ),
      // 5) 믿음 ➔ 결신 (결신 질문, 3가지 의미, 영접 기도, 확신 기도, 구원의 확신 문답)
      _makeChain(
        title: "🔗 전환 연계: 믿음 ➔ [3. 결신] 전체",
        instruction:
            "위 동기부여 전환 문장을 완성하고, 이어서 [3. 결신] 전체(결신 질문, 3가지 의미, 영접 기도, 확신 기도, 구원의 확신 문답)를 이어서 암송하세요.",
        steps: [stepMap['faith_4'], ...?secMap['commitment']?.steps],
        sourceSections: [
          secMap['faith'] ?? allSections.first,
          secMap['commitment'] ?? allSections.first,
        ],
      ),
      // 6) 서론 허락 ➔ 은혜 (엡 2:8-9 성경 구절 제외)
      _makeChain(
        title: "🔗 전환 연계: 서론 허락 ➔ [2.1 은혜] 전체",
        instruction:
            "위 복음 제시 허락 질문을 완성하고, 이어서 [2.1 은혜] 대지 전체(선물 핵심진리, 햇빛·공기·물 예화, 인간 전환문장)를 이어서 암송하세요. (성경 구절 제외)",
        steps: [
          stepMap['intro_6'],
          stepMap['grace_1'],
          stepMap['grace_3'],
          stepMap['grace_4'],
        ],
        sourceSections: [
          secMap['intro'] ?? allSections.first,
          secMap['grace'] ?? allSections.first,
        ],
      ),
    ];

    return list[_random.nextInt(list.length)];
  }

  // 2. 예화 집중 암송 생성
  ExamQuestion _pickRandomIllustration(
    Map<String, StepItem> stepMap,
    List<Section> allSections,
  ) {
    final list = [
      _makeSingle(
        title: "📖 예화 집중: [은혜] 햇빛·공기·물 선물 예화",
        instruction: "생명과 직결된 것들을 값없이 선물로 주신 원리와 영생의 선물을 연결하는 예화 단락 전체를 암송하세요.",
        step: stepMap['grace_3'],
        fallbackSection: allSections.first,
      ),
      _makeSingle(
        title: "📖 예화 집중: [인간] 하루 3번 9만 번 죄 예화",
        instruction:
            "하루 3번, 1년 천 번, 90평생 9만 번 이상의 죄로 누구나 죄인임을 증명하는 예화 단락 전체를 암송하세요.",
        step: stepMap['human_4'],
        fallbackSection: allSections.first,
      ),
      _makeSingle(
        title: "📖 예화 집중: [하나님] 가르시아 장군 어머니 채찍 예화",
        instruction:
            "도둑이 된 어머니 대신 채찍에 맞아 사랑과 공의를 모두 만족시킨 가르시아 장군 예화 단락 전체를 암송하세요.",
        step: stepMap['god_3'],
        fallbackSection: allSections.first,
      ),
      _makeSingle(
        title: "📖 예화 집중: [그리스도] 지은 모든 죄가 기록된 책 예화",
        instruction: "죄가 기록된 책의 심판과 그 모든 죄악을 예수 그리스도께 옮기신 대속 예화 단락 전체를 암송하세요.",
        step: stepMap['christ_2'],
        fallbackSection: allSections.first,
      ),
      _makeSingle(
        title: "📖 예화 집중: [믿음] 의자 예화 (온전한 맡김)",
        instruction:
            "지식적 동의와 현세적 믿음의 한계를 짚고, 온전히 자신을 예수님께 맡기는 의자 예화 단락 전체를 암송하세요.",
        step: stepMap['faith_3'],
        fallbackSection: allSections.first,
      ),
    ];

    return list[_random.nextInt(list.length)];
  }

  // 3. 서론 & 결신 문답 암송 생성 (순수 성경 구절 제외)
  ExamQuestion _pickRandomIntroOrCommit(
    Map<String, Section> secMap,
    Map<String, StepItem> stepMap,
    List<Section> allSections,
  ) {
    final list = [
      _makeSingle(
        title: "💬 서론: 제1 진단 질문 (천국 확신)",
        instruction: "천국 확신 질문과 성경 소개 단락 전체를 암송하세요.",
        step: stepMap['intro_3'],
        fallbackSection: allSections.first,
      ),
      _makeSingle(
        title: "💬 서론: 성경 기록 목적 (팀원 확신 확인)",
        instruction: "성경 기록 목적과 동행 팀원 확신 확인 단락 전체를 암송하세요.",
        step: stepMap['intro_5'],
        fallbackSection: allSections.first,
      ),
      _makeSingle(
        title: "💬 서론: 제2 진단 질문 (복음 제시 허락)",
        instruction: "천국 들어가는 이유 질문과 선한 행위 확인, 가장 기쁜 소식 허락 단락 전체를 암송하세요.",
        step: stepMap['intro_6'],
        fallbackSection: allSections.first,
      ),
      _makeChain(
        title: "🙏 결신: 결신 질문 및 3가지 의미",
        instruction: "영생 선물 수령 결신 질문과 결신의 3가지 의미 단락 전체를 이어서 암송하세요.",
        steps: [stepMap['commit_1'], stepMap['commit_2']],
        sourceSections: [secMap['commitment'] ?? allSections.first],
      ),
      _makeSingle(
        title: "🙏 결신: 영접 기도 인도",
        instruction: "대상자가 한 마디씩 따라 하는 영접 기도문 전체를 빠짐없이 암송하세요.",
        step: stepMap['commit_3'],
        fallbackSection: allSections.first,
      ),
      _makeSingle(
        title: "🙏 결신: 확신 축복 기도",
        instruction: "영접한 대상자를 위해 사죄의 확신과 구원의 확신을 간구하는 축복 기도문 전체를 암송하세요.",
        step: stepMap['commit_4'],
        fallbackSection: allSections.first,
      ),
    ];

    return list[_random.nextInt(list.length)];
  }

  // 4. 즉석 양육 항목별 암송 생성
  ExamQuestion _pickRandomFollowUp(
    Map<String, StepItem> stepMap,
    List<Section> allSections,
  ) {
    final list = [
      _makeSingle(
        title: "🌱 양육 1: 성경 (영혼의 양식)",
        instruction: "영혼의 양식인 성경 읽기(요한복음 1장씩 권유 및 일주일 후 방문 약속) 단락 전체를 암송하세요.",
        step: stepMap['follow_2'],
        fallbackSection: allSections.first,
      ),
      _makeSingle(
        title: "🌱 양육 2: 기도 (5손가락 기도법)",
        instruction:
            "5손가락 기도법(하나님 아버지, 감사, 용서, 도움, 예수님 이름, 아멘 및 실습) 단락 전체를 빠짐없이 암송하세요.",
        step: stepMap['follow_3'],
        fallbackSection: allSections.first,
      ),
      _makeSingle(
        title: "🌱 양육 3: 예배 (주일 예배 동행)",
        instruction: "예배의 정의와 이번 주일 오전 11:30분 예배 동행 약속 단락 전체를 암송하세요.",
        step: stepMap['follow_4'],
        fallbackSection: allSections.first,
      ),
      _makeSingle(
        title: "🌱 양육 4: 교제 (새가족 모임)",
        instruction: "믿음의 교제의 중요성과 새가족 모임 안내 단락 전체를 암송하세요.",
        step: stepMap['follow_5'],
        fallbackSection: allSections.first,
      ),
      _makeSingle(
        title: "🌱 양육 5: 전도 (복음 나눔)",
        instruction: "복음 전도의 중요성과 전도 대상자 질문, 방문 약속 단락 전체를 암송하세요.",
        step: stepMap['follow_6'],
        fallbackSection: allSections.first,
      ),
      _makeSingle(
        title: "🌱 양육: 마침 기도 및 마무리 인사",
        instruction: "대상자와의 귀한 교제 감사 및 신앙 성장을 위한 마침 축복 기도와 끝인사를 암송하세요.",
        step: stepMap['follow_7'],
        fallbackSection: allSections.first,
      ),
    ];

    return list[_random.nextInt(list.length)];
  }

  // 헬퍼: 단일 스텝 문제 빌더
  ExamQuestion _makeSingle({
    required String title,
    required String instruction,
    required StepItem? step,
    required Section fallbackSection,
    String? customLeadingScript,
  }) {
    final text = step?.effectiveScript ?? "";
    final lead = customLeadingScript ?? text;
    final kw = step?.keywords ?? [];
    return ExamQuestion(
      title: title,
      category: title.split(':').first,
      leadingScript: lead,
      instruction: instruction,
      originalText: text,
      keywords: kw,
      sourceSections: [fallbackSection],
    );
  }

  // 헬퍼: 복수 스텝 연계 문제 빌더
  ExamQuestion _makeChain({
    required String title,
    required String instruction,
    required List<StepItem?> steps,
    required List<Section> sourceSections,
    String? customLeadingScript,
  }) {
    final validSteps = steps.whereType<StepItem>().toList();
    final fullText = validSteps.map((s) => s.effectiveScript).join(' ');
    final lead =
        customLeadingScript ??
        (validSteps.isNotEmpty ? validSteps.first.effectiveScript : "");
    final allKw = validSteps.expand((s) => s.keywords).toSet().toList();

    return ExamQuestion(
      title: title,
      category: title.split(':').first,
      leadingScript: lead,
      instruction: instruction,
      originalText: fullText,
      keywords: allKw,
      sourceSections: sourceSections,
    );
  }

  /// 실전 구두시험 핵심 4대 영역별 세부 점수 산출 (성경 구절 암송 제외)
  static List<ExamAreaScore> calculate5AreaBreakdown(
    String originalText,
    String spokenText,
  ) {
    final normSpoken = KoreanTextNormalizer.normalize(spokenText);

    // 1. 핵심 교리 진리 (35점)
    final doctrineKw = [
      '선물',
      '공로',
      '자격',
      '죄인',
      '스스로',
      '자비',
      '공의',
      '하나님',
      '예수',
      '믿음',
    ];
    final doctrineScore = _scoreKeywords(normSpoken, doctrineKw, 35.0);

    // 2. 대지 전환문장 (25점)
    final transKw = [
      '기쁜 소식',
      '인간에 관하여',
      '죄인이 어떻게',
      '단번에 해결',
      '오직 예수',
      '신뢰의 대상',
    ];
    final transScore = _scoreKeywords(normSpoken, transKw, 25.0);

    // 3. 핵심 복음 예화 (25점)
    final illustKw = [
      '햇빛',
      '공기',
      '물',
      '천사',
      '9만 번',
      '가르시아',
      '채찍',
      '책',
      '의자',
    ];
    final illustScore = _scoreKeywords(normSpoken, illustKw, 25.0);

    // 4. 결신 및 즉석양육 (15점)
    final followKw = ['영접', '확신', '성경', '기도', '예배', '교제', '전도', '아멘'];
    final followScore = _scoreKeywords(normSpoken, followKw, 15.0);

    return [
      ExamAreaScore(
        areaName: "1. 핵심 교리 진리",
        score: doctrineScore,
        maxScore: 35.0,
      ),
      ExamAreaScore(
        areaName: "2. 대지 전환문장",
        score: transScore,
        maxScore: 25.0,
      ),
      ExamAreaScore(
        areaName: "3. 핵심 복음 예화",
        score: illustScore,
        maxScore: 25.0,
      ),
      ExamAreaScore(
        areaName: "4. 결신 및 즉석양육",
        score: followScore,
        maxScore: 15.0,
      ),
    ];
  }

  static double _scoreKeywords(
    String spoken,
    List<String> keywords,
    double maxScore,
  ) {
    if (keywords.isEmpty) return maxScore;
    final cleanSpoken = spoken.replaceAll(' ', '');
    int matched = 0;
    for (final kw in keywords) {
      final cleanKw = KoreanTextNormalizer.normalize(kw).replaceAll(' ', '');
      if (cleanSpoken.contains(cleanKw)) {
        matched++;
      }
    }
    final ratio = matched / keywords.length;
    return (ratio * maxScore).clamp(0.0, maxScore);
  }
}
