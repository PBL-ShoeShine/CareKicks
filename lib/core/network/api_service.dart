import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.18.15:3000/api/v1';

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
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> login(
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
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

  static Future<Map<String, dynamic>?> getDashboard({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/dashboard'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 404 ||
          response.statusCode == 401) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getActivities({
    required String token,
    String? status,
    String? search,
    int? limit,
  }) async {
    try {
      final queryParams = {
        if (status != null && status != 'all') 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
        if (limit != null) 'limit': limit.toString(),
      };

      final uri = Uri.parse(
        '$baseUrl/admin/dashboard',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 404 ||
          response.statusCode == 401) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getServices({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/inputoff/services'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 404 ||
          response.statusCode == 500) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
        debugPrint('Response: ${response.body}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> createOfflineOrder({
    required String token,
    required Map<String, dynamic> orderData,
    required File fotoSebelum,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/inputoff'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      orderData.forEach((key, value) {
        if (key == 'services') {
          request.fields[key] = jsonEncode(value);
        } else {
          request.fields[key] = value.toString();
        }
      });

      request.files.add(
        await http.MultipartFile.fromPath('foto_sebelum', fotoSebelum.path),
      );

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      debugPrint('Status Code: ${response.statusCode}');
      debugPrint('Response Body: $responseString');

      if (responseString.isNotEmpty) {
        return jsonDecode(responseString);
      }

      return {'success': false, 'message': 'Response kosong dari server'};
    } catch (e) {
      debugPrint('Gagal membuat pesanan: $e');
      return {'success': false, 'message': 'Gagal membuat pesanan: $e'};
    }
  }

  static Future<Map<String, dynamic>?> getProfile({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 404 ||
          response.statusCode == 401 ||
          response.statusCode == 500) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateProfile({
    required String token,
    required String nama,
    required String email,
    required String noHp,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nama': nama,
          'email': email,
          'no_hp': noHp,
        }),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 404 ||
          response.statusCode == 500) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateProfilePicture({
    required String token,
    required String imageUrl,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/profile/picture'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'imageUrl': imageUrl,
        }),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 404 ||
          response.statusCode == 500) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getServicesList({
    required String token,
    String? search,
    String? category,
  }) async {
    try {
      final queryParams = {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
      };

      final uri = Uri.parse(
        '$baseUrl/admin/manajemen_layanan',
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 404 ||
          response.statusCode == 500) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> createServiceWithImage({
    required String token,
    required String namaLayanan,
    required int harga,
    required String estimasiWaktu,
    String? deskripsi,
    File? foto,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/manajemen_layanan'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['nama_layanan'] = namaLayanan;
      request.fields['harga'] = harga.toString();
      request.fields['estimasi_waktu'] = estimasiWaktu;

      if (deskripsi != null && deskripsi.isNotEmpty) {
        request.fields['deskripsi'] = deskripsi;
      }

      if (foto != null) {
        final extension = foto.path.split('.').last.toLowerCase();
        String mimeType = 'image/jpeg';
        if (extension == 'png') mimeType = 'image/png';
        if (extension == 'webp') mimeType = 'image/webp';

        request.files.add(
          await http.MultipartFile.fromPath(
            'foto',
            foto.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      debugPrint('CREATE Service Status: ${response.statusCode}');
      debugPrint('CREATE Service Response: $responseString');

      if (responseString.isNotEmpty) {
        try {
          return jsonDecode(responseString);
        } catch (e) {
          debugPrint('JSON Decode Error (Create): $e');
          return {'success': false, 'message': 'Respon server tidak valid (Bukan JSON)'};
        }
      }

      return {'success': false, 'message': 'Response kosong dari server'};
    } catch (e) {
      debugPrint('Gagal membuat layanan: $e');
      return {'success': false, 'message': 'Gagal membuat layanan: $e'};
    }
  }

  static Future<Map<String, dynamic>?> updateServiceStatusApi({
    required String token,
    required int serviceId,
    required bool isActive,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/manajemen_layanan/$serviceId/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'is_active': isActive,
        }),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 404 ||
          response.statusCode == 500) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal memperbarui status: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateServiceWithImage({
    required String token,
    required int serviceId,
    required String namaLayanan,
    required int harga,
    required String estimasiWaktu,
    String? deskripsi,
    File? foto,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/admin/manajemen_layanan/$serviceId'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['nama_layanan'] = namaLayanan;
      request.fields['harga'] = harga.toString();
      request.fields['estimasi_waktu'] = estimasiWaktu;

      if (deskripsi != null && deskripsi.isNotEmpty) {
        request.fields['deskripsi'] = deskripsi;
      }

      if (foto != null) {
        final extension = foto.path.split('.').last.toLowerCase();
        String mimeType = 'image/jpeg';
        if (extension == 'png') mimeType = 'image/png';
        if (extension == 'webp') mimeType = 'image/webp';

        request.files.add(
          await http.MultipartFile.fromPath(
            'foto',
            foto.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      debugPrint('UPDATE Service Status: ${response.statusCode}');
      debugPrint('UPDATE Service Response: $responseString');

      if (responseString.isNotEmpty) {
        try {
          return jsonDecode(responseString);
        } catch (e) {
          debugPrint('JSON Decode Error (Update): $e');
          return {'success': false, 'message': 'Respon server tidak valid (Bukan JSON)'};
        }
      }

      return {'success': false, 'message': 'Response kosong dari server'};
    } catch (e) {
      debugPrint('Gagal memperbarui layanan: $e');
      return {'success': false, 'message': 'Gagal memperbarui layanan: $e'};
    }
  }

  static Future<Map<String, dynamic>?> deleteServiceApi({
    required String token,
    required int serviceId,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/manajemen_layanan/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 404 ||
          response.statusCode == 500) {
        return jsonDecode(response.body);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghapus layanan: $e');
    }
    return null;
  }
}
