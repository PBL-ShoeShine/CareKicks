import 'dart:io';
import '../../../../../core/network/api_service.dart';

class CustomerProfileService {
  // =========================================================================
  // PROFILE
  // =========================================================================
  static Future<Map<String, dynamic>> fetchProfile(String token) async {
    final response = await ApiService.getCustomerProfile(token: token);
    if (response == null) {
      return {'success': false, 'message': 'Gagal menghubungi server'};
    }
    return response;
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String nama,
    required String gender,
    required String birthday,
  }) async {
    final response = await ApiService.updateCustomerProfile(
      token: token,
      nama: nama,
      gender: gender,
      birthday: birthday,
    );
    if (response == null) {
      return {'success': false, 'message': 'Gagal menghubungi server'};
    }
    return response;
  }

  static Future<Map<String, dynamic>> requestEmailChange({
    required String token,
    required String email,
  }) async {
    final response = await ApiService.requestCustomerEmailChange(
      token: token,
      email: email,
    );
    if (response == null) {
      return {'success': false, 'message': 'Gagal mengirim verifikasi email'};
    }
    return response;
  }

  static Future<Map<String, dynamic>> updateNoHp({
    required String token,
    required String noHp,
    required String password,
  }) async {
    final response = await ApiService.updateCustomerNoHp(
      token: token,
      noHp: noHp,
      password: password,
    );
    if (response == null) {
      return {'success': false, 'message': 'Gagal menghubungi server'};
    }
    return response;
  }

  static Future<Map<String, dynamic>> uploadProfilePicture({
    required String token,
    required File imageFile,
  }) async {
    final response = await ApiService.uploadCustomerProfilePicture(
      token: token,
      imageFile: imageFile,
    );
    if (response == null) {
      return {'success': false, 'message': 'Gagal upload foto'};
    }
    return response;
  }

  // =========================================================================
  // ALAMAT
  // =========================================================================
  static Future<Map<String, dynamic>> fetchAlamat(String token) async {
    final response = await ApiService.getCustomerAlamat(token: token);
    if (response == null) {
      return {'success': false, 'message': 'Gagal mengambil daftar alamat'};
    }
    return response;
  }

  static Future<Map<String, dynamic>> addAlamat({
    required String token,
    required String recipientName,
    required String phoneNumber,
    required String fullAddress,
    String? addressLabel,
    bool isDefault = false,
    double? latitude,
    double? longitude,
  }) async {
    final response = await ApiService.addCustomerAlamat(
      token: token,
      recipientName: recipientName,
      phoneNumber: phoneNumber,
      fullAddress: fullAddress,
      addressLabel: addressLabel,
      isDefault: isDefault,
      latitude: latitude,
      longitude: longitude,
    );
    if (response == null) {
      return {'success': false, 'message': 'Gagal menghubungi server'};
    }
    return response;
  }

  static Future<Map<String, dynamic>> updateAlamat({
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
    final response = await ApiService.updateCustomerAlamat(
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
    if (response == null) {
      return {'success': false, 'message': 'Gagal menghubungi server'};
    }
    return response;
  }

  static Future<bool> setDefaultAlamat({
    required String token,
    required int idAddress,
  }) async {
    return ApiService.setDefaultCustomerAlamat(
      token: token,
      idAddress: idAddress,
    );
  }

  static Future<bool> deleteAlamat({
    required String token,
    required int idAddress,
  }) async {
    return ApiService.deleteCustomerAlamat(
      token: token,
      idAddress: idAddress,
    );
  }
}
