import 'package:flutter/material.dart';
import '../models/unit_model.dart';
import '../theme/app_theme.dart';

class UnitCard extends StatefulWidget {
  final UnitModel unit;
  final bool completed;
  final VoidCallback onTap;

  const UnitCard({
    super.key,
    required this.unit,
    this.completed = false,
    required this.onTap,
  });

  @override
  State<UnitCard> createState() => _UnitCardState();
}

class _UnitCardState extends State<UnitCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: tokens.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _isHovered
                ? scheme.primary.withValues(alpha: 0.4)
                : tokens.border,
            width: _isHovered ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _isHovered
                  ? scheme.primary.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.02),
              blurRadius: _isHovered ? 16 : 4,
              offset: Offset(0, _isHovered ? 6 : 2),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(18),
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(18),
            splashColor: scheme.primary.withValues(alpha: 0.08),
            highlightColor: scheme.primary.withValues(alpha: 0.04),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (widget.unit.illustration != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Image.asset(
                        widget.unit.illustration!,
                        width: 68,
                        height: 68,
                        fit: BoxFit.cover,
                      ),
                    )
                  else
                    AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 68,
                      height: 68,
                      decoration: BoxDecoration(
                        color: _isHovered
                            ? scheme.primary.withValues(alpha: 0.12)
                            : tokens.mist,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Center(
                        child: Text(
                          '${widget.unit.id}',
                          textDirection: TextDirection.ltr,
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: scheme.primary,
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: widget.completed
                                    ? AppColors2.success(context)
                                    : scheme.primary,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                'Unit ${widget.unit.id}',
                                textDirection: TextDirection.ltr,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            if (widget.completed)
                              Icon(
                                Icons.check_circle,
                                color: AppColors2.success(context),
                                size: 18,
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          widget.unit.titleAr,
                          textAlign: TextAlign.right,
                          textDirection: TextDirection.rtl,
                          style: const TextStyle(
                            fontFamily: 'Amiri',
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.5,
                          ),
                        ),
                        if (widget.unit.titleSubAr.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            widget.unit.titleSubAr,
                            textDirection: TextDirection.rtl,
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontFamily: 'Amiri',
                              fontWeight: FontWeight.w600,
                              color: tokens.textSecondary,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  AnimatedSlide(
                    offset: Offset(_isHovered ? -0.2 : 0, 0),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    child: Icon(
                      Icons.chevron_right,
                      color: _isHovered ? scheme.primary : tokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Small helper so semantic success/error stay theme-aware without importing
/// AppColors' raw brightness-specific constants directly in widgets.
class AppColors2 {
  static Color success(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFF5FAE86)
      : const Color(0xFF2D6A4F);
  static Color error(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark
      ? const Color(0xFFE0837A)
      : const Color(0xFFB3261E);
}
