import 'dart:io';
import '../../../../core/network/api_service.dart';

class MLayananService {
  static Future<Map<String, dynamic>> getServices({
    required String token,
    String? search,
    String? category,
  }) async {
    final response = await ApiService.getServicesList(
      token: token,
      search: search,
      category: category,
    );

    if (response == null) {
      return {'success': false, 'message': 'Gagal menghubungi server'};
    }

    return {
      'success': response['success'] ?? false,
      'message': response['message'],
      'data': response['data'],
    };
  }

  static Future<Map<String, dynamic>> createService({
    required String token,
    required String namaLayanan,
    required int harga,
    required String estimasiWaktu,
    String? deskripsi,
    File? foto,
  }) async {
    final response = await ApiService.createServiceWithImage(
      token: token,
      namaLayanan: namaLayanan,
      harga: harga,
      estimasiWaktu: estimasiWaktu,
      deskripsi: deskripsi,
      foto: foto,
    );

    if (response == null) {
      return {'success': false, 'message': 'Gagal menghubungi server'};
    }

    return {
      'success': response['success'] ?? false,
      'message': response['message'],
      'data': response['data'],
    };
  }

  static Future<Map<String, dynamic>> updateService({
    required String token,
    required int serviceId,
    required String namaLayanan,
    required int harga,
    required String estimasiWaktu,
    String? deskripsi,
    File? foto,
  }) async {
    final response = await ApiService.updateServiceWithImage(
      token: token,
      serviceId: serviceId,
      namaLayanan: namaLayanan,
      harga: harga,
      estimasiWaktu: estimasiWaktu,
      deskripsi: deskripsi,
      foto: foto,
    );

    if (response == null) {
      return {'success': false, 'message': 'Gagal menghubungi server'};
    }

    return {
      'success': response['success'] ?? false,
      'message': response['message'],
      'data': response['data'],
    };
  }

  static Future<Map<String, dynamic>> updateStatus({
    required String token,
    required int serviceId,
    required bool isActive,
  }) async {
    final response = await ApiService.updateServiceStatusApi(
      token: token,
      serviceId: serviceId,
      isActive: isActive,
    );

    if (response == null) {
      return {'success': false, 'message': 'Gagal menghubungi server'};
    }

    return {
      'success': response['success'] ?? false,
      'message': response['message'],
      'data': response['data'],
    };
  }

  static Future<Map<String, dynamic>> deleteService({
    required String token,
    required int serviceId,
  }) async {
    final response = await ApiService.deleteServiceApi(
      token: token,
      serviceId: serviceId,
    );

    if (response == null) {
      return {'success': false, 'message': 'Gagal menghubungi server'};
    }

    return {
      'success': response['success'] ?? false,
      'message': response['message'],
    };
  }
}
