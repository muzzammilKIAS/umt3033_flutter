#!/usr/bin/env python3
"""
Script untuk regenerate semua audio dalam UMT3033 menggunakan Microsoft Edge Neural TTS
Menyokong pemprosesan serentak (concurrent) untuk kelajuan maksimum.

Usage:
    python3 scripts/regenerate_audio_edge_tts.py [--limit N] [--concurrency C]
"""

import asyncio
import json
import os
import sys
from pathlib import Path
import edge_tts

# Konfigurasi
SCRIPT_DIR = Path(__file__).parent
PROJECT_ROOT = SCRIPT_DIR.parent
MANIFEST_PATH = PROJECT_ROOT / "assets/data/audio-manifest.json"
AUDIO_BASE_PATH = PROJECT_ROOT / "assets/audio"

# Suara Microsoft Edge Neural TTS
VOICES = {
    "male": "ar-SA-HamedNeural",      # Lelaki - Arab Saudi Standard
    "female": "ar-SA-ZariyahNeural"   # Perempuan - Arab Saudi Natural
}


async def generate_single_item(item, sem, idx, total):
    """Generate satu item audio dengan semaphore untuk concurrency"""
    async with sem:
        item_id = item.get("id", "unknown")
        arabic = item.get("arabic", "")
        gender = item.get("gender", "male")
        old_path = item.get("path", "")

        if not arabic:
            print(f"[{idx}/{total}] ⚠️  Skip {item_id} (tiada teks)")
            return False

        # Output path (.mp3)
        new_path = old_path.replace(".wav", ".mp3")
        rel_path = new_path.lstrip("/")
        if rel_path.startswith("audio/"):
            rel_path = rel_path[6:]
        output_file = AUDIO_BASE_PATH / rel_path

        output_file.parent.mkdir(parents=True, exist_ok=True)

        voice = VOICES.get(gender, VOICES["male"])

        try:
            communicate = edge_tts.Communicate(arabic, voice)
            await communicate.save(str(output_file))

            item["path"] = new_path
            item["status"] = "generated"
            item["ttsEngine"] = "Microsoft Edge Neural TTS"
            item["voice"] = voice

            print(f"[{idx:03d}/{total:03d}] ✅ {item_id:<25} ({gender}) → {output_file.name}")
            return True
        except Exception as e:
            print(f"[{idx:03d}/{total:03d}] ❌ {item_id:<25} Error: {e}")
            return False


async def main_async(limit=None, concurrency=8):
    # Restore original manifest if backup exists from test
    backup_path = MANIFEST_PATH.with_suffix(".json.backup")
    if backup_path.exists():
        with open(backup_path, 'r', encoding='utf-8') as f:
            manifest = json.load(f)
    else:
        with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
            manifest = json.load(f)

    items = manifest.get("items", [])
    total_all = len(items)

    if limit:
        items = items[:limit]

    total = len(items)
    print(f"🚀 Memulakan penjanaan {total} fail audio dengan Microsoft Edge Neural TTS...")
    print(f"⚡ Concurrency: {concurrency} proses serentak")
    print(f"🎙️  Suara Lelaki: {VOICES['male']}")
    print(f"🎙️  Suara Perempuan: {VOICES['female']}\n")

    sem = asyncio.Semaphore(concurrency)
    tasks = [
        generate_single_item(item, sem, i + 1, total)
        for i, item in enumerate(items)
    ]

    results = await asyncio.gather(*tasks)

    success_count = sum(1 for r in results if r)
    failed_count = total - success_count

    manifest["ttsModel"] = f"Microsoft Edge Neural TTS ({VOICES['male']} & {VOICES['female']})"
    manifest["generatedCount"] = success_count
    manifest["failedCount"] = failed_count
    manifest["fallbackCount"] = 0

    # Save manifest
    with open(MANIFEST_PATH, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    print("\n" + "="*60)
    print("📊 KEPUTUSAN PENJANAAN AUDIO")
    print("="*60)
    print(f"✅ Berjaya  : {success_count} / {total}")
    print(f"❌ Gagal    : {failed_count}")
    print(f"💾 Manifest : {MANIFEST_PATH}")
    print("="*60)


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, help="Limit items")
    parser.add_argument("--concurrency", type=int, default=8, help="Concurrent downloads")
    args = parser.parse_args()

    asyncio.run(main_async(limit=args.limit, concurrency=args.concurrency))
