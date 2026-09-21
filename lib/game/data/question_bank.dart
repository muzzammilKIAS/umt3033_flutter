import '../../services/data_service.dart';
import '../models/curriculum.dart';

/// Only exact, source-backed vocabulary pairs are automatically graded.
/// Grammar/verse/hadith questions require a reviewed per-question answer key.
class QuestionBank {
  final DataService data;
  QuestionBank(this.data);

  List<KnowledgeQuestion> forLevel(int levelId) {
    final level = adventureLevels[levelId - 1];
    final result = <KnowledgeQuestion>[];
    for (final topic in level.topics) {
      for (var gate = 0; gate < 3; gate++) {
        result.add(_vocabulary(topic, levelId, gate));
      }
    }
    if (level.isFinal) {
      // A vault round covers every course topic, including 13 and 14.
      for (var topic = 1; topic <= 14; topic++) {
        result.add(_vocabulary(topic, levelId, 3));
      }
    }
    return result;
  }

  KnowledgeQuestion _vocabulary(int topic, int level, int gate) {
    final vocab = data.unitById(topic)!.vocab;
    final selected = vocab[gate % vocab.length];
    final reverse = gate == 1;
    final matching = gate == 2;
    final options = <String>{reverse ? selected.arabic : selected.meaning};
    for (final item in vocab.skip(gate + 1).followedBy(vocab)) {
      options.add(reverse ? item.arabic : item.meaning);
      if (options.length == 4) break;
    }
    final ordered = options.toList();
    // Stable permutation: identical questions for every device in a race.
    final rotate = (topic + gate) % ordered.length;
    final pairs = {for (final v in vocab.skip(2).take(3)) v.arabic: v.meaning};
    return KnowledgeQuestion(
      id: 'T${topic}_G$gate',
      topicId: topic,
      levelId: level,
      type: matching
          ? QuestionType.matchWord
          : reverse
          ? QuestionType.malayToArabic
          : QuestionType.arabicToMalay,
      questionArabic: reverse ? '' : selected.arabic,
      questionMalay: matching
          ? 'Padankan perkataan dengan maknanya.'
          : reverse
          ? 'Pilih perkataan Arab: ${selected.meaning}'
          : 'Pilih makna yang sepadan.',
      options: [...ordered.skip(rotate), ...ordered.take(rotate)],
      correctAnswer: reverse ? selected.arabic : selected.meaning,
      pairs: matching ? pairs : const {},
      explanation: matching
          ? pairs.entries.map((e) => '${e.key} — ${e.value}').join('\n')
          : '${selected.arabic} — ${selected.meaning}',
      sourceReference:
          'assets/data/units.json • Unit $topic • ${matching ? vocab.skip(2).take(3).map((v) => v.id).join(', ') : selected.id}',
    );
  }
}
