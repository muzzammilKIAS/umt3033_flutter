#!/usr/bin/env python3
"""Development-time extractor: FINAL edited module DOCX -> assets/data/units JSON.

Source hierarchy (per project instructions):
  FINAL edited module = output/Topik_*_Enriched_Final.docx (text-only, no embedded
  images -> fast/reliable parsing). Illustrations are mapped separately from the
  *_With_Images_Final.docx siblings by scripts/extract_illustrations.py.

This script does NOT paraphrase or invent content. It walks the DOCX body in true
document order (paragraphs + tables interleaved) and:
  1. Segments the stream into the 14 units by their big title table.
  2. Segments each unit into an ordered list of "blocks" (faithful transcript --
     used by the app to render each unit's ACTUAL approved structure).
  3. Derives typed convenience fields (vocab, dialog w/ speaker gender, exercises,
     qawaid, reading, ayah/hadith, pair practice, summary, self-assessment) by
     pattern-matching on the section headings already present in the module --
     nothing is authored here, only structured.

Run: python3 scripts/extract_units.py
"""
import json
import re
import sys
import unicodedata
from pathlib import Path

import docx
from docx.oxml.ns import qn
from docx.table import Table
from docx.text.paragraph import Paragraph

SRC_DIR = Path("/Users/sufyanthawry/Desktop/UMT3033_ENRICHMENT/output")
OUT_DIR = Path(__file__).resolve().parent.parent / "assets" / "data"
REPORT_PATH = Path(__file__).resolve().parent.parent / "docs" / "_extract_report.txt"

FILES = [
    "Topik_1_dan_2_Enriched_Final.docx",
    "Topik_3_dan_4_Enriched_Final.docx",
    "Topik_5_dan_6_Enriched_Final.docx",
    "Topik_7_dan_8_Enriched_Final.docx",
    "Topik_9_dan_10_Enriched_Final.docx",
    "Topik_11_dan_12_Enriched_Final.docx",
    "Topik_13_dan_14_Enriched_Final.docx",
]

ARABIC_ORDINALS = {
    "الْأُولَى": 1, "الْأُولى": 1,
    "الثَّانِيَةُ": 2, "الثَّانِيَة": 2,
    "الثَّالِثَةُ": 3, "الثَّالِثَة": 3,
    "الرَّابِعَةُ": 4, "الرَّابِعَة": 4,
    "الْخَامِسَةُ": 5, "الْخَامِسَة": 5,
    "السَّادِسَةُ": 6, "السَّادِسَة": 6,
    "السَّابِعَةُ": 7, "السَّابِعَة": 7,
    "الثَّامِنَةُ": 8, "الثَّامِنَة": 8,
    "التَّاسِعَةُ": 9, "التَّاسِعَة": 9,
    "الْعَاشِرَةُ": 10, "الْعَاشِرَة": 10,
    "الْحَادِيَةَ عَشْرَةَ": 11,
    "الثَّانِيَةَ عَشْرَةَ": 12,
    "الثَّالِثَةَ عَشْرَةَ": 13,
    "الرَّابِعَةَ عَشْرَةَ": 14,
}


def strip_harakat(s: str) -> str:
    s = unicodedata.normalize("NFC", s or "")
    return "".join(c for c in s if unicodedata.category(c) != "Mn")


def norm(s: str) -> str:
    return re.sub(r"\s+", " ", (s or "")).strip()


def bare(s: str) -> str:
    """Harakat-stripped, whitespace-normalized text for robust heading matching
    (the source DOCX encodes identical-looking words with inconsistent diacritic
    ordering in different places, so exact-string matching is unreliable)."""
    return norm(strip_harakat(s or ""))


def iter_block_items(document):
    """Yield Paragraph/Table objects from the document body in true order."""
    body = document.element.body
    for child in body.iterchildren():
        if child.tag == qn("w:p"):
            yield Paragraph(child, document)
        elif child.tag == qn("w:tbl"):
            yield Table(child, document)


def table_rows(t: Table):
    """Row cells, de-duplicating horizontally-merged cells.

    python-docx's Row.cells repeats the same underlying <w:tc> element once per
    grid column it spans, so a merged header cell shows up 2-3x in a row. Track
    element identity to keep each physical cell exactly once.
    """
    rows = []
    for r in t.rows:
        seen = set()
        cells = []
        for c in r.cells:
            key = id(c._tc)
            if key in seen:
                continue
            seen.add(key)
            cells.append(norm(c.text))
        rows.append(cells)
    return rows


_ORDINALS_SORTED = sorted(
    ((bare(k), v) for k, v in ARABIC_ORDINALS.items()), key=lambda kv: -len(kv[0])
)
_WAHDA = bare("الْوَحْدَةُ")


def is_unit_title_table(t: Table):
    if len(t.rows) == 0 or len(t.rows[0].cells) != 1:
        return None
    lines = [norm(x) for x in t.rows[0].cells[0].text.split("\n") if norm(x)]
    if not lines:
        return None
    head_line = next((l for l in lines if bare(l).startswith(_WAHDA)), None)
    if head_line is None:
        return None
    head_bare = bare(head_line)
    unit_no = None
    for ord_bare, n in _ORDINALS_SORTED:
        if ord_bare in head_bare:
            unit_no = n
            break
    return {"unitNo": unit_no, "lines": lines}


HEADING_PATTERNS = [
    ("outcomes_hdr", "نَتَائِجُ التَّعَلُّمِ"),
    ("keyterms_hdr", "الْمُصْطَلَحَاتُ الرَّئِيسَةُ"),
    ("vocab_hdr", "الْمُفْرَدَاتُ الرَّئِيسَةُ"),
    ("expand_dialog_hdr", "نُوَسِّعُ الْحِوَارَ"),
    ("pair_practice_hdr", "تَدَرَّبْ مَعَ زَمِيلِكَ"),
    ("dialog_hdr", "الْحِوَارُ"),
    ("expr_hdr", "التَّعْبِيرَاتُ الْمُهِمَّةُ"),
    ("qawaid_hdr", "الْقَوَاعِدُ"),
    ("dict_usage_hdr", "طَرِيقَةُ اسْتِعْمَالِ الْمُعْجَمِ"),
    ("dict_examples_hdr", "أَمْثِلَةُ الْبَحْثِ"),
    ("reading_hdr", "النَّصُّ الْقِرَائِيُّ"),
    ("hadith_vocab_hdr", "مُفْرَدَاتُ الْحَدِيثِ"),
    ("verse_vocab_hdr", "مُفْرَدَاتُ الْآيَةِ"),
    ("ayah_hadith_hdr", "الْآيَةُ وَالْحَدِيثُ"),
    ("ayah_hdr", "الْآيَةُ الْقُرْآنِيَّةُ"),
    ("hadith_hdr", "الْحَدِيثُ"),
    ("activity_conditions_hdr", "شُرُوطُ الْحِوَارِ"),
    ("activity_conditions_hdr", "شُرُوطُ النَّشَاطِ"),
    ("activity_hdr", "نَشَاطُ الْحِوَارِ"),
    ("summary_hdr", "خُلَاصَةُ"),
    ("selfassess_hdr", "التَّقْوِيمُ الذَّاتِيُّ"),
    ("notes_hdr", "مُلَاحَظَاتِي"),
]


_HEADING_PATTERNS_BARE = [(kind, bare(pat)) for kind, pat in HEADING_PATTERNS]
_LEADING_INDEX_RE = re.compile(r"^[\s0-9٠-٩.,،\-–—:]+")


def _strip_leading_index(b: str) -> str:
    return _LEADING_INDEX_RE.sub("", b)


def classify_heading(cell0_text):
    b = _strip_leading_index(bare(cell0_text))
    for kind, pat in _HEADING_PATTERNS_BARE:
        if b.startswith(pat):
            return kind
    return None


AUX_PATTERNS = [
    ("learning_context", "مَوْقِفُ التَّعَلُّمِ"),
    ("pair_practice_note", "تَدَرَّبْ مَعَ زَمِيلِكَ"),
    ("exercise", "التَّمْرِينُ"),
    ("remember_note", "تَذَكَّرْ"),
    ("observe_note", "لَاحِظْ"),
    ("linguistic_note", "مُلَاحَظَةٌ لُغَوِيَّةٌ"),
    ("important_note", "مُلَاحَظَةٌ مُهِمَّةٌ"),
    ("precision_note", "مُلَاحَظَةٌ فِي الدِّقَّةِ"),
    ("general_note", "مُلَاحَظَةٌ"),
    ("lessons_learned", "الدُّرُوسُ الْمُسْتَفَادَةُ"),
    ("verse_vocab", "مُفْرَدَاتُ الْآيَةِ"),
    ("hadith_vocab", "مُفْرَدَاتُ الْحَدِيثِ"),
    ("reflect_discuss", "فَكِّرْ وَنَاقِشْ"),
    ("linguistic_analysis", "التَّحْلِيلُ اللُّغَوِيُّ"),
    ("activity_conditions", "شُرُوطُ الْحِوَارِ"),
    ("activity_conditions", "شُرُوطُ النَّشَاطِ"),
]


_AUX_PATTERNS_BARE = [(kind, pat, bare(pat)) for kind, pat in AUX_PATTERNS]
_EXERCISE_INTRO = bare("أَجِبْ عَنِ الْأَسْئِلَةِ")


def classify_aux(cell0_text):
    """Returns (kind, matched_pattern_text_for_prefix_split) or (None, None)."""
    b = bare(cell0_text)
    for kind, pat, patb in _AUX_PATTERNS_BARE:
        if b.startswith(patb) or patb in b[:60]:
            return kind, pat
    if b.startswith(_EXERCISE_INTRO):
        return "exercise", "أَجِبْ عَنِ الْأَسْئِلَةِ الْآتِيَةِ جَمِيعِهَا:"
    return None, None


def _tolerant_pattern(word_bare):
    return "".join(re.escape(c) + r"[ً-ٰٟـ]*" for c in word_bare)


_SOURCE_MARKERS = ["صحيح", "سورة", "سنن", "مسند", "رواه", "المصدر", "أخرجه", "متفق عليه"]
_SOURCE_RE = re.compile("|".join(_tolerant_pattern(bare(m)) for m in _SOURCE_MARKERS))
_MAKSUD_MARKERS_AR = ["الترجمة"]
_MAKSUD_RE = re.compile(
    r"(?:[Mm]aksud|[Tt]erjemahan)\s*[:：]?\s*|"
    + "|".join(_tolerant_pattern(bare(m)) for m in _MAKSUD_MARKERS_AR)
)


def split_hadith_block(raw_text):
    """DOCX cells get whitespace-flattened by table_rows(), so a hadith/ayah cell
    like 'ARABIC_TEXT SOURCE Maksud: MALAY' (or 'ARABIC Maksud: MALAY SOURCE',
    the module uses both orders) has no newlines left to split on. Locate the two
    markers wherever they fall and slice around them instead of assuming order."""
    mm = _MAKSUD_RE.search(raw_text)
    sm = _SOURCE_RE.search(raw_text)
    markers = []
    if mm:
        markers.append(("maksud", mm.start(), mm.end()))
    if sm:
        markers.append(("source", sm.start(), sm.end()))
    if not markers:
        return raw_text.strip(), "", ""
    markers.sort(key=lambda m: m[1])
    arabic = raw_text[: markers[0][1]].strip()
    out = {"maksud": "", "source": ""}
    for i, (label, _s, e) in enumerate(markers):
        end = markers[i + 1][1] if i + 1 < len(markers) else len(raw_text)
        content = raw_text[e:end].strip(" :：").strip("\"'“”‘’").rstrip(".").strip()
        out[label] = content
    return arabic, out["source"], out["maksud"]


def split_off_prefix(raw_text, pattern):
    """Split 'HEADING body...' into (heading, body) by consuming whole words
    until their harakat-stripped length matches the pattern's, regardless of
    whether the source used a newline or a plain space after the heading."""
    pattern_b = bare(pattern)
    words = raw_text.split()
    acc = ""
    i = 0
    while i < len(words) and len(bare(acc)) < len(pattern_b):
        acc = (acc + " " + words[i]).strip()
        i += 1
    return " ".join(words[:i]), " ".join(words[i:])


def split_speaker(arabic_line, malay_line):
    """Split 'SPEAKER: utterance' into (speakerAr, utteranceAr, speakerMs, utteranceMs)."""
    a_speaker, a_rest = "", arabic_line
    if ":" in arabic_line:
        a_speaker, a_rest = arabic_line.split(":", 1)
        a_speaker, a_rest = norm(a_speaker), norm(a_rest)
    m_speaker, m_rest = "", malay_line
    if ":" in malay_line:
        m_speaker, m_rest = malay_line.split(":", 1)
        m_speaker, m_rest = norm(m_speaker), norm(m_rest)
    return a_speaker, a_rest, m_speaker, m_rest


def guess_gender(speaker_ar):
    b = strip_harakat(speaker_ar).strip()
    if not b:
        return "unknown"
    last = b[-1]
    if last == "ة":
        return "female"
    # common role words ending without taa marbuta but referring generically -
    # fall back unknown so it gets flagged for lecturer review rather than guessed.
    return "male"


_AR_HDR_MARKERS = [bare(x) for x in ["عربي", "نص", "تعبير", "مفردة"]]


def parse_dialog_table(rows):
    """rows[0] = header ('Maksud...' | 'النص العربي' or reverse). Detect column order."""
    if not rows:
        return []
    header = rows[0]
    ar_col = 0
    for i, h in enumerate(header):
        hb = bare(h)
        if any(m in hb for m in _AR_HDR_MARKERS):
            ar_col = i
    ms_col = 1 - ar_col if len(header) == 2 else (0 if ar_col != 0 else 1)
    out = []
    for r in rows[1:]:
        if len(r) < 2 or len(r) <= ar_col:
            continue
        ar_line = r[ar_col]
        ms_line = r[ms_col] if len(r) > ms_col else ""
        if not ar_line:
            continue
        sp_ar, utt_ar, sp_ms, utt_ms = split_speaker(ar_line, ms_line)
        out.append({
            "arabicFull": ar_line,
            "arabic": utt_ar or ar_line,
            "meaning": utt_ms or ms_line,
            "speakerAr": sp_ar,
            "speakerMs": sp_ms,
            "gender": guess_gender(sp_ar) if sp_ar else "unknown",
        })
    return out


def parse_vocab_table(rows):
    if not rows:
        return []
    header = rows[0]
    # 3 columns typical: Maksud | النطق (transliteration) | المفردة (arabic)
    # or 2 columns in some units: Maksud | Arabic
    idx = {"ar": None, "translit": None, "ms": None}
    for i, h in enumerate(header):
        hb = bare(h)
        if bare("المفردة") in hb or bare("اللغة العربية") in hb:
            idx["ar"] = i
        elif bare("النطق") in hb:
            idx["translit"] = i
        elif bare("النوع") in hb:
            idx["type"] = i
        elif "maksud" in h.lower() or bare("المعنى") in hb:
            idx["ms"] = i
    if idx["ar"] is None:
        # fallback: last column tends to hold Arabic (RTL table authored right-to-left)
        idx["ar"] = len(header) - 1
    if idx["ms"] is None:
        idx["ms"] = 0
    out = []
    for r in rows[1:]:
        if len(r) <= idx["ar"] or not r[idx["ar"]]:
            continue
        out.append({
            "arabic": r[idx["ar"]],
            "transliteration": r[idx["translit"]] if idx.get("translit") is not None and len(r) > idx["translit"] else "",
            "meaning": r[idx["ms"]] if len(r) > idx["ms"] else "",
        })
    return out


def process_file(path):
    document = docx.Document(str(path))
    blocks = list(iter_block_items(document))
    units = []
    cur = None
    cur_section = None  # (kind, headingAr)

    def flush_section():
        pass

    for b in blocks:
        if isinstance(b, Table):
            title = is_unit_title_table(b)
            if title:
                cur = {
                    "unitNo": title["unitNo"],
                    "titleLines": title["lines"],
                    "sections": [],
                }
                units.append(cur)
                cur_section = None
                continue
            if cur is None:
                continue
            rows = table_rows(b)
            if not rows or not rows[0]:
                continue
            cell0 = rows[0][0] if rows[0] else ""
            ncols = len(rows[0])
            nrows = len(rows)
            # heading table: 1 row, <=2 cols, second cell (if any) blank
            is_heading_like = nrows == 1 and (ncols == 1 or (ncols == 2 and not norm(rows[0][1] if len(rows[0]) > 1 else "")))
            kind = classify_heading(cell0) if is_heading_like else None
            if kind:
                cur_section = {"kind": kind, "headingAr": cell0, "tables": [], "notes": []}
                cur["sections"].append(cur_section)
                continue
            aux, aux_pat = classify_aux(cell0)
            if aux and nrows == 1 and ncols == 1:
                # self-contained note/exercise block: heading + body in one cell,
                # possibly on the same line (no newline) -> split by matched prefix.
                head, body = split_off_prefix(rows[0][0], aux_pat)
                body_lines = [x for x in body.split("\n") if x.strip()]
                entry = {"auxKind": aux, "headingLine": head, "bodyLines": body_lines, "raw": rows[0][0]}
                if cur_section is None:
                    cur_section = {"kind": "misc", "headingAr": "", "tables": [], "notes": []}
                    cur["sections"].append(cur_section)
                cur_section["notes"].append(entry)
                continue
            # plain data table (vocab, dialog, expressions, grammar table, etc.)
            if cur_section is None:
                cur_section = {"kind": "misc", "headingAr": "", "tables": [], "notes": []}
                cur["sections"].append(cur_section)
            cur_section["tables"].append(rows)
        else:
            # paragraph
            text = norm(b.text)
            if not text:
                continue
            if bare(text).startswith(_WAHDA):
                # Stray unit-title-style paragraph (the source formats some unit
                # boundaries as a table, others as a loose heading paragraph). Treat
                # it as a boundary marker rather than section body text; the full
                # title (with subtitle lines) arrives moments later as a table and
                # overwrites this stub in the final units dict keyed by unit number.
                head_bare = bare(text)
                unit_no = None
                for ord_bare, n in _ORDINALS_SORTED:
                    if ord_bare in head_bare:
                        unit_no = n
                        break
                if unit_no:
                    cur = {"unitNo": unit_no, "titleLines": [text], "sections": []}
                    units.append(cur)
                    cur_section = None
                continue
            if cur is None:
                continue
            if cur_section is None:
                cur_section = {"kind": "misc", "headingAr": "", "tables": [], "notes": []}
                cur["sections"].append(cur_section)
            cur_section.setdefault("paragraphs", []).append(text)

    return units


_CHECKLIST_HEADER_WORDS = [bare(w) for w in ["العبارة", "أَتْقَنْتَهَا"]]


def _extract_checklist(table_rows_):
    """Self-assessment checklists appear in two authored shapes: a single 1x1
    cell with '☐ item1 ☐ item2 ...' inline, or a proper 2-column grid table
    (statement | checkbox) with a header row. Handle both, skip header/intro."""
    items = []
    for row in table_rows_:
        if len(row) >= 2:
            # Column order for statement vs checkbox varies by unit -- pick
            # whichever cell isn't just a checkbox/tick glyph.
            candidates = [c.strip() for c in row if c.strip() not in ("✓", "☐", "")]
            item = candidates[0] if candidates else ""
            if item and not any(item.startswith(w) or bare(item) == w for w in _CHECKLIST_HEADER_WORDS):
                if len(bare(item)) > 6:
                    items.append(item)
            continue
        for cell in row:
            if "☐" not in cell:
                continue
            for chunk in cell.split("☐"):
                chunk = chunk.strip()
                if len(bare(chunk)) > 6 and not bare(chunk).startswith(bare("ضَعْ عَلَامَةَ")):
                    items.append(chunk)
    return items


_COURSE_TITLE_BARE = bare("اللُّغَةُ الْعَرَبِيَّةُ الْأَسَاسِيَّةُ لِلْمُعَامَلَاتِ")


def _title_content_lines(title_lines):
    """The big unit-title table mixes several kinds of lines (course name,
    'Unit N' ordinal, the real descriptive title, a category subtitle, a
    trailing 'UMT3033' marker) in an order that isn't consistent between the
    source files. Keep only the descriptive lines, in original order."""
    out = []
    for line in title_lines:
        b = bare(line)
        if b.startswith(_WAHDA) or b == _COURSE_TITLE_BARE or b == bare("UMT3033") or not b:
            continue
        out.append(line)
    return out


def derive_fields(unit_raw, code_prefix):
    """Turn the generic sections list into typed fields matching the app schema."""
    _title_lines = _title_content_lines(unit_raw["titleLines"])
    if not _title_lines:
        _title_lines = unit_raw["titleLines"]
    u = {
        "titleAr": _title_lines[0] if _title_lines else "",
        "titleSubAr": " • ".join(_title_lines[1:]),
        "learningContextAr": "",
        "outcomesAr": "",
        "outcomes": [],
        "keyTermsAr": "",
        "vocab": [],
        "dialogTitleAr": "",
        "dialog": [],
        "expandedDialog": [],
        "pairPracticeSimpleAr": "",
        "importantExpressions": [],
        "qawaid": [],
        "readingAr": "",
        "readingExercises": [],
        "ayahAr": "",
        "ayahSource": "",
        "ayahMaksud": "",
        "ayahVocab": "",
        "ayahReflection": "",
        "hadithAr": "",
        "hadithSource": "",
        "hadithMaksud": "",
        "hadithVocab": "",
        "hadithLessons": [],
        "dictUsageAr": "",
        "dictExamples": [],
        "pairPracticeRoleA": "",
        "pairPracticeRoleB": "",
        "pairPracticeConditionsAr": "",
        "exercises": [],
        "summaryAr": "",
        "assessmentItems": [],
        "reviewFlags": [],
    }
    exercise_seq = 0
    for sec in unit_raw["sections"]:
        kind = sec["kind"]
        headingAr = sec.get("headingAr", "")
        paras = sec.get("paragraphs", [])
        tables = sec.get("tables", [])
        notes = sec.get("notes", [])

        for n in notes:
            if n["auxKind"] == "learning_context":
                u["learningContextAr"] = "\n".join(n["bodyLines"]).strip()
            elif n["auxKind"] == "exercise":
                exercise_seq += 1
                title_line = n["headingLine"]
                body = "\n".join(n["bodyLines"]).strip()
                etype = "open"
                if "صِلِ" in title_line or "صِلْ" in title_line:
                    etype = "matching"
                elif "صَنِّفِ" in title_line or "صَنِّفْ" in title_line or "عَيِّنِ" in title_line:
                    etype = "classification"
                elif "أَكْمِلِ" in title_line or "أَكْمِلْ" in title_line or "حَدِّدِ" in title_line:
                    etype = "fill"
                elif "فَهْمُ" in title_line:
                    etype = "comprehension"
                u["exercises"].append({
                    "id": f"{code_prefix}-ex-{exercise_seq:03d}",
                    "titleAr": title_line,
                    "type": etype,
                    "promptAr": body,
                    "contextHeading": headingAr,
                })
            elif n["auxKind"] == "pair_practice_note":
                u["pairPracticeSimpleAr"] = n["raw"]
            elif n["auxKind"] in ("remember_note", "observe_note", "linguistic_note", "important_note", "precision_note", "general_note"):
                u["qawaid"].append({"noteType": n["auxKind"], "raw": n["raw"]})
            elif n["auxKind"] == "lessons_learned":
                lessons = [x.lstrip("•").strip() for x in n["bodyLines"] if x.strip()]
                u["hadithLessons"] = lessons
            elif n["auxKind"] == "verse_vocab":
                u["ayahVocab"] = "\n".join(n["bodyLines"]).strip()
            elif n["auxKind"] == "hadith_vocab":
                u["hadithVocab"] = "\n".join(n["bodyLines"]).strip()
            elif n["auxKind"] == "reflect_discuss":
                u["ayahReflection"] = "\n".join(n["bodyLines"]).strip()
            elif n["auxKind"] == "linguistic_analysis":
                u["qawaid"].append({"noteType": "linguistic_analysis", "raw": n["raw"]})
            elif n["auxKind"] == "activity_conditions":
                u["pairPracticeConditionsAr"] = "\n".join(n["bodyLines"]).strip()

        if kind == "outcomes_hdr":
            combined = "\n".join(paras).strip()
            u["outcomesAr"] = combined
            items = re.findall(r"[٠-٩]+\.\s*(.*?)(?=\s*[٠-٩]+\.\s|$)", combined, flags=re.S)
            u["outcomes"] = [norm(x) for x in items if norm(x)]
        elif kind == "keyterms_hdr":
            for t in tables:
                for r in t[1:] if len(t) > 1 and not t[0][-1] else t:
                    pass
            u["keyTermsAr"] = "\n".join(paras).strip()
        elif kind == "vocab_hdr":
            for t in tables:
                u["vocab"].extend(parse_vocab_table(t))
        elif kind == "dialog_hdr":
            u["dialogTitleAr"] = headingAr
            for t in tables:
                u["dialog"].extend(parse_dialog_table(t))
        elif kind == "expand_dialog_hdr":
            for t in tables:
                u["expandedDialog"].extend(parse_dialog_table(t))
        elif kind == "pair_practice_hdr":
            content = "\n".join(paras).strip()
            if not content and tables:
                content = "\n".join(c for row in tables[0] for c in row if c)
            u["pairPracticeSimpleAr"] = (headingAr + "\n" + content).strip() if content else headingAr
        elif kind == "hadith_vocab_hdr":
            content = "\n".join(paras).strip()
            if not content and tables:
                content = "\n".join(c for row in tables[0] for c in row if c)
            u["hadithVocab"] = content
        elif kind == "verse_vocab_hdr":
            content = "\n".join(paras).strip()
            if not content and tables:
                content = "\n".join(c for row in tables[0] for c in row if c)
            u["ayahVocab"] = content
        elif kind == "activity_conditions_hdr":
            content = "\n".join(paras).strip()
            if not content and tables:
                content = "\n".join(c for row in tables[0] for c in row if c)
            u["pairPracticeConditionsAr"] = content
        elif kind == "expr_hdr":
            for t in tables:
                rows = parse_vocab_table(t)
                for r in rows:
                    u["importantExpressions"].append({"arabic": r["arabic"], "meaning": r["meaning"]})
        elif kind == "qawaid_hdr":
            entry = {"titleAr": headingAr, "tables": tables, "paragraphs": paras}
            u["qawaid"].append(entry)
        elif kind == "reading_hdr":
            if paras:
                u["readingAr"] = "\n".join(paras).strip()
            elif tables:
                u["readingAr"] = "\n".join(c for row in tables[0] for c in row if c)
        elif kind == "ayah_hadith_hdr" or kind == "ayah_hdr":
            if tables:
                text = tables[0][0][0] if tables[0] and tables[0][0] else ""
                u["ayahAr"], u["ayahSource"], u["ayahMaksud"] = split_hadith_block(text)
                if len(tables) > 1:
                    text2 = tables[1][0][0] if tables[1] and tables[1][0] else ""
                    u["hadithAr"], u["hadithSource"], u["hadithMaksud"] = split_hadith_block(text2)
        elif kind == "hadith_hdr":
            if tables:
                text = tables[0][0][0] if tables[0] and tables[0][0] else ""
                u["hadithAr"], u["hadithSource"], u["hadithMaksud"] = split_hadith_block(text)
        elif kind == "dict_usage_hdr":
            u["dictUsageAr"] = "\n".join(paras).strip()
            for t in tables:
                u["qawaid"].append({"titleAr": headingAr, "tables": [t], "paragraphs": []})
        elif kind == "dict_examples_hdr":
            for t in tables:
                u["dictExamples"].append({"titleAr": headingAr, "rows": t})
        elif kind == "activity_hdr":
            if tables:
                t = tables[0]
                if len(t) >= 2 and len(t[0]) == 2:
                    u["pairPracticeRoleA"] = f"{t[0][1]}\n{t[1][1]}".strip()
                    u["pairPracticeRoleB"] = f"{t[0][0]}\n{t[1][0]}".strip()
        elif kind == "summary_hdr":
            # Unit 1 merges "summary + self-assessment" under one heading; other
            # units split them. Extract checklist items from either location.
            summary_text_parts = []
            for p in paras:
                if "☐" not in p:
                    summary_text_parts.append(p)
            u["summaryAr"] = "\n".join(summary_text_parts).strip()
            for t in tables:
                u["assessmentItems"].extend(_extract_checklist(t))
        elif kind == "selfassess_hdr":
            for t in tables:
                u["assessmentItems"].extend(_extract_checklist(t))
        elif kind == "notes_hdr":
            pass

    if not u["outcomes"]:
        u["reviewFlags"].append("outcomes_empty")
    if not u["vocab"]:
        u["reviewFlags"].append("vocab_empty")
    if not u["dialog"]:
        u["reviewFlags"].append("dialog_empty")
    for d in u["dialog"] + u["expandedDialog"]:
        if d["gender"] == "unknown":
            u["reviewFlags"].append(f"gender_unknown:{d['speakerAr']}")

    return u


def main():
    report = []
    all_units = {}
    for fname in FILES:
        path = SRC_DIR / fname
        if not path.exists():
            report.append(f"MISSING FILE: {fname}")
            continue
        raw_units = process_file(path)
        report.append(f"{fname}: found {len(raw_units)} unit(s)")
        for ru in raw_units:
            no = ru["unitNo"]
            if no is None:
                report.append(f"  !! could not determine unit number for: {ru['titleLines']}")
                continue
            code_prefix = f"u{no:02d}"
            derived = derive_fields(ru, code_prefix)
            derived["id"] = no
            derived["code"] = f"UMT3033-U{no:02d}"
            all_units[no] = derived
            report.append(f"  Unit {no}: vocab={len(derived['vocab'])} dialog={len(derived['dialog'])} "
                          f"expandedDialog={len(derived['expandedDialog'])} exercises={len(derived['exercises'])} "
                          f"flags={derived['reviewFlags']}")

    ordered = [all_units[i] for i in sorted(all_units.keys())]
    OUT_DIR.mkdir(parents=True, exist_ok=True)
    with open(OUT_DIR / "units_extracted.json", "w", encoding="utf-8") as f:
        json.dump(ordered, f, ensure_ascii=False, indent=2)

    REPORT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(REPORT_PATH, "w", encoding="utf-8") as f:
        f.write("\n".join(report))
    print("\n".join(report))
    print(f"\nWrote {len(ordered)} units -> {OUT_DIR / 'units_extracted.json'}")


if __name__ == "__main__":
    main()
