class AdventureLevel {
  final int id;
  final String title;
  final List<int> topics;
  final List<String> zones;
  const AdventureLevel(this.id, this.title, this.topics, this.zones);
  bool get isFinal => id == 5;
}

const adventureLevels = [
  AdventureLevel(
    1,
    'Campus & Banking',
    [1, 2, 3],
    ['University Campus', 'Islamic Finance Institution', 'Islamic Bank'],
  ),
  AdventureLevel(
    2,
    'Sources & Investment',
    [4, 5, 6],
    ['Knowledge Garden', 'Hadith Library', 'Investment District'],
  ),
  AdventureLevel(
    3,
    'Shariah Finance',
    [7, 8, 9],
    ['Muamalat Marketplace', 'Takaful Protection Zone', 'Baitul Mal Treasury'],
  ),
  AdventureLevel(
    4,
    'Social Finance',
    [10, 11, 12],
    [
      'Community Finance District',
      'Ar-Rahn Gold Quarter',
      'Currency Exchange City',
    ],
  ),
  AdventureLevel(
    5,
    'Arabic Mastery',
    [13, 14],
    ['The Wordsmith Academy', 'Dictionary Observatory', 'Grand Muamalat Vault'],
  ),
];

const avatarNames = [
  'Student • Adam',
  'Student • Hana',
  'Explorer • Rayyan',
  'Explorer • Maryam',
];

enum QuestionType {
  multipleChoice,
  arabicToMalay,
  malayToArabic,
  matchWord,
  matchPhrase,
  completeSentence,
  wordClass,
  gender,
  number,
  demonstrative,
  relativePronoun,
  pastTense,
  presentTense,
  preposition,
  adverb,
  adjective,
  derivation,
  pattern,
  terminology,
  reading,
}

class KnowledgeQuestion {
  final String id,
      questionArabic,
      questionMalay,
      correctAnswer,
      explanation,
      sourceReference;
  final int topicId, levelId;
  final QuestionType type;
  final List<String> options;
  final Map<String, String> pairs;
  final String difficulty;
  const KnowledgeQuestion({
    required this.id,
    required this.topicId,
    required this.levelId,
    required this.type,
    required this.questionArabic,
    required this.questionMalay,
    required this.options,
    required this.correctAnswer,
    required this.explanation,
    required this.sourceReference,
    this.pairs = const {},
    this.difficulty = 'normal',
  });
  bool get isMatching =>
      type == QuestionType.matchWord || type == QuestionType.matchPhrase;
}
