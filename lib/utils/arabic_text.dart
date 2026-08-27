/// Shared helpers for Arabic text display: stripping diacritics (harakat/
/// tashkeel) and splitting run-on strings that pack multiple logical lines
/// (numbered sub-questions, an appended Malay translation) into one.
library;

final _harakatPattern = RegExp('[ً-ْٰ]');

/// Removes Arabic diacritics (fathatan..sukun, U+064B-U+0652, plus the
/// superscript alef U+0670). Non-Arabic characters are left untouched, so
/// it's safe to call on any string regardless of language.
String stripHarakat(String text) => text.replaceAll(_harakatPattern, '');

const _westernDigits = '0123456789';
const _arabicIndicDigits = '٠١٢٣٤٥٦٧٨٩';

/// Converts Western (0-9) digits to Arabic-Indic numerals (٠-٩).
String toArabicDigits(String input) => input
    .split('')
    .map((c) {
      final i = _westernDigits.indexOf(c);
      return i == -1 ? c : _arabicIndicDigits[i];
    })
    .join();

/// Checks if text is predominantly Arabic script.
bool isArabic(String text) {
  final arabicChars = RegExp(
    r'[\u0600-\u06FF\u0750-\u077F\u08A0-\u08FF\uFB50-\uFDFF\uFE70-\uFEFF]',
  );
  final latinChars = RegExp(r'[a-zA-Z]');
  final arabicCount = arabicChars.allMatches(text).length;
  final latinCount = latinChars.allMatches(text).length;
  if (arabicCount == 0 && latinCount == 0) return true;
  return arabicCount >= latinCount;
}

/// Prepares Arabic text for Text-To-Speech (TTS) engine synthesis:
/// 1. Expands the single-character Sallallahu Alayhi Wasallam ligature (ﷺ / U+FDFA)
///    into the full vocalized phrase "صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ" so TTS engines
///    pronounce it smoothly rather than glitching or stopping.
/// 2. Ensures the Divine Name (الله) carries standard Alif + Tashdid ("اللَّهُ" / "اللَّهِ" / "اللَّهَ")
///    without non-standard Quranic symbols (like U+0671 ٱ) that disrupt Neural TTS engines.
/// 3. Normalizes punctuation around quotes and colons to prevent awkward pauses.
String prepareArabicForTts(String text) {
  if (text.isEmpty) return text;
  var s = text;

  // Remove any non-standard Quranic Wasla character U+0671 -> standard Alif
  s = s.replaceAll('\u0671', 'ا');

  // 1. Expand ligature ﷺ (U+FDFA) to full vocalized phrase
  s = s.replaceAll('\uFDFA', ' صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ ');
  s = s.replaceAll('ﷺ', ' صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ ');

  // 2. Standard Tashkeel for Lafzul Jalalah:
  s = s.replaceAll(RegExp(r'وَ?أَحَلَّ\s+اللهُ?\s+الْبَيْعَ'), 'وَأَحَلَّ اللَّهُ الْبَيْعَ');
  s = s.replaceAll(RegExp(r'وَحَرَّمَ\s+الرِّبَا'), 'وَحَرَّمَ الرِّبَا');
  s = s.replaceAll(RegExp(r'أَحَلَّ\s+اللهُ?'), 'أَحَلَّ اللَّهُ');
  s = s.replaceAll(RegExp(r'رَسُولُ\s+اللهِ?'), 'رَسُولُ اللَّهِ');
  s = s.replaceAll(RegExp(r'رَسُولِ\s+اللهِ?'), 'رَسُولِ اللَّهِ');
  s = s.replaceAll(RegExp(r'رَسُولَ\s+اللهِ?'), 'رَسُولَ اللَّهِ');
  s = s.replaceAll(RegExp(r'نَبِيُّ\s+اللهِ?'), 'نَبِيُّ اللَّهِ');
  s = s.replaceAll(RegExp(r'نَبِيِّ\s+اللهِ?'), 'نَبِيِّ اللَّهِ');
  s = s.replaceAll(RegExp(r'نَبِيَّ\s+اللهِ?'), 'نَبِيَّ اللَّهِ');
  s = s.replaceAll(RegExp(r'عَبْدُ\s+اللهِ?'), 'عَبْدُ اللَّهِ');
  s = s.replaceAll(RegExp(r'عَبْدِ\s+اللهِ?'), 'عَبْدِ اللَّهِ');
  s = s.replaceAll(RegExp(r'عَبْدَ\s+اللهِ?'), 'عَبْدَ اللَّهِ');
  s = s.replaceAll(RegExp(r'صَلَّى\s+اللهُ?'), 'صَلَّى اللَّهُ');
  s = s.replaceAll(RegExp(r'قَالَ\s+اللهُ?\s*تَعَالَى:?'), 'قَالَ اللَّهُ تَعَالَى:');
  s = s.replaceAll(RegExp(r'قَالَ\s+اللهُ?'), 'قَالَ اللَّهُ');
  s = s.replaceAll(RegExp(r'حَرَّمَهُ\s+اللهُ?'), 'حَرَّمَهُ اللَّهُ');
  s = s.replaceAll(RegExp(r'بَارَكَ\s+اللهُ?'), 'بَارَكَ اللَّهُ');
  s = s.replaceAll(RegExp(r'وَفَّقَكَ\s+اللهُ?'), 'وَفَّقَكَ اللَّهُ');
  s = s.replaceAll(RegExp(r'تَقَبَّلَ\s+اللهُ?'), 'تَقَبَّلَ اللَّهُ');
  s = s.replaceAll(RegExp(r'سَهَّلَ\s+اللهُ?'), 'سَهَّلَ اللَّهُ');
  s = s.replaceAll(RegExp(r'يَسَّرَ\s+اللهُ?'), 'يَسَّرَ اللَّهُ');
  s = s.replaceAll(RegExp(r'رَحِمَ\s+اللهُ?'), 'رَحِمَ اللَّهُ');
  s = s.replaceAll(RegExp(r'إِنَّ\s+اللهَ?'), 'إِنَّ اللَّهَ');
  s = s.replaceAll(RegExp(r'أَنَّ\s+اللهَ?'), 'أَنَّ اللَّهَ');

  // 3. Standalone / sentence-initial instances of Allah
  s = s.replaceAll(RegExp(r'\bاللهِ\b'), 'اللَّهِ');
  s = s.replaceAll(RegExp(r'\bاللهُ\b'), 'اللَّهُ');
  s = s.replaceAll(RegExp(r'\bاللهَ\b'), 'اللَّهَ');
  s = s.replaceAll(RegExp(r'\bالله\b'), 'اللَّهُ');

  // 4. Clean up punctuation that causes unnatural glottal stops / pauses
  s = s.replaceAll(RegExp(r':\s*["«“”]'), ': ');
  s = s.replaceAll(RegExp(r'["“”«»]'), ' ');
  s = s.replaceAll(RegExp(r'\s+'), ' ').trim();

  return s;
}

