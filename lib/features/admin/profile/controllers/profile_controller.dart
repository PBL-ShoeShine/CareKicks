import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class ProfileController extends ChangeNotifier {
  final String baseUrl = "http://10.254.102.20:3000";

  Map<String, dynamic>? userData;
  String? errorMessage;
  bool isLoading = false;
  bool _isDisposed = false;

  bool isUploadingPhoto = false;
  String? photoUploadError;

  String? get userName => userData?['nama']?.toString();
  String? get userEmail => userData?['email']?.toString();
  String? get userPhone =>
      (userData?['no_hp'] ?? userData?['noHp'])?.toString();
  String? get userPhoto =>
      (userData?['path_gambar'] ?? userData?['foto'])?.toString();
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

        debugPrint("===== CEK DATA SERVER =====");
        debugPrint(response.body);
        debugPrint("===========================");

        userData = data['data'] ?? data;
        errorMessage = null;
      } else {
        errorMessage = "Gagal mengambil data profil.";
      }
    } catch (e) {
      errorMessage = "Terjadi kesalahan koneksi.";
      debugPrint('Error fetchProfile: $e');
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
      debugPrint('Error updateProfile: $e');
      return false;
    }
  }

  // ✅ FIX: Ganti PUT → POST
  Future<bool> updateProfilePicture({
    required String token,
    required File imageFile,
  }) async {
    isUploadingPhoto = true;
    photoUploadError = null;
    notifyListeners();

    try {
      var request = http.MultipartRequest(
        'POST', // ✅ Fix: was PUT
        Uri.parse('$baseUrl/api/v1/admin/profile/picture'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      // ✅ Fix: field name 'image' sesuai backend (bukan 'path_gambar')
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      var streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

      // ✅ Debug log — hapus setelah fitur berjalan normal
      debugPrint('Upload status: ${streamedResponse.statusCode}');
      debugPrint('Upload response: $responseBody');

      if (streamedResponse.statusCode == 200) {
        isUploadingPhoto = false;
        notifyListeners();
        return true;
      } else {
        photoUploadError =
            'Gagal mengunggah foto (${streamedResponse.statusCode}): $responseBody';
        isUploadingPhoto = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      photoUploadError = 'Terjadi kesalahan jaringan: $e';
      isUploadingPhoto = false;
      notifyListeners();
      debugPrint('Error updateProfilePicture: $e');
      return false;
    }
  }
}
