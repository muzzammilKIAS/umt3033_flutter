class VocabItem {
  final String id;
  final String arabic;
  final String meaning;
  final String type;

  VocabItem({
    required this.id,
    required this.arabic,
    required this.meaning,
    this.type = '',
  });

  factory VocabItem.fromJson(Map<String, dynamic> json) => VocabItem(
        id: json['id'] ?? '',
        arabic: json['arabic'] ?? '',
        meaning: json['meaning'] ?? '',
        type: json['type'] ?? '',
      );
}

class DialogLine {
  final String id;
  final String arabic;
  final String meaning;
  final String speakerLabel;
  final String speakerAr;
  final String gender;

  DialogLine({
    required this.id,
    required this.arabic,
    required this.meaning,
    this.speakerLabel = '',
    this.speakerAr = '',
    this.gender = 'male',
  });

  factory DialogLine.fromJson(Map<String, dynamic> json) => DialogLine(
        id: json['id'] ?? '',
        arabic: json['arabic'] ?? '',
        meaning: json['meaning'] ?? '',
        speakerLabel: json['speakerLabel'] ?? '',
        speakerAr: json['speakerAr'] ?? '',
        gender: json['gender'] ?? 'male',
      );
}

class UnitModel {
  final int id;
  final String code;
  final String titleAr;
  final String title;
  final int pageNumber;
  final String outcomesAr;
  final List<String> outcomes;
  final String introductionAr;
  final String introduction;
  final List<VocabItem> vocab;
  final List<DialogLine> dialog;
  final String readingAr;
  final String readingMs;
  final String hadithAr;
  final String hadithSource;
  final String hadithMaksud;
  final List<String> hadithLessons;
  final String exercisesAr;
  final List<String> exercises;
  final Map<String, dynamic> rules;
  final String summaryAr;
  final String summary;
  final String assessmentAr;
  final List<String> assessmentItems;

  UnitModel({
    required this.id,
    required this.code,
    required this.titleAr,
    required this.title,
    this.pageNumber = 0,
    this.outcomesAr = '',
    this.outcomes = const [],
    this.introductionAr = '',
    this.introduction = '',
    this.vocab = const [],
    this.dialog = const [],
    this.readingAr = '',
    this.readingMs = '',
    this.hadithAr = '',
    this.hadithSource = '',
    this.hadithMaksud = '',
    this.hadithLessons = const [],
    this.exercisesAr = '',
    this.exercises = const [],
    this.rules = const {},
    this.summaryAr = '',
    this.summary = '',
    this.assessmentAr = '',
    this.assessmentItems = const [],
  });

  factory UnitModel.fromJson(Map<String, dynamic> json) => UnitModel(
        id: json['id'] ?? 0,
        code: json['code'] ?? '',
        titleAr: json['titleAr'] ?? '',
        title: json['title'] ?? '',
        pageNumber: json['pageNumber'] ?? 0,
        outcomesAr: json['outcomesAr'] ?? '',
        outcomes: List<String>.from(json['outcomes'] ?? []),
        introductionAr: json['introductionAr'] ?? '',
        introduction: json['introduction'] ?? '',
        vocab: (json['vocab'] as List<dynamic>?)
                ?.map((v) => VocabItem.fromJson(v))
                .toList() ??
            [],
        dialog: (json['dialog'] as List<dynamic>?)
                ?.map((d) => DialogLine.fromJson(d))
                .toList() ??
            [],
        readingAr: json['readingAr'] ?? '',
        readingMs: json['readingMs'] ?? '',
        hadithAr: json['hadithAr'] ?? '',
        hadithSource: json['hadithSource'] ?? '',
        hadithMaksud: json['hadithMaksud'] ?? '',
        hadithLessons: List<String>.from(json['hadithLessons'] ?? []),
        exercisesAr: json['exercisesAr'] ?? '',
        exercises: List<String>.from(json['exercises'] ?? []),
        rules: json['rules'] as Map<String, dynamic>? ?? {},
        summaryAr: json['summaryAr'] ?? '',
        summary: json['summary'] ?? '',
        assessmentAr: json['assessmentAr'] ?? '',
        assessmentItems: List<String>.from(json['assessmentItems'] ?? []),
      );
}

class CourseModel {
  final String institution;
  final String institution2;
  final String courseTitleAr;
  final String courseTitleEn;
  final String courseCode;
  final String authorName;
  final String authorTitle;
  final int totalUnits;
  final String mukadimahAr;

  CourseModel({
    this.institution = '',
    this.institution2 = '',
    this.courseTitleAr = '',
    this.courseTitleEn = '',
    this.courseCode = '',
    this.authorName = '',
    this.authorTitle = '',
    this.totalUnits = 14,
    this.mukadimahAr = '',
  });

  factory CourseModel.fromJson(Map<String, dynamic> json) => CourseModel(
        institution: json['institution'] ?? '',
        institution2: json['institution2'] ?? '',
        courseTitleAr: json['courseTitleAr'] ?? '',
        courseTitleEn: json['courseTitleEn'] ?? '',
        courseCode: json['courseCode'] ?? '',
        authorName: json['authorName'] ?? '',
        authorTitle: json['authorTitle'] ?? '',
        totalUnits: json['totalUnits'] ?? 14,
        mukadimahAr: json['mukadimahAr'] ?? '',
      );
}

class GlossaryEntry {
  final String id;
  final String term;
  final String termAr;
  final String type;
  final int unitId;

  GlossaryEntry({
    required this.id,
    required this.term,
    required this.termAr,
    this.type = '',
    this.unitId = 0,
  });

  factory GlossaryEntry.fromJson(Map<String, dynamic> json) => GlossaryEntry(
        id: json['id'] ?? '',
        term: json['term'] ?? '',
        termAr: json['termAr'] ?? '',
        type: json['type'] ?? '',
        unitId: json['unitId'] ?? 0,
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
