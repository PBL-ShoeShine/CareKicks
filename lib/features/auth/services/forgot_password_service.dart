import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../core/network/api_service.dart';

class ForgotPasswordService {
  // 1. Request OTP Lupa Password
  static Future<Map<String, dynamic>> requestOtp(String email) async {
    try {
      final response = await http
          .post(
            // Menggunakan ApiService.baseUrl agar IP-nya tersinkronisasi otomatis
            Uri.parse('${ApiService.baseUrl}/auth/forgot-password/request-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email}),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan jaringan atau Server mati.',
      };
    }
  }

  // 2. Verifikasi Kode OTP
  static Future<Map<String, dynamic>> verifyOtp(
    String email,
    String otpCode,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('${ApiService.baseUrl}/auth/forgot-password/verify-otp'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'email': email, 'otpCode': otpCode}),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan jaringan atau Server mati.',
      };
    }
  }

  // 3. Reset Password ke Password Baru
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    try {
      final response = await http
          .put(
            Uri.parse('${ApiService.baseUrl}/auth/forgot-password/reset'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'otpCode': otpCode,
              'newPassword': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 10));

      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan jaringan atau Server mati.',
      };
    }
  }
}
