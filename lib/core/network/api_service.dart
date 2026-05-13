import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://172.16.162.151:3000/api/v1';

  static Future<Map<String, dynamic>?> cekSepatu(String qrCode) async {
    try {
      // Mengirim POST request ke rute admin pemindai
      final response = await http.post(
        Uri.parse('$baseUrl/admin/pemindai/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'qr_code': qrCode}),
      );

      // Membaca balasan dari server (sukses maupun error dari backend)
      if (response.statusCode == 200 ||
          response.statusCode == 404 ||
          response.statusCode == 400) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 404) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> register({
    required String nama,
    required String noHp,
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nama': nama,
          'no_hp': noHp,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 404) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }
}

