import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/customer_profile_service.dart';

class CustomerProfileController extends ChangeNotifier {
  bool isLoading = false;
  String errorMessage = '';
  Map<String, dynamic> userData = {};
  List<Map<String, dynamic>> alamatList = [];

  // =========================================================================
  // PROFILE
  // =========================================================================
  Future<void> fetchProfile(String token) async {
    isLoading = true;
    notifyListeners();

    final result = await CustomerProfileService.fetchProfile(token);
    if (result['success'] == true) {
      userData = Map<String, dynamic>.from(result['data']);
    } else {
      errorMessage = result['message'] ?? 'Error fetching data';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> updateProfile({
    required String token,
    required String nama,
    required String gender,
    required String birthday, // ✅ key 'birthday' bukan 'tglLahir'
  }) async {
    isLoading = true;
    notifyListeners();

    final result = await CustomerProfileService.updateProfile(
      token: token,
      nama: nama,
      gender: gender,
      birthday: birthday,
    );

    isLoading = false;
    if (result['success'] == true) {
      await fetchProfile(token);
      return true;
    } else {
      errorMessage = result['message'] ?? '';
      notifyListeners();
      return false;
    }
  }

  Future<bool> requestEmailChange({
    required String token,
    required String email,
  }) async {
    final result = await CustomerProfileService.requestEmailChange(
      token: token,
      email: email,
    );
    return result['success'] == true;
  }

  Future<bool> updateNoHp({
    required String token,
    required String noHp,
    required String password,
  }) async {
    final result = await CustomerProfileService.updateNoHp(
      token: token,
      noHp: noHp,
      password: password,
    );
    if (result['success'] == true) {
      await fetchProfile(token);
      return true;
    }
    errorMessage = result['message'] ?? '';
    notifyListeners();
    return false;
  }

  Future<bool> uploadFoto(String token, ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: source,
      maxWidth: 800,
      imageQuality: 85,
    );
    if (image == null) return false;

    final result = await CustomerProfileService.uploadProfilePicture(
      token: token,
      imageFile: File(image.path),
    );
    if (result['success'] == true) {
      await fetchProfile(token);
      return true;
    }
    errorMessage = result['message'] ?? '';
    notifyListeners();
    return false;
  }

  // =========================================================================
  // ALAMAT
  // =========================================================================
  Future<void> fetchAlamat(String token) async {
    final result = await CustomerProfileService.fetchAlamat(token);
    if (result['success'] == true) {
      alamatList = List<Map<String, dynamic>>.from(result['data']);
      notifyListeners();
    }
  }

  Future<bool> addAlamat({
    required String token,
    required String recipientName,
    required String phoneNumber,
    required String fullAddress,
    String? addressLabel,
    bool isDefault = false,
    double? latitude,
    double? longitude,
  }) async {
    final result = await CustomerProfileService.addAlamat(
      token: token,
      recipientName: recipientName,
      phoneNumber: phoneNumber,
      fullAddress: fullAddress,
      addressLabel: addressLabel,
      isDefault: isDefault,
      latitude: latitude,
      longitude: longitude,
    );
    if (result['success'] == true) {
      await fetchAlamat(token);
      return true;
    }
    errorMessage = result['message'] ?? '';
    notifyListeners();
    return false;
  }

  Future<bool> updateAlamat({
    required String token,
    required int idAddress,
    required String recipientName,
    required String phoneNumber,
    required String fullAddress,
    String? addressLabel,
    bool isDefault = false,
    double? latitude,
    double? longitude,
  }) async {
    final result = await CustomerProfileService.updateAlamat(
      token: token,
      idAddress: idAddress,
      recipientName: recipientName,
      phoneNumber: phoneNumber,
      fullAddress: fullAddress,
      addressLabel: addressLabel,
      isDefault: isDefault,
      latitude: latitude,
      longitude: longitude,
    );
    if (result['success'] == true) {
      await fetchAlamat(token);
      return true;
    }
    errorMessage = result['message'] ?? '';
    notifyListeners();
    return false;
  }

  Future<bool> setDefaultAlamat({
    required String token,
    required int idAddress,
  }) async {
    final ok = await CustomerProfileService.setDefaultAlamat(
      token: token,
      idAddress: idAddress,
    );
    if (ok) await fetchAlamat(token);
    return ok;
  }

  Future<bool> deleteAlamat({
    required String token,
    required int idAddress,
  }) async {
    final ok = await CustomerProfileService.deleteAlamat(
      token: token,
      idAddress: idAddress,
    );
    if (ok) await fetchAlamat(token);
    return ok;
  }
}
