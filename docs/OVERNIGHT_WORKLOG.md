# Overnight Work Log — UMT3033 Full Module Integration & Redesign

Autonomous session, no intermediate approvals. Summary of major milestones
(trivial edits omitted — see git log for full history).

## 1. Audit & checkpoint
- Inspected existing app: Provider-based architecture, Material 3, only
  Unit 1 populated (units 2–14 were `[PERLU SEMAKAN PENSYARAH]` placeholders),
  orange/brown "cocoa" theme, 42 pre-generated audio files for Unit 1 only
  (one of which turned out to be a faked female voice — see §6).
- No git repository existed; initialized one and committed a full checkpoint
  before any changes, per the preserve-existing-work requirement.

## 2. Source discovery
- Located the final syllabus (CG UMT3033), the final edited module (7
  `Topik_*_Enriched_Final.docx` files + image-bearing siblings), and the
  final answer guide, across several near-duplicate `KIAS/UMT3033...` folders
  on the user's Desktop. Verified the CG's 14-topic table maps 1:1, in
  order, to the module's 14 units (`docs/SYLLABUS_MODULE_MAPPING.md`).

## 3. DOCX → JSON extraction pipeline (`scripts/extract_units.py`)
The single largest and highest-risk piece of work: a from-scratch parser
that walks each DOCX in true document order (tables + paragraphs
interleaved) and reconstructs each unit's actual structure without
paraphrasing anything. Iteratively debugged against real content, fixing:
- Heading misclassification caused by inconsistent harakat/diacritic
  ordering between otherwise-identical Arabic words in the source (solved
  with a harakat-stripped "bare" comparison used throughout).
- python-docx repeating merged header cells once per spanned grid column
  (de-duplicated by tracking `<w:tc>` element identity).
- Ordinal-number mismatches (e.g. "Unit 12" matching as "Unit 2") — fixed by
  matching longest ordinal pattern first, on harakat-stripped text.
- Whitespace-flattened table cells losing the newlines needed to separate a
  hadith/ayah's Arabic text from its source citation and Malay translation
  — replaced with content-aware marker splitting (handles both citation
  orders the module actually uses: source-before-translation and
  source-after-translation, with either an Arabic or a Latin-script
  citation).
- Self-assessment checklists using two different authored table shapes
  across units (inline "☐ item" text vs. a proper 2-column grid with
  variable column order) — handled generically.
- Unit titles mixing course name / ordinal label / real title / category
  subtitle in inconsistent order between the file covering units 1–2 and
  the six files covering units 3–14.

Result: all 14 units extract cleanly, zero review flags
(`docs/CONTENT_REVIEW_FLAGS.md`), verified against direct DOCX inspection at
every step (never trusted blindly).

## 4. Illustrations
- `scripts/extract_illustrations.py` maps each unit's one embedded hiwar
  image (from the `_With_Images_Final.docx` files) by document-order
  position relative to the same unit-title boundaries used for text.
- Re-encoded PNG → JPEG at a capped 1200px edge (23.2MB → 1.5MB total) for a
  reasonable app size, no visible quality loss.

## 5. Data models, services, theme
- Rewrote `UnitModel` and friends for the much richer schema (learning
  context, expanded hiwar, pair practice, qawaid, ayah+hadith with
  source/translation, exercises with type, dict usage/examples for Unit 14,
  self-assessment) while keeping `DataService`/`StorageService`'s public
  shape close to the original for continuity.
- Replaced the orange/brown/cocoa palette entirely with the specified deep
  teal / sage / mist / ivory system plus a restrained champagne accent, via
  a `ThemeExtension` (`AppTokens`) so no screen hard-codes a
  brightness-specific color literal. Light, dark and system theme modes.

## 6. Audio
- Investigated local TTS options exhaustively (macOS system voices, Piper's
  full public catalogue, other local tools): exactly one free/offline
  MSA-capable Arabic voice exists anywhere in reach — Piper's single male
  "kareem" model. No free female Arabic voice exists.
- Found that Unit 1's previously-shipped "female" audio was in fact the
  same male Piper voice with altered duration/pitch, mislabeled as female
  (the manifest's own `ttsModel` field named only one voice for all 42
  files). Deleted it rather than keep shipping a faked voice, and rebuilt
  the audio pipeline honestly: male lines get real pre-generated Piper
  audio; female lines are explicitly marked `fallback-tts` and spoken live
  by the device's own (offline) `flutter_tts` engine at runtime. Documented
  in full in `docs/TTS_IMPLEMENTATION.md`.
- Generated 550 audio files across all 14 units (vocab, original + expanded
  hiwar, reading, hadith, ayah, self-assessment) with the upgraded
  `ar_JO-kareem-medium` voice (also regenerated Unit 1 for quality
  consistency). Zero synthesis failures; zero missing/zero-byte files on
  validation (`docs/AUDIO_REPORT.md`).

## 7. UI rebuild
- `UnitScreen` rebuilt as a linear scroll matching the module's own approved
  flow (opening → outcomes → vocab → illustration → hiwar → expanded hiwar
  → pair practice → expressions → qawaid → reading → ayah/hadith →
  exercises → summary → self-assessment), rendering only the sections a
  given unit actually has.
- Interactive matching exercises reconstruct word/meaning pairs from the
  exercise prompt using the unit's own vocabulary as the answer key (no
  external answer source needed for this exercise type); other exercise
  types are free-response with a "mark attempted" toggle, never
  auto-graded incorrect.
- New `GlossaryScreen` (233 aggregated, de-duplicated terms) and
  `SearchScreen` (harakat-normalized index across units/vocab/hiwar/reading/
  glossary, original text always displayed with full harakat).
- `SettingsScreen` completed: theme (light/dark/system), Arabic text size,
  playback speed, audio/TTS info, reset-with-confirmation, course info.
- Removed the duplicate floating "Tetapan" button (bottom nav already
  covers Settings).

## 8. Testing & QA
- `flutter analyze`: 0 issues.
- `flutter test`: 14/14 passing — 11 data-integrity tests (unit count/order,
  outcomes/vocab/hiwar present, unique ids, gender always male/female,
  illustration present) + 3 widget smoke tests (app launches, bottom nav
  opens Glossary/Search/Settings, opening a unit renders its content).
- `flutter build web --release`: succeeds. Android/iOS release/debug builds
  could not be attempted — this machine has no JDK and no Android SDK
  command-line tools installed, and Xcode is incomplete. This is an
  environment limitation, not a code defect; the web build (same Dart
  compiler front-end) is the closest available compile-correctness proxy.

## Limitations carried forward (see docs/CONTENT_REVIEW_FLAGS.md for detail)

- Answer guide (`Dalil_Al-Ijabat_UMT3033_Final.docx`) located but not parsed
  into a structured per-exercise key in this pass.
- Female voice quality/identity depends on the end-user's device TTS engine.
- Android/iOS builds unverified in this environment (web build verified).
