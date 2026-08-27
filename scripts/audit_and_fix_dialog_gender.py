#!/usr/bin/env python3
"""
Comprehensive script to audit and regenerate dialogue audio for male and female speakers
using Microsoft Edge Neural TTS.
"""

import asyncio
import json
import os
import re
from pathlib import Path
import edge_tts

PROJECT_ROOT = Path(__file__).parent.parent
UNITS_PATH = PROJECT_ROOT / "assets/data/units.json"
MANIFEST_PATH = PROJECT_ROOT / "assets/data/audio-manifest.json"
AUDIO_BASE_PATH = PROJECT_ROOT / "assets/audio"

VOICES = {
    "male": "ar-SA-HamedNeural",
    "female": "ar-SA-ZariyahNeural"
}

# Tentukan jantina untuk setiap unit hiwar:
# (role_A_gender, role_B_gender) di mana dialog ganjil (1, 3, 5...) = Role A, genap (2, 4, 6...) = Role B
# Atau berdasarkan address marker
UNIT_DIALOG_ROLES = {
    1: ("female", "male"),     # Pensyarah Perempuan (P) & Pelajar Lelaki (L)
    2: ("male", "male"),       # Pegawai (L) & Pelanggan Lelaki (L)
    3: ("female", "female"),   # Pegawai Bank (P - الْمُوَظَّفَةُ) & Pelanggan Perempuan (P - الْعَمِيلَةُ)
    5: ("male", "male"),       # Penjual (L) & Pembeli Lelaki (L - كَيْفَ أُسَاعِدُكَ)
    6: ("male", "female"),     # Pegawai Pelaburan (L) & Pelabur Wanita (P - كَيْفَ أُسَاعِدُكِ)
    7: ("male", "female"),     # Pegawai Syariah (L) & Pelanggan Wanita (P - كَيْفَ أُسَاعِدُكِ)
    8: ("female", "male"),     # Pegawai Takaful Wanita (P) & Pelanggan Lelaki (L)
    9: ("male", "male"),       # Pegawai Baitulmal (L) & Pemohon Lelaki (L)
    10: ("male", "female"),    # Pegawai Zakat (L) & Pembayar Zakat Wanita (P - كَيْفَ أُسَاعِدُكِ)
    11: ("male", "male"),      # Pegawai Pajak Gadai (L) & Pelanggan Lelaki (L)
    12: ("male", "female"),    # Jurubahasa/Tukar Wang (L) & Pelanggan Wanita (P - كَيْفَ أُسَاعِدُكِ)
    13: ("male", "male"),      # Dua rakan pelajar lelaki berdiskusi
    14: ("female", "male"),    # Pensyarah/Tutor Wanita (P) & Pelajar Lelaki (L)
}

async def generate_audio_file(arabic: str, voice: str, output_path: Path, sem: asyncio.Semaphore):
    async with sem:
        try:
            output_path.parent.mkdir(parents=True, exist_ok=True)
            communicate = edge_tts.Communicate(arabic, voice)
            await communicate.save(str(output_path))
            return True
        except Exception as e:
            print(f"❌ Error generating {output_path.name}: {e}")
            return False

async def main():
    with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
        manifest = json.load(f)

    with open(UNITS_PATH, 'r', encoding='utf-8') as f:
        units = json.load(f)

    # Build manifest lookup
    manifest_items = {item["id"]: item for item in manifest["items"]}

    sem = asyncio.Semaphore(10)
    tasks = []
    updated_items = []

    print("="*70)
    print("🔍 AUDIT & REGENERATE DIALOGUE GENDER AUDIOS (EDGE NEURAL TTS)")
    print("="*70)

    for unit in units:
        unit_id = unit.get("id")
        role_a_gender, role_b_gender = UNIT_DIALOG_ROLES.get(unit_id, ("male", "female"))
        unit_str = f"unit-{unit_id:02d}"

        print(f"\n📌 Unit {unit_id:02d}: Role A={role_a_gender}, Role B={role_b_gender}")

        # Main Dialog
        dialog = unit.get("dialog", [])
        for i, d in enumerate(dialog):
            item_id = f"u{unit_id:02d}-dialog-{i+1:03d}"
            # Ganjil (i=0,2,4..) -> Role A; Genap (i=1,3,5..) -> Role B
            expected_gender = role_a_gender if (i % 2 == 0) else role_b_gender
            arabic = d.get("arabic", "")

            item = manifest_items.get(item_id)
            if not item:
                item = {
                    "id": item_id,
                    "unitId": unit_id,
                    "section": "dialog",
                    "arabic": arabic,
                }
                manifest["items"].append(item)

            item["gender"] = expected_gender
            voice = VOICES[expected_gender]
            rel_path = f"{unit_str}/{expected_gender}/{item_id}-{expected_gender}.mp3"
            item["path"] = f"/audio/{rel_path}"
            item["status"] = "generated"
            item["ttsEngine"] = "Microsoft Edge Neural TTS"
            item["voice"] = voice

            output_path = AUDIO_BASE_PATH / rel_path
            print(f"   [{item_id}] ({expected_gender.upper():<6}) Voice: {voice} → {output_path.name}")
            tasks.append(generate_audio_file(arabic, voice, output_path, sem))
            updated_items.append(item)

        # Expanded Dialog
        exp_dialog = unit.get("expandedDialog", [])
        for i, d in enumerate(exp_dialog):
            item_id = f"u{unit_id:02d}-expdialog-{i+1:03d}"
            # Expanded dialog: alternating as well
            expected_gender = role_a_gender if (i % 2 == 0) else role_b_gender
            arabic = d.get("arabic", "")

            item = manifest_items.get(item_id)
            if not item:
                item = {
                    "id": item_id,
                    "unitId": unit_id,
                    "section": "expdialog",
                    "arabic": arabic,
                }
                manifest["items"].append(item)

            item["gender"] = expected_gender
            voice = VOICES[expected_gender]
            rel_path = f"{unit_str}/{expected_gender}/{item_id}-{expected_gender}.mp3"
            item["path"] = f"/audio/{rel_path}"
            item["status"] = "generated"
            item["ttsEngine"] = "Microsoft Edge Neural TTS"
            item["voice"] = voice

            output_path = AUDIO_BASE_PATH / rel_path
            print(f"   [{item_id}] ({expected_gender.upper():<6}) Voice: {voice} → {output_path.name}")
            tasks.append(generate_audio_file(arabic, voice, output_path, sem))
            updated_items.append(item)

    # Run generation
    print(f"\n🚀 Menjana semula {len(tasks)} fail audio dialog...")
    results = await asyncio.gather(*tasks)
    success = sum(1 for r in results if r)

    # Save manifest
    with open(MANIFEST_PATH, 'w', encoding='utf-8') as f:
        json.dump(manifest, f, ensure_ascii=False, indent=2)

    print("\n" + "="*70)
    print(f"✅ Selesai! {success}/{len(tasks)} fail audio dialog telah dijana dengan suara yang tepat.")
    print("="*70)

if __name__ == "__main__":
    asyncio.run(main())
