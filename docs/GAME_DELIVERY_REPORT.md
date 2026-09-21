# Arabic Muamalat Adventure — delivery report (2026-09-21)

Status: **implemented, deployed, and connected to a live Firebase project
(`umt3033-adventure`, Realtime Database in `asia-southeast1`).** The remaining gate is
running it on real phones in a real classroom (see the checklist).

## Created files
- `lib/game/` — isolated game module (nothing in `lib/models|services|screens` was replaced):
  - `game_routes.dart` (hash-safe routes `/game`, `/game/solo`, `/game/host`, `/game/join`, `/game/play`, …)
  - `models/` `curriculum.dart` (14 topics → 5 worlds), `race_state.dart`
  - `data/question_bank.dart` (source-derived questions)
  - `engine/` Flame game, course geometry, and the environment, prop and avatar
    vector art (`environment_art.dart`, `prop_art.dart`, `avatar_art.dart`)
  - `multiplayer/` `room_service.dart` (interface), `firebase_room_service.dart`, `local_room_service.dart`
  - `services/progress_store.dart` (solo saves, separate from course progress)
  - `screens/` home, solo route, room (host/join/lobby), play, results
  - `widgets/` question gate, race board, world cards, design system
  - `utils/` browser helpers (web / stub)
- `test/game/adventure_test.dart`
- `firebase/database.rules.json`, `firebase.json`
- `tools/game_qa/` — `rules.test.mjs` (RTDB emulator), `browser.test.mjs` (Playwright + Chrome), `package.json`
- `docs/` — `GAME_IMPLEMENTATION_PLAN`, `GAME_ARCHITECTURE`, `FIREBASE_SETUP`, `GAME_ASSETS`, `GAME_CONTENT_REVIEW`, `GAME_QA_CHECKLIST`, this report

## Modified files
- `lib/main.dart`, `lib/screens/dashboard_screen.dart` — game entry only; course navigation kept.
- `pubspec.yaml`, `pubspec.lock`; generated macOS/Windows plugin registrants.
- `.github/workflows/flutter_web.yml` — now runs `flutter analyze` and `flutter test` before the build, and
  passes optional `FIREBASE_WEB_CONFIG` (repository variable) via `--dart-define-from-file`. Without the
  variable the build is identical to before and the game runs in local-preview mode.
- `.gitignore`, `analysis_options.yaml`, `README.md`.
- `test/arabic_text_test.dart`, `test/data_test.dart`, `test/widget_test.dart` — 10 tests were already
  failing before this work (stale expectations); updated to match current behaviour. No course content or
  TTS behaviour was changed to make them pass.

## Dependencies added
`flame ^1.38.2`, `firebase_core ^4.15.0`, `firebase_auth ^6.7.0`, `firebase_database ^12.6.0`,
`qr_flutter ^4.1.0`, `web ^1.1.1`. Dev tooling (`tools/game_qa`, not shipped): `playwright`,
`firebase-tools`, `firebase`, `@firebase/rules-unit-testing`.

## Test results (re-run at hand-over)
| Check | Result |
|---|---|
| `flutter analyze` | No issues |
| `flutter test` | 36 passed (includes 2/10/50-player local lifecycle, full Level 1 physics run, 390×844 Arabic UI, 20/50-player 16:9 projector layouts, CSV injection) |
| `flutter build web --release --base-href=/umt3033_flutter/ --no-web-resources-cdn` | Succeeds; CanvasKit is bundled so the page renders even where `gstatic.com` is blocked |
| `npm run browser` (release build served at `/umt3033_flutter/`) | PASS — root, menu, QR, two real player tabs, host/player refresh, touch movement, live progress, pause/resume, results, next world, solo refresh |
| `npm run rules` (RTDB emulator) | PASS — rules, lifecycle, recovery, 50 concurrent player writes. `permission_denied` warnings in the log are the expected rejected writes |

Note: the emulator needs Java. It was run with the JDK 21 JRE Codex left in `/private/tmp/umt-java`; that
path is temporary, so install a JDK (e.g. `brew install openjdk@17`) to repeat it.

## Remaining manual steps
1. If deploying to Render, follow "Deploying to Render with Firebase" in `FIREBASE_SETUP.md`
   and add the Render domain to Firebase Authentication → Authorized domains.
2. Run the 17-step live classroom gate in `GAME_QA_CHECKLIST.md` on real phones.
3. Lecturer review of vocabulary selection/distractors and supply per-question keys for grammar/reading
   (currently `CONTENT_REVIEW_REQUIRED`; see `GAME_CONTENT_REVIEW.md`).

## Known limitations
- No claim of 50-physical-phone performance or classroom Wi-Fi behaviour; only emulator + simulated clients.
- The 50-player cap is a UI guard, not server-enforced under simultaneous admission.
- Local preview mode is same-browser only and does not replace Firebase.
- Artwork is original, functional vector art meant to be replaced (`GAME_ASSETS.md`); no audio pass.
- The 70/30 gameplay/learning balance has not been timed with real students.
- CI now gates deployment on analyze + tests; a future failing test will block the Pages publish.

## Changes after the first hand-over
- **Art pass.** The scenery, props and characters were redrawn as layered vector art:
  gradient skies, parallax ridges, per-zone landmarks, textured terrain, faceted gems,
  arch gates and a vault finish. Background bands are hazed toward the sky so the
  playfield stays the most readable thing on screen. Collision geometry is unchanged.
- **UI pass.** World cards now carry a painted thumbnail of the world they open, the
  projector lobby scales the QR to the screen height, and race lanes show rank medals,
  a filled track and gate counts.
- **Fonts.** Button text styles now name the bundled `Inter`; previously they fell back
  to Roboto, which is fetched from the Google Fonts CDN and vanished when that was
  blocked.
- **CanvasKit is bundled** (`--no-web-resources-cdn`, in CI too). Without it the app
  renders a blank page wherever `www.gstatic.com` is unreachable — likely on a campus
  or classroom network.
- **No level locking.** All five worlds are open from the start, so a lecturer can run
  any topic. `ProgressStore.unlocked` was removed; bests, stars and mastery remain.

## Live Firebase verification (2026-09-21)
Against the real project, using a separate browser context per participant so each has
its own anonymous identity: the host shows the green LIVE CLASSROOM banner, two players
join from the QR link, both start together after the server-clock countdown, the host
sees both lanes, and results render. Repeated against the deployed GitHub Pages site.
Database rules are deployed (not test mode) and GitHub Pages is authorized for sign-in.
Test rooms were deleted afterwards. Physical phones and 10–50 concurrent clients on
classroom Wi-Fi remain untested.
