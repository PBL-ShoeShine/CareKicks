import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/tracking_service.dart';

class TrackingDetailController extends ChangeNotifier {
  bool _isLoading = false;
  bool _isUpdating = false;
  String? _errorMessage;
  Map<String, dynamic>? _detailData;
  bool _isRouting = false;
  String? _routeError;
  List<LatLng> _routePoints = [];
  double? _routeDistanceMeters;
  double? _routeDurationSeconds;
  String? _nextInstruction;
  double? _nextDistanceMeters;

  bool get isLoading => _isLoading;
  bool get isUpdating => _isUpdating;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get detailData => _detailData;
  bool get isRouting => _isRouting;
  String? get routeError => _routeError;
  List<LatLng> get routePoints => _routePoints;
  double? get routeDistanceMeters => _routeDistanceMeters;
  double? get routeDurationSeconds => _routeDurationSeconds;
  String? get nextInstruction => _nextInstruction;
  double? get nextDistanceMeters => _nextDistanceMeters;

  Future<bool> fetchTrackingDetail({
    required String token,
    required int orderId,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    _routeError = null;
    _routePoints = [];
    _routeDistanceMeters = null;
    _routeDurationSeconds = null;
    _nextInstruction = null;
    _nextDistanceMeters = null;
    notifyListeners();

    try {
      final result = await TrackingService.getTrackingDetail(
        token: token,
        orderId: orderId,
      );

      if (result['success'] == true) {
        _detailData = result['data'] as Map<String, dynamic>?;
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'] ?? 'Gagal mengambil detail tracking';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> fetchRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    _isRouting = true;
    _routeError = null;
    notifyListeners();

    try {
      final result = await TrackingService.getRoute(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destLat: destination.latitude,
        destLng: destination.longitude,
      );

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        final encoded = data['geometry']?.toString() ?? '';
        _routePoints = encoded.isEmpty ? [] : _decodePolyline(encoded);
        _routeDistanceMeters = (data['distance'] as num?)?.toDouble();
        _routeDurationSeconds = (data['duration'] as num?)?.toDouble();

        final steps = data['steps'] as List<dynamic>? ?? [];
        final nextStep = _pickNextStep(steps);
        if (nextStep != null) {
          _nextInstruction = _buildInstruction(nextStep);
          _nextDistanceMeters = (nextStep['distance'] as num?)?.toDouble();
        }

        _isRouting = false;
        notifyListeners();
        return true;
      }

      _routeError = result['message'] ?? 'Gagal mengambil rute';
      _isRouting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _routeError = 'Terjadi kesalahan: $e';
      _isRouting = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitValidationPhoto({
    required String token,
    required int orderId,
    required File foto,
    double? latitude,
    double? longitude,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await TrackingService.updateTrackingStatus(
        token: token,
        orderId: orderId,
        status: 'selesai',
        isValidation: true,
        latitude: latitude,
        longitude: longitude,
        foto: foto,
      );

      if (result['success'] == true) {
        _isUpdating = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'] ?? 'Gagal mengirim foto validasi';
      _isUpdating = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isUpdating = false;
      notifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  List<LatLng> _decodePolyline(String encoded) {
    final points = <LatLng>[];
    int index = 0;
    int lat = 0;
    int lng = 0;

    while (index < encoded.length) {
      int shift = 0;
      int result = 0;
      int b;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dLat = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lat += dLat;

      shift = 0;
      result = 0;
      do {
        b = encoded.codeUnitAt(index++) - 63;
        result |= (b & 0x1f) << shift;
        shift += 5;
      } while (b >= 0x20);

      final dLng = (result & 1) != 0 ? ~(result >> 1) : (result >> 1);
      lng += dLng;

      points.add(LatLng(lat / 1e5, lng / 1e5));
    }

    return points;
  }

  Map<String, dynamic>? _pickNextStep(List<dynamic> steps) {
    for (final rawStep in steps) {
      if (rawStep is! Map<String, dynamic>) continue;
      final distance = (rawStep['distance'] as num?)?.toDouble() ?? 0;
      final maneuver = rawStep['maneuver'] as Map<String, dynamic>? ?? {};
      final type = maneuver['type']?.toString() ?? '';
      if (type == 'arrive') continue;
      if (distance > 1) return rawStep;
    }
    return steps.isNotEmpty && steps.first is Map<String, dynamic>
        ? steps.first as Map<String, dynamic>
        : null;
  }

  String _buildInstruction(Map<String, dynamic> step) {
    final maneuver = step['maneuver'] as Map<String, dynamic>? ?? {};
    final type = maneuver['type']?.toString() ?? '';
    final modifier = maneuver['modifier']?.toString() ?? '';
    final name = step['name']?.toString() ?? '';
    final exitNumber = maneuver['exit'];

    switch (type) {
      case 'arrive':
        return 'Tiba di tujuan';
      case 'depart':
        return name.isNotEmpty ? 'Mulai dari $name' : 'Mulai perjalanan';
      case 'roundabout':
      case 'rotary':
      case 'roundabout turn':
        final exitLabel = exitNumber is num
            ? 'Ambil keluar ke-${exitNumber.toInt()}'
            : 'Masuk bundaran';
        return name.isNotEmpty ? '$exitLabel ke $name' : exitLabel;
      case 'fork':
        final forkLabel = _forkLabel(modifier);
        if (forkLabel.isNotEmpty) {
          return name.isNotEmpty ? '$forkLabel ke $name' : forkLabel;
        }
        return name.isNotEmpty ? 'Ambil jalur ke $name' : 'Ambil jalur';
      case 'merge':
        return name.isNotEmpty ? 'Bergabung ke $name' : 'Bergabung ke jalan';
      case 'on ramp':
        return name.isNotEmpty ? 'Masuk ramp ke $name' : 'Masuk ramp';
      case 'off ramp':
        return name.isNotEmpty ? 'Keluar ramp ke $name' : 'Keluar ramp';
      case 'end of road':
        final modLabel = _modifierLabel(modifier);
        if (modLabel.isNotEmpty) return 'Ujung jalan, $modLabel';
        return name.isNotEmpty ? 'Ujung jalan, ke $name' : 'Ujung jalan';
      case 'new name':
        return name.isNotEmpty ? 'Lanjut ke $name' : 'Lanjutkan perjalanan';
      case 'continue':
        final modLabel = _modifierLabel(modifier);
        if (modLabel.isNotEmpty) {
          return name.isNotEmpty ? '$modLabel ke $name' : modLabel;
        }
        return name.isNotEmpty ? 'Lanjut ke $name' : 'Lanjutkan perjalanan';
      default:
        final modLabel = _modifierLabel(modifier);
        if (modLabel.isNotEmpty) {
          return name.isNotEmpty ? '$modLabel ke $name' : modLabel;
        }
        return name.isNotEmpty ? 'Lanjut ke $name' : 'Lanjutkan perjalanan';
    }
  }

  String _modifierLabel(String modifier) {
    switch (modifier) {
      case 'left':
        return 'Belok kiri';
      case 'right':
        return 'Belok kanan';
      case 'slight left':
        return 'Belok kiri sedikit';
      case 'slight right':
        return 'Belok kanan sedikit';
      case 'sharp left':
        return 'Belok kiri tajam';
      case 'sharp right':
        return 'Belok kanan tajam';
      case 'uturn':
        return 'Putar balik';
      case 'straight':
        return 'Lurus';
      default:
        return '';
    }
  }

  String _forkLabel(String modifier) {
    switch (modifier) {
      case 'left':
      case 'slight left':
        return 'Ambil jalur kiri';
      case 'right':
      case 'slight right':
        return 'Ambil jalur kanan';
      case 'straight':
        return 'Ambil jalur tengah';
      default:
        return '';
    }
  }
}
