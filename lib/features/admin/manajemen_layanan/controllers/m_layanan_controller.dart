import 'dart:io';
import 'package:flutter/material.dart';
import '../services/m_layanan_service.dart';

class MLayananController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _services = [];
  String _searchQuery = '';
  String _selectedCategory = 'Semua';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get services => _services;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSelectedCategory(String category) {
    _selectedCategory = category;
    notifyListeners();
  }

  Future<void> fetchServices(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await MLayananService.getServices(
        token: token,
        search: _searchQuery,
        category: _selectedCategory,
      );

      if (result['success']) {
        _services = result['data'] ?? [];
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengambil data layanan';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> createService({
    required String token,
    required String namaLayanan,
    required int harga,
    required String estimasiWaktu,
    String? deskripsi,
    File? foto,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await MLayananService.createService(
        token: token,
        namaLayanan: namaLayanan,
        harga: harga,
        estimasiWaktu: estimasiWaktu,
        deskripsi: deskripsi,
        foto: foto,
      );

      if (result['success']) {
        await fetchServices(token);
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Gagal membuat layanan';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateService({
    required String token,
    required int serviceId,
    required String namaLayanan,
    required int harga,
    required String estimasiWaktu,
    String? deskripsi,
    File? foto,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await MLayananService.updateService(
        token: token,
        serviceId: serviceId,
        namaLayanan: namaLayanan,
        harga: harga,
        estimasiWaktu: estimasiWaktu,
        deskripsi: deskripsi,
        foto: foto,
      );

      if (result['success']) {
        await fetchServices(token);
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Gagal memperbarui layanan';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleStatus(String token, int serviceId, bool currentStatus) async {
    try {
      final result = await MLayananService.updateStatus(
        token: token,
        serviceId: serviceId,
        isActive: !currentStatus,
      );

      if (result['success']) {
        // Update local state for better UX
        final index = _services.indexWhere((s) => s['id_services'] == serviceId);
        if (index != -1) {
          _services[index]['is_active'] = !currentStatus;
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Gagal memperbarui status';
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteService(String token, int serviceId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await MLayananService.deleteService(
        token: token,
        serviceId: serviceId,
      );

      if (result['success']) {
        _services.removeWhere((s) => s['id_services'] == serviceId);
        return true;
      } else {
        String msg = result['message'] ?? 'Gagal menghapus layanan';
        if (msg.toLowerCase().contains('foreign key') || msg.toLowerCase().contains('violates')) {
          msg = "Layanan tidak dapat dihapus karena sudah memiliki riwayat pesanan atau ulasan dari pelanggan. Silakan nonaktifkan saja layanan ini agar tidak dapat dipesan lagi.";
        }
        _errorMessage = msg;
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
