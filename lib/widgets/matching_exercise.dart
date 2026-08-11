import 'dart:math';
import 'package:flutter/material.dart';
import '../models/unit_model.dart';
import '../theme/app_theme.dart';
import '../widgets/unit_card.dart';

/// Interactive matching exercise: reconstructs word/meaning pairs from the
/// exercise prompt text using the unit's own vocabulary as the answer key
/// (nothing invented -- the correct meaning always comes from vocab already
/// approved in the module). Falls back to a static prompt display if the
/// word list can't be confidently parsed.
class MatchingExercise extends StatefulWidget {
  final ExerciseBlock exercise;
  final UnitModel unit;

  const MatchingExercise({
    super.key,
    required this.exercise,
    required this.unit,
  });

  @override
  State<MatchingExercise> createState() => _MatchingExerciseState();
}

class _MatchingExerciseState extends State<MatchingExercise> {
  late List<String> _words;
  late List<String> _meanings;
  final Map<String, String?> _selected = {};
  final Map<String, bool> _checked = {};

  static String _bare(String s) => s.replaceAll(RegExp(r'[ً-ٰٟـ]'), '').trim();

  @override
  void initState() {
    super.initState();
    _parse();
  }

  void _parse() {
    final prompt = widget.exercise.promptAr;
    final colonIdx = prompt.indexOf(':');
    final wordsPart = colonIdx >= 0 ? prompt.substring(colonIdx + 1) : prompt;
    _words = wordsPart
        .split(RegExp('[،,]'))
        .map((w) => w.trim())
        .where(
          (w) => w.isNotEmpty && !w.contains('خيار') && !w.contains('خِيَار'),
        )
        .toList();

    final answerKey = <String, String>{};
    for (final v in widget.unit.vocab) {
      answerKey[_bare(v.arabic)] = v.meaning;
    }
    for (final e in widget.unit.importantExpressions) {
      answerKey[_bare(e.arabic)] = e.meaning;
    }
    _meanings = [];
    for (final w in _words) {
      final m = answerKey[_bare(w)];
      if (m != null) _meanings.add(m);
    }
    // Only proceed with the interactive UI if we resolved a meaning for every word.
    if (_meanings.length != _words.length || _words.isEmpty) {
      _words = [];
      _meanings = [];
    } else {
      _meanings.shuffle(Random(widget.exercise.id.hashCode));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    if (_words.isEmpty) {
      // Couldn't confidently parse -- show the original prompt as authored.
      return _StaticExercise(exercise: widget.exercise);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.exercise.titleAr,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 10),
        ..._words.map((w) {
          final checked = _checked[w] == true;
          final selected = _selected[w];
          final correctMeaning = widget.unit.vocab
              .firstWhere(
                (v) => _bare(v.arabic) == _bare(w),
                orElse: () => VocabItem(id: '', arabic: '', meaning: ''),
              )
              .meaning;
          final isCorrect = checked && selected == correctMeaning;
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tokens.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: checked
                    ? (isCorrect
                          ? AppColors2.success(context)
                          : AppColors2.error(context))
                    : tokens.border,
                width: checked ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    w,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'LotusLinotype',
                      fontSize: 22.5,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: DropdownButtonFormField<String>(
                    initialValue: selected,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                    ),
                    hint: const Text(
                      'Pilih makna',
                      style: TextStyle(fontSize: 12),
                    ),
                    items: _meanings
                        .toSet()
                        .map(
                          (m) => DropdownMenuItem(
                            value: m,
                            child: Text(
                              m,
                              style: const TextStyle(fontSize: 12),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (v) => setState(() {
                      _selected[w] = v;
                      _checked[w] = false;
                    }),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(
                    checked
                        ? (isCorrect ? Icons.check_circle : Icons.cancel)
                        : Icons.playlist_add_check,
                    color: checked
                        ? (isCorrect
                              ? AppColors2.success(context)
                              : AppColors2.error(context))
                        : tokens.textSecondary,
                  ),
                  onPressed: selected == null
                      ? null
                      : () => setState(() => _checked[w] = true),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }
}

class _StaticExercise extends StatelessWidget {
  final ExerciseBlock exercise;
  const _StaticExercise({required this.exercise});

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          exercise.titleAr,
          textDirection: TextDirection.rtl,
          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Text(
          exercise.promptAr,
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: TextStyle(
            height: 1.8,
            color: tokens.textPrimary,
            fontFamily: 'LotusLinotype',
            fontSize: 20,
          ),
        ),
      ],
    );
  }
}
