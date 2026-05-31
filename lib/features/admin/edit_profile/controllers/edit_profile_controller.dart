import 'dart:io';
import 'package:flutter/material.dart';
import '../services/edit_profile_service.dart';

class EditProfileController extends ChangeNotifier {
  bool _isLoading = false;
  String _message = '';

  bool get isLoading => _isLoading;
  String get message => _message;

  // =========================================================================
  // 1. UPDATE DATA PROFIL & REQUEST EMAIL
  // =========================================================================
  Future<bool> updateProfil({
    required String token,
    String? nama,
    String? noHp,
    String? email,
    bool? isRequestEmailOnly,
  }) async {
    _setLoading(true);

    final result = await EditProfileService.updateProfile(
      token: token,
      nama: nama,
      noHp: noHp,
      email: email,
      isRequestEmailOnly: isRequestEmailOnly,
    );

    _message = result['message'] ?? '';
    _setLoading(false);
    return result['success'] ?? false;
  }

  // =========================================================================
  // 2. UPLOAD FOTO PROFIL
  // =========================================================================
  Future<String?> uploadProfilePicture({
    required String token,
    required File imageFile,
  }) async {
    _setLoading(true);
    _message = '';

    final result = await EditProfileService.uploadProfilePicture(
      token: token,
      imageFile: imageFile,
    );

    _message = result['message'] ?? '';
    _setLoading(false);

    if (result['success'] == true) {
      return result['url'];
    } else {
      return null;
    }
  }

  // =========================================================================
  // 3. GANTI KATA SANDI
  // =========================================================================
  Future<bool> changePassword({
    required String token,
    required String oldPassword,
    required String newPassword,
  }) async {
    _setLoading(true);
    _message = '';

    final result = await EditProfileService.changePassword(
      token: token,
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    _message = result['message'] ?? '';
    _setLoading(false);
    return result['success'] ?? false;
  }

  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }
}
