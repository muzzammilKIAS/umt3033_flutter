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
                  fontFamily: 'Amiri',
                  fontSize: 24,
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
              padding: const EdgeInsets.all(20),
              children: [
                _heroSection(context, course, storage),
                const SizedBox(height: 24),
                _progressCard(context, storage),
                const SizedBox(height: 28),
                _sectionHeader(
                  context,
                  'فِهْرِسُ الْوَحَدَاتِ',
                  'Senarai Unit Pembelajaran',
                ),
                const SizedBox(height: 14),
                ...units.map(
                  (u) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: UnitCard(
                      unit: u,
                      completed: storage.isUnitCompleted(u.id),
                      onTap: () => onOpenUnit(u.id),
                    ),
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
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [tokens.heroGradientStart, tokens.heroGradientEnd],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: tokens.heroGradientStart.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
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
                fontFamily: 'Amiri',
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                shadows: [
                  Shadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    offset: const Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
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
          _HeroButton(
            storage: storage,
            tokens: tokens,
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
          fontFamily: 'Amiri',
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _progressCard(BuildContext context, StorageService storage) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.card,
        borderRadius: BorderRadius.circular(22),
        boxShadow: context.softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionKicker(context, 'تَقَدُّمُ التَّعَلُّمِ', 'Progress'),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 108,
                height: 108,
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 800),
                  curve: Curves.easeOutCubic,
                  tween: Tween<double>(begin: 0, end: storage.overallProgress),
                  builder: (context, value, _) {
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: 1,
                            strokeWidth: 12,
                            color: tokens.mist,
                          ),
                        ),
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: value,
                            strokeWidth: 12,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.transparent,
                            valueColor: AlwaysStoppedAnimation(scheme.primary),
                          ),
                        ),
                        Text(
                          '${(value * 100).round()}%',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendRow(
                      context,
                      color: scheme.primary,
                      label: 'Unit Selesai',
                      value: '${storage.completedUnitCount}/14',
                    ),
                    const SizedBox(height: 12),
                    _legendRow(
                      context,
                      color: scheme.secondary,
                      label: 'Kosa Kata Dipelajari',
                      value: '${storage.vocabLearned.length}',
                    ),
                    const SizedBox(height: 12),
                    _legendRow(
                      context,
                      color: tokens.champagne,
                      label: 'Baki Unit',
                      value: '${14 - storage.completedUnitCount}',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendRow(
    BuildContext context, {
    required Color color,
    required String label,
    required String value,
  }) {
    final tokens = context.tokens;
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            textDirection: TextDirection.ltr,
            style: TextStyle(fontSize: 13, color: tokens.textSecondary),
          ),
        ),
        Text(
          value,
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

  Widget _sectionHeader(BuildContext context, String ar, String my) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          ar,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 20,
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
            fontFamily: 'Amiri',
            fontSize: 20,
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

class _HeroButton extends StatefulWidget {
  final StorageService storage;
  final AppTokens tokens;

  const _HeroButton({
    required this.storage,
    required this.tokens,
  });

  @override
  State<_HeroButton> createState() => _HeroButtonState();
}

class _HeroButtonState extends State<_HeroButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedScale(
        scale: _isHovered ? 1.04 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        child: ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => UnitScreen(unitId: widget.storage.lastUnitId),
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.white,
            foregroundColor: widget.tokens.heroGradientStart,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: _isHovered ? 6 : 2,
            shadowColor: Colors.black.withValues(alpha: 0.25),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          icon: const Icon(Icons.play_arrow_rounded, size: 22),
          label: Text(
            widget.storage.lastUnitId > 1 ||
                    widget.storage.completedUnitCount > 0
                ? 'Sambung Belajar'
                : 'Mula Belajar',
            textDirection: TextDirection.ltr,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
        ),
      ),
    );
  }
}
