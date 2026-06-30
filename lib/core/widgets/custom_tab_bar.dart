import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_radius.dart';
import '../constants/app_sizes.dart';

class CustomTabBar extends StatelessWidget implements PreferredSizeWidget {
  final TabController controller;
  final List<String> labels;
  final ValueChanged<int>? onTap;
  final bool isScrollable;

  const CustomTabBar({
    super.key,
    required this.controller,
    required this.labels,
    this.onTap,
    this.isScrollable = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(52);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: preferredSize.height,
      color: AppColors.surface,
      alignment: Alignment.centerLeft,
      child: TabBar(
        controller: controller,
        onTap: onTap,
        isScrollable: isScrollable,
        labelColor: AppColors.primary,
        unselectedLabelColor: AppColors.textSecondary,
        indicatorSize: TabBarIndicatorSize.tab,
        indicatorPadding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingSm,
          vertical: AppSizes.paddingSm,
        ),
        indicator: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: AppRadius.medium,
        ),
        labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
        unselectedLabelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.w600,
            ),
        tabs: labels.map((label) => Tab(text: label)).toList(),
      ),
    );
  }
}
