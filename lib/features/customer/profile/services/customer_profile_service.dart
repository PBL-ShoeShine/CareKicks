import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class CustomerProfileService {
  static const String baseUrl =
      'http://10.137.229.70:3000/api/v1/customer/profile';
  static const String alamatUrl =
      'http://10.137.229.70:3000/api/v1/customer/addresses';

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  // =========================================================================
  // PROFILE
  // =========================================================================
  static Future<Map<String, dynamic>> fetchProfile(String token) async {
    try {
      final response = await http.get(
        Uri.parse(baseUrl),
        headers: _headers(token),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil profil'};
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String nama,
    required String gender,
    required String birthday,
  }) async {
    try {
      final response = await http.put(
        Uri.parse(baseUrl),
        headers: _headers(token),
        body: jsonEncode({
          'nama': nama,
          'gender': gender,
          'birthday': birthday,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  static Future<Map<String, dynamic>> requestEmailChange({
    required String token,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/request-email-change'),
        headers: _headers(token),
        body: jsonEncode({'email': email}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengirim verifikasi email'};
    }
  }

  static Future<Map<String, dynamic>> updateNoHp({
    required String token,
    required String noHp,
    required String password,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/phone'),
        headers: _headers(token),
        body: jsonEncode({'no_hp': noHp, 'password': password}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  static Future<Map<String, dynamic>> uploadProfilePicture({
    required String token,
    required File imageFile,
  }) async {
    try {
      var request = http.MultipartRequest('PUT', Uri.parse('$baseUrl/picture'));
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
      return {'success': false, 'message': 'Gagal unggah foto'};
    }
  }

  // =========================================================================
  // ALAMAT
  // =========================================================================
  static Future<Map<String, dynamic>> fetchAlamat(String token) async {
    try {
      final response = await http.get(
        Uri.parse(alamatUrl),
        headers: _headers(token),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Gagal mengambil daftar alamat'};
    }
  }

  static Future<Map<String, dynamic>> addAlamat({
    required String token,
    required String recipientName,
    required String phoneNumber,
    required String fullAddress,
    String? addressLabel,
    bool isDefault = false,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(alamatUrl),
        headers: _headers(token),
        body: jsonEncode({
          'recipient_name': recipientName,
          'phone_number': phoneNumber,
          'full_address': fullAddress,
          'address_label': addressLabel,
          'is_default': isDefault,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  static Future<Map<String, dynamic>> updateAlamat({
    required String token,
    required int idAddress,
    required String recipientName,
    required String phoneNumber,
    required String fullAddress,
    String? addressLabel,
    bool isDefault = false,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$alamatUrl/$idAddress'),
        headers: _headers(token),
        body: jsonEncode({
          'recipient_name': recipientName,
          'phone_number': phoneNumber,
          'full_address': fullAddress,
          'address_label': addressLabel,
          'is_default': isDefault,
          if (latitude != null) 'latitude': latitude,
          if (longitude != null) 'longitude': longitude,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  static Future<bool> setDefaultAlamat({
    required String token,
    required int idAddress,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$alamatUrl/$idAddress/default'),
        headers: _headers(token),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }

  static Future<bool> deleteAlamat({
    required String token,
    required int idAddress,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$alamatUrl/$idAddress'),
        headers: _headers(token),
      );
      final data = jsonDecode(response.body);
      return data['success'] == true;
    } catch (e) {
      return false;
    }
  }
}
