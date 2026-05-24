import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_service.dart';

class DetailOrderService {
  static Future<Map<String, dynamic>> getDetailOrder({
    required String token,
    required String orderId,
  }) async {
    try {
      final response = await ApiService.getCustomerDetailOrder(
        token: token,
        orderId: orderId,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response['status'] == 'success') {
        return {'success': true, 'data': response['data']};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Gagal mengambil detail pesanan',
      };
    } catch (e) {
      debugPrint('Error in DetailOrderService.getDetailOrder: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
