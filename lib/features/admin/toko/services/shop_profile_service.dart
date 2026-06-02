import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_service.dart';

class ShopProfileService {
  static Future<Map<String, dynamic>> getShopProfile(String token) async {
    try {
      final response = await ApiService.getShopProfile(token: token);

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response.containsKey('data')) {
        return {'success': true, 'data': response['data']};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Respon tidak valid dari server',
      };
    } catch (e) {
      debugPrint('Error in ShopProfileService.getShopProfile: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> updateShopProfile({
    required String token,
    required Map<String, dynamic> payload,
    File? fotoToko,
  }) async {
    try {
      final response = await ApiService.updateShopProfile(
        token: token,
        payload: payload,
        fotoToko: fotoToko,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response.containsKey('data')) {
        return {
          'success': true,
          'message': response['message'] ?? 'Profil toko berhasil diperbarui',
          'data': response['data'],
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Respon tidak valid dari server',
      };
    } catch (e) {
      debugPrint('Error in ShopProfileService.updateShopProfile: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }
}
