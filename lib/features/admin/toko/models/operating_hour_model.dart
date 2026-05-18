import 'package:flutter/material.dart';

class ShopOperatingHour {
  final int? id;
  final int dayOfWeek;
  final String dayName;
  bool isOpen;
  TimeOfDay? openTime;
  TimeOfDay? closeTime;

  ShopOperatingHour({
    this.id,
    required this.dayOfWeek,
    required this.dayName,
    required this.isOpen,
    this.openTime,
    this.closeTime,
  });

  factory ShopOperatingHour.fromJson(Map<String, dynamic> json) {
    final rawDay = json['day_of_week'];
    final dayOfWeek = rawDay is int
        ? rawDay
        : int.tryParse(rawDay?.toString() ?? '') ?? 0;
    return ShopOperatingHour(
      id: json['id_shop_operating_hours'],
      dayOfWeek: dayOfWeek,
      dayName: json['day_name'] ?? dayNameFromInt(dayOfWeek),
      isOpen: json['is_open'] ?? false,
      openTime: parseTime(json['open_time']),
      closeTime: parseTime(json['close_time']),
    );
  }

  factory ShopOperatingHour.forDay(int dayOfWeek) {
    return ShopOperatingHour(
      dayOfWeek: dayOfWeek,
      dayName: dayNameFromInt(dayOfWeek),
      isOpen: false,
      openTime: null,
      closeTime: null,
    );
  }

  Map<String, dynamic> toPayload() {
    return {
      'day_of_week': dayOfWeek,
      'is_open': isOpen,
      'open_time': isOpen ? formatTime(openTime) : null,
      'close_time': isOpen ? formatTime(closeTime) : null,
    };
  }

  ShopOperatingHour copyWith({
    int? id,
    int? dayOfWeek,
    String? dayName,
    bool? isOpen,
    TimeOfDay? openTime,
    TimeOfDay? closeTime,
  }) {
    return ShopOperatingHour(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      dayName: dayName ?? this.dayName,
      isOpen: isOpen ?? this.isOpen,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
    );
  }

  static TimeOfDay? parseTime(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length < 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  static String? formatTime(TimeOfDay? time) {
    if (time == null) return null;
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static String dayNameFromInt(int dayOfWeek) {
    switch (dayOfWeek) {
      case 1:
        return 'Senin';
      case 2:
        return 'Selasa';
      case 3:
        return 'Rabu';
      case 4:
        return 'Kamis';
      case 5:
        return 'Jumat';
      case 6:
        return 'Sabtu';
      case 7:
        return 'Minggu';
      default:
        return 'Hari';
    }
  }
}
