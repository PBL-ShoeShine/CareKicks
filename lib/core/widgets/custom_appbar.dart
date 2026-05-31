import 'package:flutter/material.dart';

import '../constants/app_colors.dart';
import '../constants/app_sizes.dart';
import '../constants/app_text_styles.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? subtitle;
  final bool showBackButton;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final double elevation;
  final double scrolledUnderElevation;
  final VoidCallback? onBack;
  final bool automaticallyImplyLeading;

  const CustomAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.showBackButton = false,
    this.actions,
    this.bottom,
    this.centerTitle = false,
    this.backgroundColor,
    this.foregroundColor,
    this.elevation = 0,
    this.scrolledUnderElevation = 0,
    this.onBack,
    this.automaticallyImplyLeading = true,
  });

  @override
  Size get preferredSize {
    final titleHeight = subtitle == null ? kToolbarHeight : 72.0;
    return Size.fromHeight(titleHeight + (bottom?.preferredSize.height ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary;
    final fg = foregroundColor ?? Colors.white;

    return AppBar(
      automaticallyImplyLeading: automaticallyImplyLeading,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(Icons.arrow_back_rounded),
              onPressed: onBack ?? () => Navigator.maybePop(context),
            )
          : null,
      titleSpacing: showBackButton ? 0 : AppSizes.paddingMd,
      toolbarHeight: subtitle == null ? kToolbarHeight : 72,
      centerTitle: centerTitle,
      title: subtitle == null
          ? Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: fg),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: fg),
                ),
                const SizedBox(height: AppSizes.gapXs),
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: fg.withValues(alpha: 0.82),
                  ),
                ),
              ],
            ),
      actions: actions,
      bottom: bottom,
      backgroundColor: bg,
      foregroundColor: fg,
      elevation: elevation,
      scrolledUnderElevation: scrolledUnderElevation,
      iconTheme: IconThemeData(color: fg),
      actionsIconTheme: IconThemeData(color: fg),
    );
  }
}
