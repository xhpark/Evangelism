import 'package:flutter/foundation.dart';
import '../models/section_model.dart';
import '../data/script_repository.dart';

class ScriptManageProvider extends ChangeNotifier {
  final ScriptRepository _repository;

  List<Section> _sections = [];
  String _userTestimony = '';
  String _userChurch = '';
  bool _isLoading = false;

  ScriptManageProvider(this._repository) {
    loadData();
  }

  List<Section> get sections => _sections;
  String get userTestimony => _userTestimony;
  String get userChurch => _userChurch;
  bool get isLoading => _isLoading;

  Future<void> loadData() async {
    _isLoading = true;
    notifyListeners();

    _sections = await _repository.loadSections();
    _userTestimony = await _repository.getUserTestimony();
    _userChurch = await _repository.getUserChurch();

    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateStep(String stepId, String newScript) async {
    await _repository.updateStepScript(stepId, newScript);
    await loadData();
  }

  Future<void> saveTestimony(String text) async {
    _userTestimony = text;
    await _repository.saveUserTestimony(text);
    notifyListeners();
  }

  Future<void> saveChurch(String text) async {
    _userChurch = text;
    await _repository.saveUserChurch(text);
    notifyListeners();
  }

  Future<bool> importText(String rawText) async {
    final success = await _repository.importFromPlainText(rawText);
    if (success) {
      await loadData();
    }
    return success;
  }

  Future<bool> undoLastImport() async {
    final success = await _repository.undoLastImport();
    if (success) await loadData();
    return success;
  }
}
