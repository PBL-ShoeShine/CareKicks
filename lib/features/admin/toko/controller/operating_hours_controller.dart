import 'package:flutter/material.dart';
import '../models/operating_hour_model.dart';
import '../services/operating_hours_service.dart';

class OperatingHoursController extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  List<ShopOperatingHour> _hours = [];

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  List<ShopOperatingHour> get hours => _hours;

  Future<bool> fetchHours(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await OperatingHoursService.getOperatingHours(token);

      if (result['success'] == true) {
        final List list = result['data'] ?? [];
        final parsed = list
            .map((item) => ShopOperatingHour.fromJson(item))
            .toList();
        _hours = _ensureFullWeek(parsed);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'] ?? 'Gagal mengambil jam operasional';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateHours(String token) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      for (final item in _hours) {
        if (item.isOpen) {
          item.openTime ??= const TimeOfDay(hour: 9, minute: 0);
          item.closeTime ??= const TimeOfDay(hour: 18, minute: 0);
        }
      }

      final payload = _hours.map((item) => item.toPayload()).toList();

      final result = await OperatingHoursService.updateOperatingHours(
        token: token,
        hours: payload,
      );

      if (result['success'] == true) {
        final List list = result['data'] ?? [];
        final parsed = list
            .map((item) => ShopOperatingHour.fromJson(item))
            .toList();
        _hours = _ensureFullWeek(parsed);
        _isSaving = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'] ?? 'Gagal memperbarui jam operasional';
      _isSaving = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  void setIsOpen(int index, bool isOpen) {
    if (index < 0 || index >= _hours.length) return;
    final item = _hours[index];
    item.isOpen = isOpen;

    if (isOpen) {
      item.openTime ??= const TimeOfDay(hour: 9, minute: 0);
      item.closeTime ??= const TimeOfDay(hour: 18, minute: 0);
    } else {
      item.openTime = null;
      item.closeTime = null;
    }

    notifyListeners();
  }

  void setOpenTime(int index, TimeOfDay time) {
    if (index < 0 || index >= _hours.length) return;
    _hours[index].openTime = time;
    notifyListeners();
  }

  void setCloseTime(int index, TimeOfDay time) {
    if (index < 0 || index >= _hours.length) return;
    _hours[index].closeTime = time;
    notifyListeners();
  }

  List<ShopOperatingHour> _ensureFullWeek(List<ShopOperatingHour> items) {
    final map = {for (final item in items) item.dayOfWeek: item};

    return List.generate(7, (index) {
      final day = index + 1;
      return map[day] ?? ShopOperatingHour.forDay(day);
    });
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
