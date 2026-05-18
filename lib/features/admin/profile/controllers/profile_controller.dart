import 'dart:io';

import 'package:flutter/material.dart';

import '../services/profile_service.dart';

class ProfileController extends ChangeNotifier {
  bool _isLoading = false;
  bool _isUploadingPhoto = false;
  String? _errorMessage;
  String? _photoUploadError;
  Map<String, dynamic>? _profileData;

  bool get isLoading => _isLoading;
  bool get isUploadingPhoto => _isUploadingPhoto;
  String? get errorMessage => _errorMessage;
  String? get photoUploadError => _photoUploadError;
  Map<String, dynamic>? get profileData => _profileData;

  String? get userName => _profileData?['user']?['nama'];
  String? get userEmail => _profileData?['user']?['email'];
  String? get userPhone => _profileData?['user']?['no_hp'];
  String? get userRole => _profileData?['user']?['jenis_role'];
  String? get userPhoto =>
      _profileData?['user']?['foto_profil'] ??
      _profileData?['user']?['path_gambar'] ??
      _profileData?['user']?['userPhoto'];

  Map<String, dynamic>? get shopData => _profileData?['shop'];
  String? get shopName => _profileData?['shop']?['nm_toko'];
  String? get shopAddress => _profileData?['shop']?['alamat_toko'];
  String? get shopOpenTime => _profileData?['shop']?['jam_buka'];
  String? get shopCloseTime => _profileData?['shop']?['jam_tutup'];
  int? get shopBalance => _profileData?['shop']?['saldo_toko'];
  String? get shopDescription => _profileData?['shop']?['desk_toko'];

  Future<bool> fetchProfile(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ProfileService.getProfileData(token);

      if (result['success']) {
        _profileData = result['data'];
        final user = _profileData?['user'];
        if (user is Map<String, dynamic>) {
          user['foto_profil'] = user['path_gambar'] ?? user['foto_profil'];
          user['userPhoto'] = user['foto_profil'];
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengambil data profil';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String token,
    required String nama,
    required String email,
    required String noHp,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ProfileService.updateProfile(
        token: token,
        nama: nama,
        email: email,
        noHp: noHp,
      );

      if (result['success']) {
        _profileData?['user'] = result['data'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Gagal memperbarui profil';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfilePicture({
    required String token,
    required File imageFile,
  }) async {
    _isUploadingPhoto = true;
    _photoUploadError = null;
    notifyListeners();

    try {
      final result = await ProfileService.uploadProfilePhoto(
        token: token,
        photo: imageFile,
      );

      if (result['success']) {
        _profileData?['user']?['foto_profil'] = result['data']?['foto_profil'];
        _profileData?['user']?['path_gambar'] = result['data']?['foto_profil'];
        _profileData?['user']?['userPhoto'] = result['data']?['foto_profil'];
        _isUploadingPhoto = false;
        notifyListeners();
        return true;
      } else {
        _photoUploadError = result['message'] ?? 'Gagal memperbarui foto profil';
        _isUploadingPhoto = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _photoUploadError = 'Terjadi kesalahan: $e';
      _isUploadingPhoto = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
