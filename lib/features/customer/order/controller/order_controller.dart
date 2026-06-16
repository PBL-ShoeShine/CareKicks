import 'dart:io';
import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../../../../core/utils/location_utils.dart';

class OrderController extends ChangeNotifier {
  // ─── State: Services ──────────────────────────────────────────────────────
  bool _isLoadingServices = false;
  bool _isSubmitting = false;
  String? _errorMessage;
  String? _successMessage;

  List<Map<String, dynamic>> _services = [];
  final List<int> _selectedServiceIds = [];
  String _nmToko = '';
  double? _latToko;
  double? _longToko;

  // ─── State: Form Fields ───────────────────────────────────────────────────
  final List<File> _fotoSepatuList = [];
  double? _currentLat;
  double? _currentLong;

  // ─── Getters ──────────────────────────────────────────────────────────────
  bool get isLoadingServices => _isLoadingServices;
  bool get isSubmitting => _isSubmitting;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  List<Map<String, dynamic>> get services => _services;
  List<int> get selectedServiceIds => List.unmodifiable(_selectedServiceIds);
  String get nmToko => _nmToko;
  List<File> get fotoSepatuList => List.unmodifiable(_fotoSepatuList);

  double? get latToko => _latToko;
  double? get longToko => _longToko;

  bool isServiceSelected(int idServices) =>
      _selectedServiceIds.contains(idServices);

  /// Hitung jarak (KM) antara toko dan lokasi customer saat ini
  double get distanceKm {
    if (_latToko == null || _longToko == null || _currentLat == null || _currentLong == null) {
      return 0.0;
    }
    return LocationUtils.calculateDistanceKm(
      _latToko!,
      _longToko!,
      _currentLat!,
      _currentLong!,
    );
  }

  /// Hitung ongkos kirim berdasarkan jarak
  int get totalOngkir => LocationUtils.calculateOngkir(distanceKm);

  /// Hitung total harga dari layanan yang dipilih + ongkir
  int get totalHargaLayanan {
    int total = 0;
    for (final svc in _services) {
      if (_selectedServiceIds.contains(svc['id_services'])) {
        final harga = int.tryParse(svc['harga']?.toString() ?? '0') ?? 0;
        total += harga;
      }
    }
    return total;
  }

  int get totalHargaKeseluruhan => totalHargaLayanan + totalOngkir;

  // ─── Actions ──────────────────────────────────────────────────────────────

  void updateLocation(double? lat, double? lng) {
    _currentLat = lat;
    _currentLong = lng;
    notifyListeners();
  }

  void addFotoSepatu(File file) {
    if (_fotoSepatuList.length < 5) {
      _fotoSepatuList.add(file);
      notifyListeners();
    }
  }

  void removeFotoSepatu(int index) {
    if (index >= 0 && index < _fotoSepatuList.length) {
      _fotoSepatuList.removeAt(index);
      notifyListeners();
    }
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
      _latToko = double.tryParse(data['lat_toko']?.toString() ?? '');
      _longToko = double.tryParse(data['long_toko']?.toString() ?? '');
      
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
    required String merk,
    required String jenisSepatu,
    required String warna,
    String? catatan,
    double? latOrder,
    double? longOrder,
  }) async {
    if (_selectedServiceIds.isEmpty) {
      _errorMessage = 'Pilih minimal satu layanan';
      notifyListeners();
      return null;
    }
    
    if (_fotoSepatuList.isEmpty) {
      _errorMessage = 'Minimal 1 foto sepatu harus diunggah';
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
      merk: merk,
      jenisSepatu: jenisSepatu,
      warna: warna,
      selectedServiceIds: _selectedServiceIds,
      totalOngkir: totalOngkir,
      catatan: catatan,
      latOrder: latOrder,
      longOrder: longOrder,
      fotoSepatuList: _fotoSepatuList,
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
