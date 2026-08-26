#!/usr/bin/env python3
"""
Analisis dan betulkan gender untuk dialog audio berdasarkan konteks Arab
"""

import json
import re
from pathlib import Path

PROJECT_ROOT = Path(__file__).parent.parent
UNITS_PATH = PROJECT_ROOT / "assets/data/units.json"
MANIFEST_PATH = PROJECT_ROOT / "assets/data/audio-manifest.json"

# Pattern untuk detect gender dari teks Arab
FEMALE_PATTERNS = [
    r'تَفَضَّلِي',  # tafaddali (perempuan)
    r'أُخْتِي',     # ukhti (saudari)
    r'هَلْ مَعَكِ',  # hal ma'aki (dengan awak - perempuan)
    r'يُمْكِنُكِ',  # yumkinuki (boleh awak - perempuan)
    r'أَنْتِ',      # anti (awak - perempuan)
    r'كِ\b',        # suffix ki (awak - perempuan)
]

MALE_PATTERNS = [
    r'تَفَضَّلْ\b',  # tafaddal (lelaki)
    r'أَخِي',        # akhi (saudaraku)
    r'هَلْ مَعَكَ\b', # hal ma'aka (dengan awak - lelaki)
    r'يُمْكِنُكَ\b', # yumkinuka (boleh awak - lelaki)
    r'أَنْتَ',       # anta (awak - lelaki)
]

def detect_gender_from_text(text):
    """Detect gender dari konteks teks Arab"""
    # Check female patterns first (more specific)
    for pattern in FEMALE_PATTERNS:
        if re.search(pattern, text):
            return 'female'

    # Check male patterns
    for pattern in MALE_PATTERNS:
        if re.search(pattern, text):
            return 'male'

    # Default: alternate (dialog biasanya berganti-ganti)
    return None

def main():
    # Load units
    with open(UNITS_PATH, 'r', encoding='utf-8') as f:
        units = json.load(f)

    # Load manifest
    with open(MANIFEST_PATH, 'r', encoding='utf-8') as f:
        manifest = json.load(f)

    # Create lookup dict for manifest items
    manifest_dict = {item['id']: item for item in manifest['items']}

    corrections = []

    # Analyze each unit
    for unit in units:
        unit_id = unit.get('id', 0)

        # Main dialog
        dialog = unit.get('dialog', [])
        for i, d in enumerate(dialog):
            item_id = f"u{unit_id:02d}-dialog-{i+1:03d}"
            arabic = d.get('arabic', '')

            detected = detect_gender_from_text(arabic)

            if item_id in manifest_dict:
                current_gender = manifest_dict[item_id].get('gender', 'male')

                if detected and detected != current_gender:
                    corrections.append({
                        'id': item_id,
                        'unit': unit_id,
                        'type': 'dialog',
                        'text': arabic[:60],
                        'current_gender': current_gender,
                        'detected_gender': detected,
                        'reason': 'Context analysis'
                    })

        # Expanded dialog
        exp_dialog = unit.get('expandedDialog', [])
        for i, d in enumerate(exp_dialog):
            item_id = f"u{unit_id:02d}-expdialog-{i+1:03d}"
            arabic = d.get('arabic', '')

            detected = detect_gender_from_text(arabic)

            if item_id in manifest_dict:
                current_gender = manifest_dict[item_id].get('gender', 'female')

                if detected and detected != current_gender:
                    corrections.append({
                        'id': item_id,
                        'unit': unit_id,
                        'type': 'expdialog',
                        'text': arabic[:60],
                        'current_gender': current_gender,
                        'detected_gender': detected,
                        'reason': 'Context analysis'
                    })

    # Print report
    print("="*70)
    print("ANALISIS GENDER UNTUK DIALOG HIWAR")
    print("="*70)
    print(f"Total dialog diperiksa: {sum(len(u.get('dialog', [])) + len(u.get('expandedDialog', [])) for u in units)}")
    print(f"Pembetulan diperlukan: {len(corrections)}\n")

    if corrections:
        print("Dialog yang perlu dibetulkan:\n")
        for c in corrections:
            print(f"  [{c['id']}]")
            print(f"    Unit {c['unit']} | {c['type']}")
            print(f"    Teks: {c['text']}")
            print(f"    Gender semasa: {c['current_gender']} → Sepatutnya: {c['detected_gender']}")
            print(f"    Sebab: {c['reason']}\n")
    else:
        print("✅ Tiada pembetulan diperlukan - semua gender sudah betul!\n")

    # Save corrections to JSON for next script
    corrections_path = PROJECT_ROOT / "scripts/gender_corrections.json"
    with open(corrections_path, 'w', encoding='utf-8') as f:
        json.dump(corrections, f, ensure_ascii=False, indent=2)

    print(f"📝 Senarai pembetulan disimpan di: {corrections_path}")

if __name__ == "__main__":
    main()
