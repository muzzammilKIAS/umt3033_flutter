import 'package:flutter/material.dart';
import '../models/unit_model.dart';
import '../theme/app_colors.dart';

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
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: completed ? AppColors.success : AppColors.accentHover,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Unit ${unit.id}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    unit.code,
                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  ),
                  const Spacer(),
                  if (completed)
                    const Icon(Icons.check_circle, color: AppColors.success, size: 20),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                unit.titleAr,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontFamily: 'LotusLinotype',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textMid,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                unit.title,
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.textMid),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
