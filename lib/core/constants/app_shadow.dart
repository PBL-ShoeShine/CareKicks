import 'package:flutter/material.dart';

class AppShadow {
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 16,
      offset: Offset(0, 8),
    ),
  ];

  static const List<BoxShadow> bottomNav = [
    BoxShadow(
      color: Color(0x1F000000),
      blurRadius: 16,
      offset: Offset(0, -4),
    ),
  ];
}
