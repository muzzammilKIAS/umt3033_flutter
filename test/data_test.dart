// Data-integrity tests for the course content bundled in assets/data.
// Run with: flutter test
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:umt3033_app/models/unit_model.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late List<UnitModel> units;
  late List<GlossaryEntry> glossary;
  late Map<String, dynamic> audioManifest;

  setUpAll(() async {
    final unitsJson = await rootBundle.loadString('assets/data/units.json');
    units = (json.decode(unitsJson) as List)
        .map((j) => UnitModel.fromJson(j))
        .toList();
    final glossaryJson = await rootBundle.loadString(
      'assets/data/glossary.json',
    );
    glossary = (json.decode(glossaryJson) as List)
        .map((j) => GlossaryEntry.fromJson(j))
        .toList();
    final audioJson = await rootBundle.loadString(
      'assets/data/audio-manifest.json',
    );
    audioManifest = json.decode(audioJson) as Map<String, dynamic>;
  });

  group('units.json', () {
    test('exactly 14 units are present', () {
      expect(units.length, 14);
    });

    test('unit ids are 1..14, unique, and in order', () {
      final ids = units.map((u) => u.id).toList();
      expect(ids, List.generate(14, (i) => i + 1));
      expect(ids.toSet().length, 14);
    });

    test('every unit has a non-empty Arabic title', () {
      for (final u in units) {
        expect(
          u.titleAr.trim(),
          isNotEmpty,
          reason: 'unit ${u.id} missing titleAr',
        );
      }
    });

    test('every unit has learning outcomes', () {
      for (final u in units) {
        expect(u.outcomes, isNotEmpty, reason: 'unit ${u.id} missing outcomes');
      }
    });

    test('every unit has vocabulary and an original hiwar', () {
      for (final u in units) {
        expect(u.vocab, isNotEmpty, reason: 'unit ${u.id} missing vocab');
        expect(u.dialog, isNotEmpty, reason: 'unit ${u.id} missing dialog');
      }
    });

    test(
      'every unit has lecturer-guide model answers available (reveal-only)',
      () {
        for (final u in units) {
          expect(
            u.modelAnswersAr,
            isNotEmpty,
            reason: 'unit ${u.id} missing modelAnswersAr',
          );
        }
      },
    );

    test(
      'dialogue speaker gender is always male or female (never guessed odd/even)',
      () {
        for (final u in units) {
          for (final d in [...u.dialog, ...u.expandedDialog]) {
            expect(
              ['male', 'female'],
              contains(d.gender),
              reason: '${d.id} has gender=${d.gender}',
            );
          }
        }
      },
    );

    test('vocab/dialog ids are unique within each unit', () {
      for (final u in units) {
        final ids = [
          ...u.vocab.map((v) => v.id),
          ...u.dialog.map((d) => d.id),
          ...u.expandedDialog.map((d) => d.id),
        ];
        expect(
          ids.toSet().length,
          ids.length,
          reason: 'duplicate ids in unit ${u.id}',
        );
      }
    });

    test(
      'illustration path is set for every unit and looks like a bundled asset',
      () {
        for (final u in units) {
          expect(
            u.illustration,
            isNotNull,
            reason: 'unit ${u.id} missing illustration',
          );
          expect(u.illustration, startsWith('assets/images/units/'));
        }
      },
    );
  });

  group('glossary.json', () {
    test('glossary loads and every entry has Arabic + meaning', () {
      expect(glossary, isNotEmpty);
      for (final g in glossary) {
        expect(g.termAr.trim(), isNotEmpty);
        expect(g.term.trim(), isNotEmpty);
      }
    });
  });

  group('audio-manifest.json', () {
    test(
      'every generated item has a real file and an explicit supported voice',
      () {
        final items = audioManifest['items'] as List;
        for (final item in items) {
          if (item['status'] == 'generated') {
            expect(item['path'], isNotEmpty);
            expect(['male', 'female'], contains(item['gender']));
            expect(File('assets/${item['path']}').existsSync(), isTrue);
          }
        }
      },
    );

    test(
      'female dialogue lines use female recordings or explicit TTS fallback',
      () {
        final items = audioManifest['items'] as List;
        final femaleItems = items.where((i) => i['gender'] == 'female');
        expect(femaleItems, isNotEmpty);
        for (final item in femaleItems) {
          expect(['generated', 'fallback-tts'], contains(item['status']));
          if (item['status'] == 'generated') {
            expect(item['path'], contains('/female/'));
            expect(File('assets/${item['path']}').existsSync(), isTrue);
          } else {
            expect(item['path'], isEmpty);
          }
        }
      },
    );
  });
}
