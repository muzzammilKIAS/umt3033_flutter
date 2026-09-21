import 'package:flutter/material.dart';
import '../models/race_state.dart';
import '../utils/browser.dart';
import '../widgets/adventure_style.dart';

class ResultsView extends StatelessWidget {
  final List<RacePlayer> players;
  final bool classroom;
  const ResultsView({super.key, required this.players, this.classroom = false});
  Map<int, List<int>> get topicTotals {
    final totals = <int, List<int>>{};
    for (final player in players) {
      for (final e in player.run.topics.entries) {
        final t = jsonMap(e.value), topic = int.parse(e.key);
        final sum = totals.putIfAbsent(topic, () => [0, 0]);
        sum[0] += (t['correct'] as num?)?.toInt() ?? 0;
        sum[1] += (t['wrong'] as num?)?.toInt() ?? 0;
      }
    }
    return totals;
  }

  @override
  Widget build(BuildContext context) {
    final ranked = [...players]..sort(comparePlayers);
    final topics = topicTotals;
    final ordered = topics.keys.toList()
      ..sort(
        (a, b) => (topics[b]![0] / (topics[b]![0] + topics[b]![1])).compareTo(
          topics[a]![0] / (topics[a]![0] + topics[a]![1]),
        ),
      );
    final correct = players.fold<int>(0, (n, p) => n + p.run.correct);
    final wrong = players.fold<int>(0, (n, p) => n + p.run.wrong);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          classroom ? 'A class of explorers.' : 'Knowledge unlocked.',
          style: const TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.w800,
            color: navy,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          classroom
              ? 'Every answer is a step forward.'
              : 'Accuracy ${(players.first.run.accuracy * 100).round()}%  •  ${'★' * players.first.run.stars}',
          style: const TextStyle(fontSize: 18, color: emerald),
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: ranked
              .take(3)
              .toList()
              .asMap()
              .entries
              .map(
                (e) => SizedBox(
                  width: 210,
                  child: AdventureCard(
                    color: e.key == 0 ? navy : Colors.white,
                    child: Column(
                      children: [
                        Text(
                          '#${e.key + 1}',
                          style: TextStyle(
                            color: e.key == 0 ? gold : emerald,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 12),
                        AvatarBadge(e.value.avatar, size: 70),
                        const SizedBox(height: 12),
                        Text(
                          e.value.nickname,
                          style: TextStyle(
                            color: e.key == 0 ? cream : navy,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '${e.value.run.score} pts',
                          style: TextStyle(color: e.key == 0 ? gold : emerald),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 24),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: const [
              DataColumn(label: Text('Rank')),
              DataColumn(label: Text('Nickname')),
              DataColumn(label: Text('Score')),
              DataColumn(label: Text('Accuracy')),
              DataColumn(label: Text('Correct')),
              DataColumn(label: Text('Wrong')),
              DataColumn(label: Text('Time + penalties')),
              DataColumn(label: Text('Status')),
            ],
            rows: ranked.asMap().entries.map((e) {
              final p = e.value;
              return DataRow(
                cells: [
                  DataCell(Text('${e.key + 1}')),
                  DataCell(Text(p.nickname)),
                  DataCell(Text('${p.run.score}')),
                  DataCell(Text('${(p.run.accuracy * 100).round()}%')),
                  DataCell(Text('${p.run.correct}')),
                  DataCell(Text('${p.run.wrong}')),
                  DataCell(Text(formatTime(p.run.elapsedMs))),
                  DataCell(Text(p.run.finished ? 'Finished' : 'Incomplete')),
                ],
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 24),
        AdventureCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${classroom ? 'CLASS' : 'YOUR'} ACCURACY  ${correct + wrong == 0 ? '—' : '${(correct / (correct + wrong) * 100).round()}%'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 12),
              if (ordered.isNotEmpty)
                Text(
                  'Strongest: Topic ${ordered.first}   •   Review next: Topic ${ordered.last}',
                ),
              const SizedBox(height: 16),
              ...topics.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Topic ${e.key}   ${(e.value[0] / (e.value[0] + e.value[1]) * 100).round()}%   (${e.value[0]} correct / ${e.value[0] + e.value[1]} answered)',
                  ),
                ),
              ),
              if (topics.isEmpty) const Text('No answers recorded yet.'),
            ],
          ),
        ),
        if (classroom)
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => downloadCsv(resultsCsv(ranked)),
                icon: const Icon(Icons.download),
                label: const Text('Export CSV'),
              ),
            ),
          ),
      ],
    );
  }
}

String resultsCsv(List<RacePlayer> players) {
  String cell(String value) {
    // Spreadsheet formula injection protection for user-entered nicknames.
    final safe = RegExp(r'^[=+@\-\t\r]').hasMatch(value) ? "'$value" : value;
    return '"${safe.replaceAll('"', '""')}"';
  }

  return [
    'Rank,Nickname,Score,Accuracy,Correct,Wrong,TimeSeconds,Finished',
    ...players.asMap().entries.map((e) {
      final p = e.value;
      return [
        '${e.key + 1}',
        cell(p.nickname),
        '${p.run.score}',
        '${(p.run.accuracy * 100).round()}',
        '${p.run.correct}',
        '${p.run.wrong}',
        '${p.run.elapsedMs / 1000}',
        '${p.run.finished}',
      ].join(',');
    }),
  ].join('\r\n');
}
