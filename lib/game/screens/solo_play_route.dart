import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/data_service.dart';
import '../data/question_bank.dart';
import '../models/curriculum.dart';
import '../services/progress_store.dart';
import '../widgets/adventure_style.dart';
import 'play_screen.dart';

/// A reloadable hash route restores solo play at the last knowledge gate.
class SoloPlayRoute extends StatefulWidget {
  final int level, avatar;
  const SoloPlayRoute({super.key, required this.level, required this.avatar});
  @override
  State<SoloPlayRoute> createState() => _SoloPlayRouteState();
}

class _SoloPlayRouteState extends State<SoloPlayRoute> {
  late final Future<ProgressStore> _store = ProgressStore.load();
  @override
  Widget build(BuildContext context) => FutureBuilder<ProgressStore>(
    future: _store,
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const GameFrame(
          title: 'Loading adventure',
          child: Center(child: CircularProgressIndicator()),
        );
      }
      final store = snapshot.data!;
      final saved = store.resume(widget.level);
      return GameFrame(
        title: adventureLevels[widget.level - 1].title,
        child: PlayScreen(
          level: widget.level,
          avatar: widget.avatar,
          questions: QuestionBank(
            context.read<DataService>(),
          ).forLevel(widget.level),
          restored: saved?.finished == false ? saved : null,
        ),
      );
    },
  );
}
