import 'package:flutter/material.dart';
import '../services/ubah_password_service.dart';

class UbahPasswordController extends ChangeNotifier {
  final UbahPasswordService _service = UbahPasswordService();

  bool isLoading = false;
  bool isDisposed = false;

  @override
  void dispose() {
    isDisposed = true;
    super.dispose();
  }

  void _setLoading(bool value) {
    isLoading = value;
    if (!isDisposed) notifyListeners();
  }

  Future<String?> verifyOldPassword(String token, String oldPass) async {
    _setLoading(true);
    final result = await _service.verifyOldPassword(token, oldPass);
    _setLoading(false);
    return result['success'] ? null : result['message'];
  }

  Future<String?> requestOtp(String token) async {
    _setLoading(true);
    final result = await _service.requestOtp(token);
    _setLoading(false);
    return result['success'] ? null : result['message'];
  }

  Future<String?> verifyOtpOnly(String token, String otpCode) async {
    _setLoading(true);
    final result = await _service.verifyOtpOnly(token, otpCode);
    _setLoading(false);
    return result['success'] ? null : result['message'];
  }

  Future<bool> changeDirect(
    String token,
    String oldPass,
    String newPass,
  ) async {
    _setLoading(true);
    final success = await _service.changePasswordDirect(token, oldPass, newPass);
    _setLoading(false);
    return success;
  }

  Future<bool> changeWithOtp(
    String token,
    String otpCode,
    String newPass,
  ) async {
    _setLoading(true);
    final success = await _service.changePasswordWithOtp(token, otpCode, newPass);
    _setLoading(false);
    return success;
  }
}
