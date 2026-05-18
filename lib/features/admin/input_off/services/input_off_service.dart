import 'dart:io';
import '../../../../core/network/api_service.dart';

class InputOffService {
  static Future<Map<String, dynamic>> getAvailableServices(String token) async {
    try {
      final response = await ApiService.getServices(token: token);
      if (response != null && response['success'] == true) {
        return {
          'success': true,
          'data': response['data'],
        };
      }
      return {
        'success': false,
        'message': response?['message'] ?? 'Gagal mengambil data layanan',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> submitOfflineOrder({
    required String token,
    required Map<String, dynamic> orderData,
    required File fotoSebelum,
  }) async {
    try {
      final response = await ApiService.createOfflineOrder(
        token: token,
        orderData: orderData,
        fotoSebelum: fotoSebelum,
      );
      if (response != null && response['success'] == true) {
        return {
          'success': true,
          'data': response['data'],
        };
      }
      return {
        'success': false,
        'message': response?['message'] ?? 'Gagal membuat pesanan',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
}
