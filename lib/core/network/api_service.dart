import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.110.217:3000/api/v1';

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
}
