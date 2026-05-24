import 'package:flutter/foundation.dart';
import '../../../../../core/network/api_service.dart';

class PaymentService {
  static Future<Map<String, dynamic>> getBankAccounts({
    required String token,
  }) async {
    try {
      final response = await ApiService.getCustomerBankAccounts(token: token);

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response['status'] == 'success') {
        return {'success': true, 'data': response['data']};
      }

      return {
        'success': false,
        'message': response['message'] ?? 'Gagal mengambil rekening bank',
      };
    } catch (e) {
      debugPrint('Error in PaymentService.getBankAccounts: $e');
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> confirmPayment({
    required String token,
    required String orderId,
    required String paymentProofUrl,
  }) async {
    try {
      final response = await ApiService.confirmCustomerPayment(
        token: token,
        orderId: orderId,
        paymentProofUrl: paymentProofUrl,
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
