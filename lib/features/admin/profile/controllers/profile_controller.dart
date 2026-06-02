import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';

class ProfileController extends ChangeNotifier {
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

  // ─── Fetch Profile ────────────────────────────────────────────────────────

  /// [role] — jenis_role dari data user login ('courier', 'washer', atau lainnya)
  Future<void> fetchProfile(String token, {String? role}) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    // Staff (courier/washer) pakai endpoint /staff/profile,
    // owner/admin pakai /admin/profile
    final prefix = ApiService.resolveRole(role);

    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/$prefix/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('===== FETCH PROFILE [$prefix] =====');
      debugPrint('STATUS: ${response.statusCode}');
      debugPrint('BODY  : ${response.body}');
      debugPrint('===================================');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        userData = data['data'] ?? data;
        errorMessage = null;
      } else {
        errorMessage = 'Gagal mengambil data profil.';
      }
    } catch (e) {
      errorMessage = 'Terjadi kesalahan koneksi.';
      debugPrint('Error fetchProfile: $e');
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ─── Update Profile ───────────────────────────────────────────────────────

  Future<bool> updateProfile({
    required String token,
    String nama = '',
    String email = '',
    String noHp = '',
    String? password,
    String? role,
  }) async {
    final prefix = ApiService.resolveRole(role);
    try {
      final Map<String, dynamic> body = {};
      if (nama.isNotEmpty) body['nama'] = nama;
      if (email.isNotEmpty) body['email'] = email;
      if (noHp.isNotEmpty) body['noHp'] = noHp;
      if (password != null) body['password'] = password;

      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/$prefix/profile'),
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

  // ─── Update Profile Picture ───────────────────────────────────────────────

  Future<bool> updateProfilePicture({
    required String token,
    required File imageFile,
    String? role,
  }) async {
    final prefix = ApiService.resolveRole(role);
    isUploadingPhoto = true;
    photoUploadError = null;
    notifyListeners();

    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiService.baseUrl}/$prefix/profile/picture'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      final streamedResponse = await request.send();
      final responseBody = await streamedResponse.stream.bytesToString();

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