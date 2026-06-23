import 'package:flutter/material.dart';
import '../services/ongkir_service.dart';

class OngkirController extends ChangeNotifier {
  bool isLoading = false;
  bool isSaving = false;
  String? errorMessage;
  String? successMessage;

  // Data model untuk form
  double jarakGratisKm = 0;
  double tarifPerKm = 0;
  double jarakMaksimalKm = 10;
  double tarifPerKmLuarRadius = 0;

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  /// Mengambil data konfigurasi dari server
  Future<void> fetchOngkirSetting(String token) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    final result = await OngkirService.getOngkirSetting(token);

    if (result != null && result['success'] == true) {
      final data = result['data'] as Map<String, dynamic>;

      // Parse data dari server ke variabel lokal
      jarakGratisKm =
          double.tryParse(data['jarak_gratis_km']?.toString() ?? '0') ?? 0;
      tarifPerKm =
          double.tryParse(data['tarif_per_km']?.toString() ?? '0') ?? 0;
      jarakMaksimalKm =
          double.tryParse(data['jarak_maksimal_km']?.toString() ?? '10') ?? 10;
      tarifPerKmLuarRadius =
          double.tryParse(
            data['tarif_per_km_luar_radius']?.toString() ?? '0',
          ) ??
          0;

      errorMessage = null;
    } else {
      errorMessage = result?['message'] ?? 'Gagal mengambil pengaturan ongkir';
    }

    isLoading = false;
    notifyListeners();
  }

  /// Mengirim data konfigurasi ke server
  Future<bool> saveOngkirSetting(String token) async {
    isSaving = true;
    errorMessage = null;
    successMessage = null;
    notifyListeners();

    // Validasi Logika di sisi client (Prevent request yang tidak masuk akal)
    if (jarakGratisKm > jarakMaksimalKm) {
      errorMessage =
          'Jarak gratis tidak boleh lebih besar dari jarak maksimal.';
      isSaving = false;
      notifyListeners();
      return false;
    }

    // Panggil Service (Pastikan OngkirService memanggil endpoint /api/v1/admin/ongkir)
    final result = await OngkirService.updateOngkirSetting(
      token: token,
      jarakGratisKm: jarakGratisKm,
      tarifPerKm: tarifPerKm,
      jarakMaksimalKm: jarakMaksimalKm,
      tarifPerKmLuarRadius: tarifPerKmLuarRadius,
    );

    isSaving = false;

    if (result != null && result['success'] == true) {
      successMessage = result['message'] ?? 'Pengaturan berhasil diperbarui.';
      notifyListeners();
      return true;
    } else {
      errorMessage =
          result?['message'] ?? 'Gagal memperbarui pengaturan ongkir.';
      notifyListeners();
      return false;
    }
  }
}
