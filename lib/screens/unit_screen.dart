import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/unit_model.dart';
import '../services/data_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/arabic_text.dart';
import '../widgets/matching_exercise.dart';

class UnitScreen extends StatefulWidget {
  final int unitId;
  const UnitScreen({super.key, required this.unitId});

  @override
  State<UnitScreen> createState() => _UnitScreenState();
}

class _UnitScreenState extends State<UnitScreen> {
  final AudioPlayer _player = AudioPlayer();
  final FlutterTts _tts = FlutterTts();
  String? _playingId;
  bool _ttsReady = false;
  final Set<String> _revealedTranslations = {};
  bool _showHarakat = true;

  /// Applies the harakat toggle to any Arabic text before rendering.
  String _h(String s) => _showHarakat ? s : stripHarakat(s);

  @override
  void initState() {
    super.initState();
    _initTts();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<StorageService>().setLastPosition(widget.unitId, 'opening');
    });
  }

  Future<void> _initTts() async {
    try {
      await _tts.setLanguage('ar');
      await _tts.awaitSpeakCompletion(true);
      _ttsReady = true;
    } catch (_) {
      _ttsReady = false;
    }
  }

  @override
  void dispose() {
    _player.stop();
    _player.dispose();
    _tts.stop();
    super.dispose();
  }

  double get _speed =>
      (context.read<StorageService>().audioPrefs['speed'] as num?)
          ?.toDouble() ??
      1.0;

  Future<void> _stopAll() async {
    await _player.stop();
    await _tts.stop();
    if (mounted) setState(() => _playingId = null);
  }

  Future<void> _playLine(String itemId, String text, String gender) async {
    final data = context.read<DataService>();
    final path = data.getAudioPath(itemId, gender);
    await _player.stop();
    await _tts.stop();
    setState(() => _playingId = itemId);
    if (path != null) {
      try {
        if (kIsWeb) {
          // just_audio's asset: scheme isn't supported on web; resolve the
          // asset's actual served URL (assets/assets/<path>) instead.
          await _player.setUrl(Uri.base.resolve('assets/assets/$path').toString());
        } else {
          await _player.setAsset(path);
        }
        await _player.setSpeed(_speed);
        await _player.play();
        _player.playerStateStream
            .firstWhere((s) => s.processingState == ProcessingState.completed)
            .then((_) {
              if (mounted && _playingId == itemId) {
                setState(() => _playingId = null);
              }
            });
        return;
      } catch (_) {
        // fall through to TTS fallback
      }
    }
    if (_ttsReady) {
      await _tts.setSpeechRate(0.4 * _speed);
      await _tts.speak(text);
    }
    if (mounted) setState(() => _playingId = null);
  }

  Future<void> _playQueue(List<DialogLine> lines) async {
    await _stopAll();
    for (final d in lines) {
      if (!mounted) return;
      await _playLine(d.id, d.arabic, d.isMale ? 'male' : 'female');
      // brief pause between speakers
      await Future.delayed(const Duration(milliseconds: 350));
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final storage = context.watch<StorageService>();
    final unit = data.unitById(widget.unitId);

    if (unit == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Unit', textDirection: TextDirection.ltr),
        ),
        body: const Center(
          child: Text('Unit tidak dijumpai', textDirection: TextDirection.ltr),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Unit ${unit.id}', textDirection: TextDirection.ltr),
        actions: [
          IconButton(
            icon: Text(
              'ً',
              style: TextStyle(
                fontFamily: 'Amiri',
                fontWeight: FontWeight.bold,
                fontSize: 20,
                color: _showHarakat
                    ? Theme.of(context).colorScheme.primary
                    : context.tokens.textSecondary,
                decoration: _showHarakat
                    ? null
                    : TextDecoration.lineThrough,
              ),
            ),
            tooltip: _showHarakat ? 'Sembunyikan Harakat' : 'Tunjukkan Harakat',
            onPressed: () => setState(() => _showHarakat = !_showHarakat),
          ),
          IconButton(
            icon: Icon(
              storage.isUnitCompleted(unit.id)
                  ? Icons.check_circle
                  : Icons.check_circle_outline,
            ),
            tooltip: 'Tandakan Selesai',
            onPressed: () => storage.setUnitCompleted(unit.id),
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined),
            tooltip: 'Henti Audio',
            onPressed: _stopAll,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _openingHeader(context, unit),
          const SizedBox(height: 24),
          if (unit.learningContextAr.isNotEmpty)
            _mauqifSection(context, unit),
          if (unit.outcomes.isNotEmpty) _outcomesSection(context, unit),
          if (unit.vocab.isNotEmpty) _vocabSection(context, unit),
          if (unit.illustration != null) _illustrationSection(context, unit),
          if (unit.dialog.isNotEmpty)
            _dialogSection(
              context,
              unit,
              unit.dialog,
              unit.dialogTitleAr.isNotEmpty ? unit.dialogTitleAr : 'الْحِوَارُ',
              'Hiwar',
            ),
          if (unit.expandedDialog.isNotEmpty)
            _dialogSection(
              context,
              unit,
              unit.expandedDialog,
              'نُوَسِّعُ الْحِوَارَ',
              'Memperluas Hiwar',
            ),
          if (unit.pairPracticeSimpleAr.isNotEmpty ||
              unit.pairPracticeRoleA.isNotEmpty)
            _pairPracticeSection(context, unit, storage),
          if (unit.importantExpressions.isNotEmpty)
            _expressionsSection(context, unit),
          if (unit.qawaid.isNotEmpty) _qawaidSection(context, unit),
          if (unit.readingAr.isNotEmpty) _readingSection(context, unit),
          if (unit.ayahAr.isNotEmpty) _ayahSection(context, unit),
          if (unit.hadithAr.isNotEmpty) _hadithSection(context, unit),
          if (unit.exercises.isNotEmpty) _exercisesSection(context, unit),
          if (unit.summaryAr.isNotEmpty) _summarySection(context, unit),
          if (unit.assessmentItems.isNotEmpty)
            _assessmentSection(context, unit, storage),
          const SizedBox(height: 8),
          _navRow(context, unit, storage),
        ],
      ),
    );
  }

  // ---------- shared building blocks ----------

  Widget _card(BuildContext context, {required Widget child}) {
    final tokens = context.tokens;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(22),
        border: isDark ? Border.all(color: tokens.border) : null,
        boxShadow: context.softShadow,
      ),
      child: Material(color: Colors.transparent, child: child),
    );
  }

  Widget _sectionLabel(BuildContext context, String ar, [String my = '']) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Text(
            _h(ar),
            textDirection: TextDirection.rtl,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 20,
              color: scheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (my.isNotEmpty) ...[
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                my,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: tokens.textSecondary,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _arabicBlock(
    BuildContext context,
    String text, {
    double size = 20,
    TextAlign align = TextAlign.right,
  }) {
    final tokens = context.tokens;
    return Text(
      _h(text),
      textAlign: align,
      textDirection: TextDirection.rtl,
      style: TextStyle(
        fontFamily: 'Amiri',
        fontSize: size,
        fontWeight: FontWeight.bold,
        height: 1.9,
        color: tokens.textPrimary,
      ),
    );
  }

  // ---------- sections ----------

  Widget _openingHeader(BuildContext context, UnitModel unit) {
    final tokens = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Unit ${unit.id} • ${unit.code}',
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: 12,
            color: tokens.textSecondary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerEnd,
          child: Text(
            _h(unit.titleAr),
            textDirection: TextDirection.rtl,
            maxLines: 1,
            softWrap: false,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: tokens.textPrimary,
            ),
          ),
        ),
        if (unit.titleSubAr.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            _h(unit.titleSubAr),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'Amiri',
              color: tokens.textSecondary,
              fontSize: 17,
            ),
          ),
        ],
      ],
    );
  }

  Widget _mauqifSection(BuildContext context, UnitModel unit) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'مَوْقِفٌ تَعَلُّمِيٌّ'),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: context.tokens.mist,
              borderRadius: BorderRadius.circular(12),
            ),
            child: _arabicBlock(context, unit.learningContextAr, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _outcomesSection(BuildContext context, UnitModel unit) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'أَهْدَافُ التَّعَلُّمِ'),
          ...unit.outcomes.asMap().entries.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _numberBadge(context, e.key + 1),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _h(e.value),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontSize: 21,
                        height: 1.8,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberBadge(BuildContext context, int n) {
    final tokens = context.tokens;
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tokens.heroGradientStart, tokens.heroGradientEnd],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(
          '$n',
          textDirection: TextDirection.ltr,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _vocabSection(BuildContext context, UnitModel unit) {
    final storage = context.watch<StorageService>();
    final scheme = Theme.of(context).colorScheme;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionLabel(
                  context,
                  'الْمُفْرَدَاتُ',
                  'Kosa Kata (${unit.vocab.length})',
                ),
              ),
              IconButton(
                icon: Icon(Icons.playlist_play, color: scheme.primary),
                tooltip: 'Dengar Semua',
                onPressed: () async {
                  await _stopAll();
                  for (final v in unit.vocab) {
                    if (!mounted) return;
                    await _playLine(
                      v.id,
                      v.arabic,
                      storage.audioPrefs['voice'] as String? ?? 'male',
                    );
                    await Future.delayed(const Duration(milliseconds: 250));
                  }
                },
              ),
            ],
          ),
          ...unit.vocab.map((v) {
            final learned = storage.vocabLearned.contains(v.id);
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: context.tokens.mist,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: Icon(
                      _playingId == v.id
                          ? Icons.graphic_eq
                          : Icons.volume_up_outlined,
                      color: scheme.primary,
                      size: 20,
                    ),
                    onPressed: () => _playLine(
                      v.id,
                      v.arabic,
                      storage.audioPrefs['voice'] as String? ?? 'male',
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _h(v.arabic),
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.right,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          v.meaning,
                          textDirection: TextDirection.ltr,
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: context.tokens.textPrimary,
                            fontSize: 13,
                          ),
                        ),
                        if (v.transliteration.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            v.transliteration,
                            textDirection: TextDirection.ltr,
                            textAlign: TextAlign.left,
                            style: TextStyle(
                              fontSize: 11,
                              color: context.tokens.textSecondary,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      learned ? Icons.bookmark : Icons.bookmark_border,
                      size: 18,
                      color: learned
                          ? scheme.primary
                          : context.tokens.textSecondary,
                    ),
                    tooltip: 'Sudah dipelajari',
                    onPressed: () => storage.toggleVocabLearned(v.id),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _illustrationSection(BuildContext context, UnitModel unit) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: context.tokens.border),
      ),
      child: Image.asset(
        unit.illustration!,
        fit: BoxFit.cover,
        width: double.infinity,
      ),
    );
  }

  Widget _dialogSection(
    BuildContext context,
    UnitModel unit,
    List<DialogLine> lines,
    String headingAr,
    String headingMy,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final revealed = _revealedTranslations.contains(headingMy);
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: _sectionLabel(context, headingAr, headingMy)),
              IconButton(
                icon: Icon(
                  revealed ? Icons.translate : Icons.translate_outlined,
                  color: revealed ? scheme.primary : tokens.textSecondary,
                ),
                tooltip: revealed
                    ? 'Sembunyikan Terjemahan'
                    : 'Tunjukkan Terjemahan',
                onPressed: () => setState(() {
                  if (revealed) {
                    _revealedTranslations.remove(headingMy);
                  } else {
                    _revealedTranslations.add(headingMy);
                  }
                }),
              ),
              IconButton(
                icon: Icon(Icons.playlist_play, color: scheme.primary),
                tooltip: 'Dengar Semua',
                onPressed: () => _playQueue(lines),
              ),
            ],
          ),
          ...lines.map((d) {
            final isMale = d.gender == 'male';
            final bubbleColor = isMale
                ? scheme.primary.withValues(alpha: 0.08)
                : tokens.champagne.withValues(alpha: 0.14);
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: bubbleColor,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: tokens.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isMale ? Icons.person : Icons.person_2,
                        size: 14,
                        color: tokens.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _h(d.speakerAr),
                        textDirection: TextDirection.rtl,
                        style: TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: tokens.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  _arabicBlock(context, d.arabic, size: 22),
                  if (revealed) ...[
                    const SizedBox(height: 6),
                    Divider(height: 1, color: tokens.border),
                    const SizedBox(height: 6),
                    Text(
                      d.meaning,
                      textDirection: TextDirection.ltr,
                      textAlign: TextAlign.left,
                      style: TextStyle(
                        color: tokens.textSecondary,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: IconButton(
                      visualDensity: VisualDensity.compact,
                      icon: Icon(
                        _playingId == d.id
                            ? Icons.graphic_eq
                            : Icons.volume_up_outlined,
                        size: 20,
                        color: scheme.primary,
                      ),
                      onPressed: () => _playLine(
                        d.id,
                        d.arabic,
                        d.gender == 'female' ? 'female' : 'male',
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _pairPracticeSection(
    BuildContext context,
    UnitModel unit,
    StorageService storage,
  ) {
    final done = storage.checkedItems.contains('${unit.code}-pair-practice');
    final tokens = context.tokens;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(
            context,
            'تَدَرَّبْ مَعَ زَمِيلِكَ',
            'Latihan Berpasangan',
          ),
          if (unit.pairPracticeSimpleAr.isNotEmpty)
            _arabicBlock(context, unit.pairPracticeSimpleAr, size: 20),
          if (unit.pairPracticeRoleA.isNotEmpty) ...[
            const SizedBox(height: 8),
            _roleTile(context, 'Pelajar (أ)', unit.pairPracticeRoleA),
            const SizedBox(height: 8),
            _roleTile(context, 'Pelajar (ب)', unit.pairPracticeRoleB),
          ],
          if (unit.pairPracticeConditionsAr.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _h(unit.pairPracticeConditionsAr),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontFamily: 'Amiri',
                color: tokens.textSecondary,
                fontSize: 13,
                height: 1.6,
              ),
            ),
          ],
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () =>
                storage.toggleChecked('${unit.code}-pair-practice'),
            icon: Icon(
              done ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
            ),
            label: Text(
              done ? 'Latihan Selesai' : 'Tandakan Selesai',
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleTile(BuildContext context, String label, String textAr) {
    final tokens = context.tokens;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.mist,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _h(textAr),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            style: const TextStyle(fontFamily: 'Amiri', fontSize: 21),
          ),
        ],
      ),
    );
  }

  Widget _expressionsSection(BuildContext context, UnitModel unit) {
    final tokens = context.tokens;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(
            context,
            'التَّعْبِيرَاتُ الْمُهِمَّةُ',
            'Ungkapan Penting',
          ),
          ...unit.importantExpressions.map(
            (e) => Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: tokens.mist,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _h(e.arabic),
                    textDirection: TextDirection.rtl,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    e.meaning,
                    textDirection: TextDirection.ltr,
                    textAlign: TextAlign.left,
                    style: TextStyle(
                      color: tokens.textSecondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _qawaidSection(BuildContext context, UnitModel unit) {
    final tokens = context.tokens;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'الْقَوَاعِدُ', 'Kaedah Bahasa'),
          ...unit.qawaid.map((q) {
            if (q.containsKey('raw')) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: tokens.mist,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _arabicBlock(context, q['raw'] as String, size: 20),
              );
            }
            final title = q['titleAr'] as String? ?? '';
            final tables = (q['tables'] as List?) ?? [];
            final paragraphs = (q['paragraphs'] as List?) ?? [];
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      _h(title),
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'Amiri',
                        fontWeight: FontWeight.bold,
                        fontSize: 22,
                      ),
                    ),
                  const SizedBox(height: 6),
                  ...paragraphs.map(
                    (p) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        _h(p as String),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ),
                  ...tables.map(
                    (t) =>
                        _miniTable(context, (t as List).cast<List<dynamic>>()),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _miniTable(BuildContext context, List<List<dynamic>> rows) {
    final tokens = context.tokens;
    if (rows.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: tokens.border),
        borderRadius: BorderRadius.circular(10),
      ),
      clipBehavior: Clip.antiAlias,
      child: Table(
        // Row data is authored in literal left-to-right column order (e.g.
        // a trailing "number" column that must land at the visual right
        // edge). Force LTR column layout so it isn't mirrored by the app's
        // ambient RTL Directionality; the Arabic cell text itself still
        // renders RTL via each cell's own textDirection.
        textDirection: TextDirection.ltr,
        border: TableBorder(horizontalInside: BorderSide(color: tokens.border)),
        children: rows.map((row) {
          return TableRow(
            decoration: BoxDecoration(
              color: row == rows.first ? tokens.mist : tokens.card,
            ),
            children: row
                .map(
                  (cell) => Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      _h('$cell'),
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontFamily: 'Amiri', fontSize: 18),
                    ),
                  ),
                )
                .toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _readingSection(BuildContext context, UnitModel unit) {
    final scheme = Theme.of(context).colorScheme;
    final tokens = context.tokens;
    final (arabic, malay) = _splitReadingText(unit.readingAr);
    final revealed = _revealedTranslations.contains('reading-${unit.id}');
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionLabel(
                  context,
                  'النَّصُّ الْقِرَائِيُّ',
                  'Teks Bacaan',
                ),
              ),
              if (malay.isNotEmpty)
                IconButton(
                  icon: Icon(
                    revealed ? Icons.translate : Icons.translate_outlined,
                    color: revealed ? scheme.primary : tokens.textSecondary,
                  ),
                  tooltip: revealed
                      ? 'Sembunyikan Terjemahan'
                      : 'Tunjukkan Terjemahan',
                  onPressed: () => setState(() {
                    if (revealed) {
                      _revealedTranslations.remove('reading-${unit.id}');
                    } else {
                      _revealedTranslations.add('reading-${unit.id}');
                    }
                  }),
                ),
              IconButton(
                icon: Icon(
                  _playingId == '${unit.audioCode}-reading'
                      ? Icons.graphic_eq
                      : Icons.volume_up_outlined,
                  color: scheme.primary,
                ),
                onPressed: () => _playLine(
                  '${unit.audioCode}-reading',
                  arabic,
                  'male',
                ),
              ),
            ],
          ),
          _arabicBlock(context, arabic, size: 22),
          if (revealed) ...[
            const SizedBox(height: 10),
            Divider(height: 1, color: tokens.border),
            const SizedBox(height: 10),
            Text(
              malay,
              textDirection: TextDirection.ltr,
              textAlign: TextAlign.left,
              style: TextStyle(color: tokens.textSecondary, height: 1.6),
            ),
          ],
        ],
      ),
    );
  }

  Widget _ayahSection(BuildContext context, UnitModel unit) {
    final tokens = context.tokens;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'الْآيَةُ الْقُرْآنِيَّةُ', 'Ayat al-Quran'),
          _arabicBlock(context, unit.ayahAr, size: 24),
          if (unit.ayahSource.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _h(unit.ayahSource),
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 12,
                color: tokens.textSecondary,
              ),
            ),
          ],
          if (unit.ayahMaksud.isNotEmpty) ...[
            const Divider(height: 20),
            Text(
              'Maksud:',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unit.ayahMaksud,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: tokens.textSecondary, height: 1.5),
            ),
          ],
          if (unit.ayahReflection.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: tokens.mist,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _h(unit.ayahReflection),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 20),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _hadithSection(BuildContext context, UnitModel unit) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: _sectionLabel(context, 'الْحَدِيثُ الشَّرِيفُ', 'Hadis'),
              ),
              IconButton(
                icon: Icon(
                  _playingId == '${unit.audioCode}-hadith'
                      ? Icons.graphic_eq
                      : Icons.volume_up_outlined,
                  color: scheme.primary,
                ),
                onPressed: () => _playLine(
                  '${unit.audioCode}-hadith',
                  unit.hadithAr,
                  'male',
                ),
              ),
            ],
          ),
          _arabicBlock(context, unit.hadithAr, size: 24),
          if (unit.hadithSource.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              _h(unit.hadithSource),
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 12,
                color: tokens.textSecondary,
              ),
            ),
          ],
          if (unit.hadithMaksud.isNotEmpty) ...[
            const Divider(height: 20),
            Text(
              'Maksud:',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: tokens.textSecondary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              unit.hadithMaksud,
              textDirection: TextDirection.ltr,
              style: TextStyle(color: tokens.textSecondary, height: 1.5),
            ),
          ],
          if (unit.hadithLessons.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _h('الدُّرُوسُ الْمُسْتَفَادَةُ'),
              textDirection: TextDirection.rtl,
              style: TextStyle(
                fontFamily: 'Amiri',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: scheme.primary,
              ),
            ),
            ...unit.hadithLessons.map(
              (l) => Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.circle, size: 6, color: tokens.textSecondary),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _h(l),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _exercisesSection(BuildContext context, UnitModel unit) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'التَّمَارِينُ', 'Latihan'),
          ...unit.exercises.map(
            (ex) => Padding(
              padding: const EdgeInsets.only(bottom: 18),
              child: ex.type == 'matching'
                  ? MatchingExercise(
                      exercise: ex,
                      unit: unit,
                      showHarakat: _showHarakat,
                    )
                  : _OpenExercise(exercise: ex, showHarakat: _showHarakat),
            ),
          ),
          if (unit.modelAnswersAr.isNotEmpty)
            _ModelAnswersReveal(
              answers: unit.modelAnswersAr,
              showHarakat: _showHarakat,
            ),
        ],
      ),
    );
  }

  Widget _summarySection(BuildContext context, UnitModel unit) {
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(context, 'خُلَاصَةُ الْوَحْدَةِ', 'Rumusan'),
          _arabicBlock(context, unit.summaryAr, size: 20),
        ],
      ),
    );
  }

  Widget _assessmentSection(
    BuildContext context,
    UnitModel unit,
    StorageService storage,
  ) {
    final scheme = Theme.of(context).colorScheme;
    return _card(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel(
            context,
            'التَّقْوِيمُ الذَّاتِيُّ',
            'Penilaian Kendiri',
          ),
          ...unit.assessmentItems.asMap().entries.map((e) {
            final id = '${unit.code}-assess-${e.key}';
            final checked = storage.checkedItems.contains(id);
            return CheckboxListTile(
              value: checked,
              onChanged: (_) => storage.toggleChecked(id),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: scheme.primary,
              title: Text(
                _h(e.value),
                textDirection: TextDirection.rtl,
                textAlign: TextAlign.right,
                style: const TextStyle(fontFamily: 'Amiri', fontSize: 21),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _navRow(BuildContext context, UnitModel unit, StorageService storage) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: unit.id > 1
              ? () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UnitScreen(unitId: unit.id - 1),
                  ),
                )
              : null,
          icon: const Icon(Icons.arrow_back, size: 18),
          label: const Text('Sebelum', textDirection: TextDirection.ltr),
        ),
        ElevatedButton.icon(
          onPressed: () => storage.setUnitCompleted(unit.id),
          icon: const Icon(Icons.check, size: 18),
          label: Text(
            storage.isUnitCompleted(unit.id) ? 'Selesai' : 'Tandakan Selesai',
            textDirection: TextDirection.ltr,
          ),
        ),
        TextButton.icon(
          onPressed: unit.id < 14
              ? () => Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                    builder: (_) => UnitScreen(unitId: unit.id + 1),
                  ),
                )
              : null,
          icon: const Icon(Icons.arrow_forward, size: 18),
          label: const Text('Seterusnya', textDirection: TextDirection.ltr),
        ),
      ],
    );
  }
}

/// The reading passage (النَّصُّ الْقِرَائِيُّ) is stored with its Malay
/// translation appended in the same string, e.g. "...دِرَاسَتِهِ. Maksud:
/// Kursus Bahasa Arab...". Split it so the Arabic body and the Malay gloss
/// can be rendered (and revealed) separately instead of running together
/// as one RTL Amiri block.
final _maksudSplitPattern = RegExp(
  r'\s*(?:Maksud:|التَّرْجَمَةُ بِاللُّغَةِ الْمَلَايُوِيَّةِ:)\s*',
);

(String arabic, String malay) _splitReadingText(String text) {
  final parts = text.split(_maksudSplitPattern);
  if (parts.length < 2) return (text.trim(), '');
  return (parts.first.trim(), parts.sublist(1).join(' ').trim());
}

/// Exercise prompt text from the source guide packs multiple numbered
/// sub-questions (e.g. "١. ... ٢. ... ٣. ...") into one run-on string with
/// no line breaks. Split on the Arabic-Indic numeral markers so each
/// sub-question renders as its own paragraph instead of one dense block.
List<String> _splitNumberedArabic(String text) {
  final markers = RegExp(r'[٠-٩]+\.').allMatches(text).toList();
  if (markers.length < 2) return [text];
  final lines = <String>[];
  if (markers.first.start > 0) {
    final lead = text.substring(0, markers.first.start).trim();
    if (lead.isNotEmpty) lines.add(lead);
  }
  for (var i = 0; i < markers.length; i++) {
    final start = markers[i].start;
    final end = i + 1 < markers.length ? markers[i + 1].start : text.length;
    final segment = text.substring(start, end).trim();
    if (segment.isNotEmpty) lines.add(segment);
  }
  return lines;
}

class _OpenExercise extends StatefulWidget {
  final ExerciseBlock exercise;
  final bool showHarakat;
  const _OpenExercise({required this.exercise, required this.showHarakat});

  @override
  State<_OpenExercise> createState() => _OpenExerciseState();
}

class _OpenExerciseState extends State<_OpenExercise> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final done = storage.checkedItems.contains(widget.exercise.id);
    final tokens = context.tokens;
    String h(String s) => widget.showHarakat ? s : stripHarakat(s);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          h(widget.exercise.titleAr),
          textDirection: TextDirection.rtl,
          textAlign: TextAlign.right,
          style: const TextStyle(
            fontFamily: 'Amiri',
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        const SizedBox(height: 6),
        ..._splitNumberedArabic(widget.exercise.promptAr).map(
          (line) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              h(line),
              textDirection: TextDirection.rtl,
              textAlign: TextAlign.right,
              style: TextStyle(
                height: 1.8,
                color: tokens.textPrimary,
                fontFamily: 'Amiri',
                fontSize: 21,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          textDirection: TextDirection.rtl,
          maxLines: 3,
          style: const TextStyle(fontFamily: 'Amiri', fontSize: 18),
          decoration: const InputDecoration(hintText: 'Tulis jawapan anda...'),
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: () => storage.toggleChecked(widget.exercise.id),
          icon: Icon(
            done ? Icons.check_circle : Icons.circle_outlined,
            size: 18,
          ),
          label: Text(
            done ? 'Ditandakan Selesai' : 'Tandakan Selesai',
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    );
  }
}

/// Lecturer answer-guide model answers for this unit, collapsed by default --
/// the student must explicitly tap to reveal them. Framed as guidance
/// ("نموذج الإجابة", per the guide's own wording), not an auto-grading key:
/// open-ended activities may have more than one acceptable answer.
class _ModelAnswersReveal extends StatefulWidget {
  final List<String> answers;
  final bool showHarakat;
  const _ModelAnswersReveal({required this.answers, required this.showHarakat});

  @override
  State<_ModelAnswersReveal> createState() => _ModelAnswersRevealState();
}

class _ModelAnswersRevealState extends State<_ModelAnswersReveal> {
  bool _revealed = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: tokens.mist,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: () => setState(() => _revealed = !_revealed),
            child: Row(
              children: [
                Icon(
                  _revealed
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: scheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _revealed
                        ? 'Sembunyikan نَمُوذَجَ الْإِجَابَةِ'
                        : 'Papar نَمُوذَجُ الْإِجَابَةِ (Panduan Pensyarah)',
                    textDirection: TextDirection.ltr,
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: scheme.primary,
                      fontSize: 13,
                    ),
                  ),
                ),
                Icon(
                  _revealed ? Icons.expand_less : Icons.expand_more,
                  color: scheme.primary,
                ),
              ],
            ),
          ),
          if (_revealed) ...[
            const SizedBox(height: 10),
            Text(
              'Ini contoh jawapan daripada panduan pensyarah. Aktiviti terbuka mungkin menerima lebih daripada satu jawapan yang betul.',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontSize: 11,
                color: tokens.textSecondary,
                fontStyle: FontStyle.italic,
              ),
            ),
            const Divider(height: 20),
            ...widget.answers.asMap().entries.map(
              (e) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${e.key + 1}.',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: tokens.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        widget.showHarakat ? e.value : stripHarakat(e.value),
                        textDirection: TextDirection.rtl,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          fontFamily: 'Amiri',
                          fontSize: 20,
                          height: 1.7,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
