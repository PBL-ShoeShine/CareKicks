import 'dart:convert';
import 'package:http/http.dart' as http;

class UbahPasswordService {
  final String baseUrl = "http://10.254.102.20:3000";

  // 1. Verifikasi Sandi Lama (Halaman 1)
  Future<Map<String, dynamic>> verifyOldPassword(
    String token,
    String oldPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/admin/profile/verify-old-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'oldPassword': oldPassword}),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // 2. Request OTP (Kirim ke Email)
  Future<Map<String, dynamic>> requestOtp(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/admin/profile/request-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // 3. Verifikasi OTP Saja (Halaman 2)
  Future<Map<String, dynamic>> verifyOtpOnly(
    String token,
    String otpCode,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/v1/admin/profile/verify-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'otpCode': otpCode}),
      );
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200,
        'message': data['message'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
  }

  // 4. Simpan Sandi Baru via Direct (Halaman 3)
  Future<bool> changePasswordDirect(
    String token,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/admin/profile/change-password-direct'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'oldPassword': oldPassword,
          'newPassword': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // 5. Simpan Sandi Baru via OTP (Halaman 3)
  Future<bool> changePasswordWithOtp(
    String token,
    String otpCode,
    String newPassword,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/api/v1/admin/profile/change-password-otp'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'otpCode': otpCode, 'newPassword': newPassword}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
