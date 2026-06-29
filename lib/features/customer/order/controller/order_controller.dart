import 'dart:io';
import 'package:flutter/material.dart';
import '../services/order_service.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../../core/network/api_service.dart';

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

  // ─── State: Tarif Ongkir Toko (dinamis per toko) ───────────────────────────
  double _jarakGratisKm = 2.0;
  double _tarifPerKm = 5000;
  double _jarakMaksimalKm = double.infinity;
  double _tarifPerKmLuarRadius = 5000;

  // ─── State: Form Fields ───────────────────────────────────────────────────
  final List<File> _fotoSepatuList = [];
  double? _currentLat;
  double? _currentLong;

  // ─── State: OSRM Distance ─────────────────────────────────────────────────
  /// Jarak via OSRM (jalan raya). null = belum di-fetch / gagal.
  double? _osrmDistanceKm;
  bool _isFetchingOsrm = false;

  // ─── Getters ──────────────────────────────────────────────────────────────
  bool get isLoadingServices => _isLoadingServices;
  bool get isSubmitting => _isSubmitting;
  bool get isFetchingOsrm => _isFetchingOsrm;
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

  /// Jarak dalam KM: pakai OSRM jika tersedia, fallback ke Haversine.
  double get distanceKm {
    // Jika OSRM sudah berhasil, gunakan jarak rute jalan raya
    if (_osrmDistanceKm != null) return _osrmDistanceKm!;

    // Fallback: Haversine (garis lurus) jika OSRM belum/gagal
    if (_latToko == null ||
        _longToko == null ||
        _currentLat == null ||
        _currentLong == null) {
      return 0.0;
    }
    return LocationUtils.calculateDistanceKm(
      _latToko!,
      _longToko!,
      _currentLat!,
      _currentLong!,
    );
  }

  /// Hitung ongkos kirim berdasarkan jarak & tarif milik toko
  int get totalOngkir => LocationUtils.calculateOngkir(
    distanceKm,
    jarakGratisKm: _jarakGratisKm,
    tarifPerKm: _tarifPerKm,
    jarakMaksimalKm: _jarakMaksimalKm,
    tarifPerKmLuarRadius: _tarifPerKmLuarRadius,
  );

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

  /// Update lokasi customer, lalu fetch jarak via OSRM jika toko sudah diketahui.
  void updateLocation(double? lat, double? lng) {
    _currentLat = lat;
    _currentLong = lng;
    // Reset OSRM cache karena lokasi berubah
    _osrmDistanceKm = null;
    notifyListeners();
    // Fetch OSRM distance asynchronously
    _fetchOsrmDistance();
  }

  /// Panggil OSRM untuk mendapatkan jarak rute jalan raya.
  Future<void> _fetchOsrmDistance() async {
    if (_latToko == null ||
        _longToko == null ||
        _currentLat == null ||
        _currentLong == null) {
      return;
    }

    _isFetchingOsrm = true;
    notifyListeners();

    try {
      final response = await ApiService.getRouteOsrm(
        originLat: _latToko!,
        originLng: _longToko!,
        destLat: _currentLat!,
        destLng: _currentLong!,
      );

      if (response != null) {
        final routes = response['routes'] as List<dynamic>?;
        if (routes != null && routes.isNotEmpty) {
          final route = routes.first as Map<String, dynamic>;
          final distanceMeters = (route['distance'] as num?)?.toDouble() ?? 0;
          _osrmDistanceKm = distanceMeters / 1000.0;
        }
      }
    } catch (e) {
      debugPrint('OrderController OSRM error: $e');
      // Biarkan _osrmDistanceKm = null → fallback ke Haversine
    }

    _isFetchingOsrm = false;
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

      // FIX: isi tarif ongkir dinamis dari data toko
      _jarakGratisKm =
          double.tryParse(data['jarak_gratis_km']?.toString() ?? '') ?? 2.0;
      _tarifPerKm =
          double.tryParse(data['tarif_per_km']?.toString() ?? '') ?? 5000;
      _jarakMaksimalKm =
          double.tryParse(data['jarak_maksimal_km']?.toString() ?? '') ??
          double.infinity;
      _tarifPerKmLuarRadius =
          double.tryParse(data['tarif_per_km_luar_radius']?.toString() ?? '') ??
          5000;

      // Auto-select layanan jika diberikan
      if (prefillServiceId != null) {
        // Cek apakah layanan tersebut benar-benar ada di toko ini
        final exists = _services.any(
          (svc) => svc['id_services'] == prefillServiceId,
        );
        if (exists) {
          _selectedServiceIds.add(prefillServiceId);
        }
      }

      // Setelah koordinat toko diketahui, fetch OSRM jika lokasi customer sudah ada
      if (_currentLat != null && _currentLong != null) {
        _fetchOsrmDistance();
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
