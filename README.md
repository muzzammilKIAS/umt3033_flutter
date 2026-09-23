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
  fonts/     Amiri (Arabic), Inter (Latin) -- see "Fonts" below
scripts/     Development-time content pipeline (DOCX -> JSON -> audio).
             Not shipped in the app; see "Regenerating course data" below.
docs/        This project's academic-source mapping, content/audio QA
             reports, and the TTS implementation writeup.
```

State management: `provider` (two singletons — `DataService`,
`StorageService` — injected via `MultiProvider` in `main.dart`). The original
course remains account-free. The optional Adventure module adds Firebase
anonymous classroom sessions when configured; solo play needs no backend.

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

## Fonts

**Arabic (all lesson content — vocab, hiwar, expanded hiwar, reading texts,
qawaid, exercises, glossary, unit titles): Amiri.**
- Source: official release `Amiri-1.003.zip` from
  `github.com/aliftype/amiri` (the font's own upstream repo).
- License: SIL Open Font License 1.1 — free to bundle and redistribute.
  License text bundled at `assets/fonts/amiri/OFL.txt`.
- Files bundled: `assets/fonts/amiri/Amiri-Regular.ttf`,
  `assets/fonts/amiri/Amiri-Bold.ttf`.
- Why: a classical Naskh book face (originally drawn for Quranic
  typesetting) with excellent, purpose-built harakat/shaddah/tanwin
  rendering — closer to the traditional, elegant look the course wanted
  than a more modern-leaning face, while being fully redistributable.

**Malay / English / transliteration / UI / navigation: Inter.**
- Source: Google Fonts' upstream repo (`github.com/google/fonts`,
  `ofl/inter/`), variable font (weight 100–900 in one file).
- License: SIL Open Font License 1.1. License text bundled at
  `assets/fonts/inter/OFL.txt`.
- Files bundled: `assets/fonts/inter/Inter-VariableFont.ttf`. Set as the
  app's default `fontFamily` in `lib/theme/app_theme.dart`; every Arabic
  text widget explicitly overrides to `fontFamily: 'Amiri'` instead.

Two fonts were rejected before landing on the above, both discovered while
auditing the previously-bundled files:
- `LotusLinotype.ttf` was a genuine **proprietary Linotype GmbH font** whose
  own embedded license explicitly forbids copying/distribution — it had been
  bundled into the app anyway, which would have shipped a license violation
  to every install.
- The bundled "Amiri-Regular.ttf" *at that time* was not a font file at
  all — it was a saved GitHub HTML error page with a `.ttf` extension. The
  real Amiri now bundled above was fetched fresh from the upstream release.

Noto Naskh Arabic was used as an intermediate replacement for one revision
before this one; Amiri was chosen over it on request for a more classical,
book-like appearance. If Amiri or Inter ever shows a rendering problem with
fully-vocalized text, the documented fallback path is Scheherazade New
(SIL OFL) for Arabic — not a silent revert to Noto Naskh Arabic.

### Typography scale

Per-role Arabic sizes (logical px), tuned for phone-first reading:

| Role | Size | Line height |
|---|---|---|
| Arabic body (context notes, qawaid notes, summaries) | 20 | 1.7–1.9 |
| Arabic hiwar (dialogue lines) | 22 | 1.9 |
| Arabic reading text (النص القرائي) | 22 | 1.9 |
| Arabic headings (unit titles, course title, glossary header) | 24–32 | — |
| Ayah / hadith quotes | 24 | 1.9 |
| Malay / English translation | 12–17 | 1.5–1.8 |

Module/unit title headings use `FittedBox` + `maxLines: 1` so they scale to
fit on one line rather than wrapping, while staying as large as the
available width allows; hiwar, instructions and vocab sections keep normal
multi-line wrapping.

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


## Arabic Muamalat Adventure

Open the **Arabic Muamalat Adventure** card on the existing dashboard, or visit
`#/game`. Five original platform worlds cover all fourteen topics using exact
vocabulary from the existing module. Solo play saves checkpoints, best results,
stars and topic mastery separately from course progress.

- Desktop: A/D or arrows, Space to jump. Phone: hold left/right and tap jump.
- Solo: choose an avatar and any of the five worlds. Cleared gates are saved.
- Classroom: Host → select world → create → share QR/link → Start. Projector
  lanes show every participant; host controls include pause/resume, lock, remove,
  end, restart, next world, fullscreen, analytics and CSV.
- **Without a configured game server, classroom mode is a labelled same-browser
  preview. Scanning that QR on another phone does not provide multiplayer.**
- Live deployment is pending game server deployment and physical-device QA.

See [implementation/audit](docs/GAME_IMPLEMENTATION_PLAN.md),
[architecture](docs/GAME_ARCHITECTURE.md), [game server setup](docs/GAME_SERVER_SETUP.md),
[QA and outstanding checks](docs/GAME_QA_CHECKLIST.md),
[academic review requirements](docs/GAME_CONTENT_REVIEW.md), and
[original artwork](docs/GAME_ASSETS.md).

Validation:
```sh
flutter analyze
flutter test
flutter build web --release --base-href=/umt3033_flutter/
cd tools/game_qa
npm ci
npm run rules   # Java 21+, local demo Firebase emulator only
npm run browser # Chrome; serve build/web at localhost:8765/umt3033_flutter/
```
The existing JavaScript web build is used. The pre-existing flutter_tts package
currently reports Wasm dry-run compatibility warnings; the release JS build passes.
