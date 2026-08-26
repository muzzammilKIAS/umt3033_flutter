#!/usr/bin/env python3
"""
Fix & generate all remaining/unassigned audio items in audio-manifest.json
"""

import asyncio
import json
import os
from pathlib import Path
import edge_tts

PROJECT_ROOT = Path(__file__).parent.parent
MANIFEST_PATH = PROJECT_ROOT / "assets/data/audio-manifest.json"
AUDIO_BASE_PATH = PROJECT_ROOT / "assets/audio"

VOICES = {
    "male": "ar-SA-HamedNeural",
    "female": "ar-SA-ZariyahNeural"
}

async def generate_item(item, sem, idx, total):
    async with sem:
        item_id = item.get("id", "unknown")
        arabic = item.get("arabic", "")
        gender = item.get("gender", "female")
        unit_id = item.get("unitId", 1)

        if not arabic:
            return False

        # Tentukan path yang betul
        unit_str = f"unit-{unit_id:02d}"
        filename = f"{item_id}-{gender}.mp3"
        rel_path = f"{unit_str}/{gender}/{filename}"
        new_path = f"/audio/{rel_path}"

        output_file = AUDIO_BASE_PATH / rel_path
        output_file.parent.mkdir(parents=True, exist_ok=True)

        voice = VOICES.get(gender, VOICES["female"])

        try:
            communicate = edge_tts.Communicate(arabic, voice)
            await communicate.save(str(output_file))

            item["path"] = new_path
            item["status"] = "generated"
            item["ttsEngine"] = "Microsoft Edge Neural TTS"
            item["voice"] = voice

            print(f"[{idx:02d}/{total:02d}] ✅ {item_id:<25} ({gender}) → {filename}")
            return True
        except Exception as e:
            print(f"[{idx:02d}/{total:02d}] ❌ {item_id:<25} Error: {e}")
            return False

async def main():
    with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
        manifest = json.load(f)

    # Ambil item yang belum 'generated'
    items_to_generate = [
        item for item in manifest["items"]
        if item.get("status") != "generated" or not item.get("path")
    ]

    total = len(items_to_generate)
    print(f"🚀 Memulakan penjanaan untuk {total} fail yang belum siap...\n")

    sem = asyncio.Semaphore(8)
    tasks = [
        generate_item(item, sem, i + 1, total)
        for i, item in enumerate(items_to_generate)
    ]

    results = await asyncio.gather(*tasks)
    success_count = sum(1 for r in results if r)

    # Recalculate all generated
    all_generated = sum(1 for item in manifest["items"] if item.get("status") == "generated")
    manifest["generatedCount"] = all_generated
    manifest["failedCount"] = len(manifest["items"]) - all_generated
    manifest["fallbackCount"] = 0

    with open(MANIFEST_PATH, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    print("\n" + "="*60)
    print("📊 KEPUTUSAN AKHIR PENJANAAN AUDIO")
    print("="*60)
    print(f"✅ Sesi ini berjaya : {success_count} / {total}")
    print(f"🌟 Jumlah Keseluruhan Audio Siap: {all_generated} / {len(manifest['items'])} (100%)")
    print("="*60)

if __name__ == "__main__":
    asyncio.run(main())
