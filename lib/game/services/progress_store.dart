import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/race_state.dart';

class ProgressStore {
  static const key = 'umt3033_adventure_v1';
  final SharedPreferences prefs;
  Map<String, dynamic> data;
  ProgressStore._(this.prefs, this.data);
  static Future<ProgressStore> load() async {
    final prefs = await SharedPreferences.getInstance();
    Map<String, dynamic> data = {};
    try {
      data = jsonMap(jsonDecode(prefs.getString(key) ?? '{}'));
    } catch (_) {
      /* recover corrupt save */
    }
    return ProgressStore._(prefs, data);
  }

  /// Every world is open from the start; progress is kept as bests and stars.
  Map<String, dynamic> best(int level) =>
      jsonMap(jsonMap(data['best'])['$level']);
  RunState? resume(int level) {
    final save = jsonMap(data['solo']);
    return save['level'] == level ? RunState.fromJson(save['run']) : null;
  }

  Future<void> saveSolo(int level, RunState run) async {
    data['solo'] = {'level': level, 'run': run.toJson()};
    if (run.finished) {
      final record = best(level);
      final all = jsonMap(data['best']);
      all['$level'] = {
        'score': max((record['score'] as num?)?.toInt() ?? 0, run.score),
        'stars': max((record['stars'] as num?)?.toInt() ?? 0, run.stars),
        'time': min(
          (record['time'] as num?)?.toInt() ?? run.elapsedMs,
          run.elapsedMs,
        ),
      };
      data['best'] = all;
      final mastery = jsonMap(data['mastery']);
      for (final entry in run.topics.entries) {
        final t = jsonMap(entry.value);
        final total = (t['correct'] as num? ?? 0) + (t['wrong'] as num? ?? 0);
        if (total > 0) mastery[entry.key] = (t['correct'] as num? ?? 0) / total;
      }
      data['mastery'] = mastery;
    }
    await prefs.setString(key, jsonEncode(data));
  }
}
