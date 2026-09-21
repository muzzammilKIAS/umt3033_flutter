# Arabic Muamalat Adventure — architecture

## Integration boundary
The existing MaterialApp, four-tab MainShell, providers, course models, JSON,
fonts, and learning persistence remain in place. Two integration points:
`main.dart` registers `adventureRoute`; Dashboard exposes a game-entry card.
The game sets its own LTR shell; Arabic text explicitly uses RTL + bundled Amiri,
generous 1.9 line height and wrapping. Course UI remains RTL.

Hash routes: `/game`, `/game/solo`, `/game/host`, `/game/join?room=CODE`,
`/game/lobby?room=CODE`, `/game/play?level=1&avatar=0`.
Lobby/play/results in multiplayer are room-state views rather than separately
navigated pages. This avoids losing subscriptions on transitions. Solo play has
a reloadable route and resumes at its latest checkpoint.

## Modules
- `models`: immutable curriculum/question definitions, room/player snapshots,
  serialized RunState and scoring.
- `data`: QuestionBank adapts exact existing vocabulary pairs, preserving source
  references. See GAME_CONTENT_REVIEW.md for categories awaiting lecturer keys.
- `engine`: Flame rendering/input with bounded 120Hz physics steps; camera,
  parallax, original vector avatars, one-way platforms, moving bridge/barriers,
  gems, gated progress, respawn and knowledge boost.
- `services`: namespaced solo save, best score/time/stars, topic mastery. All five
  worlds are open from the start; progress is recorded, never gated.
- `multiplayer`: RoomService, Firebase implementation, browser-only preview.
- `screens/widgets`: map, avatars, projector, responsive race lanes, question
  interaction, mobile controls, full results, topic analytics and CSV export.
- `utils`: conditional web fullscreen, session recovery and CSV download.

## Progress and learning
A segment is 1,100 logical units. Three gates per topic in Worlds 1–4; six gates
plus a fourteen-topic Grand Muamalat Vault in World 5. A gate cannot be bypassed
by jumping. Wrong answers show the source-backed mapping, add three seconds,
and allow continuation. Falling/barrier contact adds two seconds and respawns
at the latest cleared gate. Right answers award 100 + 0–50 response-time points
and a three-second movement boost. Gems are capped to two per segment at ten
points each; completing the level awards 200 once. First-attempt accuracy is
retained. Stars: ≥90% = 3, ≥65% = 2, otherwise 1 on completion.

Ranking uses knowledge-led score, accuracy, progress, then elapsed active time including
penalties. Scores are not suitable for high-stakes examination grading: local
clients calculate their own outcomes. Rules prevent changing other students,
not a determined player forging their own valid-range score. A trusted grading
service is required for anti-cheat assessment.

## Room state and synchronization
`lobby → countdown → playing/paused → results → lobby (new round)`.
The stored countdown phase is logically playing after startAt + 3 seconds;
clients do not wait for another host event to begin. Start is an RTDB server
timestamp. Clients estimate server time using `.info/serverTimeOffset`.
Pause/resume stores pause timestamps; local simulation freezes during a pause
or disconnected Firebase connection. At every player's completion the host
moves to results; the host can also end a partially completed race.

Each client runs physics locally. Writes occur about once per second and after
answers/completion, with an in-flight guard. They contain aggregate run state,
never coordinates or animation frames. Race lanes interpolate between progress
snapshots. All participants are rendered, with compact columns above 20. At
1440×900 the automated projector test fits all 50 avatars in 720 vertical pixels.
Very small screens allow scrolling instead of hiding participants.

Firebase uses anonymous auth with SESSION persistence on web so separate tabs
can represent different people and a refresh retains identity. RTDB stores the
last acknowledged run; a refresh restores score/checkpoint (position rolls back
to the checkpoint). `round` rejects old-round writes. A removed player is banned
from rejoining that room UID. Presence uses onDisconnect and reconnect handlers.
Host recovery uses the same tab's room code + anonymous UID. Closing the tab or
clearing browser session data ends that recovery guarantee. No student account.

The preview adapter uses shared_preferences + tab session IDs and 400ms polling.
It only connects tabs on one browser origin; QR links on phones require Firebase.
Its read/modify/write storage is not a production concurrent database and can
lose a preview update during simultaneous writes. Use Firebase for classroom
operation. Tests verify local 2/10/50-player lifecycle sequences and 50 concurrent
writes against actual RTDB emulator rules, not 50 physical phones.

## Firebase schema
```
rooms/CODE/
  metadata: hostId, level, round, phase, locked, startAt,
            pausedAt, pausedMs, expiresAt
  names/normalizedNickname: uid       # atomic uniqueness reservation
  blocked/uid: true                   # host removal ban
  players/uid:
    nickname, avatar, round, connected
    run: score, progress, checkpoint, correct, wrong,
         elapsedMs, gems, finished, topics/topicId/{correct,wrong}
```
Code-addressed reads require authentication; room listing is denied. Only the
host can configure, start/pause/end, reset or delete a room. Players can write
only their own validated record. Numeric bounds, finished-gate counts, round,
immutable nickname/avatar, nickname ownership, phase and expiry are checked.
Initial runs must start empty. Writes to run data are rejected during pauses.
Rooms expire for writes after six hours. Host Close room removes data; a scheduled
backend cleanup is still needed for abandoned rooms. UI admission targets 50;
strict server-enforced capacity/rate limits and App Check are production follow-ups.

## Performance and testing boundaries
No image downloads; vector geometry renders only visible segments. Game engines
are created only for play. Existing course bootstrap remains unchanged. The host subscribes to the full room. During a race, students subscribe only to
metadata and their own player record; lobby/results subscribe to the roster.
50-client emulator writes passed, but bandwidth/latency must be measured on the
actual classroom Wi-Fi. Smooth 60FPS is a target, not a measured
claim across phone models. See GAME_QA_CHECKLIST.md.
