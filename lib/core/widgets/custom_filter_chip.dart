import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_sizes.dart';

class CustomFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final int? count;
  final IconData? icon;

  const CustomFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.count,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final bg = selected ? AppColors.primary : AppColors.surface;
    final fg = selected ? Colors.white : AppColors.textPrimary;

    return InkWell(
      borderRadius: AppRadius.extraLarge,
      onTap: onSelected,
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: AppRadius.extraLarge,
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fg),
              const SizedBox(width: AppSizes.gapXs),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w700,
                  ),
            ),
            if (count != null) ...[
              const SizedBox(width: AppSizes.gapSm),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : AppColors.lightBlue,
                  borderRadius: AppRadius.extraLarge,
                ),
                child: Text(
                  count.toString(),
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: fg,
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
