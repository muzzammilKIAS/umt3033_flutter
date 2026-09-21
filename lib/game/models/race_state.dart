import 'dart:math';

enum RoomPhase { lobby, countdown, playing, paused, finished, results }

// RTDB can decode dense numeric topic keys as a List rather than a Map.
Map<String, dynamic> jsonMap(dynamic value) {
  if (value is Map) return value.map((k, v) => MapEntry(k.toString(), v));
  if (value is List) {
    return {
      for (var i = 0; i < value.length; i++)
        if (value[i] != null) '$i': value[i],
    };
  }
  return {};
}

class RunState {
  int score, checkpoint, correct, wrong, elapsedMs, gems;
  bool finished;
  double progress;
  Map<String, dynamic> topics;
  RunState({
    this.score = 0,
    this.checkpoint = 0,
    this.correct = 0,
    this.wrong = 0,
    this.elapsedMs = 0,
    this.gems = 0,
    this.finished = false,
    this.progress = 0,
    Map<String, dynamic>? topics,
  }) : topics = topics ?? {};
  double get accuracy => correct + wrong == 0 ? 0 : correct / (correct + wrong);
  int get stars => !finished
      ? 0
      : accuracy >= .9
      ? 3
      : accuracy >= .65
      ? 2
      : 1;
  void answer(int topic, bool right, int responseMs) {
    if (right) {
      correct++;
      score += 100 + max(0, 50 - responseMs ~/ 200);
    } else {
      wrong++;
      elapsedMs += 3000;
    }
    final values = jsonMap(topics['$topic']);
    values[right ? 'correct' : 'wrong'] =
        (values[right ? 'correct' : 'wrong'] as num? ?? 0) + 1;
    topics['$topic'] = values;
    checkpoint++;
  }

  void collect() {
    gems++;
    score += 10;
  }

  void finish() {
    if (!finished) {
      finished = true;
      progress = 1;
      score += 200;
    }
  }

  Map<String, dynamic> toJson() => {
    'score': score,
    'checkpoint': checkpoint,
    'correct': correct,
    'wrong': wrong,
    'elapsedMs': elapsedMs,
    'gems': gems,
    'finished': finished,
    'progress': progress,
    'topics': topics,
  };
  factory RunState.fromJson(dynamic raw) {
    final m = jsonMap(raw);
    return RunState(
      score: (m['score'] as num?)?.toInt() ?? 0,
      checkpoint: (m['checkpoint'] as num?)?.toInt() ?? 0,
      correct: (m['correct'] as num?)?.toInt() ?? 0,
      wrong: (m['wrong'] as num?)?.toInt() ?? 0,
      elapsedMs: (m['elapsedMs'] as num?)?.toInt() ?? 0,
      gems: (m['gems'] as num?)?.toInt() ?? 0,
      finished: m['finished'] == true,
      progress: (m['progress'] as num?)?.toDouble() ?? 0,
      topics: jsonMap(m['topics']),
    );
  }
}

class RacePlayer {
  final String id, nickname;
  final int avatar, round;
  final bool connected;
  final RunState run;
  RacePlayer({
    required this.id,
    required this.nickname,
    this.avatar = 0,
    this.round = 0,
    this.connected = true,
    RunState? run,
  }) : run = run ?? RunState();
  Map<String, dynamic> toJson() => {
    'nickname': nickname,
    'avatar': avatar,
    'round': round,
    'connected': connected,
    'run': run.toJson(),
  };
  factory RacePlayer.fromJson(String id, dynamic raw) {
    final m = jsonMap(raw);
    return RacePlayer(
      id: id,
      nickname: m['nickname'] as String? ?? 'Student',
      avatar: (m['avatar'] as num?)?.toInt() ?? 0,
      round: (m['round'] as num?)?.toInt() ?? 0,
      connected: m['connected'] == true,
      run: RunState.fromJson(m['run']),
    );
  }
}

class RaceRoom {
  final String code, hostId;
  final int level, round, startAt, pausedAt, pausedMs, expiresAt;
  final RoomPhase phase;
  final bool locked;
  final List<RacePlayer> players;
  const RaceRoom({
    required this.code,
    required this.hostId,
    required this.level,
    this.round = 0,
    this.startAt = 0,
    this.pausedAt = 0,
    this.pausedMs = 0,
    this.expiresAt = 0,
    this.phase = RoomPhase.lobby,
    this.locked = false,
    this.players = const [],
  });
  factory RaceRoom.fromJson(String code, dynamic raw) {
    final m = jsonMap(raw), meta = jsonMap(m['metadata']);
    return RaceRoom(
      code: code,
      hostId: meta['hostId'] as String? ?? '',
      level: (meta['level'] as num?)?.toInt() ?? 1,
      round: (meta['round'] as num?)?.toInt() ?? 0,
      startAt: (meta['startAt'] as num?)?.toInt() ?? 0,
      pausedAt: (meta['pausedAt'] as num?)?.toInt() ?? 0,
      pausedMs: (meta['pausedMs'] as num?)?.toInt() ?? 0,
      expiresAt: (meta['expiresAt'] as num?)?.toInt() ?? 0,
      locked: meta['locked'] == true,
      phase: RoomPhase.values.firstWhere(
        (e) => e.name == meta['phase'],
        orElse: () => RoomPhase.lobby,
      ),
      players: jsonMap(
        m['players'],
      ).entries.map((e) => RacePlayer.fromJson(e.key, e.value)).toList(),
    );
  }
  List<RacePlayer> get ranked => [...players]..sort(comparePlayers);
}

int comparePlayers(RacePlayer a, RacePlayer b) {
  final score = b.run.score.compareTo(a.run.score);
  if (score != 0) return score;
  final accuracy = b.run.accuracy.compareTo(a.run.accuracy);
  if (accuracy != 0) return accuracy;
  final progress = b.run.progress.compareTo(a.run.progress);
  if (progress != 0) return progress;
  final time = a.run.elapsedMs.compareTo(b.run.elapsedMs);
  return time != 0 ? time : a.id.compareTo(b.id);
}

String joinUrl(Uri base, String code) => Uri(
  scheme: base.scheme,
  host: base.host,
  port: base.hasPort ? base.port : null,
  path: base.path,
  fragment: '/game/join?room=${Uri.encodeComponent(code)}',
).toString();
String formatTime(int ms) =>
    '${ms ~/ 60000}:${(ms ~/ 1000 % 60).toString().padLeft(2, '0')}';
