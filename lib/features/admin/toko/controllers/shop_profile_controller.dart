import 'dart:io';
import 'package:flutter/material.dart';
import '../models/shop_profile_model.dart';
import '../services/shop_profile_service.dart';

class ShopProfileController extends ChangeNotifier {
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  ShopProfileModel? _profile;

  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;
  ShopProfileModel? get profile => _profile;

  Future<bool> fetchProfile(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await ShopProfileService.getShopProfile(token);

      if (result['success'] == true) {
        _profile = ShopProfileModel.fromJson(result['data']);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'] ?? 'Gagal mengambil profil toko';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateProfile({
    required String token,
    required ShopProfileModel profile,
    File? fotoToko,
  }) async {
    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final payload = {
        'nm_toko': profile.nmToko,
        'desk_toko': profile.deskToko,
        'alamat_toko': profile.alamatToko,
        'lat_toko': profile.latToko,
        'long_toko': profile.longToko,
        'spesialisasi': profile.spesialisasi,
        'tgl_berdiri': profile.tglBerdiriFormatted,
        'email_toko': profile.emailToko,
        'wa_toko': profile.waToko,
      };

      final result = await ShopProfileService.updateShopProfile(
        token: token,
        payload: payload,
        fotoToko: fotoToko,
      );

      if (result['success'] == true) {
        _profile = ShopProfileModel.fromJson(result['data']);
        _isSaving = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'] ?? 'Gagal memperbarui profil toko';
      _isSaving = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isSaving = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
