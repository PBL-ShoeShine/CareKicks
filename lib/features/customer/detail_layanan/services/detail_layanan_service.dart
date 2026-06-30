import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_service.dart';

class DetailLayananService {
  static Future<Map<String, dynamic>> getDetailLayanan({
    required String token,
    required int serviceId,
  }) async {
    try {
      final response = await ApiService.getCustomerServiceDetail(
        token: token,
        serviceId: serviceId,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response['success'] == true) {
        return {
          'success': true,
          'data': response['data'],
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Gagal mengambil detail layanan',
      };
    } catch (e) {
      debugPrint('Error in DetailLayananService.getDetailLayanan: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getReviews({
    required int serviceId,
  }) async {
    try {
      final response = await ApiService.getCustomerReviews(serviceId: serviceId);

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response['success'] == true) {
        return {
          'success': true,
          'data': response['data'],
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Gagal mengambil ulasan',
      };
    } catch (e) {
      debugPrint('Error in DetailLayananService.getReviews: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
