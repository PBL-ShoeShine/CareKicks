import 'package:flutter/material.dart';
import '../services/riwayat_service.dart';

class RiwayatController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _orders = [];
  String _selectedStatus = '';
  String _searchQuery = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get orders => _orders;
  String get selectedStatus => _selectedStatus;
  String get searchQuery => _searchQuery;

  void setStatus(String status) {
    _selectedStatus = status;
    notifyListeners();
  }

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  Future<void> fetchRiwayat(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await RiwayatService.getRiwayat(
        token: token,
        status: _selectedStatus.isEmpty ? null : _selectedStatus,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      if (result['success']) {
        _orders = result['data'] ?? [];
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengambil riwayat';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
