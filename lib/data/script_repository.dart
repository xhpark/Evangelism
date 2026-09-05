import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/section_model.dart';
import '../models/exam_result_model.dart';

class ScriptRepository extends ChangeNotifier {
  static const String _customScriptsKey = 'just_ee_custom_scripts_v1';
  static const String _userTestimonyKey = 'just_ee_user_testimony';
  static const String _userChurchKey = 'just_ee_user_church';
  static const String _examHistoryKey = 'just_ee_exam_history';
  static const String _mistakesKey = 'just_ee_mistakes';
  static const String _importBackupKey =
      'just_ee_custom_scripts_import_backup_v1';

  List<Section>? _cachedSections;

  /// 기본 JSON 데이터 로드 및 로컬 커스텀 오버라이드 병합
  Future<List<Section>> loadSections() async {
    if (_cachedSections != null) return _cachedSections!;

    final jsonString = await rootBundle.loadString('data/just_ee_data.json');
    final Map<String, dynamic> data = json.decode(jsonString);
    final List<dynamic> sectionList = data['sections'] ?? [];

    final customMap = await _getCustomScriptsMap();
    final userTestimony = await getUserTestimony();
    final userChurch = await getUserChurch();

    List<Section> sections = sectionList.map((s) {
      return Section.fromJson(s as Map<String, dynamic>);
    }).toList();

    // 커스텀 스크립트 및 개인 간증/교회명 주입
    for (var sec in sections) {
      for (var step in sec.steps) {
        if (customMap.containsKey(step.stepId)) {
          step.customScript = customMap[step.stepId];
        } else if (step.stepId == 'intro_2' && userTestimony.isNotEmpty) {
          // 이전 버전에서 별도 저장된 간증은 직접 수정본이 없을 때만 마이그레이션한다.
          step.customScript = userTestimony;
        }

        // 교회명 치환
        if (userChurch.isNotEmpty && step.effectiveScript.contains('[교회 이름]')) {
          step.customScript = step.effectiveScript.replaceAll(
            '[교회 이름]',
            userChurch,
          );
        }
      }
    }

    _cachedSections = sections;
    return sections;
  }

  /// 특정 스텝의 스크립트 수정 저장
  Future<void> updateStepScript(String stepId, String newScript) async {
    final prefs = await SharedPreferences.getInstance();
    final customMap = await _getCustomScriptsMap();

    customMap[stepId] = newScript;
    await prefs.setString(_customScriptsKey, json.encode(customMap));
    _cachedSections = null; // 캐시 무효화
    await loadSections();
    notifyListeners();
  }

  Future<Map<String, String>> _getCustomScriptsMap() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_customScriptsKey);
    if (raw == null || raw.isEmpty) return {};
    try {
      final decoded = json.decode(raw) as Map<String, dynamic>;
      return decoded.map((k, v) => MapEntry(k, v.toString()));
    } catch (_) {
      return {};
    }
  }

  /// 개인 간증 저장/조회
  Future<void> saveUserTestimony(String testimony) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userTestimonyKey, testimony);
    await updateStepScript('intro_2', testimony);
  }

  Future<String> getUserTestimony() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userTestimonyKey) ?? '';
  }

  /// 교회 이름 저장/조회
  Future<void> saveUserChurch(String churchName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userChurchKey, churchName);
    _cachedSections = null;
    await loadSections();
    notifyListeners();
  }

  Future<String> getUserChurch() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userChurchKey) ?? '';
  }

  /// 시험 결과 저장 및 조회
  /// 보관하는 시험 이력 최대 건수.
  /// 한 건에 원문·발화문·대조 토큰이 모두 들어가 무제한 누적되면
  /// 저장할 때마다 전체를 다시 직렬화하느라 앱이 느려진다.
  static const int maxExamHistory = 50;

  Future<void> saveExamResult(ExamResult result) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getExamHistory();
    list.insert(0, result);

    final trimmed = list.length > maxExamHistory
        ? list.sublist(0, maxExamHistory)
        : list;
    final encoded = json.encode(trimmed.map((r) => r.toJson()).toList());
    await prefs.setString(_examHistoryKey, encoded);
  }

  Future<List<ExamResult>> getExamHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_examHistoryKey);
    if (raw == null || raw.isEmpty) return [];
    try {
      final list = json.decode(raw) as List;
      return list
          .map((item) => ExamResult.fromJson(item as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// 오답 노트 (1초 순발력 헷갈림 항목) 저장/조회
  Future<void> addMistake(String stepId) async {
    final prefs = await SharedPreferences.getInstance();
    final mistakes = await getMistakeStepIds();
    if (!mistakes.contains(stepId)) {
      mistakes.add(stepId);
      await prefs.setStringList(_mistakesKey, mistakes);
    }
  }

  Future<void> removeMistake(String stepId) async {
    final prefs = await SharedPreferences.getInstance();
    final mistakes = await getMistakeStepIds();
    mistakes.remove(stepId);
    await prefs.setStringList(_mistakesKey, mistakes);
  }

  Future<List<String>> getMistakeStepIds() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_mistakesKey) ?? [];
  }

  /// 라벨 접두사(예: "핵심 진리: ")만 안전하게 제거
  static String _cleanPrefix(String s) {
    String text = s.trim();
    if (text.contains(':') || text.contains('：')) {
      final colonIdx = text.indexOf(RegExp(r'[:：]'));
      final prefix = text.substring(0, colonIdx).trim();
      if (prefix.length <= 18 &&
          !prefix.contains('니다') &&
          !prefix.contains('시오') &&
          !prefix.contains('까요') &&
          !prefix.contains('어때요')) {
        return text.substring(colonIdx + 1).trim();
      }
    }
    return text;
  }

  /// 외부 TXT 전문 자동 구조화 파싱 및 저장 (Import)
  /// 서론, 핵심 5가지(은혜/인간/하나님/그리스도/믿음), 결신, 양육 자동 분류
  Future<bool> importFromPlainText(String rawText) async {
    final text = rawText.trim();
    if (text.isEmpty) return false;

    final sections = await loadSections();
    final lines = text.split('\n');
    final detectedSections = <String>{};

    String? currentSecId;
    final Map<String, List<String>> sectionLines = {
      'intro': [],
      'grace': [],
      'humanity': [],
      'god': [],
      'christ': [],
      'faith': [],
      'commitment': [],
      'follow_up': [],
    };

    // 1. 8대 대지(서론, 핵심 5가지, 결신, 양육) 정밀 메인 헤더 검출
    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      bool isSectionHeader = false;
      String? detectedSec;
      final trimmed = line.replaceAll(RegExp(r'^#+\s*'), '').trim();

      if (RegExp(
            r'^(?:1[\.\s]+|1\s*장[\.\s]*)?(?:서론|Introduction)$',
            caseSensitive: false,
          ).hasMatch(trimmed) ||
          trimmed == '1. 서론' ||
          trimmed == '1.서론' ||
          trimmed == '서론') {
        detectedSec = 'intro';
        isSectionHeader = true;
      } else if (RegExp(
            r'^(?:2\.1[\.\s]+|2-1[\.\s]*)?(?:은혜|Grace)$',
            caseSensitive: false,
          ).hasMatch(trimmed) ||
          trimmed == '2.1 은혜' ||
          trimmed == '2.1. 은혜' ||
          trimmed == '2.1은혜' ||
          trimmed == '은혜') {
        detectedSec = 'grace';
        isSectionHeader = true;
      } else if (RegExp(
            r'^(?:2\.2[\.\s]+|2-2[\.\s]*)?(?:인간|Humanity)$',
            caseSensitive: false,
          ).hasMatch(trimmed) ||
          trimmed == '2.2 인간' ||
          trimmed == '2.2. 인간' ||
          trimmed == '2.2인간' ||
          trimmed == '인간') {
        detectedSec = 'humanity';
        isSectionHeader = true;
      } else if (RegExp(
            r'^(?:2\.3[\.\s]+|2-3[\.\s]*)?(?:하나님|God)$',
            caseSensitive: false,
          ).hasMatch(trimmed) ||
          trimmed == '2.3 하나님' ||
          trimmed == '2.3. 하나님' ||
          trimmed == '2.3하나님' ||
          trimmed == '하나님') {
        detectedSec = 'god';
        isSectionHeader = true;
      } else if (RegExp(
            r'^(?:2\.4[\.\s]+|2-4[\.\s]*)?(?:그리스도|예수\s*그리스도|Christ)$',
            caseSensitive: false,
          ).hasMatch(trimmed) ||
          trimmed == '2.4 그리스도' ||
          trimmed == '2.4. 그리스도' ||
          trimmed == '2.4그리스도' ||
          trimmed == '그리스도') {
        detectedSec = 'christ';
        isSectionHeader = true;
      } else if (RegExp(
            r'^(?:2\.5[\.\s]+|2-5[\.\s]*)?(?:믿음|Faith)$',
            caseSensitive: false,
          ).hasMatch(trimmed) ||
          trimmed == '2.5 믿음' ||
          trimmed == '2.5. 믿음' ||
          trimmed == '2.5믿음' ||
          trimmed == '믿음') {
        detectedSec = 'faith';
        isSectionHeader = true;
      } else if (RegExp(
            r'^(?:3[\.\s]+|3\s*장[\.\s]*)?(?:결신|결단|Commitment)$',
            caseSensitive: false,
          ).hasMatch(trimmed) ||
          trimmed == '3. 결신' ||
          trimmed == '3.결신' ||
          trimmed == '결신' ||
          trimmed == '결단') {
        detectedSec = 'commitment';
        isSectionHeader = true;
      } else if (RegExp(
            r'^(?:4[\.\s]+|4\s*장[\.\s]*)?(?:즉석\s*양육|양육|FollowUp)$',
            caseSensitive: false,
          ).hasMatch(trimmed) ||
          trimmed == '4. 즉석 양육' ||
          trimmed == '4. 즉석양육' ||
          trimmed == '4. 양육' ||
          trimmed == '4.양육' ||
          trimmed == '즉석 양육' ||
          trimmed == '양육') {
        detectedSec = 'follow_up';
        isSectionHeader = true;
      }

      if (isSectionHeader && detectedSec != null) {
        currentSecId = detectedSec;
        detectedSections.add(detectedSec);
        continue;
      }

      if (currentSecId != null) {
        sectionLines[currentSecId]!.add(line);
      } else {
        sectionLines['intro']!.add(line);
      }
    }

    // 일반 메모나 일부 문장을 전체 대본으로 오인해 기존 데이터를 덮지 않는다.
    if (detectedSections.length != sectionLines.length) return false;

    // 2. 각 섹션별 세부 스텝 매핑
    final prefs = await SharedPreferences.getInstance();
    final previousScripts = json.encode(await _getCustomScriptsMap());
    final customScripts = <String, String>{};
    int changedStepCount = 0;

    for (final sec in sections) {
      final linesForSec = sectionLines[sec.id] ?? [];
      if (linesForSec.isEmpty) continue;

      final Map<int, List<String>> stepBuckets = {};
      for (int i = 0; i < sec.steps.length; i++) {
        stepBuckets[i] = [];
      }

      int currentStepIdx = 0;
      for (final line in linesForSec) {
        bool matched = false;

        // A) 번호 패턴 매칭 (예: "1.1", "2.1.2", "2.2.1", "3.1", "4.1" 등)
        final numMatch = RegExp(
          r'^(\d+(?:\.\d+)*)[:\.\s\)\-]',
        ).firstMatch(line);
        if (numMatch != null) {
          final numStr = numMatch.group(1)!;
          final lastDigit = int.tryParse(numStr.split('.').last);
          if (lastDigit != null &&
              lastDigit >= 1 &&
              lastDigit <= sec.steps.length) {
            currentStepIdx = lastDigit - 1;
            matched = true;
            final stripped = line.substring(numMatch.end).trim();
            final cleanText = _cleanPrefix(stripped);
            if (cleanText.isNotEmpty) {
              stepBuckets[currentStepIdx]!.add(cleanText);
            }
          }
        }

        // B) 명시적 키워드 라벨 매칭 (콜론 앞의 라벨에 스텝 이름/키워드가 있을 때만)
        if (!matched && (line.contains(':') || line.contains('：'))) {
          final colonIdx = line.indexOf(RegExp(r'[:：]'));
          final labelPart = line.substring(0, colonIdx).trim();
          final contentPart = line.substring(colonIdx + 1).trim();

          if (labelPart.length <= 25 && contentPart.isNotEmpty) {
            for (int i = 0; i < sec.steps.length; i++) {
              final s = sec.steps[i];
              final pureName = s.name
                  .replaceAll(RegExp(r'\([^)]*\)'), '')
                  .trim();
              if (labelPart.contains(pureName) ||
                  (s.reference != null && labelPart.contains(s.reference!))) {
                currentStepIdx = i;
                matched = true;
                stepBuckets[currentStepIdx]!.add(contentPart);
                break;
              }
            }
          }
        }

        // C) 라벨 없는 일반 본문 라인 ➔ 본문 온전히 보존
        if (!matched) {
          final cleanText = _cleanPrefix(line);
          if (cleanText.isNotEmpty) {
            stepBuckets[currentStepIdx]!.add(cleanText);
          }
        }
      }

      for (int i = 0; i < sec.steps.length; i++) {
        final content = stepBuckets[i]!.join('\n').trim();
        if (content.isNotEmpty) {
          customScripts[sec.steps[i].stepId] = content;
          changedStepCount++;
        }
      }
    }

    if (changedStepCount < sectionLines.length) return false;

    // 3. 성공 직전에 직전 상태를 백업하고 원자적으로 교체한다.
    await prefs.setString(_importBackupKey, previousScripts);
    await prefs.setString(_customScriptsKey, json.encode(customScripts));
    _cachedSections = null;
    await loadSections();
    notifyListeners();
    return true;
  }

  Future<bool> undoLastImport() async {
    final prefs = await SharedPreferences.getInstance();
    final backup = prefs.getString(_importBackupKey);
    if (backup == null) return false;
    try {
      final decoded = json.decode(backup);
      if (decoded is! Map<String, dynamic>) return false;
      await prefs.setString(_customScriptsKey, backup);
      await prefs.remove(_importBackupKey);
      _cachedSections = null;
      await loadSections();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }
}
