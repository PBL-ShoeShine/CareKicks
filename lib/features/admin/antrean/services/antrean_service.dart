import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/antrean_model.dart';

class AntreanService {
  static const String _baseUrl = 'http://10.254.102.20:3000/api/v1';

  static Future<List<AntreanModel>> fetchAntrean(
    String token,
    String status,
  ) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/admin/antrean?status=$status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
    );

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);
      final List data = json['data'] ?? [];
      return data.map((e) => AntreanModel.fromJson(e)).toList();
    } else {
      throw Exception('Gagal mengambil data antrean: ${response.statusCode}');
    }
  }

  static Future<bool> updateStatus(
    String token,
    int idOrder,
    String status,
  ) async {
    final response = await http.patch(
      Uri.parse('$_baseUrl/admin/antrean/$idOrder/status'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode({'status': status}),
    );
    return response.statusCode == 200;
  }
}
