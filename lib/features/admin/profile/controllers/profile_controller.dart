import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileController extends ChangeNotifier {
  final String baseUrl = "http://10.85.113.20:3000";

  Map<String, dynamic>? userData;
  String? errorMessage;
  bool isLoading = false;
  bool _isDisposed = false;

  bool isUploadingPhoto = false;
  String? photoUploadError;

  // --- GETTER DISESUAIKAN DENGAN NAMA KOLOM SUPABASE ---
  String? get userName => userData?['nama']?.toString();
  String? get userEmail => userData?['email']?.toString();
  String? get userPhone =>
      (userData?['no_hp'] ?? userData?['noHp'])?.toString();

  // Membaca kolom path_gambar
  String? get userPhoto =>
      (userData?['path_gambar'] ?? userData?['foto'])?.toString();

  // Membaca kolom jenis_role
  String? get userRole =>
      (userData?['jenis_role'] ?? userData?['role'])?.toString();

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) super.notifyListeners();
  }

  Future<void> fetchProfile(String token) async {
    isLoading = true;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/v1/admin/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        print("===== CEK DATA SERVER =====");
        print(response.body);
        print("===========================");

        userData = data['data'] ?? data;
        errorMessage = null;
      } else {
        errorMessage = "Gagal mengambil data profil.";
      }
    } catch (e) {
      errorMessage = "Terjadi kesalahan koneksi.";
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile({
    required String token,
    String nama = '',
    String email = '',
    String noHp = '',
    String? password,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (nama.isNotEmpty) body['nama'] = nama;
      if (email.isNotEmpty) body['email'] = email;
      if (noHp.isNotEmpty) body['noHp'] = noHp;
      if (password != null) body['password'] = password;

      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/admin/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );

      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- FUNGSI UPLOAD FOTO PROFIL ---
  Future<bool> updateProfilePicture({
    required String token,
    required File imageFile,
  }) async {
    isUploadingPhoto = true;
    photoUploadError = null;
    notifyListeners();

    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/api/v1/admin/profile/picture'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // Mengubah field name form-data menjadi 'path_gambar' agar sesuai dengan database
      request.files.add(
        await http.MultipartFile.fromPath('path_gambar', imageFile.path),
      );

      var response = await request.send();

      if (response.statusCode == 200) {
        isUploadingPhoto = false;
        notifyListeners();
        return true;
      } else {
        photoUploadError = 'Gagal mengunggah foto (${response.statusCode})';
        isUploadingPhoto = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      photoUploadError = 'Terjadi kesalahan jaringan.';
      isUploadingPhoto = false;
      notifyListeners();
      return false;
    }
  }
}
