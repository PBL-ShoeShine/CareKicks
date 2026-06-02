import 'package:flutter/material.dart';
import '../services/payment_service.dart';

class PaymentController extends ChangeNotifier {
  bool _isLoading = false;
  bool _isConfirming = false;
  String? _errorMessage;
  List<dynamic> _bankAccounts = [];
  Map<String, dynamic>? _paymentResult;

  bool get isLoading => _isLoading;
  bool get isConfirming => _isConfirming;
  String? get errorMessage => _errorMessage;
  List<dynamic> get bankAccounts => _bankAccounts;
  Map<String, dynamic>? get paymentResult => _paymentResult;

  Future<void> fetchBankAccounts(String token) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await PaymentService.getBankAccounts(token: token);

      if (result['success']) {
        _bankAccounts = result['data'] ?? [];
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengambil rekening bank';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> confirmPayment({
    required String token,
    required String orderId,
    required String paymentProofUrl,
  }) async {
    _isConfirming = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await PaymentService.confirmPayment(
        token: token,
        orderId: orderId,
        paymentProofUrl: paymentProofUrl,
      );

      if (result['success']) {
        _paymentResult = result['data'];
        _isConfirming = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Gagal konfirmasi pembayaran';
        _isConfirming = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isConfirming = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
