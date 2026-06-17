import '../../../../../core/network/api_service.dart';

class ShopProfileService {
  static Future<Map<String, dynamic>> getShopProfile({
    required String token,
    required int idShops,
  }) async {
    try {
      final response = await ApiService.getCustomerShopProfile(
        token: token,
        idShops: idShops,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      return response;
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
