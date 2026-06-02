import 'package:flutter/foundation.dart';
import '../../../../core/network/api_service.dart';

class HistoryService {
  static Future<Map<String, dynamic>> getHistoryData({
    required String token,
    String? status,
    String? search,
    int? limit,
  }) async {
    try {
      final response = await ApiService.getActivities(
        token: token,
        status: status,
        search: search,
        limit: limit,
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
          'data': response['data']['aktivitas_terkini'],
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
      debugPrint('Error in HistoryService.getHistoryData: $e');
      return {
        'success': false,
        'message': 'Terjadi kesalahan: ${e.toString()}',
      };
    }
  }
}
