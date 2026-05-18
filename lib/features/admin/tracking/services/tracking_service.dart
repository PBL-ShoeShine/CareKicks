import 'dart:io';
import '../../../../core/network/api_service.dart';

class TrackingService {
  static Future<Map<String, dynamic>> getTrackingList({
    required String token,
    String? status,
    String? search,
  }) async {
    try {
      final response = await ApiService.getTrackingList(
        token: token,
        status: status,
        search: search,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response.containsKey('data')) {
        return {'success': true, 'data': response['data']};
      } else if (response.containsKey('message')) {
        return {'success': false, 'message': response['message']};
      }

      return {'success': false, 'message': 'Respon tidak valid dari server'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getTrackingDetail({
    required String token,
    required int orderId,
  }) async {
    try {
      final response = await ApiService.getTrackingDetail(
        token: token,
        orderId: orderId,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response.containsKey('data')) {
        return {'success': true, 'data': response['data']};
      } else if (response.containsKey('message')) {
        return {'success': false, 'message': response['message']};
      }

      return {'success': false, 'message': 'Respon tidak valid dari server'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getLatestTracking({
    required String token,
    required int orderId,
  }) async {
    try {
      final response = await ApiService.getLatestTracking(
        token: token,
        orderId: orderId,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      if (response.containsKey('data')) {
        return {'success': true, 'data': response['data']};
      } else if (response.containsKey('message')) {
        return {'success': false, 'message': response['message']};
      }

      return {'success': false, 'message': 'Respon tidak valid dari server'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> updateTrackingStatus({
    required String token,
    required int orderId,
    required String status,
    String? keterangan,
    double? latitude,
    double? longitude,
    int? idStaff,
    int? idDetailOrders,
    String? fotoType,
    bool? isValidation,
    File? foto,
  }) async {
    final response = await ApiService.updateTrackingStatus(
      token: token,
      orderId: orderId,
      status: status,
      keterangan: keterangan,
      latitude: latitude,
      longitude: longitude,
      idStaff: idStaff,
      idDetailOrders: idDetailOrders,
      fotoType: fotoType,
      isValidation: isValidation,
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

  static Future<Map<String, dynamic>> updateCourierLocation({
    required String token,
    required int orderId,
    required double latitude,
    required double longitude,
    int? idStaff,
    String? status,
  }) async {
    try {
      final response = await ApiService.updateCourierLocation(
        token: token,
        orderId: orderId,
        latitude: latitude,
        longitude: longitude,
        idStaff: idStaff,
        status: status,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi server'};
      }

      return {
        'success': response['success'] ?? false,
        'message': response['message'] ?? 'Berhasil update lokasi',
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }

  static Future<Map<String, dynamic>> getRoute({
    required double originLat,
    required double originLng,
    required double destLat,
    required double destLng,
  }) async {
    try {
      final response = await ApiService.getRouteOsrm(
        originLat: originLat,
        originLng: originLng,
        destLat: destLat,
        destLng: destLng,
      );

      if (response == null) {
        return {'success': false, 'message': 'Gagal menghubungi layanan rute'};
      }

      final routes = response['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        return {'success': false, 'message': 'Rute tidak ditemukan'};
      }

      final route = routes.first as Map<String, dynamic>;
      final legs = route['legs'] as List<dynamic>? ?? [];
      final steps = legs.isNotEmpty
          ? (legs.first as Map<String, dynamic>)['steps'] as List<dynamic>?
          : null;
      return {
        'success': true,
        'data': {
          'geometry': route['geometry'],
          'distance': route['distance'],
          'duration': route['duration'],
          'steps': steps ?? [],
        },
      };
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
}
