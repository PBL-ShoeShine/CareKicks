import 'package:flutter/foundation.dart';
import '../../../../core/network/api_service.dart';

class DashboardService {
  static Future<Map<String, dynamic>> getDashboardData(String token) async {
    try {
      final response = await ApiService.getDashboard(token: token);

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
      debugPrint('Error in DashboardService.getDashboardData: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }
}
