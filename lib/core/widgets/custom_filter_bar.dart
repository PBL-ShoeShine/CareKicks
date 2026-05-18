import 'package:flutter/material.dart';

import '../constants/app_sizes.dart';
import 'custom_filter_chip.dart';

class CustomFilterItem<T> {
  final T value;
  final String label;
  final int? count;
  final IconData? icon;

  const CustomFilterItem({
    required this.value,
    required this.label,
    this.count,
    this.icon,
  });
}

class CustomFilterBar<T> extends StatelessWidget {
  final List<CustomFilterItem<T>> items;
  final T selectedValue;
  final ValueChanged<T> onSelected;
  final EdgeInsetsGeometry padding;

  const CustomFilterBar({
    super.key,
    required this.items,
    required this.selectedValue,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: AppSizes.paddingMd),
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: [
          for (var i = 0; i < items.length; i++) ...[
            CustomFilterChip(
              label: items[i].label,
              count: items[i].count,
              icon: items[i].icon,
              selected: items[i].value == selectedValue,
              onSelected: () => onSelected(items[i].value),
            ),
            if (i != items.length - 1) const SizedBox(width: AppSizes.gapSm),
          ],
        ],
      ),
    );
  }
}
