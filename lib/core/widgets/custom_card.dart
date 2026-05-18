import 'package:flutter/material.dart';

import '../constants/app_shadow.dart';
import '../constants/app_sizes.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const CustomCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSizes.paddingMd),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      child: Container(
        width: double.infinity,
        padding: padding,
        decoration: const BoxDecoration(boxShadow: AppShadow.card),
        child: child,
      ),
    );

    if (onTap == null) return card;
    return InkWell(onTap: onTap, child: card);
  }
}
