import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:just_audio/just_audio.dart';
import '../models/unit_model.dart';
import '../services/data_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class UnitScreen extends StatefulWidget {
  final int unitId;
  const UnitScreen({super.key, required this.unitId});

  @override
  State<UnitScreen> createState() => _UnitScreenState();
}

class _UnitScreenState extends State<UnitScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AudioPlayer _audioPlayer = AudioPlayer();

  static const _tabs = [
    {'id': 'outcomes', 'label': 'Pembelajaran', 'labelAr': 'نَتَائِج'},
    {'id': 'intro', 'label': 'Pengenalan', 'labelAr': 'مُقَدِّمَة'},
    {'id': 'vocab', 'label': 'Kosa Kata', 'labelAr': 'مُفْرَدَات'},
    {'id': 'dialog', 'label': 'Dialog', 'labelAr': 'حِوَار'},
    {'id': 'reading', 'label': 'Bacaan', 'labelAr': 'قِرَاءَة'},
    {'id': 'dalil', 'label': 'Dalil', 'labelAr': 'دَلِيل'},
    {'id': 'rules', 'label': 'Kaidah', 'labelAr': 'قَوَاعِد'},
    {'id': 'exercises', 'label': 'Latihan', 'labelAr': 'تَمَارِين'},
    {'id': 'summary', 'label': 'Rumusan', 'labelAr': 'خُلَاصَة'},
    {'id': 'assessment', 'label': 'Penilaian', 'labelAr': 'تَقْوِيم'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _tabController.dispose();
    super.dispose();
  }

  String _voiceGender() {
    final prefs = context.read<StorageService>().audioPrefs;
    return prefs['voice'] as String? ?? 'male';
  }

  void _playItem(String itemId, String fallbackText) {
    final data = context.read<DataService>();
    final prefs = context.read<StorageService>().audioPrefs;
    final gender = _voiceGender();
    final path = data.getAudioPath(itemId, gender);

    if (path != null) {
      _audioPlayer.stop();
      _audioPlayer.setAsset(path).then((_) {
        _audioPlayer.setSpeed((prefs['speed'] as num?)?.toDouble() ?? 1.0);
        _audioPlayer.play();
      }).catchError((_) {});
    } else {
      _playTtsFallback(fallbackText);
    }
  }

  void _playTtsFallback(String text) {
    _audioPlayer.stop();
  }

  void _playVocabQueue(List<VocabItem> items) {
    _audioPlayer.stop();
    final data = context.read<DataService>();
    final gender = _voiceGender();
    final sources = <AudioSource>[];
    for (final v in items) {
      final path = data.getAudioPath(v.id, gender);
      if (path != null) sources.add(AudioSource.asset(path));
    }
    if (sources.isNotEmpty) {
      _audioPlayer.setAudioSource(ConcatenatingAudioSource(children: sources)).then((_) {
        _audioPlayer.play();
      });
    }
  }

  void _playDialogQueue(List<DialogLine> lines) {
    _audioPlayer.stop();
    final data = context.read<DataService>();
    final sources = <AudioSource>[];
    for (final d in lines) {
      final g = _voiceGender() == 'auto' ? d.gender : _voiceGender();
      final path = data.getAudioPath(d.id, g);
      if (path != null) sources.add(AudioSource.asset(path));
    }
    if (sources.isNotEmpty) {
      _audioPlayer.setAudioSource(ConcatenatingAudioSource(children: sources)).then((_) {
        _audioPlayer.play();
      });
    }
  }

  void _cycleVoice() {
    final storage = context.read<StorageService>();
    final current = _voiceGender();
    final next = current == 'male' ? 'female' : (current == 'female' ? 'auto' : 'male');
    storage.setAudioPref('voice', next);
  }

  IconData _voiceIcon() {
    return switch (_voiceGender()) {
      'female' => Icons.voice_chat,
      'auto' => Icons.auto_awesome,
      _ => Icons.record_voice_over,
    };
  }

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final storage = context.watch<StorageService>();
    final unit = data.units.where((u) => u.id == widget.unitId).firstOrNull;

    if (unit == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Unit')),
        body: const Center(child: Text('Unit tidak dijumpai')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Unit ${unit.id}: ${unit.title}'),
        actions: [
          IconButton(
            icon: Icon(_voiceIcon()),
            tooltip: 'Suara: ${_voiceGender() == 'male' ? 'Lelaki' : _voiceGender() == 'female' ? 'Wanita' : 'Auto'}',
            onPressed: _cycleVoice,
          ),
          IconButton(
            icon: Icon(storage.isUnitCompleted(unit.id) ? Icons.check_circle : Icons.check_circle_outline),
            tooltip: 'Tandakan Selesai',
            onPressed: () => storage.setUnitCompleted(unit.id),
          ),
          IconButton(
            icon: const Icon(Icons.stop_circle_outlined),
            tooltip: 'Henti Audio',
            onPressed: () => _audioPlayer.stop(),
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: Theme.of(context).scaffoldBackgroundColor,
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              labelColor: AppColors.accentHover,
              unselectedLabelColor: AppColors.textMuted,
              indicatorColor: AppColors.accent,
              tabs: _tabs.map((t) => Tab(text: t['label'])).toList(),
            ),
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _tabs.map((t) => _buildTab(t['id']!, unit, storage)).toList(),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        color: AppColors.darkCocoa,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            TextButton.icon(
              onPressed: widget.unitId > 1
                  ? () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UnitScreen(unitId: widget.unitId - 1)))
                  : null,
              icon: const Icon(Icons.arrow_back, color: AppColors.mutedBrown),
              label: const Text('Sebelum', style: TextStyle(color: AppColors.mutedBrown)),
            ),
            ElevatedButton.icon(
              onPressed: () => storage.setUnitCompleted(widget.unitId),
              icon: const Icon(Icons.check, size: 18),
              label: Text(storage.isUnitCompleted(unit.id) ? 'Selesai' : 'Tandakan Selesai'),
            ),
            TextButton.icon(
              onPressed: widget.unitId < 14
                  ? () => Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => UnitScreen(unitId: widget.unitId + 1)))
                  : null,
              icon: const Icon(Icons.arrow_forward, color: AppColors.mutedBrown),
              label: const Text('Seterusnya', style: TextStyle(color: AppColors.mutedBrown)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTab(String tabId, UnitModel unit, StorageService storage) {
    switch (tabId) {
      case 'outcomes': return _outcomesTab(unit);
      case 'intro': return _readingTab('Pengenalan Unit', 'مُقَدِّمَة', unit.introductionAr, unit.introduction, 'u01-intro');
      case 'vocab': return _vocabTab(unit);
      case 'dialog': return _dialogTab(unit);
      case 'reading': return _readingTab('Teks Bacaan', 'النَّصُّ الْقِرَائِيُّ', unit.readingAr, unit.readingMs, 'u01-reading');
      case 'dalil': return _dalilTab(unit);
      case 'rules': return _placeholderTab('Kaidah Bahasa', 'الْقَوَاعِدُ', unit.rules['content'] as String? ?? '');
      case 'exercises': return _exercisesTab(unit);
      case 'summary': return _readingTab('Rumusan', 'خُلَاصَةُ الْوَحْدَةِ', unit.summaryAr, unit.summary, 'u01-summary');
      case 'assessment': return _assessmentTab(unit);
      default: return const Center(child: Text('Kandungan tidak tersedia'));
    }
  }

  Widget _sectionLabel(String ar) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: AppColors.accent.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.accent.withValues(alpha: 0.2))),
      child: Text(ar, style: const TextStyle(fontFamily: 'LotusLinotype', fontSize: 14, color: AppColors.accent, fontWeight: FontWeight.bold)),
    );
  }

  Widget _outcomesTab(UnitModel unit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('نَتَائِجُ التَّعَلُّمِ'),
        const SizedBox(height: 8),
        const Text('Hasil Pembelajaran', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ...unit.outcomes.asMap().entries.map((e) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.accent.withValues(alpha: 0.15))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 26, height: 26, decoration: const BoxDecoration(color: AppColors.accentHover, shape: BoxShape.circle), child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)))),
            const SizedBox(width: 10),
            Expanded(child: Text(e.value, style: const TextStyle(color: AppColors.textMuted))),
          ]),
        )),
      ]),
    );
  }

  Widget _readingTab(String title, String labelAr, String arText, String myText, String audioId) {
    final isPlaceholder = arText.contains('[PERLU') || arText.contains('[KANDUNGAN');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel(labelAr),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        if (isPlaceholder)
          _emptyState('Kandungan akan tersedia selepas pengesahan pensyarah')
        else ...[
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0x22F5670A), Color(0xFFFFF8F1)], begin: Alignment.topLeft, end: Alignment.bottomRight), borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.accent.withValues(alpha: 0.2))),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              IconButton(icon: const Icon(Icons.volume_up, color: AppColors.accentHover), onPressed: () => _playItem(audioId, arText)),
              Expanded(child: Text(arText, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'LotusLinotype', fontSize: 22, fontWeight: FontWeight.bold, height: 1.8, color: AppColors.textMid))),
            ]),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: const Color(0xFFFFF8F1), borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.textDark.withValues(alpha: 0.08))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Terjemahan:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
              const SizedBox(height: 6),
              Text(myText, style: const TextStyle(color: AppColors.textMuted, height: 1.6)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _vocabTab(UnitModel unit) {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          _sectionLabel('الْمُفْرَدَاتُ'),
          const Spacer(),
          IconButton(icon: const Icon(Icons.playlist_play, color: AppColors.accentHover), tooltip: 'Dengar Semua', onPressed: () => _playVocabQueue(unit.vocab)),
        ]),
      ),
      Expanded(
        child: unit.vocab.isEmpty
            ? _emptyState('Tiada kosa kata untuk unit ini')
            : ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: unit.vocab.length,
                itemBuilder: (_, i) {
                  final v = unit.vocab[i];
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(12),
                      leading: IconButton(icon: const Icon(Icons.volume_up, color: AppColors.accentHover), onPressed: () => _playItem(v.id, v.arabic)),
                      title: Text(v.arabic, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'LotusLinotype', fontSize: 24, fontWeight: FontWeight.bold, height: 1.6)),
                      subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(v.meaning, style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMid)),
                        if (v.type.isNotEmpty) Text(v.type, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ]),
                    ),
                  );
                },
              ),
      ),
    ]);
  }

  Widget _dialogTab(UnitModel unit) {
    if (unit.dialog.isEmpty) return _emptyState('Dialog belum tersedia');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          _sectionLabel('الْحِوَارُ'),
          const Spacer(),
          IconButton(icon: const Icon(Icons.playlist_play, color: AppColors.accentHover), tooltip: 'Dengar Semua', onPressed: () => _playDialogQueue(unit.dialog)),
        ]),
        const SizedBox(height: 8),
        const Text('Dialog', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        ...unit.dialog.map((d) {
          final isMale = d.gender == 'male';
          return Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isMale ? const Color(0xFF4A1F0D) : AppColors.cream,
              borderRadius: BorderRadius.circular(16),
              border: isMale ? Border.all(color: AppColors.accent.withValues(alpha: 0.2)) : Border.all(color: AppColors.accent.withValues(alpha: 0.15)),
            ),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(d.speakerAr, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isMale ? AppColors.accentSoft : AppColors.accentHover)),
              const SizedBox(height: 4),
              Text(d.arabic, textAlign: TextAlign.right, style: TextStyle(fontFamily: 'LotusLinotype', fontSize: 20, fontWeight: FontWeight.bold, height: 1.6, color: isMale ? AppColors.textOnDark : AppColors.textMid)),
              const SizedBox(height: 4),
              Text(d.speakerLabel, style: TextStyle(fontSize: 11, color: isMale ? AppColors.mutedBrown : AppColors.textMuted)),
              Text(d.meaning, style: TextStyle(color: isMale ? AppColors.mutedBrown : AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 6),
              IconButton(icon: Icon(Icons.volume_up, size: 22, color: isMale ? AppColors.accentSoft : AppColors.accentHover), onPressed: () => _playItem(d.id, d.arabic)),
            ]),
          );
        }),
      ]),
    );
  }

  Widget _dalilTab(UnitModel unit) {
    final isPlaceholder = unit.hadithAr.contains('[KANDUNGAN');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('الْآيَةُ وَالْحَدِيثُ'),
        const SizedBox(height: 8),
        const Text('Ayat & Hadis', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        if (isPlaceholder)
          _emptyState('Dalil akan tersedia selepas pengesahan pensyarah')
        else ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(gradient: const LinearGradient(colors: [Color(0xFFFFFAF6), Color(0xFFFDF2E4)]), borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.accent.withValues(alpha: 0.2))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(unit.hadithAr, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'LotusLinotype', fontSize: 24, fontWeight: FontWeight.bold, height: 2.0)),
              const SizedBox(height: 8),
              if (unit.hadithSource.isNotEmpty) Text(unit.hadithSource, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const SizedBox(height: 10),
              if (unit.hadithMaksud.isNotEmpty) ...[
                const Divider(),
                const Text('Maksud:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textMuted)),
                Text(unit.hadithMaksud, style: const TextStyle(color: AppColors.textMuted, height: 1.5)),
              ],
            ]),
          ),
          if (unit.hadithLessons.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Pengajaran', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ...unit.hadithLessons.asMap().entries.map((e) => Container(
              margin: const EdgeInsets.only(top: 6),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(10)),
              child: Row(children: [
                Container(width: 22, height: 22, decoration: const BoxDecoration(color: AppColors.accentHover, shape: BoxShape.circle), child: Center(child: Text('${e.key + 1}', style: const TextStyle(color: Colors.white, fontSize: 11)))),
                const SizedBox(width: 8),
                Expanded(child: Text(e.value, style: const TextStyle(fontFamily: 'LotusLinotype', fontSize: 15))),
              ]),
            )),
          ],
        ],
      ]),
    );
  }

  Widget _exercisesTab(UnitModel unit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('التَّمَارِينُ'),
        const SizedBox(height: 8),
        const Text('Latihan', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        if (unit.exercises.isEmpty || unit.exercises[0].contains('[PERLU'))
          _emptyState('Latihan akan tersedia selepas pengesahan pensyarah')
        else
          ...unit.exercises.asMap().entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(14), border: Border.all(color: AppColors.textDark.withValues(alpha: 0.08))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${e.key + 1}. ${e.value}', style: const TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              TextField(decoration: InputDecoration(hintText: 'Tulis jawapan...', filled: true, fillColor: AppColors.warmWhite), maxLines: 2),
            ]),
          )),
      ]),
    );
  }

  Widget _assessmentTab(UnitModel unit) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel('التَّقْوِيمُ الذَّاتِيُّ'),
        const SizedBox(height: 8),
        const Text('Penilaian Kendiri', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        if (unit.assessmentItems.isEmpty)
          _emptyState('Penilaian kendiri akan tersedia selepas pengesahan pensyarah')
        else
          ...unit.assessmentItems.asMap().entries.map((e) => Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(color: AppColors.warmWhite, borderRadius: BorderRadius.circular(10), border: Border.all(color: AppColors.textDark.withValues(alpha: 0.06))),
            child: Row(children: [
              Checkbox(value: false, onChanged: (_) {}, activeColor: AppColors.accent),
              IconButton(icon: const Icon(Icons.volume_up, color: AppColors.accentHover, size: 22), onPressed: () => _playItem('u01-assess-${(e.key + 1).toString().padLeft(3, '0')}', e.value)),
              Expanded(child: Text(e.value, textAlign: TextAlign.right, style: const TextStyle(fontFamily: 'LotusLinotype', fontSize: 17))),
            ]),
          )),
      ]),
    );
  }

  Widget _placeholderTab(String title, String labelAr, String content) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _sectionLabel(labelAr),
        const SizedBox(height: 8),
        Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        content.contains('[KANDUNGAN') ? _emptyState('Kandungan kaidah akan tersedia selepas pengesahan pensyarah') : Text(content),
      ]),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      margin: const EdgeInsets.only(top: 32),
      padding: const EdgeInsets.all(32),
      child: Column(children: [
        const Icon(Icons.hourglass_empty, size: 48, color: AppColors.mutedBrown),
        const SizedBox(height: 12),
        Text(message, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.textMuted)),
      ]),
    );
  }
}
