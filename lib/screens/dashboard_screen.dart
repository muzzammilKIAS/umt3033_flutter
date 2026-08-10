import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/unit_model.dart';
import '../services/data_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/unit_card.dart';

class DashboardScreen extends StatelessWidget {
  final void Function(int unitId) onOpenUnit;

  const DashboardScreen({super.key, required this.onOpenUnit});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final storage = context.watch<StorageService>();
    final course = data.course;
    final units = data.units;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'اللُّغَةُ الْعَرَبِيَّةُ لِلْمُعَامَلَاتِ',
              style: TextStyle(
                fontFamily: 'LotusLinotype',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textOnDark,
              ),
            ),
            Text(
              'Basic Arabic for Muamalat • UMT3033',
              style: TextStyle(
                fontSize: 11,
                color: AppColors.mutedBrown,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
            onPressed: () {
              storage.setTheme(isDark ? 'light' : 'dark');
            },
          ),
        ],
      ),
      body: units.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _heroSection(context, course, storage),
                const SizedBox(height: 20),
                _progressCards(storage, context),
                const SizedBox(height: 24),
                _sectionHeader('فِهْرِسُ الْوَحَدَاتِ', 'Senarai Unit Pembelajaran'),
                const SizedBox(height: 12),
                ...units.map((u) => UnitCard(
                      unit: u,
                      completed: storage.isUnitCompleted(u.id),
                      onTap: () => onOpenUnit(u.id),
                    )),
              ],
            ),
    );
  }

  Widget _heroSection(BuildContext context, CourseModel? course, StorageService storage) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF2A1008), Color(0xFF4A1F0D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow('MODUL INTERAKTIF • 14 UNIT'),
          const SizedBox(height: 12),
          Text(
            'اللُّغَةُ الْعَرَبِيَّةُ لِلْمُعَامَلَاتِ',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontFamily: 'LotusLinotype',
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: AppColors.textOnDark,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            course?.courseTitleEn ?? 'Basic Arabic for Muamalat',
            style: TextStyle(
              color: AppColors.mutedBrown,
              fontSize: 14,
            ),
          ),
          Text(
            '${course?.courseCode ?? 'UMT3033'} • ${course?.authorName ?? ''}',
            style: TextStyle(
              color: AppColors.accentSoft,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () => onOpenUnit(storage.lastUnitId),
                icon: const Icon(Icons.play_arrow, size: 20),
                label: Text(storage.lastUnitId > 1 ? 'Sambung Belajar' : 'Mula Belajar'),
              ),
              const SizedBox(width: 12),
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accentSoft,
                  side: const BorderSide(color: AppColors.accentSoft),
                ),
                child: const Text('Panduan Kursus'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _eyebrow(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.accent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.accent.withValues(alpha: 0.4)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.accentSoft,
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  Widget _progressCards(StorageService storage, BuildContext ctx) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(ctx).cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.textDark.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionKicker('تَقَدُّمُ التَّعَلُّمِ', 'Progress'),
          const SizedBox(height: 12),
          Row(
            children: [
              _statCard('Unit Selesai', '${storage.completedUnitCount}/14', Icons.check_circle),
              _statCard('Kosa Kata', '${storage.vocabLearned.length}', Icons.book),
              _statCard('Progress', '${(storage.overallProgress * 100).round()}%', Icons.trending_up),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: storage.overallProgress,
              backgroundColor: AppColors.accent.withValues(alpha: 0.1),
              color: AppColors.accent,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statCard(String label, String value, IconData icon) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.warmWhite,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.textDark.withValues(alpha: 0.06)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 22, color: AppColors.accent),
              const SizedBox(height: 6),
              Text(value,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.accentHover)),
              Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String ar, String my) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Text(ar,
              style: TextStyle(
                  fontFamily: 'LotusLinotype', fontSize: 14, color: AppColors.accent, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(my, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textMid)),
          ),
          _countBadge('14 Unit'),
        ],
      ),
    );
  }

  Widget _sectionKicker(String ar, String my) {
    return Row(
      children: [
        Text(ar,
            style: TextStyle(
                fontFamily: 'LotusLinotype', fontSize: 13, color: AppColors.accent, fontWeight: FontWeight.bold)),
        const SizedBox(width: 6),
        Text(my, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.textMid)),
      ],
    );
  }

  Widget _countBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.accentHover,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(text,
          style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
    );
  }
}
