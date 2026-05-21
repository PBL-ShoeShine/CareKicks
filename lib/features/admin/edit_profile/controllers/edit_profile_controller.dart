import 'package:flutter/material.dart';
import '../services/edit_profile_service.dart'; // Import diperbarui

class EditProfileController extends ChangeNotifier {
  bool _isLoading = false;
  String _message = '';

  bool get isLoading => _isLoading;
  String get message => _message;

  // METHOD UPDATE DATA PROFIL UTAMA (NAMA, NO HP, EMAIL)
  Future<bool> updateProfil({
    required int idUser,
    required String nama,
    required String noHp,
    required String email,
  }) async {
    _setLoading(true);

    final result = await EditProfileService.updateProfile(
      idUser: idUser,
      nama: nama,
      noHp: noHp,
      email: email,
    );

    _message = result['message'] ?? '';
    _setLoading(false);
    return result['success'] ?? false;
  }

  // METHOD BARU: VALIDASI KATA SANDI NYATA KE SERVER API
  Future<bool> verifyPassword({
    required String token,
    required String password,
  }) async {
    _setLoading(true);
    _message = '';

    try {
      // Di sini nanti kamu panggil fungsi di EditProfileService kamu, contoh:
      // final result = await EditProfileService.verifyPassword(token: token, password: password);

      // Menggunakan simulasi sukses sementara sebelum service-nya kamu buat di backend:
      await Future.delayed(const Duration(milliseconds: 1000));

      if (password == "password123") {
        // Ganti dengan logic result['success'] dari API asli
        _setLoading(false);
        return true;
      } else {
        _message = 'Kata sandi salah';
        _setLoading(false);
        return false;
      }
    } catch (e) {
      _message = 'Terjadi kesalahan jaringan';
      _setLoading(false);
      return false;
    }
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
