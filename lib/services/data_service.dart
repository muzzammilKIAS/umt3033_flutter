import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/unit_model.dart';

class DataService {
  List<UnitModel> _units = [];
  CourseModel? _course;
  List<GlossaryEntry> _glossary = [];
  List<AudioManifestItem> _audioManifest = [];

  List<UnitModel> get units => _units;
  CourseModel? get course => _course;
  List<GlossaryEntry> get glossary => _glossary;
  List<AudioManifestItem> get audioManifest => _audioManifest;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> loadAll() async {
    if (_loaded) return;
    try {
      final unitsJson =
          await rootBundle.loadString('assets/data/units.json');
      final courseJson =
          await rootBundle.loadString('assets/data/course.json');
      final glossaryJson =
          await rootBundle.loadString('assets/data/glossary.json');
      final audioJson =
          await rootBundle.loadString('assets/data/audio-manifest.json');

      final unitsList = json.decode(unitsJson) as List;
      _units = unitsList.map((j) => UnitModel.fromJson(j)).toList();
      _course = CourseModel.fromJson(json.decode(courseJson));
      _glossary = (json.decode(glossaryJson) as List)
          .map((j) => GlossaryEntry.fromJson(j))
          .toList();
      final am = json.decode(audioJson);
      _audioManifest = (am['items'] as List)
          .map((j) => AudioManifestItem.fromJson(j))
          .toList();
      _loaded = true;
    } catch (e) {
      _loaded = false;
    }
  }

  String? getAudioPath(String itemId, String gender) {
    for (final item in _audioManifest) {
      if (item.id == itemId && item.gender == gender) {
        return item.path.replaceFirst('/audio/', 'assets/audio/');
      }
    }
    return null;
  }
}
