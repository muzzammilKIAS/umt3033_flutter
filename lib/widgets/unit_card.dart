import 'package:flutter/material.dart';
import '../models/unit_model.dart';
import '../theme/app_theme.dart';

class UnitCard extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (unit.illustration != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    unit.illustration!,
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                  ),
                )
              else
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: tokens.mist,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${unit.id}',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: scheme.primary,
                      ),
                    ),
                  ),
                ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: completed
                                ? AppColors2.success(context)
                                : scheme.primary,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            'Unit ${unit.id}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10.5,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (completed)
                          Icon(
                            Icons.check_circle,
                            color: AppColors2.success(context),
                            size: 18,
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      unit.titleAr,
                      textAlign: TextAlign.right,
                      textDirection: TextDirection.rtl,
                      style: const TextStyle(
                        fontFamily: 'NotoNaskhArabic',
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                        height: 1.6,
                      ),
                    ),
                    if (unit.titleSubAr.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        unit.titleSubAr,
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: tokens.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: tokens.textSecondary),
            ],
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
