#!/usr/bin/env python3
"""Assemble the final assets/data/units.json, glossary.json and references.json
from units_extracted.json (DOCX extraction) + illustrations.json (image mapping).

Assigns stable per-item ids (uNN-vocab-NNN, uNN-dialog-NNN, ...) used later by
the audio manifest / TTS generation script and by the app's audio lookup.
"""
import json
from pathlib import Path

DATA_DIR = Path(__file__).resolve().parent.parent / "assets" / "data"


def load(name):
    return json.load(open(DATA_DIR / name, encoding="utf-8"))


def main():
    units = load("units_extracted.json")
    illustrations = load("illustrations.json")

    glossary = []
    seen_terms = set()
    references = []
    seen_refs = set()

    for u in units:
        no = u["id"]
        prefix = f"u{no:02d}"

        for i, v in enumerate(u["vocab"], start=1):
            v["id"] = f"{prefix}-vocab-{i:03d}"
            v["unitId"] = no
            key = v["arabic"].strip()
            if key and key not in seen_terms:
                seen_terms.add(key)
                glossary.append({
                    "id": v["id"],
                    "termAr": v["arabic"],
                    "transliteration": v.get("transliteration", ""),
                    "term": v["meaning"],
                    "unitId": no,
                })

        for i, e in enumerate(u["importantExpressions"], start=1):
            e["id"] = f"{prefix}-expr-{i:03d}"

        for i, d in enumerate(u["dialog"], start=1):
            d["id"] = f"{prefix}-dialog-{i:03d}"
        for i, d in enumerate(u["expandedDialog"], start=1):
            d["id"] = f"{prefix}-expdialog-{i:03d}"

        for i, item in enumerate(u["assessmentItems"], start=1):
            pass  # assessmentItems stay plain strings; ids assigned at render time (uNN-assess-i)

        img = illustrations.get(str(no))
        u["illustration"] = img[0] if img else None

        for src, text, kind in [
            (u.get("hadithSource", ""), u.get("hadithAr", ""), "hadith"),
            (u.get("ayahSource", ""), u.get("ayahAr", ""), "ayah"),
        ]:
            if src and src not in seen_refs:
                seen_refs.add(src)
                references.append({"kind": kind, "sourceAr": src, "unitId": no, "textAr": text})

    with open(DATA_DIR / "units.json", "w", encoding="utf-8") as f:
        json.dump(units, f, ensure_ascii=False, indent=2)
    with open(DATA_DIR / "glossary.json", "w", encoding="utf-8") as f:
        json.dump(glossary, f, ensure_ascii=False, indent=2)
    with open(DATA_DIR / "references.json", "w", encoding="utf-8") as f:
        json.dump(references, f, ensure_ascii=False, indent=2)

    print(f"units.json: {len(units)} units")
    print(f"glossary.json: {len(glossary)} unique terms")
    print(f"references.json: {len(references)} sources")


if __name__ == "__main__":
    main()
