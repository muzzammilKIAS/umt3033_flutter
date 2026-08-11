# Content Review Flags

Programmatic QA (`test/data_test.dart`, `scripts/extract_units.py`'s
`reviewFlags` field) found **zero** structural review flags across all 14
units after the extraction pipeline was debugged (see git history of
`scripts/extract_units.py` for the iterative fixes — harakat-normalization
for heading matching, merged-cell de-duplication, hadith/ayah source-vs-
translation splitting, etc.). Every unit has non-empty outcomes, vocab,
original hiwar and correctly-typed speaker gender.

The items below are **content-shape observations**, not extraction defects —
each was manually verified against the source DOCX directly (not just the
parsed output) before being recorded here. None required inventing content;
they are differences the authored module has between units, faithfully
preserved.

| # | Unit(s) | Observation | Verified how | Safest interpretation applied |
|---|---|---|---|---|
| 1 | 1, 6, 7, 8 | No standalone numbered "التمرين" exercise block in the source DOCX. | Grepped the raw DOCX text directly for "التمرين" / "أجب عن" — genuinely absent (Unit 1 has one combined reflection block instead; 6/7/8 have none). | Left empty — the app does not render an exercises section for these units (per "do not create empty sections"), and no exercise content was authored to fill the gap. |
| 2 | 9, 10 | No Quranic ayah or hadith section. | Grepped raw DOCX text for "الآية"/"الحديث" headings in these two units' source tables — genuinely absent. | Ayah/hadith UI sections simply don't render for these two units. |
| 3 | All | Answer guide (`Dalil_Al-Ijabat_UMT3033_Final.docx`) has no per-question numbered anchors, only a flat in-order sequence of "نموذج الإجابة:" / "الإجابة:" blocks per unit (204 total). Binding each answer to one specific exercise sub-question would require guessing boundaries and risks misattributing an answer to the wrong question. | Parsed with `scripts/extract_answer_guide.py`; verified unit boundaries (paragraph headings) match `units.json` titles exactly for all 14 units; inspected the answer-block sequence directly against the module's exercise order per unit. | Model answers are grouped **per unit** (not per exercise) and shown behind an explicit reveal toggle in the exercises section, clearly labelled as lecturer guidance where "other correct answers may be accepted" (the guide's own wording), never auto-graded and never shown by default. Matching exercises additionally self-check against the unit's own vocabulary table (an exact per-question answer key for that one exercise type). **Follow-up if finer granularity is wanted:** the module's own exercise sub-question count (e.g. "١. ٢. ٣." inside a `التمرين` block) could be matched against consecutive answer-guide blocks to bind per-question, but was judged too failure-prone to do silently in this pass. |
| 4 | All | Self-assessment checklist table shape (statement/checkbox column order, and whether the intro instruction line exists at all) varies between units 1–5 and 6–14. | Directly inspected raw table cells for units in both groups. | Extraction handles both shapes generically (`_extract_checklist` in `scripts/extract_units.py`); output schema is identical regardless of source shape. |
| 5 | All | Minor stray section-numbering typos in the source (e.g. a qawaid section literally labelled "٦٥." or "٥٧." instead of "٦."/"٧."). | Visible in raw DOCX dumps during development. | Cosmetic only — the app does not display the source's own numeral, it uses its own section icons/headings; no correction of the source text was made (per "do not silently rewrite academic content" — these numbering glitches are left as-authored inside any raw text that includes them verbatim, only structural classification ignores the leading digits). |

## What was deliberately NOT auto-corrected

Per the "content error handling" rule (fix only unquestionable
extraction/encoding defects, otherwise flag and continue), nothing about the
approved Arabic wording, harakat, vocabulary, hiwar content, qawaid
explanations, or ayah/hadith citations was altered. The only text-level
"fixes" applied were entirely mechanical:

- Removing the DOCX's own horizontal-merged-cell duplication artifacts
  (python-docx repeats a merged cell's text once per spanned grid column).
- Collapsing internal whitespace/newlines for table-cell text (a `docx`
  storage artifact, not part of the authored content).

No Arabic word, diacritic, translation, or exercise number was rewritten,
paraphrased, or simplified.
