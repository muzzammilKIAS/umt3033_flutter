import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;
import '../models/unit_model.dart';

class DataService {
  List<UnitModel> _units = [];
  CourseModel? _course;
  List<GlossaryEntry> _glossary = [];
  List<ReferenceEntry> _references = [];
  List<AudioManifestItem> _audioManifest = [];

  List<UnitModel> get units => _units;
  CourseModel? get course => _course;
  List<GlossaryEntry> get glossary => _glossary;
  List<ReferenceEntry> get references => _references;
  List<AudioManifestItem> get audioManifest => _audioManifest;

  bool _loaded = false;
  bool get isLoaded => _loaded;

  Future<void> loadAll() async {
    if (_loaded) return;
    try {
      final unitsJson = await rootBundle.loadString('assets/data/units.json');
      final courseJson = await rootBundle.loadString('assets/data/course.json');
      final glossaryJson = await rootBundle.loadString(
        'assets/data/glossary.json',
      );
      final referencesJson = await rootBundle.loadString(
        'assets/data/references.json',
      );
      final audioJson = await rootBundle.loadString(
        'assets/data/audio-manifest.json',
      );

      final unitsList = json.decode(unitsJson) as List;
      _units = unitsList.map((j) => UnitModel.fromJson(j)).toList()
        ..sort((a, b) => a.id.compareTo(b.id));
      _course = CourseModel.fromJson(json.decode(courseJson));
      _glossary = (json.decode(glossaryJson) as List)
          .map((j) => GlossaryEntry.fromJson(j))
          .toList();
      _references = (json.decode(referencesJson) as List)
          .map((j) => ReferenceEntry.fromJson(j))
          .toList();
      final am = json.decode(audioJson);
      _audioManifest = (am['items'] as List? ?? [])
          .map((j) => AudioManifestItem.fromJson(j))
          .toList();
      _loaded = true;
    } catch (e) {
      _loaded = false;
      rethrow;
    }
  }

  UnitModel? unitById(int id) {
    for (final u in _units) {
      if (u.id == id) return u;
    }
    return null;
  }

  /// Resolves a dialogue/vocab line's bundled audio asset path, if generated.
  /// [gender] is the requested voice ('male' | 'female'); falls back to
  /// whatever gender was actually generated for that item id.
  String? getAudioPath(String itemId, String gender) {
    AudioManifestItem? exact;
    AudioManifestItem? any;
    for (final item in _audioManifest) {
      if (item.id != itemId || item.status != 'generated') continue;
      any ??= item;
      if (item.gender == gender) {
        exact = item;
        break;
      }
    }
    final chosen = exact ?? any;
    if (chosen == null) return null;
    // Remove leading slash only - Flutter's AssetBundle prepends 'assets/' automatically
    return chosen.path.startsWith('/') ? chosen.path.substring(1) : chosen.path;
  }

  List<Map<String, dynamic>> search(String query) {
    final q = _normalizeArabic(query.trim().toLowerCase());
    if (q.isEmpty) return [];
    final results = <Map<String, dynamic>>[];

    for (final u in _units) {
      if (_normalizeArabic(u.titleAr.toLowerCase()).contains(q) ||
          u.titleSubAr.toLowerCase().contains(q)) {
        results.add({
          'type': 'unit',
          'unitId': u.id,
          'titleAr': u.titleAr,
          'subtitle': u.titleSubAr,
        });
      }
      for (final v in u.vocab) {
        if (_normalizeArabic(v.arabic.toLowerCase()).contains(q) ||
            v.meaning.toLowerCase().contains(q) ||
            v.transliteration.toLowerCase().contains(q)) {
          results.add({
            'type': 'vocab',
            'unitId': u.id,
            'titleAr': v.arabic,
            'subtitle': v.meaning,
          });
        }
      }
      for (final d in [...u.dialog, ...u.expandedDialog]) {
        if (_normalizeArabic(d.arabic.toLowerCase()).contains(q) ||
            d.meaning.toLowerCase().contains(q)) {
          results.add({
            'type': 'dialog',
            'unitId': u.id,
            'titleAr': d.arabic,
            'subtitle': d.meaning,
          });
        }
      }
      if (_normalizeArabic(u.readingAr.toLowerCase()).contains(q)) {
        results.add({
          'type': 'reading',
          'unitId': u.id,
          'titleAr': 'النَّصُّ الْقِرَائِيُّ',
          'subtitle': u.titleAr,
        });
      }
    }
    for (final g in _glossary) {
      if (_normalizeArabic(g.termAr.toLowerCase()).contains(q) ||
          g.term.toLowerCase().contains(q) ||
          g.transliteration.toLowerCase().contains(q)) {
        results.add({
          'type': 'glossary',
          'unitId': g.unitId,
          'titleAr': g.termAr,
          'subtitle': g.term,
        });
      }
    }
    return results.take(80).toList();
  }

  static String _normalizeArabic(String s) {
    // Search-index-only normalization: strip harakat/tatweel so e.g. "مرابحة"
    // finds displayed "مُرَابَحَة". Never used for on-screen text.
    return s.replaceAll(RegExp(r'[ً-ٰٟـ]'), '');
  }
}
