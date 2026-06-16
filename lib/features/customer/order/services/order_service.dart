import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_service.dart';

class OrderService {
  /// Ambil daftar layanan aktif dari toko tertentu
  static Future<Map<String, dynamic>> getServicesByShop({
    required String token,
    required int idShops,
  }) async {
    try {
      final response = await ApiService.getCustomerOrderServices(
        token: token,
        idShops: idShops,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response['status'] == 'success') {
        return {'success': true, 'data': response['data']};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Gagal mengambil layanan',
      };
    } catch (e) {
      debugPrint('OrderService.getServicesByShop error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  /// Buat pesanan online baru
  static Future<Map<String, dynamic>> createOrder({
    required String token,
    required int idShops,
    required String namaPemilik,
    required String noHp,
    required String alamat,
    required List<int> selectedServiceIds,
    String? catatan,
    double? latOrder,
    double? longOrder,
    File? fotoSepatu,
  }) async {
    try {
      final response = await ApiService.createCustomerOrder(
        token: token,
        idShops: idShops,
        namaPemilik: namaPemilik,
        noHp: noHp,
        alamat: alamat,
        selectedServiceIds: selectedServiceIds,
        catatan: catatan,
        latOrder: latOrder,
        longOrder: longOrder,
        fotoSepatu: fotoSepatu,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response['status'] == 'success') {
        return {'success': true, 'data': response['data']};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Gagal membuat pesanan',
      };
    } catch (e) {
      debugPrint('OrderService.createOrder error: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
