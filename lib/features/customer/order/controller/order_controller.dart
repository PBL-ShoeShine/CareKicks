import 'dart:io';
import 'package:flutter/material.dart';
import '../services/order_service.dart';

class OrderController extends ChangeNotifier {
  // ─── State: Services ──────────────────────────────────────────────────────
  bool _isLoadingServices = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  List<Map<String, dynamic>> _services = [];
  final List<int> _selectedServiceIds = [];
  String _nmToko = '';

  // ─── State: Form Fields ───────────────────────────────────────────────────
  File? _fotoSepatu;

  // ─── Getters ──────────────────────────────────────────────────────────────
  bool get isLoadingServices => _isLoadingServices;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<Map<String, dynamic>> get services => _services;
  List<int> get selectedServiceIds => List.unmodifiable(_selectedServiceIds);
  String get nmToko => _nmToko;
  File? get fotoSepatu => _fotoSepatu;

  bool isServiceSelected(int idServices) =>
      _selectedServiceIds.contains(idServices);

  /// Hitung total harga dari layanan yang dipilih
  int get totalHarga {
    int total = 0;
    for (final svc in _services) {
      if (_selectedServiceIds.contains(svc['id_services'])) {
        final harga = int.tryParse(svc['harga']?.toString() ?? '0') ?? 0;
        total += harga;
      }
    }
    return total;
  }

  // ─── Actions ──────────────────────────────────────────────────────────────

  void setFotoSepatu(File? file) {
    _fotoSepatu = file;
    notifyListeners();
  }

  void toggleService(int idServices) {
    if (_selectedServiceIds.contains(idServices)) {
      _selectedServiceIds.remove(idServices);
    } else {
      _selectedServiceIds.add(idServices);
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Muat daftar layanan dari toko
  Future<void> fetchServices({
    required String token,
    required int idShops,
    int? prefillServiceId,
  }) async {
    _isLoadingServices = true;
    _errorMessage = null;
    _services = [];
    _selectedServiceIds.clear();
    notifyListeners();

    final result = await OrderService.getServicesByShop(
      token: token,
      idShops: idShops,
    );

    if (result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>? ?? {};
      _services = List<Map<String, dynamic>>.from(data['services'] ?? []);
      _nmToko = data['nm_toko']?.toString() ?? '';
      
      // Auto-select layanan jika diberikan
      if (prefillServiceId != null) {
        // Cek apakah layanan tersebut benar-benar ada di toko ini
        final exists = _services.any((svc) => svc['id_services'] == prefillServiceId);
        if (exists) {
          _selectedServiceIds.add(prefillServiceId);
        }
      }
    } else {
      _errorMessage = result['message'] ?? 'Gagal memuat layanan';
    }

    _isLoadingServices = false;
    notifyListeners();
  }

  /// Submit form pesanan
  Future<Map<String, dynamic>?> submitOrder({
    required String token,
    required int idShops,
    required String namaPemilik,
    required String noHp,
    required String alamat,
    String? catatan,
    double? latOrder,
    double? longOrder,
  }) async {
    if (_selectedServiceIds.isEmpty) {
      _errorMessage = 'Pilih minimal satu layanan';
      notifyListeners();
      return null;
    }

    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();

    final result = await OrderService.createOrder(
      token: token,
      idShops: idShops,
      namaPemilik: namaPemilik,
      noHp: noHp,
      alamat: alamat,
      selectedServiceIds: _selectedServiceIds,
      catatan: catatan,
      latOrder: latOrder,
      longOrder: longOrder,
      fotoSepatu: _fotoSepatu,
    );

    _isSubmitting = false;

    if (result['success'] == true) {
      return result['data'] as Map<String, dynamic>?;
    } else {
      _errorMessage = result['message'] ?? 'Gagal membuat pesanan';
      notifyListeners();
      return null;
    }
  }
}
