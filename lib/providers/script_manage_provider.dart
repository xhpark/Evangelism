import 'package:flutter/foundation.dart';
import '../models/section_model.dart';
import '../data/script_repository.dart';

class ScriptManageProvider extends ChangeNotifier {
  final ScriptRepository _repository;

  List<Section> _sections = [];
  String _userTestimony = '';
  String _userChurch = '';
  bool _isLoading = false;

  bool _isDisposed = false;

  ScriptManageProvider(this._repository) {
    _repository.addListener(_onRepositoryChanged);
    loadData();
  }

  void _onRepositoryChanged() {
    loadData(showLoading: false);
  }

  @override
  void dispose() {
    _isDisposed = true;
    _repository.removeListener(_onRepositoryChanged);
    super.dispose();
  }

  List<Section> get sections => _sections;
  String get userTestimony => _userTestimony;
  String get userChurch => _userChurch;
  bool get isLoading => _isLoading;

  Future<void> loadData({bool showLoading = true}) async {
    if (_isDisposed) return;
    if (showLoading && _sections.isEmpty) {
      _isLoading = true;
      notifyListeners();
    }

    final loadedSections = await _repository.loadSections();
    final loadedTestimony = await _repository.getUserTestimony();
    final loadedChurch = await _repository.getUserChurch();

    if (_isDisposed) return;
    _sections = loadedSections;
    _userTestimony = loadedTestimony;
    _userChurch = loadedChurch;
    _isLoading = false;
    notifyListeners();
  }

  Future<void> updateStep(String stepId, String newScript) async {
    await _repository.updateStepScript(stepId, newScript);
  }

  Future<void> saveTestimony(String text) async {
    _userTestimony = text;
    await _repository.saveUserTestimony(text);
  }

  Future<void> saveChurch(String text) async {
    _userChurch = text;
    await _repository.saveUserChurch(text);
  }

  Future<bool> importText(String rawText) async {
    final success = await _repository.importFromPlainText(rawText);
    return success;
  }

  Future<bool> undoLastImport() async {
    final success = await _repository.undoLastImport();
    return success;
  }
}
