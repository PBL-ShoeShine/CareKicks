import '../../../../../core/network/api_service.dart';

class UbahPasswordService {
  // 1. Verifikasi Sandi Lama (Halaman 1)
  Future<Map<String, dynamic>> verifyOldPassword(
    String token,
    String oldPassword,
  ) async {
    final response = await ApiService.verifyAdminOldPassword(
      token: token,
      oldPassword: oldPassword,
    );
    if (response == null) {
      return {'success': false, 'message': 'Gagal menghubungi server'};
    }
    return {
      'success': response['success'] == true,
      'message': response['message'],
    };
  }

  // 2. Request OTP (Kirim ke Email)
  Future<Map<String, dynamic>> requestOtp(String token) async {
    final response = await ApiService.requestAdminPasswordOtp(
      token: token,
    );
    if (response == null) {
      return {'success': false, 'message': 'Gagal menghubungi server'};
    }
    return {
      'success': response['success'] == true,
      'message': response['message'],
    };
  }

  // 3. Verifikasi OTP Saja (Halaman 2)
  Future<Map<String, dynamic>> verifyOtpOnly(
    String token,
    String otpCode,
  ) async {
    final response = await ApiService.verifyAdminPasswordOtp(
      token: token,
      otpCode: otpCode,
    );
    if (response == null) {
      return {'success': false, 'message': 'Gagal menghubungi server'};
    }
    return {
      'success': response['success'] == true,
      'message': response['message'],
    };
  }

  // 4. Simpan Sandi Baru via Direct (Halaman 3)
  Future<bool> changePasswordDirect(
    String token,
    String oldPassword,
    String newPassword,
  ) async {
    final response = await ApiService.changeAdminPasswordDirect(
      token: token,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    return response?['success'] == true;
  }

  // 5. Simpan Sandi Baru via OTP (Halaman 3)
  Future<bool> changePasswordWithOtp(
    String token,
    String otpCode,
    String newPassword,
  ) async {
    final response = await ApiService.changeAdminPasswordWithOtp(
      token: token,
      otpCode: otpCode,
      newPassword: newPassword,
    );
    return response?['success'] == true;
  }
}
