import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_service.dart';

class RiwayatService {
  static Future<Map<String, dynamic>> getRiwayat({
    required String token,
    String? status,
    String? search,
  }) async {
    try {
      final response = await ApiService.getCustomerRiwayat(
        token: token,
        status: status,
        search: search,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response['status'] == 'success') {
        return {'success': true, 'data': response['data']};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Gagal mengambil riwayat',
      };
    } catch (e) {
      debugPrint('Error in RiwayatService.getRiwayat: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
