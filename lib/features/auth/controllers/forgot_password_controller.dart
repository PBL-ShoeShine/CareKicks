import 'package:flutter/material.dart';
import '../services/forgot_password_service.dart';

class ForgotPasswordController extends ChangeNotifier {
  bool _isLoading = false;
  String _message = '';
  int _currentStep = 0; // 0: Input Email, 1: Input OTP, 2: Reset Password

  bool get isLoading => _isLoading;
  String get message => _message;
  int get currentStep => _currentStep;

  void setStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  // Aksi Langkah 1: Minta OTP
  Future<bool> sendOtpRequest(String email) async {
    _setLoading(true);
    _message = '';

    final result = await ForgotPasswordService.requestOtp(email);
    _message = result['message'] ?? '';
    _setLoading(false);

    if (result['success'] == true) {
      _currentStep = 1; // Pindah ke step OTP
      notifyListeners();
      return true;
    }
    return false;
  }

  // Aksi Langkah 2: Verifikasi OTP
  Future<bool> verifyOtpCode(String email, String otpCode) async {
    _setLoading(true);
    _message = '';

    final result = await ForgotPasswordService.verifyOtp(email, otpCode);
    _message = result['message'] ?? '';
    _setLoading(false);

    if (result['success'] == true) {
      _currentStep = 2; // Pindah ke step ganti password baru
      notifyListeners();
      return true;
    }
    return false;
  }

  // Aksi Langkah 3: Simpan Password Baru
  Future<bool> executeResetPassword({
    required String email,
    required String otpCode,
    required String newPassword,
  }) async {
    _setLoading(true);
    _message = '';

    final result = await ForgotPasswordService.resetPassword(
      email: email,
      otpCode: otpCode,
      newPassword: newPassword,
    );
    _message = result['message'] ?? '';
    _setLoading(false);

    return result['success'] ?? false;
  }
}
