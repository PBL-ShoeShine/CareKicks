import 'package:flutter/foundation.dart';
import '../../../../core/network/api_service.dart';

class OperatingHoursService {
  static Future<Map<String, dynamic>> getOperatingHours(String token) async {
    try {
      final response = await ApiService.getOperatingHours(token: token);

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
      debugPrint('Error in OperatingHoursService.getOperatingHours: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }

  static Future<Map<String, dynamic>> updateOperatingHours({
    required String token,
    required List<Map<String, dynamic>> hours,
  }) async {
    try {
      final response = await ApiService.updateOperatingHours(
        token: token,
        hours: hours,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response.containsKey('data')) {
        return {
          'success': true,
          'message':
              response['message'] ?? 'Jam operasional berhasil diperbarui',
          'data': response['data'],
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Respon tidak valid dari server',
      };
    } catch (e) {
      debugPrint('Error in OperatingHoursService.updateOperatingHours: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }
}
