# Game question coverage and academic review

The executable bank reads the existing `DataService.units[].vocab` directly.
No lesson JSON, Quran text, hadith, translation or grammar key was authored or
modified for the game. Each question exposes its exact unit/vocabulary IDs.
Levels 1–4 have three gates per topic (9 gates). Level 5 has six gates for
Topics 13–14 followed by fourteen vault questions, one from each topic.

Available now: Arabic → Malay, Malay → Arabic, tap-to-match word pairs.
The reusable choice renderer and QuestionType schema also accommodate the
following categories, but no unverified answer keys are enabled:

| Category | Status |
|---|---|
| Match phrase, complete sentence, short reading | CONTENT_REVIEW_REQUIRED |
| اسم / فعل / حرف, gender, singular/dual/plural | CONTENT_REVIEW_REQUIRED |
| Demonstratives, relative pronouns | CONTENT_REVIEW_REQUIRED |
| Past/present verbs, prepositions, adverbs | CONTENT_REVIEW_REQUIRED |
| Adjective agreement, derivation, wazan | CONTENT_REVIEW_REQUIRED |
| Quran/hadith interpretation, Islamic rulings | CONTENT_REVIEW_REQUIRED |

The course contains material in these categories, but the existing lecturer
answer guide lacks reliable question-to-answer anchors (see
CONTENT_REVIEW_FLAGS.md). A lecturer must approve explicit per-question keys
and references before those categories can be graded. Vocabulary in Topics
4–5 is used without turning sacred texts into environmental collectibles.

The fixed initial bank is intentionally reproducible across race participants.
Content variety, repeated-play balance, and the targeted 70/30 play/learning
ratio need classroom timing feedback. Matching scores one first-attempt outcome
per gate. On an incorrect match, the full correct mapping is shown before the
player continues; no student is eliminated.
