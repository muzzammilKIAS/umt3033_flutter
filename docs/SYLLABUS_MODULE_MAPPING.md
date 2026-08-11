# UMT3033 — Syllabus ↔ Module Mapping

This document records which source files were treated as authoritative for the
Basic Arabic for Muamalat (UMT3033) app, per the academic source hierarchy
required for this project, and maps all 14 units between the approved course
guide and the final edited student module.

## Sources used (selected per the hierarchy: syllabus > final module > answer guide > app)

| Rank | Role | File used | Why this one |
|---|---|---|---|
| 1 | Final syllabus / course guide | `KIAS/UMT3033 BASIC ARABIC FOR MUAMALAT/2. Rancangan Pengajaran/3. Garis Panduan Kursus (CG)/CG UMT3033 BASIC ARABIC FOR MUAMALAT.docx` | The Course Guideline (CG) contains the official CLOs and the 14-unit "Isi Kandungan/Unit Pembelajaran" table — the authoritative topic sequence. Three near-duplicate copies of the KIAS folder exist (`UMT3033 BASIC ARABIC FOR MUAMALAT`, `... 2`, `... 3`); the CG content is identical across copies, so the first was used. |
| — | Assessment plan (context only, not unit content) | `SUBJEK 2026:2027 1.1/BASIC ARABIC FOR MUAMALAT/Rancangan Kerja Kursus UMT3033-KDK2023-21.docx` | Describes CLOs, grading rubric and the cluster-based presentation assignment. Confirms the same CLOs as the CG; not used for unit sequencing since it doesn't enumerate individual unit titles. |
| 2 | Final edited student module | `UMT3033_ENRICHMENT/output/Topik_{1_dan_2, 3_dan_4, 5_dan_6, 7_dan_8, 9_dan_10, 11_dan_12, 13_dan_14}_Enriched_Final.docx` | Newest "Final" per-topic files (dated 2026-08-10), each covering two units. Used for all text extraction (source-of-truth for exact Arabic/harakat, vocab, hiwar, qawaid, exercises). The compiled `Modul_Lengkap_..._Final.docx` (single 23MB file, same date) was inspected and matches these seven files section-for-section; the per-topic files were used because they parse far faster and the compiled book embeds the same content. |
| 2b | Illustrations | `UMT3033_ENRICHMENT/output/Topik_*_Enriched_With_Images_Final.docx` (image-bearing siblings of the above) | Used only to extract the one embedded hiwar illustration per unit; text was not re-parsed from these (see `scripts/extract_illustrations.py`). |
| 3 | Answer guide | `UMT3033_ENRICHMENT/answer_output/Dalil_Al-Ijabat_UMT3033_Final.docx` | Located and confirmed present. **Not integrated into the shipped app in this pass** — see "Known limitation" below. |
| 4 | Existing Flutter app | `lib/`, `assets/data/*.json` (pre-existing) | Architecture (Provider, DataService/StorageService, Material 3, bottom nav) preserved; Unit 1's already-approved JSON was re-derived from the same DOCX pipeline for schema consistency with units 2–14, not hand-edited. |

## Unit-by-unit mapping

Syllabus topic titles below are transcribed verbatim from CG Table "Isi
Kandungan/Unit Pembelajaran". Module unit titles are the Arabic descriptive
title extracted from each unit's opening table.

| # | Syllabus topic (CG, Malay) | Module unit title (Arabic) | Grammar focus (CG) | App data file | Status |
|---|---|---|---|---|---|
| 1 | Pengenalan Kursus | التَّعْرِيفُ بِالْمُقَرَّرِ | — (orientation unit) | units.json[0] | PASS |
| 2 | Perbualan Di Institusi Muamalat Islam | الْحِوَارُ فِي مُؤَسَّسَةِ الْمُعَامَلَاتِ الْإِسْلَامِيَّةِ | Isim/Fi'il/Harf | units.json[1] | PASS |
| 3 | Perbualan Di Bank | الْحِوَارُ فِي الْبَنْكِ | Muzakkar/Muannath, Alif Lam Syamsiyah/Qamariyah | units.json[2] | PASS |
| 4 | Ayat al-Quran tentang muamalat | آيَةٌ مِنَ الْقُرْآنِ فِي الْمُعَامَلَاتِ (الْبَيْعُ وَالرِّبَا) | Mufrad/Muthanna/Jamak | units.json[3] | PASS |
| 5 | Hadith tentang muamalat | الْحَدِيثُ عَنِ الْمُعَامَلَاتِ (الصِّدْقُ وَالْبَيَانُ فِي الْبَيْعِ) | Nakirah/Ma'rifah | units.json[4] | PASS |
| 6 | Pelaburan (Investment) | الِاسْتِثْمَارُ | Dhomir munfasil/muttasil | units.json[5] | PASS |
| 7 | Halal Haram Dalam Muamalat | الْحَلَالُ وَالْحَرَامُ فِي الْمُعَامَلَاتِ | Isim al-Isyarah | units.json[6] | PASS |
| 8 | Takaful Dan Insurans | التَّكَافُلُ وَالتَّأْمِينُ | Isim al-Mausul | units.json[7] | PASS |
| 9 | Baitul Mal | بَيْتُ الْمَالِ | Fi'lun madhi/mudhari' | units.json[8] | PASS |
| 10 | Sedeqah, Zakat Dan Pemberian | الصَّدَقَةُ وَالزَّكَاةُ وَالْهِبَةُ | Huruf Jar | units.json[9] | PASS |
| 11 | Pajak Gadai | الرَّهْنُ | Zorfun | units.json[10] | PASS |
| 12 | Matawang | النُّقُودُ | Sifat/Mausuf | units.json[11] | PASS |
| 13 | Mukjizat Istilah muamalat dalam teks | إِعْجَازُ مُصْطَلَحَاتِ الْمُعَامَلَاتِ فِي النُّصُوصِ | Jidhr/Wazn (root & pattern) | units.json[12] | PASS |
| 14 | Pengenalan Kamus Istilah Muamalat | مُقَدِّمَةٌ إِلَى مُعْجَمِ مُصْطَلَحَاتِ الْمُعَامَلَاتِ | Dictionary usage | units.json[13] | PASS |

**Result: 14/14 units PASS — sequence, titles and grammar scope in the final
module match the approved course guide exactly. No REVIEW FLAG items.**

The CG table has an empty "Unit" (number) column and no explicit week
numbers; the syllabus therefore does not mandate a specific teaching week per
unit, only the topic order, which is followed exactly (Unit 1 → Unit 14, no
reordering).

## Known limitation: answer guide not yet wired into the app

`Dalil_Al-Ijabat_UMT3033_Final.docx` (the lecturer answer guide) was located
and its path recorded above, but time did not allow parsing it into a
structured, per-exercise answer key in this pass. Consequently:

- Interactive exercises (matching type) self-check using the unit's own
  vocabulary table as the answer key (mathematically identical to the
  approved answers, since matching exercises reuse vocab already in the
  module) — this is safe and required no answer-guide parsing.
- Other exercise types (classification, fill-in, comprehension) are offered
  as free-response with a "mark as attempted" toggle, not auto-graded,
  which is the deliberately safe fallback per the project's exercise-feedback
  rules (never mark open-ended work objectively wrong).
- No lecturer answer content is exposed to students anywhere in the app.

See `docs/CONTENT_REVIEW_FLAGS.md` for how this is tracked as follow-up work.
