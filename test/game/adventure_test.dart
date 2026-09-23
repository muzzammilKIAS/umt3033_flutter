import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:umt3033_app/services/data_service.dart';
import 'package:umt3033_app/game/data/question_bank.dart';
import 'package:umt3033_app/game/engine/adventure_game.dart';
import 'package:umt3033_app/game/models/race_state.dart';
import 'package:umt3033_app/game/multiplayer/local_room_service.dart';
import 'package:umt3033_app/game/multiplayer/room_service.dart';
import 'package:umt3033_app/game/services/progress_store.dart';
import 'package:umt3033_app/game/widgets/adventure_style.dart';
import 'package:umt3033_app/game/widgets/question_gate.dart';
import 'package:umt3033_app/game/widgets/race_board.dart';
import 'package:umt3033_app/game/screens/results_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late DataService data;
  setUpAll(() async {
    data = DataService();
    await data.loadAll();
  });
  test('all gates use exact source answers; final vault covers 14 topics', () {
    final bank = QuestionBank(data);
    for (var level = 1; level <= 5; level++) {
      final questions = bank.forLevel(level);
      expect(questions.length, level == 5 ? 20 : 9);
      expect(questions.map((q) => q.id).toSet().length, questions.length);
      for (final q in questions) {
        final vocab = data.unitById(q.topicId)!.vocab;
        expect(q.sourceReference, contains('assets/data/units.json'));
        if (q.isMatching) {
          for (final e in q.pairs.entries) {
            expect(
              vocab.any((v) => v.arabic == e.key && v.meaning == e.value),
              isTrue,
            );
          }
        } else {
          expect(q.options.toSet().length, 4);
          expect(q.options.where((o) => o == q.correctAnswer).length, 1);
          expect(
            vocab.any(
              (v) =>
                  v.meaning == q.correctAnswer || v.arabic == q.correctAnswer,
            ),
            isTrue,
          );
        }
      }
    }
    expect(bank.forLevel(5).skip(6).map((q) => q.topicId).toSet().length, 14);
  });
  test(
    'knowledge dominates gems, first attempt accuracy and one completion award',
    () {
      final expert = RunState(), collector = RunState();
      for (var i = 0; i < 9; i++) {
        expert.answer(1, true, 20000);
        collector.answer(1, false, 10);
      }
      for (var i = 0; i < 18; i++) {
        collector.collect();
      }
      expert.finish();
      collector.finish();
      expert.finish();
      expect(expert.score, 1100);
      expect(expert.score, greaterThan(collector.score));
      expect(expert.accuracy, 1);
      expect(collector.elapsedMs, 27000);
      expect(RunState.fromJson(expert.toJson()).stars, 3);
    },
  );
  test(
    'solo progress restores checkpoints, bests and topic mastery separately',
    () async {
      SharedPreferences.setMockInitialValues({
        'umt3033_app_v1': '{"theme":"dark"}',
      });
      final store = await ProgressStore.load();
      final run = RunState();
      run.answer(1, true, 1000);
      await store.saveSolo(1, run);
      expect((await ProgressStore.load()).resume(1)!.checkpoint, 1);
      run.finish();
      await store.saveSolo(1, run);
      final restored = await ProgressStore.load();
      expect(restored.best(1)['stars'], 3);
      expect(restored.data['mastery']['1'], 1);
      expect(store.prefs.getString('umt3033_app_v1'), '{"theme":"dark"}');
    },
  );
  test('Firebase numeric topic arrays retain analytics after refresh', () {
    final run = RunState.fromJson({
      'topics': [
        null,
        {'correct': 2, 'wrong': 1},
      ],
    });
    expect(run.topics['1']['correct'], 2);
  });
  test('hash join keeps GitHub Pages base path and room parameter', () {
    final url = Uri.parse(
      joinUrl(
        Uri.parse('https://example.com/umt3033_flutter/#/game/host'),
        'ABC234',
      ),
    );
    expect(url.path, '/umt3033_flutter/');
    expect(url.fragment, '/game/join?room=ABC234');
  });
  test('host transition timestamps preserve paused time', () {
    final room = RaceRoom(
      code: 'ABC234',
      hostId: 'host',
      level: 1,
      phase: RoomPhase.paused,
      pausedAt: 1000,
      pausedMs: 200,
    );
    expect(controlChanges(room, 'resume', 4000)['pausedMs'], 3200);
    expect(() => controlChanges(room, 'start', 4000), throwsStateError);
  });
  for (final count in [2, 10, 50]) {
    test(
      'local adapter $count players: join, lock, race, recovery, results and next round',
      () async {
        SharedPreferences.setMockInitialValues({});
        final prefs = await SharedPreferences.getInstance();
        final host = LocalRoomService(prefs, 'host'),
            other = LocalRoomService(prefs, 'other');
        final code = await host.create(1);
        final players = List.generate(
          count,
          (i) => LocalRoomService(prefs, 'p$i'),
        );
        for (var i = 0; i < count; i++) {
          await players[i].join(code, 'Student $i', i % 4);
        }
        expect((await host.watch(code).first)!.players.length, count);
        await expectLater(other.join(code, 'Student 0', 0), throwsStateError);
        await expectLater(other.control(code, 'start'), throwsStateError);
        await expectLater(
          other.join('ZZZZZZ', 'New player', 0),
          throwsStateError,
        );
        await host.control(code, 'start');
        await expectLater(other.join(code, 'Late player', 0), throwsStateError);
        for (var i = 0; i < count; i++) {
          final run = RunState();
          run.answer(1, i.isEven, 1000);
          run.progress = .2;
          await players[i].publish(code, 0, run);
        }
        var room = (await host.watch(code).first)!;
        expect(room.players.every((p) => p.run.checkpoint == 1), isTrue);
        await players.first.leave(code);
        await players.first.join(code, 'Ignored recovery name', 2);
        room = (await host.watch(code).first)!;
        expect(room.players.first.run.checkpoint, 1);
        expect(room.players.first.nickname, 'Student 0');
        await host.control(code, 'end');
        await host.control(code, 'next', level: 2);
        await players.first.publish(
          code,
          0,
          RunState(score: 999),
        ); // stale round ignored
        room = (await host.watch(code).first)!;
        expect(room.level, 2);
        expect(room.round, 1);
        expect(room.players.every((p) => p.run.score == 0), isTrue);
        await host.control(code, 'remove', playerId: players.first.userId);
        await expectLater(
          players.first.join(code, 'Removed player', 0),
          throwsStateError,
        );
        await host.control(code, 'delete');
        expect(await host.watch(code).first, isNull);
      },
    );
  }
  test(
    'actual platform simulation reaches all nine gates and the finish',
    () async {
      final run = RunState();
      late AdventureGame game;
      game = AdventureGame(
        run: run,
        gates: 9,
        avatar: 0,
        level: 1,
        onGate: (i) {
          run.answer(i ~/ 3 + 1, true, 1200);
          game.releaseGate(true);
        },
        onChanged: () {},
        onFinish: () {},
      );
      // Flame requires its internal load hook for a headless physics test.
      // ignore: invalid_use_of_internal_member
      await game.load();
      for (var frame = 0; frame < 60000 && !run.finished; frame++) {
        game.right = true;
        final localX = game.x % 1100;
        if (game.grounded &&
            ((localX > 575 && localX < 640) ||
                (localX > 790 && localX < 900))) {
          game.jump();
        }
        game.update(1 / 120);
      }
      expect(
        run.finished,
        isTrue,
        reason:
            'Stopped at x=${game.x}, y=${game.y}, checkpoint=${run.checkpoint}',
      );
      expect(run.correct, 9);
      expect(run.progress, 1);
      game.onRemove();
    },
  );
  testWidgets('Arabic gate and matching remain usable at phone width', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final q = QuestionBank(data).forLevel(1).first;
    bool? answer;
    await tester.pumpWidget(
      MaterialApp(
        theme: adventureTheme(),
        home: Scaffold(
          body: QuestionGate(
            question: q,
            onComplete: (right, ms) => answer = right,
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
    await tester.tap(find.text(q.correctAnswer));
    await tester.pump();
    final continueButton = find.text('Continue adventure →');
    await tester.ensureVisible(continueButton);
    await tester.tap(continueButton);
    expect(answer, isTrue);
    await tester.pumpWidget(
      MaterialApp(
        theme: adventureTheme(),
        home: Scaffold(
          body: QuestionGate(
            key: const ValueKey('match'),
            question: QuestionBank(data).forLevel(1)[2],
            onComplete: (_, _) {},
          ),
        ),
      ),
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('50-player projector shows all avatars within 16:9 display', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(1440, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(24),
            child: SizedBox(
              height: 720,
              child: RaceBoard(
                room: RaceRoom(
                  code: 'ABC234',
                  hostId: 'host',
                  level: 1,
                  players: List.generate(
                    50,
                    (i) => RacePlayer(
                      id: '$i',
                      nickname: 'Student $i',
                      avatar: i % 4,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump(const Duration(seconds: 1));
    expect(find.byType(LiveAvatarMarker), findsNWidgets(50));
    expect(tester.takeException(), isNull);
    expect(
      tester.getBottomRight(find.byType(LiveAvatarMarker).last).dy,
      lessThan(750),
    );
  });
  for (final count in [20, 50]) {
    testWidgets('$count players fit a 1280x720 classroom projector', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                height: 480,
                child: RaceBoard(
                  room: RaceRoom(
                    code: 'ABC234',
                    hostId: 'host',
                    level: 1,
                    players: List.generate(
                      count,
                      (i) => RacePlayer(
                        id: '$i',
                        nickname: 'Student $i',
                        avatar: i % 4,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(LiveAvatarMarker), findsNWidgets(count));
      expect(
        tester.getBottomRight(find.byType(LiveAvatarMarker).last).dy,
        lessThanOrEqualTo(504),
      );
      expect(tester.takeException(), isNull);
    });
  }
  test('CSV escapes quoted names and prevents formula injection', () {
    final csv = resultsCsv([RacePlayer(id: '1', nickname: '=SUM(1,2)')]);
    expect(csv, contains('"\'=SUM(1,2)"'));
  });
}
