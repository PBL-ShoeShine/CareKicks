import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
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

  Timer? _refreshTimer;
  StreamSubscription<Position>? _positionStream;
  bool _isTrackingActive = false;
  LatLng? _currentCourierLocation;
  DateTime? _lastRouteFetchAt;
  static const _routeFetchThrottleSeconds = 5;

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
  bool get isTrackingActive => _isTrackingActive;
  LatLng? get currentCourierLocation => _currentCourierLocation;

  @override
  void dispose() {
    stopAutoRefresh();
    stopRealtimeLocation();
    super.dispose();
  }

  void startAutoRefresh(String token, int orderId) {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      fetchTrackingDetail(token: token, orderId: orderId, isSilent: true);
    });
  }

  void stopAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = null;
  }

  Future<void> startRealtimeLocation(
    String token,
    int orderId,
    int? idStaff,
  ) async {
    final hasPermission = await _handleLocationPermission();
    if (!hasPermission) return;

    await _positionStream?.cancel();

    _isTrackingActive = true;
    notifyListeners();

    // Use getPositionStream for realtime tracking
    _positionStream =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 10, // Update every 10 meters
          ),
        ).listen(
          (Position position) async {
            _currentCourierLocation = LatLng(
              position.latitude,
              position.longitude,
            );
            debugPrint('GPS UPDATE: courier=${_currentCourierLocation}');

            final status = _detailData?['order']?['status_order']
                ?.toString()
                .toLowerCase();

            // Update route from courier to customer
            final customer = _detailData?['order']?['customers'];
            if (customer != null) {
              final dest = _toLatLng(
                customer['latitude'],
                customer['longitude'],
              );
              if (dest != null) {
                debugPrint('CALLING fetchRoute from GPS stream to dest=$dest');
                await fetchRoute(
                  origin: _currentCourierLocation!,
                  destination: dest,
                );
              }
            }

            // Send to backend
            try {
              await TrackingService.updateCourierLocation(
                token: token,
                orderId: orderId,
                latitude: position.latitude,
                longitude: position.longitude,
                idStaff: idStaff,
                status: status ?? 'sedang_diantar',
              );
            } catch (e) {
              debugPrint('Failed to update location to backend: $e');
            }

            notifyListeners();
          },
          onError: (e) {
            debugPrint('GPS Stream Error: $e');
            _errorMessage = 'Gagal mengambil stream GPS: $e';
            _isTrackingActive = false;
            notifyListeners();
          },
        );
  }

  void stopRealtimeLocation() {
    _positionStream?.cancel();
    _positionStream = null;
    _isTrackingActive = false;
    notifyListeners();
  }

  Future<bool> startPickup({
    required String token,
    required int orderId,
    int? idStaff,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        _isUpdating = false;
        notifyListeners();
        return false;
      }

      final position = await Geolocator.getCurrentPosition();

      final result = await TrackingService.updateTrackingStatus(
        token: token,
        orderId: orderId,
        status: 'sedang_dijemput',
        keterangan: 'Kurir mulai menjemput pesanan',
        latitude: position.latitude,
        longitude: position.longitude,
        idStaff: idStaff,
      );

      if (result['success'] == true) {
        _isUpdating = false;
        await startRealtimeLocation(token, orderId, idStaff);
        return true;
      }

      _errorMessage = result['message'] ?? 'Gagal memulai penjemputan';
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

  Future<bool> startDelivery({
    required String token,
    required int orderId,
    int? idStaff,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Get current position first to be sure
      final hasPermission = await _handleLocationPermission();
      if (!hasPermission) {
        _isUpdating = false;
        notifyListeners();
        return false;
      }

      final position = await Geolocator.getCurrentPosition();

      // 2. Update status to 'sedang_diantar'
      final result = await TrackingService.updateTrackingStatus(
        token: token,
        orderId: orderId,
        status: 'sedang_diantar',
        keterangan: 'Kurir mulai mengantar pesanan',
        latitude: position.latitude,
        longitude: position.longitude,
        idStaff: idStaff,
      );

      if (result['success'] == true) {
        _isUpdating = false;
        // 3. Start realtime tracking
        await startRealtimeLocation(token, orderId, idStaff);
        return true;
      }

      _errorMessage = result['message'] ?? 'Gagal memulai pengantaran';
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

  Future<bool> finishPickup({
    required String token,
    required int orderId,
    required File foto,
    int? idStaff,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final position = await Geolocator.getCurrentPosition().catchError(
        (_) => Position(
          longitude: 0,
          latitude: 0,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
      );

      final result = await TrackingService.updateTrackingStatus(
        token: token,
        orderId: orderId,
        status: 'sudah_dijemput',
        keterangan: 'Pesanan telah diterima di toko',
        isValidation: true,
        latitude: position.latitude != 0 ? position.latitude : null,
        longitude: position.longitude != 0 ? position.longitude : null,
        foto: foto,
        idStaff: idStaff,
      );

      if (result['success'] == true) {
        stopRealtimeLocation();
        _isUpdating = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'] ?? 'Gagal menyelesaikan penjemputan';
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

  Future<bool> finishDelivery({
    required String token,
    required int orderId,
    required File foto,
    int? idStaff,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final position = await Geolocator.getCurrentPosition().catchError(
        (_) => Position(
          longitude: 0,
          latitude: 0,
          timestamp: DateTime.now(),
          accuracy: 0,
          altitude: 0,
          heading: 0,
          speed: 0,
          speedAccuracy: 0,
          altitudeAccuracy: 0,
          headingAccuracy: 0,
        ),
      );

      final result = await TrackingService.updateTrackingStatus(
        token: token,
        orderId: orderId,
        status: 'selesai',
        keterangan: 'Pesanan telah sampai di tujuan',
        isValidation: true,
        latitude: position.latitude != 0 ? position.latitude : null,
        longitude: position.longitude != 0 ? position.longitude : null,
        foto: foto,
        idStaff: idStaff,
      );

      if (result['success'] == true) {
        stopRealtimeLocation();
        _isUpdating = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'] ?? 'Gagal menyelesaikan pengantaran';
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

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      _errorMessage =
          'Layanan lokasi dinonaktifkan. Silakan aktifkan layanan lokasi.';
      notifyListeners();
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        _errorMessage = 'Izin lokasi ditolak.';
        notifyListeners();
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      _errorMessage =
          'Izin lokasi ditolak permanen, kami tidak dapat meminta izin.';
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<bool> fetchTrackingDetail({
    required String token,
    required int orderId,
    bool isSilent = false,
  }) async {
    if (!isSilent) {
      _isLoading = true;
      _errorMessage = null;
      notifyListeners();
    }

    try {
      final result = await TrackingService.getTrackingDetail(
        token: token,
        orderId: orderId,
      );

      if (result['success'] == true) {
        _detailData = result['data'] as Map<String, dynamic>?;

        // Auto fetch route if data is available
        final detail = _detailData ?? {};
        final order = detail['order'] as Map<String, dynamic>? ?? {};
        final logs = detail['tracking_logs'] as List<dynamic>? ?? [];
        final lastLog = logs.isNotEmpty ? logs.first : null;
        final shop = order['shops'] as Map<String, dynamic>? ?? {};
        final customer = order['customers'] as Map<String, dynamic>? ?? {};

        debugPrint('FETCH TRACKING DETAIL SUCCESS');
        debugPrint('SHOP: ${shop}');
        debugPrint('CUSTOMER: ${customer}');
        debugPrint('LAST LOG: ${lastLog}');

        // Priority for origin:
        // 1. Current GPS Stream Location (if active)
        // 2. Latest Log Location (if exists)
        // 3. Shop Location (fallback)
        final origin =
            _currentCourierLocation ??
            _toLatLng(lastLog?['latitude'], lastLog?['longitude']) ??
            _toLatLng(shop['lat_toko'], shop['long_toko']);

        final destination = _toLatLng(
          customer['latitude'],
          customer['longitude'],
        );

        debugPrint('ROUTE ORIGIN: $origin');
        debugPrint('ROUTE DESTINATION: $destination');

        if (origin != null && destination != null) {
          await fetchRoute(origin: origin, destination: destination);
        }

        if (!isSilent) _isLoading = false;
        notifyListeners();
        return true;
      }

      if (!isSilent) {
        _errorMessage = result['message'] ?? 'Gagal mengambil detail tracking';
        _isLoading = false;
        notifyListeners();
      }
      return false;
    } catch (e) {
      if (!isSilent) {
        _errorMessage = 'Terjadi kesalahan: $e';
        _isLoading = false;
        notifyListeners();
      }
      return false;
    }
  }

  LatLng? _toLatLng(dynamic lat, dynamic lng) {
    final latVal = double.tryParse(lat.toString());
    final lngVal = double.tryParse(lng.toString());
    if (latVal == null || lngVal == null) return null;
    return LatLng(latVal, lngVal);
  }

  bool _shouldFetchRoute() {
    if (_lastRouteFetchAt == null) return true;
    final now = DateTime.now();
    final diff = now.difference(_lastRouteFetchAt!).inSeconds;
    return diff >= _routeFetchThrottleSeconds;
  }

  Future<bool> fetchRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    if (!_shouldFetchRoute()) {
      debugPrint(
        'Route fetch throttled - waiting ${_routeFetchThrottleSeconds}s between calls',
      );
      return true; // Don't fail, just skip
    }

    _isRouting = true;
    _routeError = null;
    notifyListeners();

    try {
      debugPrint(
        'ROUTE FETCH STARTED: origin=$origin, destination=$destination',
      );

      final result = await TrackingService.getRoute(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destLat: destination.latitude,
        destLng: destination.longitude,
      );

      _lastRouteFetchAt = DateTime.now();

      if (result['success'] == true) {
        final data = result['data'] as Map<String, dynamic>;
        final encoded = data['geometry']?.toString() ?? '';
        _routePoints = encoded.isEmpty ? [] : _decodePolyline(encoded);
        _routeDistanceMeters = (data['distance'] as num?)?.toDouble();
        _routeDurationSeconds = (data['duration'] as num?)?.toDouble();

        debugPrint(
          'ROUTE FETCH SUCCESS: ${_routePoints.length} points, distance=${_routeDistanceMeters}m, duration=${_routeDurationSeconds}s',
        );

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
      debugPrint('ROUTE FETCH FAILED: $_routeError');

      _isRouting = false;
      notifyListeners();
      return false;
    } catch (e) {
      _routeError = 'Terjadi kesalahan: $e';
      debugPrint('ROUTE FETCH ERROR: $_routeError');
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

  Future<bool> updateStatus({
    required String token,
    required int orderId,
    required String status,
    String? keterangan,
    int? idStaff,
  }) async {
    _isUpdating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await TrackingService.updateTrackingStatus(
        token: token,
        orderId: orderId,
        status: status,
        keterangan: keterangan,
        idStaff: idStaff,
      );

      if (result['success'] == true) {
        _isUpdating = false;
        notifyListeners();
        return true;
      }

      _errorMessage = result['message'] ?? 'Gagal memperbarui status';
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
