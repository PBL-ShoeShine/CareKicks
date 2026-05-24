import 'package:flutter/material.dart';
import '../services/detail_order_service.dart';

class DetailOrderController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _order;
  List<dynamic> _items = [];
  Map<String, dynamic>? _payment;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get order => _order;
  List<dynamic> get items => _items;
  Map<String, dynamic>? get payment => _payment;

  String? get orderNumber => _order?['order_number'];
  String? get serviceType => _order?['service_type'];
  String? get status => _order?['status'];
  String? get date => _order?['date'];
  String? get address => _order?['address'];
  int? get totalPrice => _order?['total_price'];

  String? get paymentMethod => _payment?['payment_method'];
  int? get serviceFee => _payment?['service_fee'];
  int? get additionalFee => _payment?['additional_fee'];
  int? get totalAmount => _payment?['total_amount'];
  String? get paymentStatus => _payment?['payment_status'];
  String? get paymentDeadline => _payment?['payment_deadline'];

  Future<void> fetchDetailOrder({
    required String token,
    required String orderId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await DetailOrderService.getDetailOrder(
        token: token,
        orderId: orderId,
      );

      if (result['success']) {
        final data = result['data'];
        _order = data['order'];
        _items = data['items'] ?? [];
        _payment = data['payment'];
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengambil detail pesanan';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
