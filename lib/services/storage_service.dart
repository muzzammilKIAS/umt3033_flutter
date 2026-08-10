import 'dart:convert';
import 'package:flutter/foundation.dart' show ChangeNotifier;
import 'package:shared_preferences/shared_preferences.dart';

class StorageService extends ChangeNotifier {
  static const _key = 'umt3033_app_v1';

  Map<String, dynamic> _state = {};
  late SharedPreferences _prefs;

  bool _init = false;

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs.getString(_key);
    if (raw != null) {
      try {
        _state = json.decode(raw) as Map<String, dynamic>;
      } catch (_) {
        _state = {};
      }
    }
    _init = true;
  }

  bool get isInit => _init;

  Map<String, dynamic> get state => _state;

  void _save() {
    _prefs.setString(_key, json.encode(_state));
    notifyListeners();
  }

  bool isUnitCompleted(int unitId) {
    final progress = _state['progress'] as Map<String, dynamic>?;
    final unit = progress?['$unitId'] as Map<String, dynamic>?;
    return unit?['completed'] == true;
  }

  void setUnitCompleted(int unitId) {
    var progress = _state['progress'] as Map<String, dynamic>?;
    progress ??= {};
    _state['progress'] = progress;
    progress['$unitId'] = {'completed': true, 'completedAt': DateTime.now().toIso8601String()};
    _save();
  }

  int get completedUnitCount {
    final progress = _state['progress'] as Map<String, dynamic>? ?? {};
    return progress.values.where((v) => (v as Map)['completed'] == true).length;
  }

  double get overallProgress => completedUnitCount / 14.0;

  Set<String> get vocabLearned {
    final raw = _state['vocabLearned'] as List? ?? [];
    return raw.cast<String>().toSet();
  }

  void toggleVocabLearned(String id) {
    var raw = _state['vocabLearned'] as List? ?? [];
    _state['vocabLearned'] = raw;
    if (raw.contains(id)) {
      raw.remove(id);
    } else {
      raw.add(id);
    }
    _save();
  }

  String get theme {
    return _state['theme'] as String? ?? 'light';
  }

  void setTheme(String theme) {
    _state['theme'] = theme;
    _save();
  }

  Map<String, dynamic> get audioPrefs {
    return _state['audioPrefs'] as Map<String, dynamic>? ?? {
      'voice': 'male',
      'speed': 1.0,
      'repeat': 'none',
    };
  }

  void setAudioPref(String key, dynamic value) {
    var prefs = _state['audioPrefs'] as Map<String, dynamic>?;
    prefs ??= {};
    _state['audioPrefs'] = prefs;
    prefs[key] = value;
    _save();
  }

  int get lastUnitId {
    final pos = _state['lastPosition'] as Map<String, dynamic>?;
    return pos?['unitId'] as int? ?? 1;
  }

  void setLastPosition(int unitId, String tabId) {
    _state['lastPosition'] = {'unitId': unitId, 'tabId': tabId};
    _save();
  }

  void resetAll() {
    _state = {};
    _prefs.remove(_key);
    notifyListeners();
  }
}
