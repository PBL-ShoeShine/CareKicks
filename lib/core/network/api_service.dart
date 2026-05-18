import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/foundation.dart';
import '../auth/session_manager.dart';

class ApiService {
  static const String baseUrl = 'http://192.168.1.228:3000/api/v1';

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
        return await _decodeJsonResponse(response);
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
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/profile'),
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
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/admin/profile/picture'),
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

  static Future<Map<String, dynamic>?> getTrackingList({
    required String token,
    String? search,
  }) async {
    try {
      final queryParams = {
        if (search != null && search.isNotEmpty) 'search': search,
      };

      final uri = Uri.parse(
        '$baseUrl/admin/tracking',
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

  static Future<Map<String, dynamic>?> getTrackingDetail({
    required String token,
    required int orderId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/tracking/$orderId'),
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

  static Future<Map<String, dynamic>?> getLatestTracking({
    required String token,
    required int orderId,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/tracking/$orderId/latest'),
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
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/admin/tracking/$orderId'),
      );

      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['status'] = status;
      if (keterangan != null && keterangan.isNotEmpty) {
        request.fields['keterangan'] = keterangan;
      }
      if (latitude != null) request.fields['latitude'] = latitude.toString();
      if (longitude != null) request.fields['longitude'] = longitude.toString();
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

      debugPrint('UPDATE Tracking Status: ${response.statusCode}');
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
  }) async {
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/admin/tracking/$orderId/location'),
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
}
