# Arabic Muamalat Adventure — implementation plan

## Audit (2026-09-21)
The selected MARIO UMT directory was empty. Work targets the adjacent existing
umt3033_flutter checkout, whose origin is muzzammilKIAS/umt3033_flutter.
Working tree was clean before changes.

- Flutter 3.44.8, Dart 3.12.2, matching CI's pinned Flutter.
- Existing dependencies: Provider, shared_preferences, just_audio, flutter_tts,
  url_launcher, cupertino_icons and Flutter localizations.
- Architecture: models / services / screens / widgets / theme / utils.
- MaterialApp + Navigator, MainShell IndexedStack, four existing navigation tabs.
- DataService loads 14 units, glossary, course, references and audio manifests.
  units.json includes vocabulary, dialogues, grammar, exercises and source texts.
- Sources and reviewed extraction documented in SYLLABUS_MODULE_MAPPING.md and
  CONTENT_REVIEW_FLAGS.md. Answer guide has no reliable per-question anchors.
- Bundled Amiri regular/bold and Inter. Existing app is Arabic-medium RTL.
- Provider StorageService uses shared_preferences under umt3033_app_v1.
- Assets: bundled JSON, fonts, unit illustrations and male/female audio.
- No Firebase, backend, path URL strategy or game module found.
- GitHub Actions builds release with /umt3033_flutter/ and publishes gh-pages.
- Reuse DataService, vocabulary models, fonts and local persistence dependency.
  Keep game state separate from course-completion state.
- Baseline flutter analyze: clean. Baseline tests: 11 pass, 10 fail (stale
  dashboard/navigation expectations and TTS normalization expectations).

## Implementation sequence
1. Add isolated models, curriculum mapping and source-derived question bank.
2. Add hash-safe entry/routes and navy/emerald/gold responsive design system.
3. Add Flame local platform physics, original vector art, gates and save state.
4. Add realtime service interface, Firebase adapter and local preview adapter.
5. Add host/join/lobby, synchronized start, projector lanes and host controls.
6. Add results, topic analytics, persistence, recovery and CSV export.
7. Verify content, mechanics, multiplayer isolation, rules, layouts and release.
8. Document Firebase manual setup and distinguish verified from pending QA.

## Constraints
No course JSON modifications, no generated academic translations, no Nintendo
assets, no replacement of the course navigation. No live deployment or production
Firebase writes without a configured project. Hash join links retain base path.

## Implementation status
- [x] Audit and isolated architecture.
- [x] Dependencies, hash-safe game entry, avatar selection and five-world map.
- [x] Flame physics, moving bridge/barriers, parallax, gems, gates and respawn.
- [x] Source-backed question bank, matching and choice UI, saved solo progression.
- [x] Room interface, Firebase adapter, local preview, QR and host/student flows.
- [x] Server-clock start, pause/resume, refresh recovery, per-round stale-write guard.
- [x] All-player race display, results, topic analytics, CSV, host next/restart.
- [x] Analyzer, 34 Flutter tests, Firebase emulator rules/concurrency tests, release build.
- [x] Original world/zone vector scenery and mobile/projector layout inspection.
- [x] Firebase setup, architecture, content/artwork review and QA documentation.
- [ ] Production Firebase configuration and real-device classroom acceptance.
- [ ] Lecturer-approved per-question grammar/reading keys and classroom balance trial.

The implementation is delivered locally; the user-specified production classroom
quality gate remains pending. No git push, Pages publication, production Firebase
configuration or production data writes were performed.
