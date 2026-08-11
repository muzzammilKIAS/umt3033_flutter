#!/usr/bin/env python3
"""Development-time extractor: lecturer answer guide -> per-unit model answers.

Source: answer_output/Dalil_Al-Ijabat_UMT3033_Final.docx (marked "نسخة
المحاضر - ليست للتوزيع على الطلبة" -- lecturer's copy, not for distribution
to students). This script only pulls out the "نموذج الإجابة:" / "الإجابة:"
answer blocks, grouped per unit, IN DOCUMENT ORDER. It deliberately does NOT
attempt to bind each answer to one specific exercise sub-question -- the
guide has no exercise-numbered anchors to do that reliably, and a wrong
one-to-one guess would misattribute an answer, which is worse than not
attaching it at all. Instead the app shows all of a unit's model answers
together, behind an explicit "reveal" action, framed as lecturer guidance --
never as an auto-grading key, and never exposed to students by default.

Also intentionally excluded: "إرشادات التقييم:" (evaluation rubric guidance
for open communicative activities like pair-practice role-play) -- rubric
text, not a model answer, and open-ended activities must never look like
they have one compulsory answer.
"""
import json
import sys
from pathlib import Path

import docx

sys.path.insert(0, str(Path(__file__).resolve().parent))
from extract_units import bare, iter_block_items, _ORDINALS_SORTED, _WAHDA  # noqa: E402

SRC = Path("/Users/sufyanthawry/Desktop/UMT3033_ENRICHMENT/answer_output/Dalil_Al-Ijabat_UMT3033_Final.docx")
OUT = Path(__file__).resolve().parent.parent / "assets" / "data" / "answer_guide.json"

_ANSWER_LABELS = [bare("نَمُوذَجُ الْإِجَابَةِ"), bare("الْإِجَابَةُ")]


def unit_no_from_heading(text):
    b = bare(text)
    if not b.startswith(_WAHDA):
        return None
    for ord_bare, n in _ORDINALS_SORTED:
        if ord_bare in b:
            return n
    return None


def main():
    document = docx.Document(str(SRC))
    result = {}
    cur_unit = None
    for item in iter_block_items(document):
        if hasattr(item, "rows"):  # Table
            rows = item.rows
            if len(rows) != 1 or len(rows[0].cells) != 1:
                continue
            text = rows[0].cells[0].text.strip()
            b = bare(text)
            for label in _ANSWER_LABELS:
                if b.startswith(label):
                    if cur_unit is None:
                        break
                    # strip the label prefix for display
                    content = text.split(":", 1)[-1].strip() if ":" in text[:40] else text
                    result.setdefault(str(cur_unit), []).append(content)
                    break
        else:  # Paragraph
            no = unit_no_from_heading(item.text)
            if no:
                cur_unit = no

    OUT.parent.mkdir(parents=True, exist_ok=True)
    OUT.write_text(json.dumps(result, ensure_ascii=False, indent=2), encoding="utf-8")
    total = sum(len(v) for v in result.values())
    print(f"Units with model answers: {len(result)}/14, total answer blocks: {total}")
    for k in sorted(result, key=int):
        print(f"  unit {k}: {len(result[k])} answers")


if __name__ == "__main__":
    main()
