import '../../../../core/network/api_service.dart';
import '../../../../core/auth/session_manager.dart';

class KonfirmasiService {
  static Future<List<dynamic>> getOrders(String tab, {String? metodeOrder}) async {
    final session = await AuthSessionManager.getValidSession();
    if (session == null) return [];

    final response = await ApiService.getOrdersToConfirm(
      token: session.token,
      tab: tab,
      metodeOrder: metodeOrder,
    );

    if (response != null && response['success'] == true) {
      return response['data'] ?? [];
    }
    return [];
  }

  static Future<Map<String, dynamic>> processPayment({
    required int idOrders,
    required String action,
    String? reason,
  }) async {
    final session = await AuthSessionManager.getValidSession();
    if (session == null) return {'success': false, 'message': 'Session expired'};

    final response = await ApiService.confirmPayment(
      token: session.token,
      idOrders: idOrders,
      action: action,
      reason: reason,
    );

    return response ?? {'success': false, 'message': 'Gagal menghubungi server'};
  }

  static Future<Map<String, dynamic>> processOrder({
    required int idOrders,
    required String action,
    String? reason,
  }) async {
    final session = await AuthSessionManager.getValidSession();
    if (session == null) return {'success': false, 'message': 'Session expired'};

    final response = await ApiService.confirmOrder(
      token: session.token,
      idOrders: idOrders,
      action: action,
      reason: reason,
    );

    return response ?? {'success': false, 'message': 'Gagal menghubungi server'};
  }
}
