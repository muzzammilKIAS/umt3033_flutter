# Audio Report

TTS model: **Piper TTS ar_JO-kareem-medium** (male voice, pre-generated, bundled offline).
Female voice fallback: **flutter_tts (on-device engine, voice varies by OS)** (see `docs/TTS_IMPLEMENTATION.md` for why no free/offline female Arabic voice could be bundled).
License: Piper engine: MIT. Voice model dataset: see model card (AliMokhammad/arabicttstrain).

| Unit | Dialogue lines (orig+expanded) | Male lines | Female lines | Male audio generated | Missing/failed | Status |
|---|---|---|---|---|---|---|
| 1 | 12 | 6 | 6 | 24 (incl. vocab/reading/hadith/ayah/assess) | 0 | PASS |
| 2 | 15 | 15 | 0 | 39 (incl. vocab/reading/hadith/ayah/assess) | 0 | PASS |
| 3 | 17 | 0 | 17 | 28 (incl. vocab/reading/hadith/ayah/assess) | 0 | PASS |
| 4 | 16 | 16 | 0 | 42 (incl. vocab/reading/hadith/ayah/assess) | 0 | PASS |
| 5 | 17 | 17 | 0 | 44 (incl. vocab/reading/hadith/ayah/assess) | 0 | PASS |
| 6 | 19 | 10 | 9 | 37 (incl. vocab/reading/hadith/ayah/assess) | 0 | PASS |
| 7 | 16 | 8 | 8 | 35 (incl. vocab/reading/hadith/ayah/assess) | 0 | PASS |
| 8 | 16 | 8 | 8 | 36 (incl. vocab/reading/hadith/ayah/assess) | 0 | PASS |
| 9 | 16 | 16 | 0 | 44 (incl. vocab/reading/hadith/ayah/assess) | 0 | PASS |
| 10 | 16 | 8 | 8 | 34 (incl. vocab/reading/hadith/ayah/assess) | 0 | PASS |
| 11 | 17 | 17 | 0 | 45 (incl. vocab/reading/hadith/ayah/assess) | 0 | PASS |
| 12 | 16 | 8 | 8 | 36 (incl. vocab/reading/hadith/ayah/assess) | 0 | PASS |
| 13 | 16 | 16 | 0 | 48 (incl. vocab/reading/hadith/ayah/assess) | 0 | PASS |
| 14 | 16 | 8 | 8 | 40 (incl. vocab/reading/hadith/ayah/assess) | 0 | PASS |

**Totals across all 14 units: 153 male dialogue lines, 72 female dialogue lines, 532 audio files generated (vocab + dialogue + reading + hadith/ayah + self-assessment), 0 failures.**

## File-existence validation
- Referenced files missing from disk: 0 []
- Referenced files zero/near-zero bytes: 0 []
- Deterministic filenames confirmed: `{id}-male.wav` under `assets/audio/unit-NN/male/`.

## Male voice used
- **Piper TTS ar_JO-kareem-medium** — single Jordanian Arabic male speaker ("kareem"), MSA-capable, MIT-licensed engine, no API key, fully offline.

## Female voice
- No free, offline, license-clean Arabic female voice exists in this environment (verified: macOS system voices, Piper's public catalogue). Female dialogue lines are marked `status: "fallback-tts"` in the manifest (72 lines) and are spoken live via the device's own `flutter_tts` engine at runtime — never faked by pitch-shifting the male voice (see `docs/TTS_IMPLEMENTATION.md` for the removal of a previously-shipped faked female voice for Unit 1).