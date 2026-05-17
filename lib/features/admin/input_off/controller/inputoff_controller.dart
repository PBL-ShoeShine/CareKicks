import 'package:flutter/material.dart';
import 'dart:io';
import '../services/inputoff_service.dart';

class InputOffController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _services = [];
  List<dynamic> _selectedServices = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get services => _services;
  List<dynamic> get selectedServices => _selectedServices;

  double _toDouble(dynamic value) {
    if (value == null) return 0;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0;
  }

  double get totalHarga {
    double total = 0;

    for (var service in _selectedServices) {
      total += _toDouble(service['harga']);
    }

    return total;
  }

  Future<void> fetchServices(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await InputOffService.getAvailableServices(token);

    if (result['success'] == true) {
      _services = result['data'] ?? [];
    } else {
      _errorMessage = result['message'] ?? 'Gagal mengambil layanan';
    }

    _isLoading = false;
    notifyListeners();
  }

  void toggleService(Map<String, dynamic> service) {
    final index = _selectedServices.indexWhere(
      (s) => s['id_services'] == service['id_services'],
    );

    if (index != -1) {
      _selectedServices.removeAt(index);
    } else {
      _selectedServices.add(service);
    }

    notifyListeners();
  }

  Future<bool> createOrder({
    required String token,
    required String namaCustomer,
    required String nomorTelepon,
    required String jenisSepatu,
    required String merk,
    required String warna,
    required String catatan,
    required String metodeBayar,
    required File fotoSebelum,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final orderData = {
      'nama_customer': namaCustomer.trim(),
      'nomor_telepon': nomorTelepon.trim(),
      'jenis_sepatu': jenisSepatu,
      'merk': merk.trim().isEmpty ? '-' : merk.trim(),
      'warna': warna.trim().isEmpty ? '-' : warna.trim(),
      'catatan': catatan.trim(),
      'metode_bayar': metodeBayar,
      'services': _selectedServices.map((s) {
        return {
          'id_services': s['id_services'],
          'price': _toDouble(s['harga']),
        };
      }).toList(),
    };

    final result = await InputOffService.submitOfflineOrder(
      token: token,
      orderData: orderData,
      fotoSebelum: fotoSebelum,
    );

    _isLoading = false;

    if (result['success'] == true) {
      reset();
      notifyListeners();
      return true;
    } else {
      _errorMessage = result['message'] ?? 'Gagal membuat pesanan';
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _selectedServices = [];
    _errorMessage = null;
    notifyListeners();
  }
}
