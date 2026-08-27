#!/usr/bin/env python3
"""
Script untuk menjana semula 15 fail audio yang mengandungi kalimah Allah
menggunakan teks MSA standard bertashkeel (tanpa aksara Quran U+0671 ٱ yang merosakkan enjin Neural TTS).

Prasyarat:
    pip install edge-tts

Penggunaan:
    python3 scripts/regenerate_allah_audio.py
"""

import asyncio
import json
import re
import sys
from pathlib import Path

# Add user site-packages if needed
sys.path.insert(0, "/Users/sufyanthawry/Library/Python/3.9/lib/python/site-packages")

try:
    import edge_tts
except ImportError:
    print("❌ Sila pasang edge-tts terlebih dahulu: pip install edge-tts")
    sys.exit(1)

PROJECT_ROOT = Path(__file__).parent.parent
MANIFEST_PATH = PROJECT_ROOT / "assets/data/audio-manifest.json"
AUDIO_BASE = PROJECT_ROOT / "assets/audio"

VOICES = {
    "male": "ar-SA-HamedNeural",
    "female": "ar-SA-ZariyahNeural",
}


def prepare_for_tts(text: str) -> str:
    """
    Sediakan teks Arab untuk Microsoft Neural TTS:
    - Gunakan Alif standard (ا U+0627) dengan Tashdid (ّ U+0651) pada kalimah Allah
    - Kembangkan ligatur ﷺ kepada 'صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ'
    - Buang tanda petikan & simbol ganjil yang memotong frasa
    - Elakkan aksara U+0671 (ٱ) kerana ia merosakkan model Neural TTS Microsoft
    """
    s = text

    # Remove any existing Quranic Wasla U+0671 -> standard Alif
    s = s.replace("\u0671", "ا")

    # Expand ﷺ ligature
    s = s.replace("\uFDFA", " صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ ")
    s = s.replace("ﷺ", " صَلَّى اللَّهُ عَلَيْهِ وَسَلَّمَ ")

    # Normalize Allah Tashkeel
    s = re.sub(r"رَسُولُ\s+اللهِ?", "رَسُولُ اللَّهِ", s)
    s = re.sub(r"رَسُولِ\s+اللهِ?", "رَسُولِ اللَّهِ", s)
    s = re.sub(r"رَسُولَ\s+اللهِ?", "رَسُولَ اللَّهِ", s)
    s = re.sub(r"صَلَّى\s+اللهُ?", "صَلَّى اللَّهُ", s)
    s = re.sub(r"قَالَ\s+اللهُ?\s*تَعَالَى:?", "قَالَ اللَّهُ تَعَالَى:", s)
    s = re.sub(r"قَالَ\s+اللهُ?", "قَالَ اللَّهُ", s)
    s = re.sub(r"أَحَلَّ\s+اللهُ?", "أَحَلَّ اللَّهُ", s)
    s = re.sub(r"حَرَّمَهُ\s+اللهُ?", "حَرَّمَهُ اللَّهُ", s)
    s = re.sub(r"بَارَكَ\s+اللهُ?", "بَارَكَ اللَّهُ", s)
    s = re.sub(r"وَفَّقَكَ\s+اللهُ?", "وَفَّقَكَ اللَّهُ", s)
    s = re.sub(r"تَقَبَّلَ\s+اللهُ?", "تَقَبَّلَ اللَّهُ", s)
    s = re.sub(r"سَهَّلَ\s+اللهُ?", "سَهَّلَ اللَّهُ", s)
    s = re.sub(r"يَسَّرَ\s+اللهُ?", "يَسَّرَ اللَّهُ", s)
    s = re.sub(r"رَحِمَ\s+اللهُ?", "رَحِمَ اللَّهُ", s)
    s = re.sub(r"إِنَّ\s+اللهَ?", "إِنَّ اللَّهَ", s)
    s = re.sub(r"أَنَّ\s+اللهَ?", "أَنَّ اللَّهَ", s)

    # Standalone Allah
    s = re.sub(r"\bاللهِ\b", "اللَّهِ", s)
    s = re.sub(r"\bاللهُ\b", "اللَّهُ", s)
    s = re.sub(r"\bاللهَ\b", "اللَّهَ", s)
    s = re.sub(r"\bالله\b", "اللَّهُ", s)

    # Clean up punctuation that disrupts natural Neural TTS flow
    s = re.sub(r':\s*["«""]', ": ", s)
    s = re.sub(r'["""«»]', " ", s)
    s = re.sub(r"\s+", " ", s).strip()
    return s


async def regenerate_item(item: dict, idx: int, total: int) -> bool:
    item_id = item["id"]
    arabic = item.get("arabic", "")
    gender = item.get("gender", "male")
    path_str = item.get("path", "")

    if not arabic or not path_str:
        print(f"  [{idx}/{total}] ⚠️ Skip {item_id}")
        return False

    tts_text = prepare_for_tts(arabic)

    rel_path = path_str.lstrip("/")
    if rel_path.startswith("audio/"):
        rel_path = rel_path[len("audio/"):]
    output_file = AUDIO_BASE / rel_path
    output_file.parent.mkdir(parents=True, exist_ok=True)

    voice = VOICES.get(gender, VOICES["male"])

    try:
        communicate = edge_tts.Communicate(tts_text, voice)
        await communicate.save(str(output_file))
        item["status"] = "generated"
        item["ttsEngine"] = "Microsoft Edge Neural TTS"
        item["voice"] = voice
        size = output_file.stat().st_size
        print(f"  [{idx:02d}/{total:02d}] ✅ {item_id:<30} → {output_file.name} ({size:,} bytes)")
        print(f"         TTS text: {tts_text[:75]}")
        return True
    except Exception as e:
        print(f"  [{idx:02d}/{total:02d}] ❌ {item_id:<30} Error: {e}")
        return False


async def main():
    with open(MANIFEST_PATH, "r", encoding="utf-8") as f:
        manifest = json.load(f)

    items = manifest.get("items", [])
    allah_items = [
        item
        for item in items
        if any(kw in item.get("arabic", "") for kw in ("الله", "اللَّه", "ٱللَّه"))
    ]

    total = len(allah_items)
    print(f"🔊 Menjana semula {total} fail audio dengan Microsoft Edge Neural TTS (MSA Standard)...")
    print(f"🎙️ Suara Lelaki : {VOICES['male']}")
    print(f"🎙️ Suara Wanita : {VOICES['female']}\n")

    success = 0
    for idx, item in enumerate(allah_items, 1):
        ok = await regenerate_item(item, idx, total)
        if ok:
            success += 1

    with open(MANIFEST_PATH, "w", encoding="utf-8") as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    print("\n" + "=" * 60)
    print("📊 KEPUTUSAN JANA SEMULA AUDIO")
    print("=" * 60)
    print(f"✅ Berjaya : {success} / {total}")
    print(f"❌ Gagal   : {total - success}")
    print(f"💾 Manifest: {MANIFEST_PATH}")
    print("=" * 60)


if __name__ == "__main__":
    asyncio.run(main())
