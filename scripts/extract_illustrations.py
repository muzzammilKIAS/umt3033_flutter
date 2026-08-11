#!/usr/bin/env python3
"""Development-time extractor: approved hiwar illustrations -> assets/images/units/.

Source: the *_With_Images_Final.docx siblings of the FINAL edited module (the
text-only *_Final.docx used by extract_units.py strips images for fast parsing).
Images are mapped to units by DOCUMENT ORDER position relative to each unit's
title table -- the same walk extract_units.py uses -- so no image is invented
or guessed; if a unit has zero embedded images none is assigned.
"""
import json
import sys
from pathlib import Path

import docx
from docx.oxml.ns import qn

sys.path.insert(0, str(Path(__file__).resolve().parent))
from extract_units import iter_block_items, is_unit_title_table  # noqa: E402

SRC_DIR = Path("/Users/sufyanthawry/Desktop/UMT3033_ENRICHMENT/output")
OUT_IMG_DIR = Path(__file__).resolve().parent.parent / "assets" / "images" / "units"
OUT_DATA = Path(__file__).resolve().parent.parent / "assets" / "data" / "illustrations.json"

FILES = [
    "Topik_1_dan_2_Enriched_With_Images_Final.docx",
    "Topik_3_dan_4_Enriched_With_Images_Final.docx",
    "Topik_5_dan_6_Enriched_With_Images_Final.docx",
    "Topik_7_dan_8_Enriched_With_Images_Final.docx",
    "Topik_9_dan_10_Enriched_With_Images_Final.docx",
    "Topik_11_dan_12_Enriched_With_Images_Final.docx",
    "Topik_13_dan_14_Enriched_With_Images_Final.docx",
]

A_NS = "{http://schemas.openxmlformats.org/drawingml/2006/main}"
R_NS = "{http://schemas.openxmlformats.org/officeDocument/2006/relationships}"


def images_in_paragraph(paragraph, document):
    out = []
    for blip in paragraph._p.iter(qn("a:blip")):
        embed = blip.get(qn("r:embed"))
        if not embed:
            continue
        try:
            part = document.part.related_parts[embed]
        except KeyError:
            continue
        out.append(part)
    return out


def main():
    OUT_IMG_DIR.mkdir(parents=True, exist_ok=True)
    mapping = {}
    report = []
    for fname in FILES:
        path = SRC_DIR / fname
        if not path.exists():
            report.append(f"MISSING: {fname}")
            continue
        document = docx.Document(str(path))
        cur_unit = None
        count_for_unit = {}
        for item in iter_block_items(document):
            if hasattr(item, "rows"):  # Table
                title = is_unit_title_table(item)
                if title and title["unitNo"]:
                    cur_unit = title["unitNo"]
                continue
            # Paragraph
            if cur_unit is None:
                continue
            for part in images_in_paragraph(item, document):
                idx = count_for_unit.get(cur_unit, 0) + 1
                count_for_unit[cur_unit] = idx
                ext = part.partname.ext or "png"
                out_name = f"unit_{cur_unit:02d}_{idx}.{ext}"
                out_path = OUT_IMG_DIR / out_name
                out_path.write_bytes(part.blob)
                mapping.setdefault(str(cur_unit), []).append(f"assets/images/units/{out_name}")
                report.append(f"unit {cur_unit}: saved {out_name} ({len(part.blob)} bytes)")

    OUT_DATA.parent.mkdir(parents=True, exist_ok=True)
    with open(OUT_DATA, "w", encoding="utf-8") as f:
        json.dump(mapping, f, ensure_ascii=False, indent=2)
    print("\n".join(report))
    print(f"\nUnits with >=1 illustration: {len(mapping)}/14")
    print(f"Wrote {OUT_DATA}")


if __name__ == "__main__":
    main()
