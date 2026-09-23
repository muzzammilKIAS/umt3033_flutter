# Enable live classroom multiplayer (Render, no Firebase)

The Arabic Muamalat Adventure game's live classroom multiplayer runs on a
small standalone Dart WebSocket server (`server/`), not Firebase. Rooms are
kept in the server's memory only -- no database to provision. Without a
configured server the app still runs solo, plus a same-browser-tab
"LOCAL PREVIEW" mode.

## How it fits together

- `packages/game_shared/` -- pure-Dart room model and rules
  (`RaceRoom`, `RunState`, `RoomEngine`), used by **both**:
  - the Flutter client's `LocalRoomService` (browser-tab preview) and
    `RenderRoomService` (talks to the real server), and
  - the server itself (`server/bin/main.dart`).
  One engine enforces the rules everywhere, so the preview and the real
  server can never drift apart.
- `server/` -- the standalone server. `dart run bin/main.dart` locally,
  or built via `server/Dockerfile` for deployment. Wire protocol (one JSON
  object per WebSocket frame) is documented at the top of `bin/main.dart`.
- `render.yaml` -- a Render Blueprint with **two** services:
  1. `umt3033-adventure` -- the Flutter web static site.
  2. `umt3033-adventure-server` -- the Dart game server, built from
     `server/Dockerfile` (Render's Docker runtime; Dart itself isn't one of
     Render's native runtimes).

## Deploy both services

1. Render dashboard → **New → Blueprint** → pick this repository. Render
   reads `render.yaml` and creates both services.
2. Wait for `umt3033-adventure-server` to finish its first deploy. Copy its
   URL, e.g. `https://umt3033-adventure-server.onrender.com`.
3. On the `umt3033-adventure` (static site) service, set the
   `GAME_SERVER_WS_URL` environment variable to that URL with the scheme
   changed to `wss://` and `/ws` appended:
   ```
   wss://umt3033-adventure-server.onrender.com/ws
   ```
4. Redeploy the static site so the build picks up the variable (Render
   rebuilds automatically when you save an env var change).
5. Open `https://umt3033-adventure.onrender.com/#/game/host`, select a
   level, create a room. Verify the green **LIVE CLASSROOM** banner. Open
   the QR on a second device and complete the QA checklist in
   `docs/GAME_QA_CHECKLIST.md` before using it in a real class.

## GitHub Pages

The same server also backs the GitHub Pages build. Set a repository
**variable** (Settings → Secrets and variables → Actions → Variables)
named `GAME_SERVER_WS_URL` to the same `wss://.../ws` URL. The
`Flutter Web Build & Deploy` workflow passes it through as a
`--dart-define`. Without it, the workflow intentionally builds the
local-preview version.

## Local development

```sh
cd server
dart run bin/main.dart            # listens on :8080 by default
```

Then run the Flutter app pointed at it:

```sh
flutter run -d chrome --dart-define=GAME_SERVER_WS_URL=ws://localhost:8080/ws
```

## Operational notes

- **In-memory only.** A server restart or redeploy clears every active
  room immediately. Render's free/starter web services can restart at any
  time (deploys, idle spin-down), so treat rooms as disposable within a
  single class session -- the same expectation Firebase's 6-hour room
  expiry already set.
- **Identity.** Each browser tab generates a random anonymous id, stored in
  `sessionStorage` (same as the old local-preview mode). Refreshing the tab
  keeps the same identity; closing it or opening a new tab is a new
  participant, same as before.
- **No auth, no per-room encryption key.** Anyone who knows a room code can
  attempt to join or watch it over the WebSocket. `RoomEngine` still
  enforces host-only controls, nickname uniqueness, room locking/expiry
  and the 50-player cap, but there is no equivalent of Firebase's signed
  anonymous-auth identity. Do not use this for graded or sensitive
  assessments without adding real authentication first.
- **CORS/origin.** The server accepts WebSocket upgrades from any origin.
  If you need to restrict this to your own domains, check the `Origin`
  header in `server/bin/main.dart` before calling
  `WebSocketTransformer.upgrade`.
- **Health check.** `GET /healthz` returns `200 ok`; `render.yaml` uses it
  for the server service's health check.
- Only nicknames/avatars and learning results ever leave the browser.
  Use classroom nicknames rather than personal identifiers. Export CSV
  before closing a room if needed.
