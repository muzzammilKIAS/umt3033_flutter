import 'package:flutter_test/flutter_test.dart';
import 'package:umt3033_app/utils/arabic_text.dart';

void main() {
  group('isArabic', () {
    test('identifies Arabic vs Latin text correctly', () {
      expect(isArabic('الْقَوَاعِدُ'), isTrue);
      expect(isArabic('مَبْلَغٌ كَبِيرٌ'), isTrue);
      expect(isArabic('Kaedah Bahasa'), isFalse);
      expect(isArabic('Mausuf ialah kata nama yang diterangkan'), isFalse);
    });
  });

  group('prepareArabicForTts', () {
    test('expands SAW ligature ﷺ to full phrase', () {
      final input = 'قَالَ رَسُولُ اللَّهِ ﷺ';
      final output = prepareArabicForTts(input);
      expect(output, contains('صَلَّى ٱللَّهُ عَلَيْهِ وَسَلَّمَ'));
      expect(output, isNot(contains('ﷺ')));
    });

    test('ensures Allah has proper tashdid and wasl in rasulullah', () {
      final input = 'قَالَ رَسُولُ اللهِ';
      final output = prepareArabicForTts(input);
      expect(output, contains('رَسُولُ ٱللَّهِ'));
    });

    test('fixes salla Allahu and qala Allahu taala', () {
      expect(prepareArabicForTts('صَلَّى اللهُ'), contains('صَلَّى ٱللَّهُ'));
      expect(prepareArabicForTts('قَالَ الله تَعَالَى'), contains('قَالَ ٱللَّهُ'));
    });

    test('fixes Unit 4 ahalla Allahu al-bay and harrama al-riba', () {
      final input = 'لَا. أَحَلَّ اللَّهُ الْبَيْعَ وَحَرَّمَ الرِّبَا.';
      final output = prepareArabicForTts(input);
      expect(output, contains('وَأَحَلَّ ٱللَّهُ ٱلْبَيْعَ'));
      expect(output, contains('وَحَرَّمَ ٱلرِّبَا'));
    });

    test('cleans up raw quotation marks and colons around SAW', () {
      final input = 'قَالَ رَسُولُ اللهِ ﷺ: "الْحَدِيثُ"';
      final output = prepareArabicForTts(input);
      expect(output, contains('رَسُولُ ٱللَّهِ'));
      expect(output, contains('صَلَّى ٱللَّهُ عَلَيْهِ وَسَلَّمَ'));
      expect(output, isNot(contains('"')));
    });
  });
}

