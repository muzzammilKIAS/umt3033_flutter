import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_links.dart';
import '../models/unit_model.dart';
import '../services/data_service.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../utils/arabic_text.dart';
import '../widgets/unit_card.dart';
import 'unit_screen.dart';

// Dashboard headings show plain, unvocalized Arabic (via stripHarakat) --
// the fully-vocalized form used inside the unit page (for pronunciation
// guidance) looks dense/busy here.
const _stripHarakat = stripHarakat;
const _toArabicDigits = toArabicDigits;

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
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [tokens.heroGradientStart, tokens.heroGradientEnd],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Center(
                child: Text(
                  'ع',
                  textDirection: TextDirection.rtl,
                  style: TextStyle(
                    fontFamily: 'Amiri',
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'UMT3033',
              textDirection: TextDirection.ltr,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: tokens.textPrimary,
              ),
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
                const SizedBox(height: 16),
                Card(
                  color: const Color(0xFF102D3D),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: const Icon(
                      Icons.sports_esports_rounded,
                      color: Color(0xFFF0C56B),
                      size: 34,
                    ),
                    title: const Text(
                      'Arabic Muamalat Adventure',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'مغامرة العربية للمعاملات',
                      style: TextStyle(
                        fontFamily: 'Amiri',
                        color: Color(0xFFF0C56B),
                        fontSize: 22,
                        height: 1.7,
                      ),
                    ),
                    onTap: () => Navigator.pushNamed(context, '/game'),
                    trailing: const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Card(
                  color: const Color(0xFF0F2033),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    leading: const Icon(
                      Icons.terrain_rounded,
                      color: Color(0xFF8EC9E8),
                      size: 34,
                    ),
                    title: const Text(
                      'Muamalat Trail (Web)',
                      textDirection: TextDirection.ltr,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'مَسَارُ الْمُعَامَلَاتِ',
                          style: TextStyle(
                            fontFamily: 'Amiri',
                            color: Color(0xFF8EC9E8),
                            fontSize: 22,
                            height: 1.7,
                          ),
                        ),
                        Text(
                          'Sertai kelas guru di pelayar — kod bilik & QR',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            color: Color(0xFF8EC9E8),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    onTap: () => launchUrl(
                      Uri.parse(muamalatTrailUrl),
                      mode: LaunchMode.externalApplication,
                    ),
                    trailing: const Icon(Icons.open_in_new, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                _progressCard(context, storage),
                const SizedBox(height: 28),
                _sectionHeader(context, 'فِهْرِسُ الْوَحَدَاتِ'),
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
                const SizedBox(height: 20),
                _footer(context, course),
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
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerEnd,
            child: Text(
              _stripHarakat(
                'اللُّغَةُ الْعَرَبِيَّةُ الْأَسَاسِيَّةُ لِلْمُعَامَلَاتِ',
              ),
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
          const SizedBox(height: 20),
          _HeroButton(storage: storage, tokens: tokens),
        ],
      ),
    );
  }

  Widget _footer(BuildContext context, CourseModel? course) {
    final tokens = context.tokens;
    return Column(
      children: [
        Text(
          '${course?.courseCode ?? 'UMT3033'} · ${course?.authorName ?? ''}',
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: tokens.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          course?.courseTitleEn ?? 'Basic Arabic for Muamalat',
          textDirection: TextDirection.ltr,
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 10, color: tokens.textSecondary),
        ),
      ],
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
          _sectionKicker(context, 'تَقَدُّمُ التَّعَلُّمِ'),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 92,
                height: 92,
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
                          '${_toArabicDigits((value * 100).round().toString())}٪',
                          textDirection: TextDirection.rtl,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: tokens.textPrimary,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendRow(
                      context,
                      color: scheme.primary,
                      label: 'وَحَدَاتٌ مُكْتَمِلَةٌ',
                      value: _toArabicDigits(
                        '${storage.completedUnitCount}/14',
                      ),
                    ),
                    const SizedBox(height: 12),
                    _legendRow(
                      context,
                      color: scheme.secondary,
                      label: 'الْمُفْرَدَاتُ',
                      value: _toArabicDigits('${storage.vocabLearned.length}'),
                    ),
                    const SizedBox(height: 12),
                    _legendRow(
                      context,
                      color: tokens.champagne,
                      label: 'وَحَدَاتٌ مُتَبَقِّيَةٌ',
                      value: _toArabicDigits(
                        '${14 - storage.completedUnitCount}',
                      ),
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
            _stripHarakat(label),
            textDirection: TextDirection.rtl,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Amiri',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: tokens.textSecondary,
            ),
          ),
        ),
        Text(
          value,
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: tokens.textPrimary,
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(BuildContext context, String ar) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          _stripHarakat(ar),
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 20,
            color: scheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
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

  Widget _sectionKicker(BuildContext context, String ar, [String my = '']) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          _stripHarakat(ar),
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: 'Amiri',
            fontSize: 20,
            color: scheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (my.isNotEmpty) ...[
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
      ],
    );
  }
}

class _HeroButton extends StatefulWidget {
  final StorageService storage;
  final AppTokens tokens;

  const _HeroButton({required this.storage, required this.tokens});

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
            _stripHarakat(
              widget.storage.lastUnitId > 1 ||
                      widget.storage.completedUnitCount > 0
                  ? 'وَاصِلِ التَّعَلُّمَ'
                  : 'اِبْدَأِ التَّعَلُّمَ',
            ),
            textDirection: TextDirection.rtl,
            style: const TextStyle(
              fontFamily: 'Amiri',
              fontWeight: FontWeight.bold,
              fontSize: 17,
            ),
          ),
        ),
      ),
    );
  }
}
