# اللُّغَةُ الْعَرَبِيَّةُ الْأَسَاسِيَّةُ لِلْمُعَامَلَاتِ — UMT3033

Offline-first Flutter app for **Basic Arabic for Muamalat (UMT3033)**, KIAS —
an interactive digital textbook covering all 14 syllabus units: vocabulary,
hiwar (with gender-aware audio), qawaid, reading, Quran/hadith, exercises,
glossary and progress tracking.

## Architecture

```
lib/
  models/    UnitModel, VocabItem, DialogLine, ExerciseBlock, CourseModel,
             GlossaryEntry, ReferenceEntry, AudioManifestItem
  services/  DataService (loads assets/data/*.json), StorageService
             (SharedPreferences-backed progress/settings, ChangeNotifier)
  theme/     AppColors (teal/sage/ivory/champagne palette), AppTheme
             (ThemeData + AppTokens ThemeExtension for light/dark)
  screens/   DashboardScreen, UnitScreen, GlossaryScreen, SearchScreen,
             SettingsScreen
  widgets/   UnitCard, MatchingExercise
assets/
  data/      units.json, course.json, glossary.json, references.json,
             audio-manifest.json, illustrations.json
  images/units/  one hiwar illustration per unit (JPEG, ~100KB each)
  audio/unit-NN/male/  pre-generated Piper TTS audio (male voice)
  fonts/     LotusLinotype (Arabic, harakat-friendly), Amiri
scripts/     Development-time content pipeline (DOCX -> JSON -> audio).
             Not shipped in the app; see "Regenerating course data" below.
docs/        This project's academic-source mapping, content/audio QA
             reports, and the TTS implementation writeup.
```

State management: `provider` (two singletons — `DataService`,
`StorageService` — injected via `MultiProvider` in `main.dart`). No backend,
no login, no analytics, no network calls at runtime.

## Academic source hierarchy

The app's content is derived, in this priority order, from:

1. **Final syllabus / course guide** — KIAS's official Course Guideline (CG),
   which lists the 14-unit topic sequence and grammar scope.
2. **Final edited student module** — `Topik_*_Enriched_Final.docx` (7 files,
   2 units each), the newest approved version.
3. **Answer guide** — `Dalil_Al-Ijabat_UMT3033_Final.docx`, parsed into
   per-unit model answers surfaced behind an explicit reveal toggle in each
   unit's exercises section (never shown by default, never auto-graded —
   see `docs/CONTENT_REVIEW_FLAGS.md`).
4. **Existing app architecture** — preserved and extended, not replaced.

Full source-to-unit mapping: `docs/SYLLABUS_MODULE_MAPPING.md`.
Content QA: `docs/CONTENT_INTEGRATION_REPORT.md`, `docs/CONTENT_REVIEW_FLAGS.md`.

## Setup & run

```bash
flutter pub get
flutter run                 # or: flutter run -d chrome
```

No API keys, accounts, or network access are required to run the app.

## Regenerating course data (development only — not needed to just run the app)

The DOCX → JSON → audio pipeline runs at development time; the app itself
only ever reads the committed JSON/audio under `assets/`.

```bash
pip3 install python-docx piper-tts pillow

python3 scripts/extract_units.py          # DOCX -> assets/data/units_extracted.json
python3 scripts/extract_answer_guide.py   # lecturer answer guide -> answer_guide.json
python3 scripts/build_units_json.py       # -> units.json, glossary.json, references.json
python3 scripts/extract_illustrations.py  # -> assets/images/units/*.jpg + illustrations.json
python3 scripts/generate_hiwar_audio.py   # -> assets/audio/unit-NN/male/*.wav + audio-manifest.json
```

Each script is idempotent and safe to re-run after a module edit; only
changed items are regenerated (pass `--force` to `generate_hiwar_audio.py`
to force a full re-synthesis).

## Offline behaviour

Everything — all 14 units, glossary, search, illustrations, progress, and
male-voice hiwar/vocab/reading audio — works with no network connection
after install. See "Audio / TTS strategy" below for the one feature that
depends on the device's own (still offline) TTS engine.

## Arabic font

**Noto Naskh Arabic** (Google, SIL Open Font License 1.1 — free to bundle
and redistribute; `assets/fonts/noto-naskh-arabic/`, license text in that
same folder). A Naskh text face with excellent harakat rendering, chosen for
body-text legibility over decoration, matching the "premium textbook" goal.

This replaces two problems found in the previously-bundled fonts, fixed in
this pass:
- `LotusLinotype.ttf` was a genuine **proprietary Linotype GmbH font** whose
  own embedded license explicitly forbids copying/distribution — it had been
  bundled into the app anyway, which would have shipped a license violation
  to every install. A note left in the old font folder had explicitly warned
  against this ("Beli lesen dari pemilik asal" / buy a license from the
  original owner) and named Noto Naskh Arabic as the correct free fallback;
  that fallback is what's now actually wired in.
- The bundled "Amiri-Regular.ttf" was not a font file at all — it was a
  saved GitHub HTML error page with a `.ttf` extension.

## Audio / TTS strategy

- **Male hiwar/vocab/reading/hadith/ayah lines**: pre-generated offline with
  **Piper TTS** (`ar_JO-kareem-medium`, MIT-licensed engine, no API key),
  bundled as WAV files under `assets/audio/`.
- **Female lines**: no free/offline/license-clean Arabic female voice exists
  in Piper's public catalogue or on this development machine, so female
  lines are spoken live via the device's own `flutter_tts` engine at
  playback time (still fully offline, still no API key) — never a faked
  voice. Full investigation and reasoning: `docs/TTS_IMPLEMENTATION.md`.
- Playback: `just_audio` for bundled files, speed control (0.75×/1.0×/1.25×)
  persisted per user, Play-All for vocab/hiwar queues, no autoplay, audio
  stops on leaving a screen.

## Testing & QA

```bash
flutter analyze        # 0 issues
flutter test           # 15/15 passing (12 data-integrity + 3 widget smoke tests)
flutter build web --release   # succeeds
flutter build apk --debug     # succeeds (JDK 17 + Android cmdline-tools
                               # installed via Homebrew during setup; see
                               # docs/OVERNIGHT_WORKLOG.md)
```

iOS build was not attempted — this machine's Xcode install is incomplete
(`sudo xcode-select`/App Store steps require interactive/admin access not
available in this environment).

## Design

Teal/sage/mist/ivory palette with a restrained champagne accent — see
`lib/theme/app_colors.dart` for exact tokens and
`docs/OVERNIGHT_WORKLOG.md` for the rationale (replacing an earlier
orange/brown "cocoa" theme).

## Privacy

No login, no analytics, no tracking, no cloud sync, no student-data
collection. All progress is stored locally via `shared_preferences`.
