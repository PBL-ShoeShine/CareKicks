import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://10.85.113.20:3000/api/v1';

  static Future<Map<String, dynamic>?> cekSepatu(String qrCode) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/pemindai/verify'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'qr_code': qrCode}),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 404 ||
          response.statusCode == 400) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateStatusPesanan(
    String kodeOrder,
    String statusBaru,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/pemindai/update-status'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'kode_order': kodeOrder, 'status_baru': statusBaru}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Gagal update status: $e');
    }
    return null;
  }
}
