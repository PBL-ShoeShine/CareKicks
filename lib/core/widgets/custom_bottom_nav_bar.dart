import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_shadow.dart';
import '../constants/app_sizes.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final bool showInventory;
  final Color? activeColor;
  final Color? inactiveColor;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.showInventory = true,
    this.activeColor,
    this.inactiveColor,
  });

  @override
  Widget build(BuildContext context) {
    final activeCol = activeColor ?? AppColors.secondary;
    final inactiveCol = inactiveColor ?? AppColors.textSecondary;
    final items = [
      (Icons.home_outlined, 'Dashboard'),
      (Icons.assignment_outlined, 'Antrean'),
      (Icons.qr_code_scanner, 'Pemindai'),
      if (showInventory) (Icons.inventory_2_outlined, 'Inventaris'),
      (Icons.local_shipping_outlined, 'Tracking'),
    ];

    final bottomInset = MediaQuery.of(context).padding.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
        boxShadow: AppShadow.bottomNav,
      ),
      padding: EdgeInsets.fromLTRB(
        AppSizes.paddingSm,
        10,
        AppSizes.paddingSm,
        (bottomInset + AppSizes.paddingMd).clamp(24, 60),
      ),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = i == currentIndex;
          return Expanded(
            child: GestureDetector(
              onTap: () => onTap(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: AppSizes.paddingSm),
                decoration: BoxDecoration(
                  color: active
                      ? activeCol.withValues(alpha: 0.10)
                      : Colors.transparent,
                  borderRadius: AppRadius.large,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i].$1,
                      size: 22,
                      color: active ? activeCol : inactiveCol,
                    ),
                    const SizedBox(height: AppSizes.gapXs),
                    Text(
                      items[i].$2,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: active ? activeCol : inactiveCol,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
