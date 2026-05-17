import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';
import '../models/manajemen_staff.model.dart';

class ManajemenStaffService {
  static final String _base = '${ApiService.baseUrl}/admin/manajemen_staff';

  static Map<String, String> _headers(String token) => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

  // 1. Ambil semua staff
  static Future<List<ManajemenStaffModel>> getAllStaff(
      String token, {String? search}) async {
    try {
      final uri = Uri.parse(_base).replace(
        queryParameters: search != null && search.isNotEmpty
            ? {'search': search}
            : null,
      );

      final response = await http.get(uri, headers: _headers(token));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final List list = data['data'] ?? [];
        return list.map((e) => ManajemenStaffModel.fromJson(e)).toList();
      }
      throw Exception(data['message'] ?? 'Gagal mengambil data staff');
    } catch (e) {
      rethrow;
    }
  }

  // 2. Tambah staff baru
  static Future<void> createStaff({
    required String token,
    required String nama,
    required String email,
    required String noHp,
    required String idShops,
    required StaffRole role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_base/register'),
        headers: _headers(token),
        body: jsonEncode({
          'nama': nama,
          'email': email,
          'no_hp': noHp,
          'id_shops': int.tryParse(idShops) ?? idShops,
          'role': role.name,
        }),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode != 201) {
        throw Exception(data['message'] ?? 'Gagal membuat staff');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 3. Update staff
  static Future<void> updateStaff(
      String token, String id, Map<String, dynamic> updateData) async {
    try {
      final response = await http.patch(
        Uri.parse('$_base/$id'),
        headers: _headers(token),
        body: jsonEncode(updateData),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Gagal update staff');
      }
    } catch (e) {
      rethrow;
    }
  }

  // 4. Hapus staff
  static Future<void> deleteStaff(String token, String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_base/$id'),
        headers: _headers(token),
      );
      final data = jsonDecode(response.body);

      if (response.statusCode != 200) {
        throw Exception(data['message'] ?? 'Gagal menghapus staff');
      }
    } catch (e) {
      rethrow;
    }
  }
}