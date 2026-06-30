import 'dart:io';
import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_service.dart';

class PaymentService {
  static Future<Map<String, dynamic>> getBankAccounts({
    required String token,
    required String orderId,
  }) async {
    try {
      final response = await ApiService.getCustomerBankAccounts(
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
        'message': response['message'] ?? 'Gagal mengambil rekening',
      };
    } catch (e) {
      debugPrint('Error in PaymentService.getBankAccounts: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> confirmPayment({
    required String token,
    required String orderId,
    required File imageFile,
  }) async {
    try {
      final response = await ApiService.confirmCustomerPayment(
        token: token,
        orderId: orderId,
        imageFile: imageFile,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response['status'] == 'success') {
        return {
          'success': true,
          'message': response['message'],
          'data': response['data'],
        };
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Gagal konfirmasi pembayaran',
      };
    } catch (e) {
      debugPrint('Error in PaymentService.confirmPayment: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}