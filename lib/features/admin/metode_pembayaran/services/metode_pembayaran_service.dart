import 'dart:io';
import '../../../../../core/network/api_service.dart';

class MetodePembayaranService {
  static Future<Map<String, dynamic>> fetchPaymentMethods(
      String token) async {
    final response =
        await ApiService.getAdminPaymentMethods(token: token);
    if (response == null) {
      return {'success': false, 'message': 'Gagal mengambil data'};
    }
    return response;
  }

  static Future<Map<String, dynamic>> addPaymentMethod({
    required String token,
    required String tipePembayaran,
    required String namaBank,
    required String noRek,
    required String atasNama,
    bool isDefault = false,
  }) async {
    final response = await ApiService.addAdminPaymentMethod(
      token: token,
      tipePembayaran: tipePembayaran,
      namaBank: namaBank,
      noRek: noRek,
      atasNama: atasNama,
      isDefault: isDefault,
    );
    if (response == null) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
    return response;
  }

  static Future<Map<String, dynamic>> toggleStatus({
    required String token,
    required int idAccount,
    required bool isActive,
  }) async {
    final response = await ApiService.toggleAdminPaymentMethodStatus(
      token: token,
      idAccount: idAccount,
      isActive: isActive,
    );
    if (response == null) {
      return {'success': false, 'message': 'Terjadi kesalahan jaringan'};
    }
    return response;
  }

  static Future<bool> deletePaymentMethod(
      String token, int idAccount) async {
    return ApiService.deleteAdminPaymentMethod(
      token: token,
      idAccount: idAccount,
    );
  }

  static Future<Map<String, dynamic>> uploadQrisImage({
    required String token,
    required int idAccount,
    required File imageFile,
  }) async {
    final response = await ApiService.uploadAdminQrisImage(
      token: token,
      idAccount: idAccount,
      imageFile: imageFile,
    );
    if (response == null) {
      return {'success': false, 'message': 'Gagal unggah foto QRIS'};
    }
    return response;
  }
}
