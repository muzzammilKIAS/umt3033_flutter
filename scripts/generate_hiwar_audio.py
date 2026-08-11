#!/usr/bin/env python3
"""Generate bundled offline hiwar/vocab/reading audio for the UMT3033 app.

Voice strategy (documented in docs/TTS_IMPLEMENTATION.md):
  - MALE lines: pre-generated locally with Piper TTS (ar_JO-kareem-medium),
    the only free, offline, MSA-capable Arabic voice this environment has
    access to (no API key, MIT-licensed engine).
  - FEMALE lines: no free/local/offline Arabic female voice was found (not
    on this Mac, not in Piper's public voice catalogue). Rather than fake a
    female voice by pitch-shifting the male model, female lines are served
    at runtime by the device's own flutter_tts engine (Android/iOS commonly
    ship a female Arabic system voice). This script still records female
    items in the manifest with status "fallback-tts" so the app and
    docs/AUDIO_REPORT.md can report the limitation honestly.

Idempotent: existing valid (non-zero-byte) files are skipped unless --force.
Deterministic filenames: assets/audio/unit-NN/male/{id}-male.wav

Run: python3 scripts/generate_hiwar_audio.py [--force] [--unit 3]
"""
import argparse
import hashlib
import json
import sys
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
DATA_DIR = ROOT / "assets" / "data"
AUDIO_DIR = ROOT / "assets" / "audio"
VOICE_DIR = Path(__file__).resolve().parent / ".piper_voices"
VOICE_NAME = "ar_JO-kareem-medium"


def get_voice():
    try:
        from piper import PiperVoice
    except ImportError:
        print("ERROR: pip install piper-tts", file=sys.stderr)
        sys.exit(1)
    onnx = VOICE_DIR / f"{VOICE_NAME}.onnx"
    cfg = VOICE_DIR / f"{VOICE_NAME}.onnx.json"
    if not onnx.exists():
        print(f"Downloading {VOICE_NAME}...")
        VOICE_DIR.mkdir(parents=True, exist_ok=True)
        from piper.download_voices import download_voice
        download_voice(VOICE_NAME, VOICE_DIR)
    return PiperVoice.load(str(onnx), config_path=str(cfg))


def text_hash(text):
    return hashlib.sha1(text.encode("utf-8")).hexdigest()[:10]


def synth(voice, text, out_path: Path) -> bool:
    out_path.parent.mkdir(parents=True, exist_ok=True)
    tmp = out_path.with_suffix(".tmp.wav")
    try:
        with wave.open(str(tmp), "wb") as wf:
            voice.synthesize_wav(text, wf)
        if tmp.stat().st_size < 200:
            tmp.unlink(missing_ok=True)
            return False
        tmp.replace(out_path)
        return True
    except Exception as e:
        print(f"  FAILED: {out_path.name}: {e}", file=sys.stderr)
        tmp.unlink(missing_ok=True)
        return False


def collect_items(unit):
    """Yield (id, section, arabic, gender) for every audio-eligible item."""
    no = unit["id"]
    code = f"u{no:02d}"
    for v in unit["vocab"]:
        yield v["id"], "vocab", v["arabic"], "male"
    for d in unit["dialog"]:
        yield d["id"], "dialog", d["arabic"], d.get("gender", "unknown")
    for d in unit["expandedDialog"]:
        yield d["id"], "expandedDialog", d["arabic"], d.get("gender", "unknown")
    if unit.get("readingAr"):
        yield f"{code}-reading", "reading", unit["readingAr"], "male"
    if unit.get("hadithAr"):
        yield f"{code}-hadith", "hadith", unit["hadithAr"], "male"
    if unit.get("ayahAr"):
        yield f"{code}-ayah", "ayah", unit["ayahAr"], "male"
    for i, item in enumerate(unit.get("assessmentItems", [])):
        yield f"{code}-assess-{i:03d}", "assessment", item, "male"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--force", action="store_true", help="Regenerate even if a valid file exists")
    ap.add_argument("--unit", type=int, default=None, help="Only process this unit number")
    args = ap.parse_args()

    units = json.loads((DATA_DIR / "units.json").read_text(encoding="utf-8"))
    if args.unit:
        units = [u for u in units if u["id"] == args.unit]

    voice = get_voice()
    manifest_items = []
    generated = skipped = failed = fallback = 0

    for unit in units:
        no = unit["id"]
        unit_dir = AUDIO_DIR / f"unit-{no:02d}" / "male"
        for item_id, section, arabic, gender in collect_items(unit):
            if gender == "female":
                manifest_items.append({
                    "id": item_id, "unitId": no, "section": section, "arabic": arabic,
                    "gender": "female", "path": "", "status": "fallback-tts",
                })
                fallback += 1
                continue
            out_path = unit_dir / f"{item_id}-male.wav"
            rel_path = f"/audio/unit-{no:02d}/male/{item_id}-male.wav"
            if out_path.exists() and out_path.stat().st_size > 200 and not args.force:
                skipped += 1
                status = "generated"
            else:
                ok = synth(voice, arabic, out_path)
                if ok:
                    generated += 1
                    status = "generated"
                    print(f"  unit {no}: {item_id} ({len(arabic)} chars)")
                else:
                    failed += 1
                    status = "failed"
            manifest_items.append({
                "id": item_id, "unitId": no, "section": section, "arabic": arabic,
                "gender": "male", "path": rel_path if status == "generated" else "",
                "status": status,
            })

    manifest = {
        "version": "2.0",
        "ttsModel": f"Piper TTS {VOICE_NAME}",
        "femaleVoiceFallback": "flutter_tts (on-device engine, voice varies by OS)",
        "license": "Piper engine: MIT. Voice model dataset: see model card (AliMokhammad/arabicttstrain).",
        "generatedCount": generated + skipped,
        "fallbackCount": fallback,
        "failedCount": failed,
        "items": manifest_items,
    }
    (DATA_DIR / "audio-manifest.json").write_text(
        json.dumps(manifest, ensure_ascii=False, indent=2), encoding="utf-8"
    )
    print(f"\nGenerated: {generated}  Skipped(existing): {skipped}  Failed: {failed}  Female(fallback-tts): {fallback}")


if __name__ == "__main__":
    main()
