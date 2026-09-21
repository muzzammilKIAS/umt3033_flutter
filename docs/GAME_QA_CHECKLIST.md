# Adventure QA — 2026-09-21

## Verified automatically
- [x] `flutter analyze`: no issues.
- [x] `flutter test`: 36 passing tests, including existing course regressions.
- [x] All 14 original units, vocabulary, dialogue, glossary and model answers load.
- [x] Existing dashboard, glossary, search, settings and unit navigation smoke tests.
- [x] Actual bundled male/female generated audio paths exist.
- [x] Source-derived game answers and every matching pair trace to unit vocabulary.
- [x] 9 gates in each of Levels 1–4; Level 5 vault covers Topics 1–14.
- [x] Headless Flame simulation completes all 9 Level 1 gates through platform physics.
- [x] Learning-weighted score, first-attempt accuracy, penalties, idempotent finish.
- [x] Solo checkpoint, stars, bests and topic mastery persist independently of the
  original course state.
- [x] All five worlds are selectable and load directly from a hash route; no world
  is locked behind finishing another.
- [x] Firebase numeric-key topic array recovery retains analytics.
- [x] Arabic choice and matching cards fit 390×844 without overflow exceptions.
- [x] 50-player projector layout displays every avatar within 1440×900.
- [x] Local adapter lifecycle simulations with 2, 10 and 50 players: invalid room,
  duplicate name, unauthorized control, late join, recovery, stale round, removal,
  results, next world and room deletion.
- [x] Firebase RTDB emulator accepts 50 simultaneous authenticated player writes.
- [x] Rules reject unauthenticated reads, student host controls, peer edits,
  nickname takeover, pre-start/paused scoring, out-of-range scores/progress,
  premature finish, stale round, banned rejoin and non-host deletion.
- [x] `flutter build web --release --base-href=/umt3033_flutter/ --no-web-resources-cdn`
  succeeds and renders with the CanvasKit CDN blocked.
- [x] Built JS release served at the actual Pages subpath; direct hash entries load.
- [x] Chrome visual inspection: game menu, host lobby QR, mobile play, projector lanes,
  complete leaderboard and analytics section.

## Browser integration run
The checked-in `tools/game_qa/browser.test.mjs` uses real headless Chrome tabs,
Flame rendering, UI controls and local-preview persistence. It covers the original
root page, menu → host, QR/code prefill without manual code entry, two separately
joined players, synchronized race start, held touch movement, live progress,
host/player refresh, pause/resume, end/results, next world and solo route refresh.
Screenshots are written under ignored `build/game-qa/`.

Run after serving `build/web` under `/umt3033_flutter/` at localhost:8765:
```sh
cd tools/game_qa
npm ci
npm run browser
```
Browser test status is recorded in GAME_DELIVERY_REPORT.md. Canvas text is not
always represented verbatim in Flutter's HTML accessibility mirror; tests use
interactive semantics plus stored state and screenshots where appropriate.

## Live classroom quality gate — pending real-device testing
Firebase is configured and a two-client run passed against the live project and the
deployed site (see the delivery report). These are **not claimed as passed on real
devices**:

- [ ] 1–3. Lecturer opens deployed course → Adventure → Host.
- [ ] 4–7. Select world, show large QR, two physical phones scan and join live.
- [ ] 8–9. Host starts; both phones show 3,2,1,GO using shared server time.
- [ ] 10–12. Actual phone controls, Arabic answers, every player's host progress.
- [ ] 13–16. Rankings, all finish, leaderboard and topic accuracy.
- [ ] 17. Host starts another world without asking everyone to rejoin.
- [ ] Repeat with ten physical clients, then 30–50 clients on classroom Wi-Fi.
- [ ] Disconnect/reconnect Wi-Fi during a gate and at finish; refresh host/student.
- [ ] Try actual iOS Safari / Android Chrome portrait and landscape, with text scaling.
- [ ] Measure FPS, network latency and Firebase bandwidth on representative phones.
- [ ] Test simultaneous admission near 50 participants (current UI capacity guard
  is not a transactional server-enforced limit).
- [ ] Lecturer approves vocabulary selection/distractors and additional grammar keys.
- [ ] Time learning interactions; validate the desired 70/30 gameplay balance.

## Known boundaries
The emulator verifies permissions and concurrent database writes, not Firebase
Auth/RTDB browser adapters against a live regional project. No performance claim
for 50 actual phones is made. Local preview is same-browser only and cannot replace
Firebase. Advanced grammar/reading/sacred-text questions remain explicitly
CONTENT_REVIEW_REQUIRED. Original geometric artwork is functional and replaceable;
a detailed illustration/audio pass is not included. The existing flutter_tts
package warns during Wasm dry-run; the supported JavaScript release build passes.

Baseline tests had 10 failures before game changes. UI tests now target current
Arabic labels and supported screen widgets, TTS tests follow the documented
standard-Alif normalization (without adding source words), and audio tests verify
real male/female assets rather than obsolete male-only assumptions. No course
content or TTS behavior was changed to make these tests pass.
