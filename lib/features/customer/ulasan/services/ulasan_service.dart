import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_service.dart';

class UlasanService {
  static Future<Map<String, dynamic>> getUlasan({
    int? idShops,
    String? rating,
  }) async {
    try {
      final response = await ApiService.getUlasan(
        idShops: idShops,
        rating: rating,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response['success'] == true) {
        return {'success': true, 'data': response['data']};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Gagal mengambil ulasan',
      };
    } catch (e) {
      debugPrint('Error in UlasanService.getUlasan: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> createUlasan({
    required String token,
    required int rating,
    required String ulasan,
    int? idShops,
    int? idOrders,
    List<File>? fotoUlasan,
  }) async {
    try {
      final response = await ApiService.createUlasan(
        token: token,
        rating: rating,
        ulasan: ulasan,
        idShops: idShops,
        idOrders: idOrders,
        fotoUlasan: fotoUlasan,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response['success'] == true) {
        return {'success': true, 'message': response['message']};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Gagal mengirim ulasan',
      };
    } catch (e) {
      debugPrint('Error in UlasanService.createUlasan: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
