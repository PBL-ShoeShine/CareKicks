import 'package:flutter/material.dart';
import '../services/history_service.dart';

class HistoryController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic>? _historyData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic>? get historyData => _historyData;

  Future<bool> fetchHistory({
    required String token,
    String? status,
    String? search,
    int? limit,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await HistoryService.getHistoryData(
        token: token,
        status: status,
        search: search,
        limit: limit,
      );

      if (result['success']) {
        _historyData = result['data'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengambil data riwayat';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  void clearHistory() {
    _historyData = null;
    notifyListeners();
  }
}
