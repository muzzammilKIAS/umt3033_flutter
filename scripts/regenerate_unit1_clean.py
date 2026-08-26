#!/usr/bin/env python3
"""
Regenerate ALL audio files for Unit 1 from scratch using Microsoft Edge Neural TTS.
Unit 1 Roles:
- Role A (Lines 1, 3, 5): Pensyarah Wanita -> ar-SA-ZariyahNeural (Female)
- Role B (Lines 2, 4, 6): Pelajar Lelaki  -> ar-SA-HamedNeural (Male)
- Vocab / Reading / Hadith / Assessment -> ar-SA-HamedNeural (Male)
"""

import asyncio
import json
import os
from pathlib import Path
import edge_tts

PROJECT_ROOT = Path(__file__).parent.parent
UNITS_PATH = PROJECT_ROOT / "assets/data/units.json"
MANIFEST_PATH = PROJECT_ROOT / "assets/data/audio-manifest.json"
AUDIO_BASE_PATH = PROJECT_ROOT / "assets/audio/unit-01"

VOICE_FEMALE = "ar-SA-ZariyahNeural"
VOICE_MALE = "ar-SA-HamedNeural"

async def generate_file(arabic: str, voice: str, output_path: Path, sem: asyncio.Semaphore):
    async with sem:
        try:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            # Edge TTS with high quality
            communicate = edge_tts.Communicate(arabic, voice)
            await communicate.save(str(output_path))
            size = output_path.stat().st_size
            print(f"✅ Generated: {output_path.name:<35} | Voice: {voice} | Size: {size} B")
            return True
        except Exception as e:
            print(f"❌ Error {output_path.name}: {e}")
            return False

async def main():
    with open(UNITS_PATH, 'r', encoding='utf-8') as f:
        units = json.load(f)

    unit1 = next((u for u in units if u.get("id") == 1), None)
    if not unit1:
        print("Unit 1 not found!")
        return

    with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
        manifest = json.load(f)

    manifest_dict = {item["id"]: item for item in manifest["items"]}

    sem = asyncio.Semaphore(5)
    tasks = []

    print("=" * 70)
    print("🚀 MENJANA SEMULA KESEMUA AUDIO UNIT 1 DARI AWAL (EDGE NEURAL TTS)")
    print("=" * 70)

    # 1. Vocab (12 items - Male voice)
    print("\n--- 1. KOSAKATA (VOCAB) ---")
    for i, vocab in enumerate(unit1.get("vocabulary", [])):
        item_id = f"u01-vocab-{i+1:03d}"
        arabic = vocab.get("arabic", "")
        gender = "male"
        voice = VOICE_MALE
        rel_path = f"unit-01/male/{item_id}-male.mp3"
        out_file = PROJECT_ROOT / "assets/audio" / rel_path

        item = manifest_dict.get(item_id, {"id": item_id, "unitId": 1, "section": "vocab"})
        item.update({
            "arabic": arabic,
            "gender": gender,
            "path": f"/audio/{rel_path}",
            "status": "generated",
            "ttsEngine": "Microsoft Edge Neural TTS",
            "voice": voice
        })
        manifest_dict[item_id] = item
        tasks.append(generate_file(arabic, voice, out_file, sem))

    # 2. Main Dialog (6 lines: 1,3,5 Female Lecturer; 2,4,6 Male Student)
    print("\n--- 2. DIALOG UTAMA (PENSYARAH WANITA ↔ PELAJAR LELAKI) ---")
    for i, d in enumerate(unit1.get("dialog", [])):
        item_id = f"u01-dialog-{i+1:03d}"
        arabic = d.get("arabic", "")
        # i=0,2,4 -> Pensyarah Wanita (Female)
        # i=1,3,5 -> Pelajar Lelaki (Male)
        is_female = (i % 2 == 0)
        gender = "female" if is_female else "male"
        voice = VOICE_FEMALE if is_female else VOICE_MALE
        role_name = "Pensyarah (P)" if is_female else "Pelajar (L)"

        rel_path = f"unit-01/{gender}/{item_id}-{gender}.mp3"
        out_file = PROJECT_ROOT / "assets/audio" / rel_path

        print(f"[{item_id}] {role_name:<15} -> {gender.upper()} ({voice})")
        item = manifest_dict.get(item_id, {"id": item_id, "unitId": 1, "section": "dialog"})
        item.update({
            "arabic": arabic,
            "gender": gender,
            "path": f"/audio/{rel_path}",
            "status": "generated",
            "ttsEngine": "Microsoft Edge Neural TTS",
            "voice": voice
        })
        manifest_dict[item_id] = item
        tasks.append(generate_file(arabic, voice, out_file, sem))

    # 3. Expanded Dialog (6 lines: 1,3,5 Female Lecturer; 2,4,6 Male Student)
    print("\n--- 3. DIALOG TAMBAHAN / EXPANDED (PENSYARAH WANITA ↔ PELAJAR LELAKI) ---")
    for i, d in enumerate(unit1.get("expandedDialog", [])):
        item_id = f"u01-expdialog-{i+1:03d}"
        arabic = d.get("arabic", "")
        is_female = (i % 2 == 0)
        gender = "female" if is_female else "male"
        voice = VOICE_FEMALE if is_female else VOICE_MALE
        role_name = "Pensyarah (P)" if is_female else "Pelajar (L)"

        rel_path = f"unit-01/{gender}/{item_id}-{gender}.mp3"
        out_file = PROJECT_ROOT / "assets/audio" / rel_path

        print(f"[{item_id}] {role_name:<15} -> {gender.upper()} ({voice})")
        item = manifest_dict.get(item_id, {"id": item_id, "unitId": 1, "section": "expdialog"})
        item.update({
            "arabic": arabic,
            "gender": gender,
            "path": f"/audio/{rel_path}",
            "status": "generated",
            "ttsEngine": "Microsoft Edge Neural TTS",
            "voice": voice
        })
        manifest_dict[item_id] = item
        tasks.append(generate_file(arabic, voice, out_file, sem))

    # 4. Reading
    print("\n--- 4. BACAAN (READING) ---")
    reading_ar = unit1.get("reading", {}).get("arabic", "")
    if reading_ar:
        item_id = "u01-reading"
        rel_path = f"unit-01/male/{item_id}-male.mp3"
        out_file = PROJECT_ROOT / "assets/audio" / rel_path
        item = manifest_dict.get(item_id, {"id": item_id, "unitId": 1, "section": "reading"})
        item.update({
            "arabic": reading_ar,
            "gender": "male",
            "path": f"/audio/{rel_path}",
            "status": "generated",
            "ttsEngine": "Microsoft Edge Neural TTS",
            "voice": VOICE_MALE
        })
        manifest_dict[item_id] = item
        tasks.append(generate_file(reading_ar, VOICE_MALE, out_file, sem))

    # 5. Hadith
    print("\n--- 5. HADIS ---")
    hadith_ar = unit1.get("hadith", {}).get("arabic", "")
    if hadith_ar:
        item_id = "u01-hadith"
        rel_path = f"unit-01/male/{item_id}-male.mp3"
        out_file = PROJECT_ROOT / "assets/audio" / rel_path
        item = manifest_dict.get(item_id, {"id": item_id, "unitId": 1, "section": "hadith"})
        item.update({
            "arabic": hadith_ar,
            "gender": "male",
            "path": f"/audio/{rel_path}",
            "status": "generated",
            "ttsEngine": "Microsoft Edge Neural TTS",
            "voice": VOICE_MALE
        })
        manifest_dict[item_id] = item
        tasks.append(generate_file(hadith_ar, VOICE_MALE, out_file, sem))

    # 6. Assessment (4 questions)
    print("\n--- 6. PENILAIAN (ASSESSMENT) ---")
    for i, q in enumerate(unit1.get("assessment", [])):
        item_id = f"u01-assess-{i:03d}"
        q_ar = q.get("questionAr", "")
        if q_ar:
            rel_path = f"unit-01/male/{item_id}-male.mp3"
            out_file = PROJECT_ROOT / "assets/audio" / rel_path
            item = manifest_dict.get(item_id, {"id": item_id, "unitId": 1, "section": "assessment"})
            item.update({
                "arabic": q_ar,
                "gender": "male",
                "path": f"/audio/{rel_path}",
                "status": "generated",
                "ttsEngine": "Microsoft Edge Neural TTS",
                "voice": VOICE_MALE
            })
            manifest_dict[item_id] = item
            tasks.append(generate_file(q_ar, VOICE_MALE, out_file, sem))

    print(f"\n🚀 Menjana {len(tasks)} fail audio Unit 1 secara serentak...")
    results = await asyncio.gather(*tasks)
    success = sum(1 for r in results if r)

    # Save manifest
    manifest["items"] = list(manifest_dict.values())
    with open(MANIFEST_PATH, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    print("\n" + "=" * 70)
    print(f"🎉 SELESAI! {success}/{len(tasks)} fail audio Unit 1 telah berjaya dijana.")
    print("=" * 70)

if __name__ == "__main__":
    asyncio.run(main())
