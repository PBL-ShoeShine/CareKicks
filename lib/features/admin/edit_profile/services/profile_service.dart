import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ProfileService {
  static const String baseUrl = 'http://10.85.113.20:3000/api/v1/admin/profile';

  // 1. Fungsi Update Profil
  static Future<Map<String, dynamic>> updateProfile({
    required int idUser,
    required String nama,
    required String noHp,
    required String email,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/update'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_user': idUser,
          'nama': nama,
          'no_hp': noHp,
          'email': email,
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
      debugPrint('Error updateProfile: $e');
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // 2. Fungsi Ubah Kata Sandi
  static Future<Map<String, dynamic>> changePassword({
    required int idUser,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/change-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'id_user': idUser,
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message']};
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Kata sandi lama salah',
        };
      }
    } catch (e) {
      debugPrint('Error changePassword: $e');
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }
}
