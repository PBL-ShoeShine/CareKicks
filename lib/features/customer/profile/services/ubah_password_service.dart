import '../../../../../core/network/api_service.dart';

class UbahPasswordService {
  Future<Map<String, dynamic>> verifyOldPassword(
    String token,
    String oldPassword,
  ) async {
    final response = await ApiService.verifyCustomerOldPassword(
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

  Future<Map<String, dynamic>> requestOtp(String token) async {
    final response = await ApiService.requestCustomerPasswordOtp(
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

  Future<Map<String, dynamic>> verifyOtpOnly(
    String token,
    String otpCode,
  ) async {
    final response = await ApiService.verifyCustomerPasswordOtp(
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

  Future<bool> changePasswordDirect(
    String token,
    String oldPassword,
    String newPassword,
  ) async {
    final response = await ApiService.changeCustomerPasswordDirect(
      token: token,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );
    return response?['success'] == true;
  }

  Future<bool> changePasswordWithOtp(
    String token,
    String otpCode,
    String newPassword,
  ) async {
    final response = await ApiService.changeCustomerPasswordWithOtp(
      token: token,
      otpCode: otpCode,
      newPassword: newPassword,
    );
    return response?['success'] == true;
  }
}
