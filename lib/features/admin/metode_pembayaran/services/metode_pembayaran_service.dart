import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class MetodePembayaranService {
  // Sesuaikan IP Address dengan IP lokal servermu
  static const String baseUrl =
      'http://10.254.102.20:3000/api/v1/admin/payments';

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  static Future<Map<String, dynamic>> fetchPaymentMethods(String token) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: _headers(token),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil data'};
    }
  }

  static Future<Map<String, dynamic>> addPaymentMethod({
    required String token,
    required String tipePembayaran,
    required String namaBank,
    required String noRek,
    required String atasNama,
    bool isDefault = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(baseUrl),
        headers: _headers(token),
        body: jsonEncode({
          'tipe_pembayaran': tipePembayaran,
          'nama_bank': namaBank,
          'no_rek': noRek,
          'atas_nama': atasNama,
          'is_default': isDefault,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  static Future<Map<String, dynamic>> toggleStatus({
    required String token,
    required int idAccount,
    required bool isActive,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$idAccount/status'),
        headers: _headers(token),
        body: jsonEncode({'is_active': isActive}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  static Future<bool> deletePaymentMethod(String token, int idAccount) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/$idAccount'),
        headers: _headers(token),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<Map<String, dynamic>> uploadQrisImage({
    required String token,
    required int idAccount,
    required File imageFile,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/$idAccount/qris-image'),
      );
      request.headers['Authorization'] = 'Bearer $token';

      String ext = imageFile.path.split('.').last.toLowerCase();
      if (ext == 'jpg') ext = 'jpeg';

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', ext),
        ),
      );

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal unggah foto QRIS'};
    }
  }
}
