import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final storage = context.watch<StorageService>();
    final audioPrefs = storage.audioPrefs;

    return Scaffold(
      appBar: AppBar(title: const Text('Tetapan')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle('Audio'),
          const SizedBox(height: 8),
          _settingTile(
            icon: Icons.person,
            title: 'Suara',
            value: audioPrefs['voice'] ?? 'male',
            options: ['male', 'female'],
            onSelected: (v) => storage.setAudioPref('voice', v),
          ),
          _settingTile(
            icon: Icons.speed,
            title: 'Kelajuan',
            value: '${audioPrefs['speed'] ?? 1.0}×',
            options: ['0.75×', '1.0×', '1.25×'],
            onSelected: (v) {
              final sp = double.tryParse(v.replaceAll('×', '')) ?? 1.0;
              storage.setAudioPref('speed', sp);
            },
          ),
          const SizedBox(height: 16),
          _sectionTitle('Tema'),
          SwitchListTile(
            title: const Text('Mod Gelap'),
            value: storage.theme == 'dark',
            onChanged: (v) => storage.setTheme(v ? 'dark' : 'light'),
            activeThumbColor: AppColors.accent,
          ),
          const SizedBox(height: 16),
          _sectionTitle('Progress'),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Eksport Progress'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: const Icon(Icons.upload),
            title: const Text('Import Progress'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {},
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: AppColors.error),
            title: const Text('Reset Semua Progress', style: TextStyle(color: AppColors.error)),
            onTap: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Reset Progress?'),
                  content: const Text('Semua kemajuan akan dipadam. Tindakan ini tidak boleh dibatalkan.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
                    ElevatedButton(
                      onPressed: () {
                        storage.resetAll();
                        Navigator.pop(ctx);
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.error),
                      child: const Text('Reset'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(text, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textMid));
  }

  Widget _settingTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> options,
    required void Function(String) onSelected,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.accent),
      title: Text(title),
      trailing: PopupMenuButton<String>(
        initialValue: value,
        onSelected: onSelected,
        itemBuilder: (_) => options.map((o) => PopupMenuItem(value: o, child: Text(o))).toList(),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(value, style: const TextStyle(color: AppColors.accentHover, fontWeight: FontWeight.w600)),
        ),
      ),
    );
  }
}
