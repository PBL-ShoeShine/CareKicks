import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

class DashboardController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _dashboardData;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get dashboardData => _dashboardData;

  String? get shopName => _dashboardData?['shop']?['nama_toko'];
  int? get pesananAktif => _dashboardData?['summary']?['pesanan_aktif'];
  int? get antreanCuci => _dashboardData?['summary']?['antrean_cuci'];
  int? get deepCleaning => _dashboardData?['summary']?['deep_cleaning'];
  int? get saldoToko => _dashboardData?['shop']?['saldo_toko'];
  List<dynamic>? get aktivitasTerkini => _dashboardData?['aktivitas_terkini'];

  Future<bool> fetchDashboard(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await DashboardService.getDashboardData(token);

      if (result['success']) {
        _dashboardData = result['data'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengambil data dashboard';
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
