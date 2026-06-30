import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart'; 

class OngkirService {
  // GET Data Ongkir
  static Future<Map<String, dynamic>> getOngkirSetting(String token) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/admin/ongkir'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'data': body['data']};
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal mengambil data',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan koneksi: $e'};
    }
  }

  // PUT Update Ongkir
  static Future<Map<String, dynamic>> updateOngkirSetting({
    required String token,
    required double jarakGratisKm,
    required double tarifPerKm,
    required double jarakMaksimalKm,
    required double tarifPerKmLuarRadius,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('${ApiService.baseUrl}/admin/ongkir'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'jarak_gratis_km': jarakGratisKm,
          'tarif_per_km': tarifPerKm,
          'jarak_maksimal_km': jarakMaksimalKm,
          'tarif_per_km_luar_radius': tarifPerKmLuarRadius,
        }),
      );

      final body = jsonDecode(response.body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return {
          'success': true,
          'message': body['message'] ?? 'Berhasil diupdate',
        };
      } else {
        return {
          'success': false,
          'message': body['message'] ?? 'Gagal mengupdate',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Kesalahan koneksi: $e'};
    }
  }
}
