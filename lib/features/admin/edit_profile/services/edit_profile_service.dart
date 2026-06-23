import 'dart:convert';
import 'dart:io';
import 'package:carekicks/core/network/api_service.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class EditProfileService {
  static const String baseUrl = '${ApiService.baseUrl}/admin/profile';

  // =========================================================================
  // 1. UPDATE DATA PROFIL & REQUEST EMAIL
  // =========================================================================
  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    String? nama,
    String? noHp,
    String? email,
    bool? isRequestEmailOnly,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (nama != null) 'nama': nama,
          if (noHp != null) 'noHp': noHp,
          if (email != null) 'email': email,
          if (isRequestEmailOnly != null)
            'isRequestEmailOnly': isRequestEmailOnly,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal memperbarui profil',
        };
      }
    } catch (e) {
      debugPrint('Error EditProfileService.updateProfile: $e');
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // =========================================================================
  // 2. UPLOAD FOTO PROFIL (MULTIPART)
  // =========================================================================
  static Future<Map<String, dynamic>> uploadProfilePicture({
    required String token,
    required File imageFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/picture'),
      );

      request.headers['Authorization'] = 'Bearer $token';

      request.files.add(
        await http.MultipartFile.fromPath('image', imageFile.path),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      debugPrint('Upload status: ${response.statusCode}');
      debugPrint('Upload response: ${response.body}');

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data['message'],
          'url': data['url'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal mengunggah foto profil',
        };
      }
    } catch (e) {
      debugPrint('Error EditProfileService.uploadProfilePicture: $e');
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // =========================================================================
  // 3. GANTI KATA SANDI
  // =========================================================================
  static Future<Map<String, dynamic>> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/change-password-direct'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Gagal ganti password',
        };
      }
    } catch (e) {
      debugPrint('Error EditProfileService.changePassword: $e');
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }
}
