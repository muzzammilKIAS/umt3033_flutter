# Content Integration Report

Generated from `assets/data/units.json` (produced by `scripts/extract_units.py` + `scripts/build_units_json.py` from the FINAL edited module DOCX). See `docs/SYLLABUS_MODULE_MAPPING.md` for source selection.

| Unit | Syllabus mapping | Sections present | Vocab | Orig. hiwar lines | Expanded hiwar lines | Exercises | Illustration | Audio (male/pregenerated) | Status |
|---|---|---|---|---|---|---|---|---|---|
| 1 | Topik 1 (CG) | outcomes, vocab, hiwar, expanded-hiwar, pair-practice, qawaid, reading, hadith, exercises, summary, self-assessment | 12 | 6 | 6 | 1 | Ya | 24 | PASS |
| 2 | Topik 2 (CG) | outcomes, vocab, hiwar, expanded-hiwar, pair-practice, expressions, qawaid, reading, hadith, exercises, summary, self-assessment | 16 | 9 | 6 | 4 | Ya | 39 | PASS |
| 3 | Topik 3 (CG) | outcomes, vocab, hiwar, expanded-hiwar, pair-practice, expressions, qawaid, reading, hadith, exercises, summary, self-assessment | 20 | 11 | 6 | 4 | Ya | 28 | PASS |
| 4 | Topik 4 (CG) | outcomes, vocab, hiwar, expanded-hiwar, pair-practice, expressions, qawaid, reading, ayah, hadith, exercises, summary, self-assessment | 18 | 10 | 6 | 4 | Ya | 42 | PASS |
| 5 | Topik 5 (CG) | outcomes, vocab, hiwar, expanded-hiwar, pair-practice, expressions, qawaid, reading, hadith, exercises, summary, self-assessment | 20 | 11 | 6 | 4 | Ya | 44 | PASS |
| 6 | Topik 6 (CG) | outcomes, vocab, hiwar, expanded-hiwar, pair-practice, expressions, qawaid, reading, hadith, summary, self-assessment | 20 | 13 | 6 | 0 | Ya | 37 | PASS |
| 7 | Topik 7 (CG) | outcomes, vocab, hiwar, expanded-hiwar, pair-practice, expressions, qawaid, reading, hadith, summary, self-assessment | 20 | 10 | 6 | 0 | Ya | 35 | PASS |
| 8 | Topik 8 (CG) | outcomes, vocab, hiwar, expanded-hiwar, pair-practice, expressions, qawaid, reading, ayah, hadith, summary, self-assessment | 20 | 10 | 6 | 0 | Ya | 36 | PASS |
| 9 | Topik 9 (CG) | outcomes, vocab, hiwar, expanded-hiwar, pair-practice, expressions, qawaid, reading, exercises, summary, self-assessment | 22 | 10 | 6 | 5 | Ya | 44 | PASS |
| 10 | Topik 10 (CG) | outcomes, vocab, hiwar, expanded-hiwar, pair-practice, expressions, qawaid, reading, exercises, summary, self-assessment | 20 | 10 | 6 | 5 | Ya | 34 | PASS |
| 11 | Topik 11 (CG) | outcomes, vocab, hiwar, expanded-hiwar, pair-practice, expressions, qawaid, reading, ayah, hadith, exercises, summary, self-assessment | 20 | 11 | 6 | 5 | Ya | 45 | PASS |
| 12 | Topik 12 (CG) | outcomes, vocab, hiwar, expanded-hiwar, pair-practice, expressions, qawaid, reading, ayah, hadith, exercises, summary, self-assessment | 20 | 10 | 6 | 5 | Ya | 36 | PASS |
| 13 | Topik 13 (CG) | outcomes, vocab, hiwar, expanded-hiwar, pair-practice, expressions, qawaid, reading, ayah, hadith, exercises, summary, self-assessment | 24 | 10 | 6 | 4 | Ya | 48 | PASS |
| 14 | Topik 14 (CG) | outcomes, vocab, hiwar, expanded-hiwar, pair-practice, expressions, qawaid, reading, ayah, hadith, exercises, summary, self-assessment | 24 | 10 | 6 | 4 | Ya | 40 | PASS |

**Totals: 276 vocab entries, 141 original hiwar lines, 84 expanded hiwar lines, 45 exercise blocks across 14 units.**

## Notes on variance across units (verified against source, not extraction errors)

- Units 1, 6, 7, 8 have no standalone `التمرين` exercise block in the source module (the module author paced exercises differently per unit); nothing was invented to fill this gap. Unit 1 instead has a single combined "أجب عن الأسئلة" reflection block, captured as its one exercise.
- Units 9 and 10 (Baitulmal; Zakat/Sedekah/Hibah) have no Quranic ayah or hadith section in the source module — confirmed by direct inspection of the DOCX, not a parsing gap.
- Vocabulary count varies 12–24 per unit and hiwar length 9–14 lines per unit; both reflect the module author's actual content, not a truncation.

## QA checks passed programmatically (see `test/data_test.dart`)

- Exactly 14 units, ids 1..14, unique, correctly ordered.
- Every unit has a non-empty Arabic title, outcomes, vocab and an original hiwar.
- No duplicate vocab/dialog ids within any unit.
- Every dialogue line's speaker gender is explicitly 'male' or 'female' (derived from the actual Arabic speaker-role noun's grammatical gender, e.g. المُوَظَّفَة vs المُوَظَّف -- never guessed from line position).
- Every unit has an illustration asset mapped.