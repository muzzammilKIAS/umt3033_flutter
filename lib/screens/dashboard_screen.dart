import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/unit_model.dart';
import '../services/data_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/unit_card.dart';
import 'unit_screen.dart';

class DashboardScreen extends StatelessWidget {
  final void Function(int unitId) onOpenUnit;

  const DashboardScreen({super.key, required this.onOpenUnit});

  @override
  Widget build(BuildContext context) {
    final data = context.watch<DataService>();
    final storage = context.watch<StorageService>();
    final course = data.course;
    final units = data.units;
    final tokens = context.tokens;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: AlignmentDirectional.centerStart,
              child: Text(
                'اللُّغَةُ الْعَرَبِيَّةُ الْأَسَاسِيَّةُ لِلْمُعَامَلَاتِ',
                textDirection: TextDirection.rtl,
                maxLines: 1,
                softWrap: false,
                style: TextStyle(
                  fontFamily: 'NotoNaskhArabic',
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              'Basic Arabic for Muamalat • UMT3033',
              textDirection: TextDirection.ltr,
              style: TextStyle(fontSize: 11, color: tokens.textSecondary),
            ),
          ],
        ),
      ),
      body: units.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _heroSection(context, course, storage),
                const SizedBox(height: 20),
                _progressCard(context, storage),
                const SizedBox(height: 24),
                _sectionHeader(
                  context,
                  'فِهْرِسُ الْوَحَدَاتِ',
                  'Senarai Unit Pembelajaran',
                ),
                const SizedBox(height: 12),
                ...units.map(
                  (u) => UnitCard(
                    unit: u,
                    completed: storage.isUnitCompleted(u.id),
                    onTap: () => onOpenUnit(u.id),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _heroSection(
    BuildContext context,
    CourseModel? course,
    StorageService storage,
  ) {
    final tokens = context.tokens;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [tokens.heroGradientStart, tokens.heroGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _eyebrow('مُقَرَّرٌ تَفَاعُلِيٌّ • ١٤ وَحْدَةً'),
          const SizedBox(height: 14),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              'اللُّغَةُ الْعَرَبِيَّةُ الْأَسَاسِيَّةُ لِلْمُعَامَلَاتِ',
              textAlign: TextAlign.right,
              textDirection: TextDirection.rtl,
              maxLines: 1,
              softWrap: false,
              style: TextStyle(
                fontFamily: 'NotoNaskhArabic',
                fontSize: 32.5,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            course?.courseTitleEn ?? 'Basic Arabic for Muamalat',
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          Text(
            '${course?.courseCode ?? 'UMT3033'} • ${course?.authorName ?? ''}',
            textDirection: TextDirection.ltr,
            style: const TextStyle(color: Colors.white60, fontSize: 12),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UnitScreen(unitId: storage.lastUnitId),
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: tokens.heroGradientStart,
            ),
            icon: const Icon(Icons.play_arrow, size: 20),
            label: Text(
              storage.lastUnitId > 1 || storage.completedUnitCount > 0
                  ? 'Sambung Belajar'
                  : 'Mula Belajar',
              textDirection: TextDirection.ltr,
            ),
          ),
        ],
      ),
    );
  }

  Widget _eyebrow(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.3)),
      ),
      child: Text(
        text,
        textDirection: TextDirection.rtl,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: 'NotoNaskhArabic',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _progressCard(BuildContext context, StorageService storage) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: tokens.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionKicker(context, 'تَقَدُّمُ التَّعَلُّمِ', 'Progress'),
          const SizedBox(height: 14),
          Row(
            children: [
              _statTile(
                context,
                'Unit Selesai',
                '${storage.completedUnitCount}/14',
                Icons.check_circle_outline,
              ),
              _statTile(
                context,
                'Kosa Kata',
                '${storage.vocabLearned.length}',
                Icons.style_outlined,
              ),
              _statTile(
                context,
                'Progress',
                '${(storage.overallProgress * 100).round()}%',
                Icons.trending_up,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: storage.overallProgress,
              minHeight: 8,
              color: scheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 8),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: tokens.mist,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 20, color: scheme.primary),
              const SizedBox(height: 6),
              Text(
                value,
                textDirection: TextDirection.ltr,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: tokens.textPrimary,
                ),
              ),
              Text(
                label,
                textDirection: TextDirection.ltr,
                style: TextStyle(fontSize: 10.5, color: tokens.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, String ar, String my) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          ar,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 17.5,
            color: scheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            my,
            textDirection: TextDirection.ltr,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w800,
              color: tokens.textPrimary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: scheme.primary,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Text(
            '14 Unit',
            textDirection: TextDirection.ltr,
            style: TextStyle(
              color: Colors.white,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionKicker(BuildContext context, String ar, String my) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          ar,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'NotoNaskhArabic',
            fontSize: 16,
            color: scheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          my,
          textDirection: TextDirection.ltr,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: tokens.textPrimary,
          ),
        ),
      ],
    );
  }
}
