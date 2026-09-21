# Enable live classroom multiplayer

No real Firebase project configuration was found. The app builds and runs solo
and the explicitly labelled local browser-tab preview without Firebase.
**The live classroom quality gate is pending until these steps and device QA are done.**

1. In your own Firebase project, register a Web app and create a Realtime Database
   in the appropriate region. Copy the Web app configuration and database URL.
2. Enable Authentication → Sign-in method → Anonymous. Add
   `muzzammilkias.github.io` (and your testing host) under authorized domains.
3. Deploy `firebase/database.rules.json` to that project's Realtime Database.
   Do not use public test-mode rules. The file is tested with the RTDB emulator.
4. Create an ignored `firebase.local.json` in the repository. Supply your actual
   web configuration using these keys (values below are descriptive, not credentials):
   ```json
   {
     "FIREBASE_API_KEY": "your web apiKey",
     "FIREBASE_APP_ID": "your web appId",
     "FIREBASE_MESSAGING_SENDER_ID": "your messagingSenderId",
     "FIREBASE_PROJECT_ID": "your projectId",
     "FIREBASE_AUTH_DOMAIN": "your authDomain",
     "FIREBASE_DATABASE_URL": "your regional https database URL"
   }
   ```
5. Build:
   ```sh
   flutter build web --release --base-href=/umt3033_flutter/ --dart-define-from-file=firebase.local.json
   ```
   For GitHub Actions set repository variable `FIREBASE_WEB_CONFIG` to this JSON.
   Without the variable the workflow intentionally builds the local-preview version.
   Firebase web configuration is public app configuration; never include service
   account/private keys. Do not check firebase.local.json into source control.
6. Open `/umt3033_flutter/#/game/host`, select a level, create a room. Verify the
   green LIVE CLASSROOM banner. Open the QR on a second device and complete the
   17-step checklist in GAME_QA_CHECKLIST.md before using it in a real class.

## Rules verification (no production project needed)
Node and Java 21+ are required:
```sh
cd tools/game_qa
npm ci
npm run rules
```
The command uses only the `demo-umt-adventure` local emulator. The tests verify
host/student isolation, identity and score bounds, lock/late join, paused writes,
round reset, removed-player bans, deletion and 50 concurrent player updates.
They do not deploy rules or connect to a production database.

## Recovery, privacy and operations
- Anonymous identity persists for the browser tab's session. Refresh works;
  closing the tab, clearing session storage or opening another tab is a new
  participant identity. Keep the host tab open for the class.
- Only nicknames/avatars and learning results are stored. Use classroom nicknames
  rather than personal identifiers. Export CSV before closing a room if needed.
- Host Close room deletes the room. Writes expire after six hours; configure a
  scheduled Admin SDK cleanup for abandoned records (expiry does not delete them).
- Configure Firebase budget alerts and measure actual bandwidth. No physics
  frames are sent; each player publishes at most about once per second plus gates.
- Consider App Check, server-enforced admission/rate limiting, lecturer-only room
  creation and a trusted answer-grading backend before public/graded assessment.
  Current anonymous room creator is the host of that room; students cannot take
  over someone else's room. Players cannot edit peers, but own-score anti-cheat
  is outside a client-authoritative game.
- Firebase configuration errors surface in the game screen; they do not prevent
  the existing course app from opening. Production failures never silently fall
  back to a fake live room.

Sources used for the implementation: [Flutter RTDB read/write](https://firebase.google.com/docs/database/flutter/read-and-write),
[presence and server clock](https://firebase.google.com/docs/database/flutter/offline-capabilities),
[Firebase rules tests](https://firebase.google.com/docs/rules/unit-tests), and
[Flame input](https://docs.flame-engine.org/latest/flame/inputs/keyboard_input.html).
