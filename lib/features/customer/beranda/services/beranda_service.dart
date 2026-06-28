import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_service.dart';

class BerandaService {
  static Future<Map<String, dynamic>> getBeranda({
    required String token,
    String? search,
    double? minPrice,
    double? maxPrice,
    String? spesialisasi,
    double? minRating,
    String? sortBy,
    String? sortOrder,
    int? page,
    int? limit,
  }) async {
    try {
      final response = await ApiService.getCustomerBeranda(
        token: token,
        search: search,
        minPrice: minPrice,
        maxPrice: maxPrice,
        spesialisasi: spesialisasi,
        minRating: minRating,
        sortBy: sortBy,
        sortOrder: sortOrder,
        page: page,
        limit: limit,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response['success'] == true) {
        return {
          'success': true,
          'data': response['data'],
          'pagination': response['pagination'],
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Gagal mengambil data beranda',
      };
    } catch (e) {
      debugPrint('Error in BerandaService.getBeranda: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
