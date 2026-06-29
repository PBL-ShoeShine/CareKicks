import 'dart:io';
import 'package:flutter/material.dart';
import '../services/ulasan_service.dart';

class UlasanController extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  List<dynamic> _ulasanList = [];
  String _selectedRating = 'Semua';

  bool get isLoading => _isLoading;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  List<dynamic> get ulasanList => _ulasanList;
  String get selectedRating => _selectedRating;

  void setRatingFilter(String rating) {
    _selectedRating = rating;
    notifyListeners();
  }

  Future<void> fetchUlasan({int? idShops}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await UlasanService.getUlasan(
        idShops: idShops,
        rating: _selectedRating,
      );

      if (result['success']) {
        _ulasanList = result['data'] ?? [];
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengambil ulasan';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> submitUlasan({
    required String token,
    required int rating,
    required String ulasan,
    int? idShops,
    int? idOrders,
    List<int>? idServices,
    List<File>? fotoUlasan,
  }) async {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await UlasanService.createUlasan(
        token: token,
        rating: rating,
        ulasan: ulasan,
        idShops: idShops,
        idOrders: idOrders,
        idServices: idServices,
        fotoUlasan: fotoUlasan,
      );

      if (result['success']) {
        _isSubmitting = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengirim ulasan';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _isSubmitting = false;
    notifyListeners();
    return false;
  }
}
