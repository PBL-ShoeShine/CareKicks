import 'dart:convert';
import 'package:http/http.dart' as http;

class UbahPasswordService {
  static const String baseUrl =
      'http://10.137.229.70:3000/api/v1/customer/profile';

  static Map<String, String> _headers(String token) => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token',
  };

  Future<Map<String, dynamic>> verifyOldPassword(
    String token,
    String oldPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-old-password'),
        headers: _headers(token),
        body: jsonEncode({'old_password': oldPassword}), // ✅ FIX: Snake Case
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

  Future<Map<String, dynamic>> requestOtp(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/request-otp'),
        headers: _headers(token),
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

  Future<Map<String, dynamic>> verifyOtpOnly(
    String token,
    String otpCode,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/verify-otp'),
        headers: _headers(token),
        body: jsonEncode({'otp': otpCode}), // ✅ FIX: Sesuai backend
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

  Future<bool> changePasswordDirect(
    String token,
    String oldPassword,
    String newPassword,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/change-password-direct'),
        headers: _headers(token),
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePasswordWithOtp(
    String token,
    String otpCode,
    String newPassword,
  ) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/change-password-otp'),
        headers: _headers(token),
        body: jsonEncode({'otp': otpCode, 'new_password': newPassword}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
