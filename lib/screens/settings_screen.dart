import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/data_service.dart';
import '../theme/app_theme.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final data = context.watch<DataService>();
    final audioPrefs = storage.audioPrefs;
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Tetapan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle(context, 'Paparan'),
          const SizedBox(height: 8),
          _card(
            context,
            child: Column(
              children: [
                _themeRow(context, storage),
                const Divider(height: 24),
                _textSizeRow(context, storage),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, 'Audio'),
          const SizedBox(height: 8),
          _card(
            context,
            child: Column(
              children: [
                _settingTile(
                  context,
                  icon: Icons.record_voice_over_outlined,
                  title: 'Suara Lalai',
                  subtitle: 'Digunakan untuk kosa kata & bacaan bebas jantina',
                  value: audioPrefs['voice'] == 'female' ? 'Wanita' : 'Lelaki',
                  options: const {'male': 'Lelaki', 'female': 'Wanita'},
                  onSelected: (v) => storage.setAudioPref('voice', v),
                ),
                const Divider(height: 24),
                _settingTile(
                  context,
                  icon: Icons.speed_outlined,
                  title: 'Kelajuan Main Semula',
                  value: '${audioPrefs['speed'] ?? 1.0}×',
                  options: const {
                    '0.75': '0.75×',
                    '1.0': '1.0×',
                    '1.25': '1.25×',
                  },
                  onSelected: (v) =>
                      storage.setAudioPref('speed', double.tryParse(v) ?? 1.0),
                ),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.info_outline, color: scheme.primary),
                  title: const Text('Mengenai Audio & TTS'),
                  subtitle: const Text(
                    'Hiwar lelaki: suara Piper Arab pra-jana. Suara wanita & fallback lain: TTS peranti (luar talian).',
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, 'Kemajuan Pembelajaran'),
          const SizedBox(height: 8),
          _card(
            context,
            child: Column(
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    Icons.check_circle_outline,
                    color: scheme.primary,
                  ),
                  title: const Text('Unit Selesai'),
                  trailing: Text(
                    '${storage.completedUnitCount}/14',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: tokens.textPrimary,
                    ),
                  ),
                ),
                const Divider(height: 24),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.delete_forever_outlined,
                    color: Colors.red,
                  ),
                  title: const Text(
                    'Reset Semua Progress',
                    style: TextStyle(color: Colors.red),
                  ),
                  onTap: () => _confirmReset(context, storage),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _sectionTitle(context, 'Mengenai Kursus'),
          const SizedBox(height: 8),
          _card(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.course?.courseTitleAr ?? '',
                  textDirection: TextDirection.rtl,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'LotusLinotype',
                    fontSize: 22.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  data.course?.courseTitleEn ?? 'Basic Arabic for Muamalat',
                  style: TextStyle(color: tokens.textSecondary),
                ),
                Text(
                  data.course?.courseCode ?? 'UMT3033',
                  style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 10),
                Text(
                  data.course?.authorName ?? '',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: tokens.textPrimary,
                    fontSize: 13,
                  ),
                ),
                Text(
                  data.course?.authorTitle ?? '',
                  style: TextStyle(color: tokens.textSecondary, fontSize: 12),
                ),
                const SizedBox(height: 12),
                Text(
                  'Aplikasi ini berfungsi sepenuhnya luar talian. Tiada data peribadi dikumpul atau dihantar ke pelayan.',
                  style: TextStyle(color: tokens.textSecondary, fontSize: 11.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w800,
        color: context.tokens.textSecondary,
        letterSpacing: 0.3,
      ),
    );
  }

  Widget _card(BuildContext context, {required Widget child}) {
    final tokens = context.tokens;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: tokens.border),
      ),
      child: Material(color: Colors.transparent, child: child),
    );
  }

  Widget _themeRow(BuildContext context, StorageService storage) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.palette_outlined, color: scheme.primary),
        const SizedBox(width: 12),
        const Expanded(child: Text('Tema')),
        SegmentedButton<String>(
          segments: const [
            ButtonSegment(
              value: 'light',
              label: Text('Cerah'),
              icon: Icon(Icons.light_mode_outlined, size: 16),
            ),
            ButtonSegment(
              value: 'dark',
              label: Text('Gelap'),
              icon: Icon(Icons.dark_mode_outlined, size: 16),
            ),
            ButtonSegment(
              value: 'system',
              label: Text('Auto'),
              icon: Icon(Icons.brightness_auto, size: 16),
            ),
          ],
          selected: {storage.theme},
          onSelectionChanged: (s) => storage.setTheme(s.first),
          showSelectedIcon: false,
          style: const ButtonStyle(visualDensity: VisualDensity.compact),
        ),
      ],
    );
  }

  Widget _textSizeRow(BuildContext context, StorageService storage) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(Icons.text_fields, color: scheme.primary),
        const SizedBox(width: 12),
        const Expanded(child: Text('Saiz Teks Arab')),
        IconButton(
          icon: const Icon(Icons.remove_circle_outline),
          onPressed: storage.textScale > 0.85
              ? () => storage.setTextScale(
                  (storage.textScale - 0.1).clamp(0.85, 1.4),
                )
              : null,
        ),
        Text('${(storage.textScale * 100).round()}%'),
        IconButton(
          icon: const Icon(Icons.add_circle_outline),
          onPressed: storage.textScale < 1.4
              ? () => storage.setTextScale(
                  (storage.textScale + 0.1).clamp(0.85, 1.4),
                )
              : null,
        ),
      ],
    );
  }

  Widget _settingTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    required String value,
    required Map<String, String> options,
    required void Function(String) onSelected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, color: scheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11,
                    color: context.tokens.textSecondary,
                  ),
                ),
            ],
          ),
        ),
        PopupMenuButton<String>(
          onSelected: onSelected,
          itemBuilder: (_) => options.entries
              .map((e) => PopupMenuItem(value: e.key, child: Text(e.value)))
              .toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: scheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              value,
              style: TextStyle(
                color: scheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _confirmReset(BuildContext context, StorageService storage) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Progress?'),
        content: const Text(
          'Semua kemajuan pembelajaran akan dipadam. Tindakan ini tidak boleh dibatalkan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () {
              storage.resetAll();
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }
}
