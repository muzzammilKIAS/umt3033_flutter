import 'package:flutter/material.dart';
import '../models/curriculum.dart';
import 'adventure_style.dart';

class QuestionGate extends StatefulWidget {
  final KnowledgeQuestion question;
  final void Function(bool correct, int responseMs) onComplete;
  const QuestionGate({
    super.key,
    required this.question,
    required this.onComplete,
  });
  @override
  State<QuestionGate> createState() => _QuestionGateState();
}

class _QuestionGateState extends State<QuestionGate> {
  final Stopwatch _watch = Stopwatch()..start();
  bool? _correct;
  String? _selectedArabic;
  final Set<String> _matched = {};
  int _responseMs = 0;
  void _answer(bool value) {
    if (_correct != null) return;
    setState(() {
      _correct = value;
      _responseMs = _watch.elapsedMilliseconds;
    });
  }

  @override
  Widget build(BuildContext context) {
    final q = widget.question;
    final arabicOptions = q.type == QuestionType.malayToArabic;
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: AdventureCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'KNOWLEDGE GATE  /  TOPIC ${q.topicId}',
                  style: const TextStyle(
                    color: emerald,
                    fontSize: 11,
                    letterSpacing: 1.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (q.questionArabic.isNotEmpty && !q.isMatching)
                  ArabicText(q.questionArabic, size: 38),
                Text(
                  q.questionMalay,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 16),
                if (q.isMatching)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          children: q.pairs.keys
                              .map(
                                (ar) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: OutlinedButton(
                                    style: OutlinedButton.styleFrom(
                                      backgroundColor: _selectedArabic == ar
                                          ? sky
                                          : null,
                                    ),
                                    onPressed:
                                        _correct != null ||
                                            _matched.contains(ar)
                                        ? null
                                        : () => setState(
                                            () => _selectedArabic = ar,
                                          ),
                                    child: ArabicText(
                                      ar,
                                      size: 24,
                                      color: _matched.contains(ar)
                                          ? Colors.grey
                                          : navy,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          children: q.pairs.values
                              .toList()
                              .reversed
                              .map(
                                (ms) => Padding(
                                  padding: const EdgeInsets.only(bottom: 8),
                                  child: OutlinedButton(
                                    onPressed:
                                        _correct != null ||
                                            _selectedArabic == null ||
                                            _matched.any(
                                              (a) => q.pairs[a] == ms,
                                            )
                                        ? null
                                        : () {
                                            if (q.pairs[_selectedArabic] !=
                                                ms) {
                                              _answer(false);
                                              return;
                                            }
                                            setState(() {
                                              _matched.add(_selectedArabic!);
                                              _selectedArabic = null;
                                            });
                                            if (_matched.length ==
                                                q.pairs.length) {
                                              _answer(true);
                                            }
                                          },
                                    child: Text(
                                      ms,
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    ],
                  )
                else
                  ...q.options.asMap().entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: OutlinedButton(
                        onPressed: _correct != null
                            ? null
                            : () => _answer(e.value == q.correctAnswer),
                        style: OutlinedButton.styleFrom(
                          alignment: Alignment.centerLeft,
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${String.fromCharCode(65 + e.key)}  ',
                              style: const TextStyle(color: emerald),
                            ),
                            Expanded(
                              child: arabicOptions
                                  ? ArabicText(e.value, size: 26)
                                  : Text(e.value),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                if (_correct != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _correct!
                        ? '✓ CORRECT  •  +100 knowledge points + speed bonus'
                        : 'Let’s learn this one  •  +3 second penalty',
                    style: TextStyle(
                      color: _correct! ? emerald : const Color(0xFF995324),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    q.explanation,
                    textDirection: TextDirection.rtl,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 25,
                      height: 1.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () => widget.onComplete(_correct!, _responseMs),
                    child: const Text('Continue adventure →'),
                  ),
                ],
                const SizedBox(height: 12),
                Text(
                  q.sourceReference,
                  style: const TextStyle(fontSize: 10, color: Colors.blueGrey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
