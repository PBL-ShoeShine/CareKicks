import 'package:flutter/foundation.dart';
import '../../../core/network/api_service.dart';

class AuthService {
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    try {
      if (email.isEmpty || password.isEmpty) {
        return {
          'success': false,
          'message': 'Email dan password tidak boleh kosong',
        };
      }

      final response = await ApiService.login(email, password);

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response['code'] == 'SHOP_SUSPENDED') {
        return {
          'success': false,
          'code': 'SHOP_SUSPENDED',
          'message': response['message'] ?? 'Toko Anda ditangguhkan',
          'data': response['data'] ?? {},
        };
      }

      if (response.containsKey('message')) {
        final message = response['message'];
        if (message.toString().toLowerCase().contains('berhasil') ||
            response.containsKey('token')) {
          return {
            'success': true,
            'message': message,
            'token': response['token'],
            'user': response['user'],
          };
        } else {
          return {'success': false, 'message': message};
        }
      }

      return {'success': false, 'message': 'Respon tidak valid dari server'};
    } catch (e) {
      debugPrint('Error in AuthService.login: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> register({
    required String nama,
    required String noHp,
    required String email,
    required String password,
  }) async {
    try {
      if (nama.isEmpty || noHp.isEmpty || email.isEmpty || password.isEmpty) {
        return {'success': false, 'message': 'Semua field tidak boleh kosong'};
      }

      if (!email.contains('@')) {
        return {'success': false, 'message': 'Format email tidak valid'};
      }

      if (password.length < 6) {
        return {'success': false, 'message': 'Password minimal 6 karakter'};
      }

      final response = await ApiService.register(
        nama: nama,
        noHp: noHp,
        email: email,
        password: password,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      // --- PERBAIKAN: COCOKKAN DENGAN BALASAN OTP BACKEND ---
      if (response['success'] == true && response['message'] == 'OTP_SENT') {
        return {'success': true, 'message': 'OTP_SENT'};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Gagal memproses pendaftaran',
      };
    } catch (e) {
      debugPrint('Error in AuthService.register: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  // --- FUNGSI BARU: TERUSKAN VERIFIKASI KE API_SERVICE ---
  static Future<Map<String, dynamic>> verifyRegisterOtp(
    String email,
    String otpCode,
  ) async {
    try {
      final response = await ApiService.verifyRegisterOtp(email, otpCode);
      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response['success'] == true) {
        return {
          'success': true,
          'token': response['token'],
          'user': response['user'],
        };
      }
      return {'success': false, 'message': response['message'] ?? 'OTP Salah'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> resendRegisterOtp(String email) async {
    try {
      final response = await ApiService.resendRegisterOtp(email);
      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }
      return response;
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
