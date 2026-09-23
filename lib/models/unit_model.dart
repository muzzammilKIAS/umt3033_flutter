/// Data models for a UMT3033 unit, deserialized from assets/data/units.json.
/// The JSON is produced at development time by scripts/extract_units.py from
/// the FINAL edited module DOCX -- see docs/CONTENT_INTEGRATION_REPORT.md.
library;

class VocabItem {
  final String id;
  final String arabic;
  final String transliteration;
  final String meaning;

  VocabItem({
    required this.id,
    required this.arabic,
    this.transliteration = '',
    required this.meaning,
  });

  factory VocabItem.fromJson(Map<String, dynamic> json) => VocabItem(
    id: json['id'] ?? '',
    arabic: json['arabic'] ?? '',
    transliteration: json['transliteration'] ?? '',
    meaning: json['meaning'] ?? '',
  );
}

class DialogLine {
  final String id;
  final String arabic;
  final String meaning;
  final String speakerAr;
  final String speakerMs;
  final String gender; // 'male' | 'female' | 'unknown'

  DialogLine({
    required this.id,
    required this.arabic,
    required this.meaning,
    this.speakerAr = '',
    this.speakerMs = '',
    this.gender = 'unknown',
  });

  factory DialogLine.fromJson(Map<String, dynamic> json) => DialogLine(
    id: json['id'] ?? '',
    arabic: json['arabic'] ?? '',
    meaning: json['meaning'] ?? '',
    speakerAr: json['speakerAr'] ?? '',
    speakerMs: json['speakerMs'] ?? '',
    gender: json['gender'] ?? 'unknown',
  );

  bool get isMale => gender == 'male';
}

class ExpressionItem {
  final String arabic;
  final String meaning;

  ExpressionItem({required this.arabic, required this.meaning});

  factory ExpressionItem.fromJson(Map<String, dynamic> json) => ExpressionItem(
    arabic: json['arabic'] ?? '',
    meaning: json['meaning'] ?? '',
  );
}

/// type: 'matching' | 'classification' | 'fill' | 'comprehension' | 'open'
class ExerciseBlock {
  final String id;
  final String titleAr;
  final String type;
  final String promptAr;
  final String contextHeading;

  ExerciseBlock({
    required this.id,
    required this.titleAr,
    required this.type,
    required this.promptAr,
    this.contextHeading = '',
  });

  factory ExerciseBlock.fromJson(Map<String, dynamic> json) => ExerciseBlock(
    id: json['id'] ?? '',
    titleAr: json['titleAr'] ?? '',
    type: json['type'] ?? 'open',
    promptAr: json['promptAr'] ?? '',
    contextHeading: json['contextHeading'] ?? '',
  );
}

class UnitModel {
  final int id;
  final String code;
  final String titleAr;
  final String titleSubAr;
  final String learningContextAr;
  final String outcomesAr;
  final List<String> outcomes;
  final List<VocabItem> vocab;
  final String dialogTitleAr;
  final List<DialogLine> dialog;
  final List<DialogLine> expandedDialog;
  final String pairPracticeSimpleAr;
  final List<ExpressionItem> importantExpressions;
  final List<Map<String, dynamic>> qawaid;
  final String readingAr;
  final String ayahAr;
  final String ayahSource;
  final String ayahMaksud;
  final String ayahVocab;
  final String ayahReflection;
  final String hadithAr;
  final String hadithSource;
  final String hadithMaksud;
  final String hadithVocab;
  final List<String> hadithLessons;
  final String dictUsageAr;
  final List<Map<String, dynamic>> dictExamples;
  final String pairPracticeRoleA;
  final String pairPracticeRoleB;
  final String pairPracticeConditionsAr;
  final List<ExerciseBlock> exercises;

  /// Lecturer answer-guide model answers for this unit's exercises, in
  /// document order. Grouped per-unit rather than bound to one specific
  /// exercise (the source guide has no reliable per-question anchor to bind
  /// to; see docs/CONTENT_REVIEW_FLAGS.md). Never shown by default -- only
  /// behind an explicit "reveal" action in the UI.
  final List<String> modelAnswersAr;
  final String summaryAr;
  final List<String> assessmentItems;
  final String? illustration;
  final String? video;
  final List<String> reviewFlags;

  UnitModel({
    required this.id,
    required this.code,
    required this.titleAr,
    this.titleSubAr = '',
    this.learningContextAr = '',
    this.outcomesAr = '',
    this.outcomes = const [],
    this.vocab = const [],
    this.dialogTitleAr = '',
    this.dialog = const [],
    this.expandedDialog = const [],
    this.pairPracticeSimpleAr = '',
    this.importantExpressions = const [],
    this.qawaid = const [],
    this.readingAr = '',
    this.ayahAr = '',
    this.ayahSource = '',
    this.ayahMaksud = '',
    this.ayahVocab = '',
    this.ayahReflection = '',
    this.hadithAr = '',
    this.hadithSource = '',
    this.hadithMaksud = '',
    this.hadithVocab = '',
    this.hadithLessons = const [],
    this.dictUsageAr = '',
    this.dictExamples = const [],
    this.pairPracticeRoleA = '',
    this.pairPracticeRoleB = '',
    this.pairPracticeConditionsAr = '',
    this.exercises = const [],
    this.modelAnswersAr = const [],
    this.summaryAr = '',
    this.assessmentItems = const [],
    this.illustration,
    this.video,
    this.reviewFlags = const [],
  });

  /// Matches the uNN- id prefix used throughout assets/data/audio-manifest.json.
  String get audioCode => 'u${id.toString().padLeft(2, '0')}';

  bool get hasAyah => ayahAr.isNotEmpty;
  bool get hasHadith => hadithAr.isNotEmpty;
  bool get hasReading => readingAr.isNotEmpty;
  bool get hasExercises => exercises.isNotEmpty;
  bool get hasQawaid => qawaid.isNotEmpty;

  factory UnitModel.fromJson(Map<String, dynamic> json) => UnitModel(
    id: json['id'] ?? 0,
    code: json['code'] ?? '',
    titleAr: json['titleAr'] ?? '',
    titleSubAr: json['titleSubAr'] ?? '',
    learningContextAr: json['learningContextAr'] ?? '',
    outcomesAr: json['outcomesAr'] ?? '',
    outcomes: List<String>.from(json['outcomes'] ?? []),
    vocab: (json['vocab'] as List<dynamic>? ?? [])
        .map((v) => VocabItem.fromJson(v))
        .toList(),
    dialogTitleAr: json['dialogTitleAr'] ?? '',
    dialog: (json['dialog'] as List<dynamic>? ?? [])
        .map((d) => DialogLine.fromJson(d))
        .toList(),
    expandedDialog: (json['expandedDialog'] as List<dynamic>? ?? [])
        .map((d) => DialogLine.fromJson(d))
        .toList(),
    pairPracticeSimpleAr: json['pairPracticeSimpleAr'] ?? '',
    importantExpressions: (json['importantExpressions'] as List<dynamic>? ?? [])
        .map((e) => ExpressionItem.fromJson(e))
        .toList(),
    qawaid: List<Map<String, dynamic>>.from(json['qawaid'] ?? []),
    readingAr: json['readingAr'] ?? '',
    ayahAr: json['ayahAr'] ?? '',
    ayahSource: json['ayahSource'] ?? '',
    ayahMaksud: json['ayahMaksud'] ?? '',
    ayahVocab: json['ayahVocab'] ?? '',
    ayahReflection: json['ayahReflection'] ?? '',
    hadithAr: json['hadithAr'] ?? '',
    hadithSource: json['hadithSource'] ?? '',
    hadithMaksud: json['hadithMaksud'] ?? '',
    hadithVocab: json['hadithVocab'] ?? '',
    hadithLessons: List<String>.from(json['hadithLessons'] ?? []),
    dictUsageAr: json['dictUsageAr'] ?? '',
    dictExamples: List<Map<String, dynamic>>.from(json['dictExamples'] ?? []),
    pairPracticeRoleA: json['pairPracticeRoleA'] ?? '',
    pairPracticeRoleB: json['pairPracticeRoleB'] ?? '',
    pairPracticeConditionsAr: json['pairPracticeConditionsAr'] ?? '',
    exercises: (json['exercises'] as List<dynamic>? ?? [])
        .map((e) => ExerciseBlock.fromJson(e))
        .toList(),
    modelAnswersAr: List<String>.from(json['modelAnswersAr'] ?? []),
    summaryAr: json['summaryAr'] ?? '',
    assessmentItems: List<String>.from(json['assessmentItems'] ?? []),
    illustration: json['illustration'] as String?,
    video: json['video'] as String?,
    reviewFlags: List<String>.from(json['reviewFlags'] ?? []),
  );
}

class CourseModel {
  final String institution;
  final String institutionAr;
  final String institution2;
  final String institution2Ar;
  final String courseTitleAr;
  final String courseTitleEn;
  final String courseCode;
  final String authorName;
  final String authorAr;
  final String authorTitle;
  final int totalUnits;
  final String mukadimahAr;

  CourseModel({
    this.institution = '',
    this.institutionAr = '',
    this.institution2 = '',
    this.institution2Ar = '',
    this.courseTitleAr = '',
    this.courseTitleEn = '',
    this.courseCode = '',
    this.authorName = '',
    this.authorAr = '',
    this.authorTitle = '',
    this.totalUnits = 14,
    this.mukadimahAr = '',
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
    institution: json['institution'] ?? '',
    institutionAr: json['institutionAr'] ?? '',
    institution2: json['institution2'] ?? '',
    institution2Ar: json['institution2Ar'] ?? '',
    courseTitleAr: json['courseTitleAr'] ?? '',
    courseTitleEn: json['courseTitleEn'] ?? '',
    courseCode: json['courseCode'] ?? '',
    authorName: json['authorName'] ?? '',
    authorAr: json['authorAr'] ?? '',
    authorTitle: json['authorTitle'] ?? '',
    totalUnits: json['totalUnits'] ?? 14,
    mukadimahAr: json['mukadimahAr'] ?? '',
  );
}

class GlossaryEntry {
  final String id;
  final String termAr;
  final String transliteration;
  final String term;
  final int unitId;

  GlossaryEntry({
    required this.id,
    required this.termAr,
    this.transliteration = '',
    required this.term,
    this.unitId = 0,
  });

  factory GlossaryEntry.fromJson(Map<String, dynamic> json) => GlossaryEntry(
    id: json['id'] ?? '',
    termAr: json['termAr'] ?? '',
    transliteration: json['transliteration'] ?? '',
    term: json['term'] ?? '',
    unitId: json['unitId'] ?? 0,
  );
}

class ReferenceEntry {
  final String kind; // 'ayah' | 'hadith'
  final String sourceAr;
  final int unitId;
  final String textAr;

  ReferenceEntry({
    required this.kind,
    required this.sourceAr,
    required this.unitId,
    this.textAr = '',
  });

  factory ReferenceEntry.fromJson(Map<String, dynamic> json) => ReferenceEntry(
    kind: json['kind'] ?? '',
    sourceAr: json['sourceAr'] ?? '',
    unitId: json['unitId'] ?? 0,
    textAr: json['textAr'] ?? '',
  );
}

class AudioManifestItem {
  final String id;
  final int unitId;
  final String section;
  final String arabic;
  final String gender;
  final String path;
  final String status;

  AudioManifestItem({
    required this.id,
    this.unitId = 0,
    this.section = '',
    this.arabic = '',
    this.gender = 'male',
    this.path = '',
    this.status = '',
  });

  factory AudioManifestItem.fromJson(Map<String, dynamic> json) =>
      AudioManifestItem(
        id: json['id'] ?? '',
        unitId: json['unitId'] ?? 0,
        section: json['section'] ?? '',
        arabic: json['arabic'] ?? '',
        gender: json['gender'] ?? 'male',
        path: json['path'] ?? '',
        status: json['status'] ?? '',
      );
}
