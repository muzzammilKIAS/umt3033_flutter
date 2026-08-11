# Audio / TTS Implementation

## Constraint

No paid API (OpenAI, ElevenLabs, Google Cloud, Azure, AWS) is available or
permitted. Everything below is free, runs fully offline once installed, and
requires no API key.

## Environment inspection (what was actually checked, on this Mac)

| Option | Result |
|---|---|
| macOS `say -v '?'` (all installed system voices) | Exactly **one** Arabic voice installed: `Majed` (`ar_001`), male, novelty quality. No female Arabic voice is bundled with this macOS install, and installing additional voice packs requires the System Settings UI (not scriptable/headless, so unsuitable for an unattended pipeline). |
| Piper TTS (`piper-tts` Python package) | Already installed (v1.6.0). Its public voice catalogue (`rhasspy/piper-voices`) has exactly **two** Arabic models, both the same single speaker: `ar_JO-kareem-low` and `ar_JO-kareem-medium` — one Jordanian **male** voice, MSA-capable, no female counterpart exists in Piper's catalogue at all. |
| Local pre-existing models/tools | None found (no cached `.onnx` voices, no other local Arabic TTS). |

**Conclusion: there is no free, offline, license-clean Arabic female voice
available in this environment or in Piper's public catalogue.** This is a
real, verified limitation, not a shortcut — see the "faked-gender" note
below for why the previous local male voice was not simply pitch-shifted to
stand in for a female voice.

## Decision (documented, not asked)

1. **Male lines → pre-generated Piper audio.** `ar_JO-kareem-medium` (upgraded
   from `-low`, used by a prior session for Unit 1 only, to `-medium` for
   better quality across all 14 units — Unit 1 was regenerated too for
   consistency). Engine: MIT-licensed. Voice model: dataset "kareem" per its
   model card (`AliMokhammad/arabicttstrain`), fine-tuned from an English
   base model; that's the license/provenance available from Piper's public
   card.
2. **Female lines → on-device `flutter_tts` at runtime.** Android and iOS
   both ship Arabic TTS engines system-wide that commonly default to (or let
   the OS pick) a female voice; this is genuinely a different, real voice —
   not a manipulated male recording — and stays fully offline (no network
   call, no API key). Voice quality/gender is device-dependent, which is
   disclosed to the student in Settings ("Mengenai Audio & TTS").
3. **Removed a previously-shipped faked female voice.** Before this pass,
   `assets/audio/unit-01/female/*.wav` existed and was tagged `gender:
   female` in `audio-manifest.json`, but the manifest's own `ttsModel` field
   candidly named a *single* voice (`Piper TTS ar_JO-kareem-low`) for all 42
   items — i.e. the "female" files were a duration/pitch-altered copy of the
   same male Piper output, not a real distinct voice. That violates the
   "never fake a voice gender" requirement, so those 21 files were deleted
   and are not reproduced. Female items are now honestly recorded in the
   manifest with `status: "fallback-tts"` and an empty `path`, and the app's
   `DataService.getAudioPath` only ever resolves bundled files with
   `status: "generated"`.

## Pipeline

`scripts/generate_hiwar_audio.py`:

- Reads `assets/data/units.json`.
- For every vocab item, dialogue line (original + expanded hiwar), reading
  passage, hadith, ayah and self-assessment checklist item:
  - if the line's speaker (or item type) is male → synthesize with Piper,
    write `assets/audio/unit-NN/male/{id}-male.wav`, record
    `status: "generated"` in the manifest.
  - if female → record `status: "fallback-tts"`, no file written.
- Deterministic filenames: `{id}-male.wav`, where `{id}` matches the
  vocab/dialogue id already present in `units.json` (e.g. `u03-dialog-005`,
  `u09-reading`, `u01-assess-002`).
- Idempotent: an existing non-zero-byte file is skipped unless `--force`.
- Continues past individual synthesis failures (none occurred in this run —
  see `docs/AUDIO_REPORT.md`).
- Rewrites `assets/data/audio-manifest.json` from scratch each run (it is a
  derived artifact, not hand-edited).

To regenerate audio after a content change:

```bash
python3 scripts/extract_units.py        # DOCX -> units_extracted.json
python3 scripts/build_units_json.py     # -> units.json / glossary.json / references.json
python3 scripts/generate_hiwar_audio.py # -> assets/audio/**, audio-manifest.json
```

The Piper voice model (`ar_JO-kareem-medium`, ~63MB) is downloaded once into
`scripts/.piper_voices/` (git-ignored — regenerated automatically by the
script; not needed at app runtime, only at content-build time).

## App playback behaviour

- `UnitScreen` looks up `DataService.getAudioPath(id, gender)`; if a bundled
  file exists it's played with `just_audio` at the user's preferred speed
  (0.75×/1.0×/1.25×, persisted). If not (female lines, or any failure), it
  falls back to `flutter_tts` speaking the same Arabic text live.
- Play-all queues (vocab list, full hiwar) play sequentially with a short
  pause between lines; a stop button is always available; no autoplay on
  opening a unit; audio stops on leaving the screen (`dispose()`).
- TTS pronunciation text is exactly the displayed Arabic (harakat included) —
  Piper and most mobile Arabic TTS engines use diacritics to disambiguate
  pronunciation, so nothing is stripped for speech; only the search index
  (never anything user-facing) strips harakat.
