import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../auth/session_manager.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.10.232:3000/api/v1';

  // ─── Role Helpers ─────────────────────────────────────────────────────────

  /// Kembalikan 'staff' jika role adalah courier/washer, selainnya 'admin'
  static String resolveRole(String? role) {
    return (role == 'courier' || role == 'washer') ? 'staff' : 'admin';
  }

  // ─── Response Helpers ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> _decodeJsonResponse(
    http.Response response,
  ) async {
    return _decodeJsonString(response.body);
  }

  static Future<Map<String, dynamic>?> _decodeJsonString(String body) async {
    final decoded = jsonDecode(body);

    if (decoded is! Map) {
      return {'success': false, 'message': 'Respon tidak valid dari server'};
    }

    final data = Map<String, dynamic>.from(decoded);
    await AuthSessionManager.handleExpiredResponse(data);
    return data;
  }

  // ─── Auth ─────────────────────────────────────────────────────────────────

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
          response.statusCode == 403 ||
          response.statusCode == 404) {
        return await _decodeJsonResponse(response);
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
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  // ─── PERBAIKAN: TAMBAHAN ENDPOINT OTP REGISTRASI BARU ───
  static Future<Map<String, dynamic>?> verifyRegisterOtp(
    String email,
    String otpCode,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/verify-register-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otpCode': otpCode}),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 404) {
        return await _decodeJsonResponse(response);
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend verifyRegisterOtp: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> resendRegisterOtp(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/user/resend-register-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 404) {
        return await _decodeJsonResponse(response);
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend resendRegisterOtp: $e');
    }
    return null;
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getProfile({
    required String token,
    String? role,
  }) async {
    final prefix = resolveRole(role);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$prefix/profile'),
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
        return await _decodeJsonResponse(response);
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
    String? role,
  }) async {
    final prefix = resolveRole(role);
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$prefix/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'nama': nama, 'email': email, 'no_hp': noHp}),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 404 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
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
    String? role,
  }) async {
    final prefix = resolveRole(role);
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/$prefix/profile/picture'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'imageUrl': imageUrl}),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 404 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> uploadProfilePhoto({
    required String token,
    required File photo,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/user/profile/photo'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      final extension = photo.path.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (extension == 'png') mimeType = 'image/png';
      if (extension == 'webp') mimeType = 'image/webp';

      request.files.add(
        await http.MultipartFile.fromPath(
          'photo',
          photo.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      debugPrint('UPLOAD Profile Photo Status: ${response.statusCode}');
      debugPrint('UPLOAD Profile Photo Response: $responseString');

      if (responseString.isNotEmpty) {
        return await _decodeJsonString(responseString);
      }

      return {'success': false, 'message': 'Response kosong dari server'};
    } catch (e) {
      debugPrint('Gagal upload foto profil: $e');
      return {'success': false, 'message': 'Gagal upload foto profil: $e'};
    }
  }

  // ─── Dashboard ────────────────────────────────────────────────────────────

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
        return await _decodeJsonResponse(response);
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
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  // ─── Pemindai ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> cekSepatu(
    String token,
    String qrCode,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/pemindai/verify'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // <--- Token dikirim
        },
        body: jsonEncode({'qr_code': qrCode}),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 404 ||
          response.statusCode == 500 ||
          response.statusCode == 401 ||
          response.statusCode == 400) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateStatusPesanan({
    required String token, // <--- Wajib menerima token
    required String kodeOrder,
    required String statusBaru,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/pemindai/update-status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token', // <--- Token dikirim
        },
        body: jsonEncode({'kode_order': kodeOrder, 'status_baru': statusBaru}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Gagal update status: $e');
    }
    return null;
  }

  // ─── Input Offline ────────────────────────────────────────────────────────

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
        return await _decodeJsonResponse(response);
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
        return await _decodeJsonString(responseString);
      }

      return {'success': false, 'message': 'Response kosong dari server'};
    } catch (e) {
      debugPrint('Gagal membuat pesanan: $e');
      return {'success': false, 'message': 'Gagal membuat pesanan: $e'};
    }
  }

  // ─── Toko ─────────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getShopProfile({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/toko/profil'),
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
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateShopProfile({
    required String token,
    required Map<String, dynamic> payload,
    File? fotoToko,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$baseUrl/admin/toko/profil'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      payload.forEach((key, value) {
        if (value == null) return;
        request.fields[key] = value.toString();
      });

      if (fotoToko != null) {
        final extension = fotoToko.path.split('.').last.toLowerCase();
        String mimeType = 'image/jpeg';
        if (extension == 'png') mimeType = 'image/png';
        if (extension == 'webp') mimeType = 'image/webp';

        request.files.add(
          await http.MultipartFile.fromPath(
            'foto_toko',
            fotoToko.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      debugPrint('UPDATE Shop Profile Status: ${response.statusCode}');
      debugPrint('UPDATE Shop Profile Response: $responseString');

      if (responseString.isNotEmpty) {
        return jsonDecode(responseString);
      }

      return {'success': false, 'message': 'Response kosong dari server'};
    } catch (e) {
      debugPrint('Gagal memperbarui profil toko: $e');
      return {'success': false, 'message': 'Gagal memperbarui profil toko: $e'};
    }
  }

  static Future<Map<String, dynamic>?> getOperatingHours({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/toko/jam-operasional'),
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

  static Future<Map<String, dynamic>?> updateOperatingHours({
    required String token,
    required List<Map<String, dynamic>> hours,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/toko/jam-operasional'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'hours': hours}),
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

  // ─── Manajemen Layanan ────────────────────────────────────────────────────

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
        return await _decodeJsonResponse(response);
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
          return await _decodeJsonString(responseString);
        } catch (e) {
          debugPrint('JSON Decode Error (Create): $e');
          return {
            'success': false,
            'message': 'Respon server tidak valid (Bukan JSON)',
          };
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
        body: jsonEncode({'is_active': isActive}),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 404 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
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
          return await _decodeJsonString(responseString);
        } catch (e) {
          debugPrint('JSON Decode Error (Update): $e');
          return {
            'success': false,
            'message': 'Respon server tidak valid (Bukan JSON)',
          };
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
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghapus layanan: $e');
    }
    return null;
  }

  // ─── Tracking ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getTrackingList({
    required String token,
    String? search,
    String? role,
  }) async {
    final prefix = resolveRole(role);
    try {
      final queryParams = {
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse(
        '$baseUrl/$prefix/tracking',
      ).replace(queryParameters: queryParams);

      debugPrint('GET TRACKING LIST [$prefix]: $uri');

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
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getTrackingDetail({
    required String token,
    required int orderId,
    String? role,
  }) async {
    final prefix = resolveRole(role);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$prefix/tracking/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('GET TRACKING DETAIL [$prefix]: $orderId');

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 404 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getLatestTracking({
    required String token,
    required int orderId,
    String? role,
  }) async {
    final prefix = resolveRole(role);
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/$prefix/tracking/$orderId/latest'),
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
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateTrackingStatus({
    required String token,
    required int orderId,
    required String status,
    String? keterangan,
    double? latitude,
    double? longitude,
    int? idStaff,
    int? idDetailOrders,
    String? fotoType,
    bool? isValidation,
    File? foto,
    String? role,
  }) async {
    final prefix = resolveRole(role);
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/$prefix/tracking/$orderId'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['status'] = status;
      if (keterangan != null && keterangan.isNotEmpty) {
        request.fields['keterangan'] = keterangan;
      }
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) {
        request.fields['longitude'] = longitude.toString();
      }
      if (idStaff != null) request.fields['id_staff'] = idStaff.toString();
      if (idDetailOrders != null) {
        request.fields['id_detail_orders'] = idDetailOrders.toString();
      }
      if (fotoType != null && fotoType.isNotEmpty) {
        request.fields['foto_type'] = fotoType;
      }
      if (isValidation != null) {
        request.fields['is_validation'] = isValidation.toString();
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

      debugPrint('UPDATE Tracking [$prefix] Status: ${response.statusCode}');
      debugPrint('UPDATE Tracking Response: $responseString');

      if (responseString.isNotEmpty) {
        try {
          return await _decodeJsonString(responseString);
        } catch (e) {
          debugPrint('JSON Decode Error (Tracking Update): $e');
          return {
            'success': false,
            'message': 'Respon server tidak valid (Bukan JSON)',
          };
        }
      }

      return {'success': false, 'message': 'Response kosong dari server'};
    } catch (e) {
      debugPrint('Gagal memperbarui status tracking: $e');
      return {
        'success': false,
        'message': 'Gagal memperbarui status tracking: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> updateCourierLocation({
    required String token,
    required int orderId,
    required double latitude,
    required double longitude,
    int? idStaff,
    String? status,
    String? role,
  }) async {
    final prefix = resolveRole(role);
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/$prefix/tracking/$orderId/location'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'latitude': latitude,
          'longitude': longitude,
          'id_staff': idStaff,
          'status': status,
        }),
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 404 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal memperbarui lokasi kurir: $e');
    }
    return null;
  }

  // ─── Customer ─────────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getCustomerRiwayat({
    required String token,
    String? status,
    String? search,
  }) async {
    try {
      final queryParams = {
        if (status != null && status.isNotEmpty) 'status': status,
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse(
        '$baseUrl/customer/riwayat',
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
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getCustomerDetailOrder({
    required String token,
    required String orderId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer/detail-order/$orderId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 404 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getCustomerBankAccounts({
    required String token,
    required String orderId,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/customer/payment/bank-accounts',
      ).replace(queryParameters: {'order_id': orderId});

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
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> confirmCustomerPayment({
    required String token,
    required String orderId,
    required File imageFile,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/customer/payment/confirm'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['order_id'] = orderId;

      final extension = imageFile.path.split('.').last.toLowerCase();
      String mimeType = 'image/jpeg';
      if (extension == 'png') mimeType = 'image/png';
      if (extension == 'webp') mimeType = 'image/webp';

      request.files.add(
        await http.MultipartFile.fromPath(
          'payment_proof',
          imageFile.path,
          contentType: MediaType.parse(mimeType),
        ),
      );

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      debugPrint('CONFIRM Payment Status: ${response.statusCode}');
      debugPrint('CONFIRM Payment Response: $responseString');

      if (responseString.isNotEmpty) {
        return await _decodeJsonString(responseString);
      }

      return {'success': false, 'message': 'Response kosong dari server'};
    } catch (e) {
      debugPrint('Gagal konfirmasi pembayaran: $e');
      return {'success': false, 'message': 'Gagal konfirmasi pembayaran: $e'};
    }
  }

  // ─── Admin Ubah Password ──────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> verifyAdminOldPassword({
    required String token,
    required String oldPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/profile/verify-old-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'oldPassword': oldPassword}),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 429 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint(
          'Error Server verifyAdminOldPassword: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (verifyAdminOldPassword): $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> requestAdminPasswordOtp({
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/profile/request-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 429 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint(
          'Error Server requestAdminPasswordOtp: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (requestAdminPasswordOtp): $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> verifyAdminPasswordOtp({
    required String token,
    required String otpCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/profile/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'otpCode': otpCode}),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 429 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint(
          'Error Server verifyAdminPasswordOtp: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (verifyAdminPasswordOtp): $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> changeAdminPasswordDirect({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/profile/change-password-direct'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 429 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint(
          'Error Server changeAdminPasswordDirect: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (changeAdminPasswordDirect): $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> changeAdminPasswordWithOtp({
    required String token,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/profile/change-password-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'otpCode': otpCode, 'newPassword': newPassword}),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 429 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint(
          'Error Server changeAdminPasswordWithOtp: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (changeAdminPasswordWithOtp): $e');
    }
    return null;
  }

  // ─── Admin Metode Pembayaran ──────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getAdminPaymentMethods({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/metode_pembayaran'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 ||
          response.statusCode == 401 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint(
          'Error Server getAdminPaymentMethods: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (getAdminPaymentMethods): $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> addAdminPaymentMethod({
    required String token,
    required String tipePembayaran,
    required String namaBank,
    required String noRek,
    required String atasNama,
    bool isDefault = false,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/admin/metode_pembayaran'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'tipe_pembayaran': tipePembayaran,
          'nama_bank': namaBank,
          'no_rek': noRek,
          'atas_nama': atasNama,
          'is_default': isDefault,
        }),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint(
          'Error Server addAdminPaymentMethod: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (addAdminPaymentMethod): $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> toggleAdminPaymentMethodStatus({
    required String token,
    required int idAccount,
    required bool isActive,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/metode_pembayaran/$idAccount/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'is_active': isActive}),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint(
          'Error Server toggleAdminPaymentMethodStatus: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint(
        'Gagal menghubungi backend (toggleAdminPaymentMethodStatus): $e',
      );
    }
    return null;
  }

  static Future<bool> deleteAdminPaymentMethod({
    required String token,
    required int idAccount,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/metode_pembayaran/$idAccount'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 500) {
        final data = await _decodeJsonResponse(response);
        return data?['success'] == true;
      } else {
        debugPrint(
          'Error Server deleteAdminPaymentMethod: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (deleteAdminPaymentMethod): $e');
    }
    return false;
  }

  static Future<Map<String, dynamic>?> uploadAdminQrisImage({
    required String token,
    required int idAccount,
    required File imageFile,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/admin/metode_pembayaran/$idAccount/qris-image'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      String ext = imageFile.path.split('.').last.toLowerCase();
      if (ext == 'jpg') ext = 'jpeg';

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', ext),
        ),
      );

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      debugPrint('UPLOAD QRIS Image Status: ${response.statusCode}');

      if (responseString.isNotEmpty) {
        return await _decodeJsonString(responseString);
      }
      return {'success': false, 'message': 'Response kosong dari server'};
    } catch (e) {
      debugPrint('Gagal menghubungi backend (uploadAdminQrisImage): $e');
      return {'success': false, 'message': 'Gagal upload gambar QRIS: $e'};
    }
  }

  // ─── Admin Konfirmasi Pesanan ──────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getOrdersToConfirm({
    required String token,
    String tab = 'pembayaran',
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/konfirmasi_pesanan?tab=$tab'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 ||
          response.statusCode == 401 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server getOrdersToConfirm: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> confirmPayment({
    required String token,
    required int idOrders,
    required String action,
    String? reason,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/konfirmasi_pesanan/pembayaran/$idOrders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'action': action,
          if (reason != null) 'reason': reason,
        }),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server confirmPayment: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> confirmOrder({
    required String token,
    required int idOrders,
    required String action,
    String? reason,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/konfirmasi_pesanan/pesanan/$idOrders'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'action': action,
          if (reason != null) 'reason': reason,
        }),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server confirmOrder: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend: $e');
    }
    return null;
  }

  // ─── Customer Profile ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getCustomerProfile({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 ||
          response.statusCode == 401 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server getCustomerProfile: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (getCustomerProfile): $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateCustomerProfile({
    required String token,
    required String nama,
    required String gender,
    required String birthday,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/customer/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'nama': nama,
          'gender': gender,
          'birthday': birthday,
        }),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint(
          'Error Server updateCustomerProfile: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (updateCustomerProfile): $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> uploadCustomerProfilePicture({
    required String token,
    required File imageFile,
  }) async {
    try {
      final request = http.MultipartRequest(
        'PUT',
        Uri.parse('$baseUrl/customer/profile/picture'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      String ext = imageFile.path.split('.').last.toLowerCase();
      if (ext == 'jpg') ext = 'jpeg';

      request.files.add(
        await http.MultipartFile.fromPath(
          'image',
          imageFile.path,
          contentType: MediaType('image', ext),
        ),
      );

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      debugPrint(
        'UPLOAD Customer Profile Picture Status: ${response.statusCode}',
      );

      if (responseString.isNotEmpty) {
        return await _decodeJsonString(responseString);
      }
      return {'success': false, 'message': 'Response kosong dari server'};
    } catch (e) {
      debugPrint(
        'Gagal menghubungi backend (uploadCustomerProfilePicture): $e',
      );
      return {'success': false, 'message': 'Gagal upload foto: $e'};
    }
  }

  static Future<Map<String, dynamic>?> requestCustomerEmailChange({
    required String token,
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer/profile/request-email-change'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'email': email}),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 429 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint(
          'Error Server requestCustomerEmailChange: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (requestCustomerEmailChange): $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateCustomerNoHp({
    required String token,
    required String noHp,
    required String password,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/customer/profile/phone'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'no_hp': noHp, 'password': password}),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 429 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server updateCustomerNoHp: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (updateCustomerNoHp): $e');
    }
    return null;
  }

  // ─── Customer Alamat ──────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getCustomerAlamat({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 ||
          response.statusCode == 401 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server getCustomerAlamat: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (getCustomerAlamat): $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> addCustomerAlamat({
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
        Uri.parse('$baseUrl/customer/addresses'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server addCustomerAlamat: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (addCustomerAlamat): $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> updateCustomerAlamat({
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
        Uri.parse('$baseUrl/customer/addresses/$idAddress'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
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
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 404 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server updateCustomerAlamat: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (updateCustomerAlamat): $e');
    }
    return null;
  }

  static Future<bool> setDefaultCustomerAlamat({
    required String token,
    required int idAddress,
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/customer/addresses/$idAddress/default'),
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
        final data = await _decodeJsonResponse(response);
        return data?['success'] == true;
      } else {
        debugPrint(
          'Error Server setDefaultCustomerAlamat: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (setDefaultCustomerAlamat): $e');
    }
    return false;
  }

  static Future<bool> deleteCustomerAlamat({
    required String token,
    required int idAddress,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/customer/addresses/$idAddress'),
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
        final data = await _decodeJsonResponse(response);
        return data?['success'] == true;
      } else {
        debugPrint('Error Server deleteCustomerAlamat: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (deleteCustomerAlamat): $e');
    }
    return false;
  }

  // ─── Customer Password ────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> verifyCustomerOldPassword({
    required String token,
    required String oldPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer/profile/verify-old-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'old_password': oldPassword}),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 429 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint(
          'Error Server verifyCustomerOldPassword: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (verifyCustomerOldPassword): $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> requestCustomerPasswordOtp({
    required String token,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer/profile/request-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 429 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint(
          'Error Server requestCustomerPasswordOtp: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (requestCustomerPasswordOtp): $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> verifyCustomerPasswordOtp({
    required String token,
    required String otpCode,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/customer/profile/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'otp': otpCode}),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 429 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint(
          'Error Server verifyCustomerPasswordOtp: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (verifyCustomerPasswordOtp): $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> changeCustomerPasswordDirect({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/customer/profile/change-password-direct'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 429 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint(
          'Error Server changeCustomerPasswordDirect: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint(
        'Gagal menghubungi backend (changeCustomerPasswordDirect): $e',
      );
    }
    return null;
  }

  static Future<Map<String, dynamic>?> changeCustomerPasswordWithOtp({
    required String token,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/customer/profile/change-password-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'otp': otpCode, 'new_password': newPassword}),
      );
      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 429 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint(
          'Error Server changeCustomerPasswordWithOtp: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint(
        'Gagal menghubungi backend (changeCustomerPasswordWithOtp): $e',
      );
    }
    return null;
  }

  // ─── Customer Beranda ─────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getCustomerBeranda({
    required String token,
    String? search,
    double? minPrice,
    double? maxPrice,
    String? spesialisasi,
    double? minRating,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (minPrice != null) queryParams['minPrice'] = minPrice.toString();
      if (maxPrice != null) queryParams['maxPrice'] = maxPrice.toString();
      if (spesialisasi != null && spesialisasi.isNotEmpty) {
        queryParams['spesialisasi'] = spesialisasi;
      }
      if (minRating != null) queryParams['minRating'] = minRating.toString();
      if (sortBy != null && sortBy.isNotEmpty) queryParams['sortBy'] = sortBy;
      if (sortOrder != null && sortOrder.isNotEmpty) {
        queryParams['sortOrder'] = sortOrder;
      }
      if (page != null) queryParams['page'] = page.toString();
      if (limit != null) queryParams['limit'] = limit.toString();

      final uri = Uri.parse(
        '$baseUrl/customer/beranda',
      ).replace(queryParameters: queryParams);

      debugPrint('GET Customer Beranda: $uri');

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
          response.statusCode == 403 ||
          response.statusCode == 404 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server getCustomerBeranda: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (getCustomerBeranda): $e');
    }
    return null;
  }

  // ─── Customer Detail Layanan ───────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getCustomerServiceDetail({
    required String token,
    required int serviceId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer/services/$serviceId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint('GET Customer Service Detail: $serviceId');

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 401 ||
          response.statusCode == 403 ||
          response.statusCode == 404 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint(
          'Error Server getCustomerServiceDetail: ${response.statusCode}',
        );
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (getCustomerServiceDetail): $e');
    }
    return null;
  }

  // ─── Customer Ulasan (Reviews) ────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getCustomerReviews({
    int? serviceId,
    int? shopId,
    String? rating,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (serviceId != null) queryParams['id_services'] = serviceId.toString();
      if (shopId != null) queryParams['id_shops'] = shopId.toString();
      if (rating != null && rating.isNotEmpty && rating != 'Semua') {
        queryParams['rating'] = rating;
      }

      final uri = Uri.parse(
        '$baseUrl/customer/ulasan',
      ).replace(queryParameters: queryParams);

      debugPrint('GET Customer Reviews: $uri');

      final response = await http.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200 ||
          response.statusCode == 400 ||
          response.statusCode == 404 ||
          response.statusCode == 500) {
        return await _decodeJsonResponse(response);
      } else {
        debugPrint('Error Server getCustomerReviews: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Gagal menghubungi backend (getCustomerReviews): $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getUlasan({
    int? idShops,
    String? rating,
  }) async {
    return getCustomerReviews(shopId: idShops, rating: rating);
  }

  static Future<Map<String, dynamic>?> createUlasan({
    required String token,
    required int rating,
    required String ulasan,
    int? idShops,
    int? idOrders,
    int? idServices,
    List<File>? fotoUlasan,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/customer/ulasan'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['rating'] = rating.toString();
      request.fields['ulasan'] = ulasan;
      if (idShops != null) request.fields['id_shops'] = idShops.toString();
      if (idOrders != null) request.fields['id_orders'] = idOrders.toString();
      if (idServices != null) {
        request.fields['id_services'] = idServices.toString();
      }

      if (fotoUlasan != null && fotoUlasan.isNotEmpty) {
        for (final foto in fotoUlasan) {
          final extension = foto.path.split('.').last.toLowerCase();
          String mimeType = 'image/jpeg';
          if (extension == 'png') mimeType = 'image/png';
          if (extension == 'webp') mimeType = 'image/webp';

          request.files.add(
            await http.MultipartFile.fromPath(
              'foto_ulasan',
              foto.path,
              contentType: MediaType.parse(mimeType),
            ),
          );
        }
      }

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      debugPrint('CREATE Ulasan Status: ${response.statusCode}');
      debugPrint('CREATE Ulasan Response: $responseString');

      if (responseString.isNotEmpty) {
        return await _decodeJsonString(responseString);
      }

      return {'success': false, 'message': 'Response kosong dari server'};
    } catch (e) {
      debugPrint('Gagal mengirim ulasan: $e');
      return {'success': false, 'message': 'Gagal mengirim ulasan: $e'};
    }
  }

  // ─── OSRM Route ───────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getRouteOsrm({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final uri =
          Uri.parse(
            'https://router.project-osrm.org/route/v1/driving/'
            '$originLng,$originLat;$destLng,$destLat',
          ).replace(
            queryParameters: {
              'overview': 'full',
              'geometries': 'polyline',
              'steps': 'true',
            },
          );

      final response = await http.get(uri);

      if (response.statusCode == 200) {
        return await _decodeJsonResponse(response);
      }

      debugPrint('Error OSRM: ${response.statusCode}');
    } catch (e) {
      debugPrint('Gagal menghubungi OSRM: $e');
    }
    return null;
  }

  // ─── Customer: Shop Profile ──────────────────────────────────────────────
  static Future<Map<String, dynamic>?> getCustomerShopProfile({
    required String token,
    required int idShops,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/customer/shops/$idShops');
      final response = await http.get(
        uri,
        headers: {'Authorization': 'Bearer $token'},
      );

      if ([200, 400, 401, 404, 500].contains(response.statusCode)) {
        return await _decodeJsonResponse(response);
      }
    } catch (e) {
      debugPrint('getCustomerShopProfile error: $e');
    }
    return null;
  }

  // ─── Customer: Buat Pesanan Online ────────────────────────────────────────
  static Future<Map<String, dynamic>?> createCustomerOrder({
    required String token,
    required int idShops,
    required String namaPemilik,
    required String noHp,
    required String alamat,
    required String merk,
    required String jenisSepatu,
    required String warna,
    required List<int> selectedServiceIds,
    String? catatan,
    double? latOrder,
    double? longOrder,
    int? totalOngkir,
    List<File>? fotoSepatuList,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/customer/order');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..fields['id_shops'] = idShops.toString()
        ..fields['nama_pemilik'] = namaPemilik
        ..fields['no_hp'] = noHp
        ..fields['alamat'] = alamat
        ..fields['merk'] = merk
        ..fields['jenis_sepatu'] = jenisSepatu
        ..fields['warna'] = warna
        ..fields['total_ongkir'] = (totalOngkir ?? 0).toString()
        ..fields['services'] = jsonEncode(
          selectedServiceIds.map((id) => {'id_services': id}).toList(),
        );

      if (catatan != null && catatan.isNotEmpty) {
        request.fields['catatan'] = catatan;
      }
      if (latOrder != null) request.fields['lat_order'] = latOrder.toString();
      if (longOrder != null) {
        request.fields['long_order'] = longOrder.toString();
      }

      if (fotoSepatuList != null && fotoSepatuList.isNotEmpty) {
        for (int i = 0; i < fotoSepatuList.length; i++) {
          final foto = fotoSepatuList[i];
          final bytes = await foto.readAsBytes();
          final ext = foto.path.split('.').last.toLowerCase();
          final mimeType = ext == 'png' ? 'image/png' : 'image/jpeg';
          request.files.add(
            http.MultipartFile.fromBytes(
              'foto_sepatu',
              bytes,
              filename: 'foto_${i}_$ext',
              contentType: MediaType.parse(mimeType),
            ),
          );
        }
      }

      debugPrint('POST createCustomerOrder → $uri');
      final streamed = await request.send();
      final response = await http.Response.fromStream(streamed);
      debugPrint('createCustomerOrder status: ${response.statusCode}');

      if ([200, 201, 400, 401, 403, 404, 500].contains(response.statusCode)) {
        return await _decodeJsonResponse(response);
      }
    } catch (e) {
      debugPrint('createCustomerOrder error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>> createOrderFromCart({
    required String token,
    required List<int> selectedIds,
    required String namaPemilik,
    required String noHp,
    required String alamat,
    double? latOrder,
    double? longOrder,
    int? totalOngkir,
    String? metodePengambilan,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/customer/order/from-cart');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'selected_ids': selectedIds,
          'nama_pemilik': namaPemilik,
          'no_hp': noHp,
          'alamat': alamat,
          'lat_order': latOrder,
          'long_order': longOrder,
          'total_ongkir': totalOngkir ?? 0,
          'metode_pengambilan': metodePengambilan ?? 'delivery',
        }),
      );

      debugPrint('POST createOrderFromCart → ${response.statusCode}');
      if ([200, 201, 400, 401, 404, 500].contains(response.statusCode)) {
        return (await _decodeJsonResponse(response)) ??
            {'success': false, 'message': 'Respon server kosong'};
      }
    } catch (e) {
      debugPrint('createOrderFromCart error: $e');
    }
    return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
  }

  // ─── Customer: Ambil Layanan Toko (untuk form order) ─────────────────────
  static Future<Map<String, dynamic>?> getCustomerOrderServices({
    required String token,
    required int idShops,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/customer/order/services/$idShops');
      final response = await http.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      debugPrint(
        'GET order services idShops=$idShops → ${response.statusCode}',
      );
      if ([200, 400, 401, 404, 500].contains(response.statusCode)) {
        return await _decodeJsonResponse(response);
      }
    } catch (e) {
      debugPrint('getCustomerOrderServices error: $e');
    }
    return null;
  }

  // ─── Customer Cart ────────────────────────────────────────────────────────

  static Future<Map<String, dynamic>?> getCustomerCart({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/customer/cart'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return _decodeJsonResponse(response);
    } catch (e) {
      debugPrint('Gagal menghubungi backend (getCustomerCart): $e');
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  static Future<Map<String, dynamic>?> addToCart({
    required String token,
    required String idShops,
    required String idServices,
    required String hargaLayanan,
    String? catatan,
    required String merk,
    required String jenisSepatu,
    required String warna,
    required List<File> fotoSebelumList,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/customer/cart');
      final request = http.MultipartRequest('POST', uri);

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['id_shops'] = idShops;
      request.fields['id_services'] = idServices;
      request.fields['harga_layanan'] = hargaLayanan;
      if (catatan != null && catatan.isNotEmpty) {
        request.fields['catatan'] = catatan;
      }
      request.fields['merk'] = merk;
      request.fields['jenis_sepatu'] = jenisSepatu;
      request.fields['warna'] = warna;

      for (final file in fotoSebelumList) {
        final extension = file.path.split('.').last.toLowerCase();
        String mimeType = 'image/jpeg';
        if (extension == 'png') mimeType = 'image/png';
        if (extension == 'webp') mimeType = 'image/webp';

        request.files.add(
          await http.MultipartFile.fromPath(
            'foto_sebelum',
            file.path,
            contentType: MediaType.parse(mimeType),
          ),
        );
      }

      final response = await request.send();
      final responseString = await response.stream.bytesToString();

      debugPrint('ADD TO CART Status: ${response.statusCode}');
      debugPrint('ADD TO CART Response: $responseString');

      if (responseString.isNotEmpty) {
        return _decodeJsonString(responseString);
      }
      return {'success': false, 'message': 'Response kosong dari server'};
    } catch (e) {
      debugPrint('Gagal menghubungi backend (addToCart): $e');
      return {
        'success': false,
        'message': 'Gagal menambahkan ke keranjang: $e',
      };
    }
  }

  static Future<Map<String, dynamic>?> deleteCartItem({
    required String token,
    required int idCartItem,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/customer/cart/item/$idCartItem'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      return _decodeJsonResponse(response);
    } catch (e) {
      debugPrint('Gagal menghubungi backend (deleteCartItem): $e');
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  static Future<Map<String, dynamic>?> updateCartItem({
    required String token,
    required int idCartItem,
    String? catatan,
    String? merk,
    String? jenisSepatu,
    String? warna,
    String? fotoIndices,
    List<File>? fotoSebelumList,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/customer/cart/item/$idCartItem');
      final request = http.MultipartRequest('PATCH', uri);
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      if (catatan != null) request.fields['catatan'] = catatan;
      if (merk != null) request.fields['merk'] = merk;
      if (jenisSepatu != null) request.fields['jenis_sepatu'] = jenisSepatu;
      if (warna != null) request.fields['warna'] = warna;
      if (fotoIndices != null) request.fields['foto_indices'] = fotoIndices;

      if (fotoSebelumList != null) {
        for (final file in fotoSebelumList) {
          final extension = file.path.split('.').last.toLowerCase();
          String mimeType = 'image/jpeg';
          if (extension == 'png') mimeType = 'image/png';
          if (extension == 'webp') mimeType = 'image/webp';

          request.files.add(
            await http.MultipartFile.fromPath(
              'foto_sebelum',
              file.path,
              contentType: MediaType.parse(mimeType),
            ),
          );
        }
      }

      final streamed = await request.send();
      final responseString = await streamed.stream.bytesToString();
      if (responseString.isNotEmpty) {
        return _decodeJsonString(responseString);
      }
      return {'success': false, 'message': 'Response kosong dari server'};
    } catch (e) {
      debugPrint('Gagal menghubungi backend (updateCartItem): $e');
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }
}
