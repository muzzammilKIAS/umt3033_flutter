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
