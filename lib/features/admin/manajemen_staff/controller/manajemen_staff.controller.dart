import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../../core/network/api_service.dart';
import '../models/manajemen_staff.model.dart';

class ManajemenStaffController {
  final String _base = '${ApiService.baseUrl}/api/v1/admin/manajemen_staff';

  // Ganti dengan token dari login (nanti disambungkan ke shared_preferences)
  final String token = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6Miwicm9sZSI6InNob3BzX2FkbWluIiwiaWF0IjoxNzc4NTE1NDk2LCJleHAiOjE3NzkxMjAyOTZ9.WpRu7dujxVQPFUzLI18QIqXiEqByAFmuF9orj9VRuMo';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // 1. Ambil semua staff
  Future<List<ManajemenStaffModel>> getAllStaff({String? search}) async {
    try {
      final uri = Uri.parse(_base).replace(
        queryParameters: search != null && search.isNotEmpty
            ? {'search': search}
            : null,
      );

      final response = await http.get(uri, headers: _headers);
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
  Future<void> createStaff({
    required String nama,
    required String email,
    required String noHp,
    required String idShops,
    required StaffRole role,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_base/register'),
        headers: _headers,
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
  Future<void> updateStaff(String id, Map<String, dynamic> updateData) async {
    try {
      final response = await http.patch(
        Uri.parse('$_base/$id'),
        headers: _headers,
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
  Future<void> deleteStaff(String id) async {
    try {
      final response = await http.delete(
        Uri.parse('$_base/$id'),
        headers: _headers,
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