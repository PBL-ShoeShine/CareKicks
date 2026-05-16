import 'package:flutter/foundation.dart';
import '../../../../core/network/api_service.dart';

class ProfileService {
  static Future<Map<String, dynamic>> getProfileData(String token) async {
    try {
      final response = await ApiService.getProfile(token: token);

      if (response == null) {
        return {
          'success': false,
          'message': 'Gagal menghubungi server',
        };
      }

      if (response.containsKey('data')) {
        return {
          'success': true,
          'data': response['data'],
        };
      } else if (response.containsKey('message')) {
        return {
          'success': false,
          'message': response['message'],
        };
      }

      return {
        'success': false,
        'message': 'Respon tidak valid dari server',
      };
    } catch (e) {
      debugPrint('Error in ProfileService.getProfileData: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> updateProfile({
    required String token,
    required String nama,
    required String email,
    required String noHp,
  }) async {
    try {
      final response = await ApiService.updateProfile(
        token: token,
        nama: nama,
        email: email,
        noHp: noHp,
      );

      if (response == null) {
        return {
          'success': false,
          'message': 'Gagal menghubungi server',
        };
      }

      if (response.containsKey('data')) {
        return {
          'success': true,
          'message': response['message'] ?? 'Profil berhasil diperbarui',
          'data': response['data'],
        };
      } else if (response.containsKey('message')) {
        return {
          'success': false,
          'message': response['message'],
        };
      }

      return {
        'success': false,
        'message': 'Respon tidak valid dari server',
      };
    } catch (e) {
      debugPrint('Error in ProfileService.updateProfile: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> updateProfilePicture({
    required String token,
    required String imageUrl,
  }) async {
    try {
      final response = await ApiService.updateProfilePicture(
        token: token,
        imageUrl: imageUrl,
      );

      if (response == null) {
        return {
          'success': false,
          'message': 'Gagal menghubungi server',
        };
      }

      if (response.containsKey('data')) {
        return {
          'success': true,
          'message': response['message'] ?? 'Foto profil berhasil diperbarui',
          'data': response['data'],
        };
      } else if (response.containsKey('message')) {
        return {
          'success': false,
          'message': response['message'],
        };
      }

      return {
        'success': false,
        'message': 'Respon tidak valid dari server',
      };
    } catch (e) {
      debugPrint('Error in ProfileService.updateProfilePicture: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }
}
