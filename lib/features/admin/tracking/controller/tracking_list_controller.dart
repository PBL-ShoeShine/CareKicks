import 'package:flutter/material.dart';
import '../services/tracking_service.dart';

class TrackingListController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _orders = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get orders => _orders;

  Future<bool> fetchTrackingList({
    required String token,
    String? status,
    String? search,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await TrackingService.getTrackingList(
        token: token,
        status: status,
        search: search,
      );

      if (result['success'] == true) {
        _orders = (result['data'] as List<dynamic>? ?? []);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'] ?? 'Gagal mengambil data tracking';
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
