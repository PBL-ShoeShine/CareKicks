import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../services/detail_order_service.dart';
import '../../../../../core/network/api_service.dart';

class DetailOrderController extends ChangeNotifier {
  bool _isLoading = false;
  bool _isRouting = false;
  String? _errorMessage;
  String? _routeError;
  Map<String, dynamic>? _order;
  List<dynamic> _items = [];
  Map<String, dynamic>? _payment;
  List<dynamic> _timeline = []; // BARU
  List<LatLng> _routePoints = [];
  double? _routeDistanceMeters;
  double? _routeDurationSeconds;

  bool get isLoading => _isLoading;
  bool get isRouting => _isRouting;
  String? get errorMessage => _errorMessage;
  String? get routeError => _routeError;
  Map<String, dynamic>? get order => _order;
  List<dynamic> get items => _items;
  Map<String, dynamic>? get payment => _payment;
  List<dynamic> get timeline => _timeline; // BARU
  List<LatLng> get routePoints => _routePoints;
  double? get routeDistanceMeters => _routeDistanceMeters;
  double? get routeDurationSeconds => _routeDurationSeconds;

  String? get orderNumber => _order?['kode_order'];
  String? get serviceType => _order?['metode_order'];
  String? get status => _order?['status_order'];
  String? get date => _order?['tgl_order'];
  String? get address => _order?['alamat_pengantaran'];
  String? get paymentStatus => _order?['status_pembayaran'];
  String? get paymentRejectReason => _order?['alasan_tolak_pembayaran'];

  double? get customerLat =>
      double.tryParse(_order?['lat_order']?.toString() ?? '');
  double? get customerLng =>
      double.tryParse(_order?['long_order']?.toString() ?? '');
  double? get shopLat =>
      double.tryParse(_order?['shops']?['lat_toko']?.toString() ?? '');
  double? get shopLng =>
      double.tryParse(_order?['shops']?['long_toko']?.toString() ?? '');

  List<dynamic> get detailItems => _items;

  int get totalAmount {
    final biayaLayanan = _items.fold<int>(0, (sum, item) {
      final value =
          double.tryParse(item['total_harga']?.toString() ?? '0') ?? 0;
      return sum + value.toInt();
    });
    final ongkir =
        int.tryParse((_order?['total_ongkir'] ?? '0').toString()) ?? 0;
    return biayaLayanan + ongkir;
  }

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
        _timeline = data['timeline'] ?? []; // BARU

        debugPrint('=== ORDER DATA ===');
        debugPrint(_order.toString());
        debugPrint('=== TIMELINE (${_timeline.length} entries) ===');
        debugPrint(_timeline.toString());
        debugPrint('=================');

        await _tryFetchRoute();
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengambil detail pesanan';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _tryFetchRoute() async {
    final originLat = shopLat;
    final originLng = shopLng;
    final destLat = customerLat;
    final destLng = customerLng;

    if (originLat == null ||
        originLng == null ||
        destLat == null ||
        destLng == null) {
      debugPrint('Route skip: koordinat tidak lengkap');
      return;
    }

    await fetchRoute(
      origin: LatLng(originLat, originLng),
      destination: LatLng(destLat, destLng),
    );
  }

  Future<void> fetchRoute({
    required LatLng origin,
    required LatLng destination,
  }) async {
    _isRouting = true;
    _routeError = null;
    notifyListeners();

    try {
      final response = await ApiService.getRouteOsrm(
        originLat: origin.latitude,
        originLng: origin.longitude,
        destLat: destination.latitude,
        destLng: destination.longitude,
      );

      if (response == null) {
        _routeError = 'Gagal menghubungi layanan rute';
        _isRouting = false;
        notifyListeners();
        return;
      }

      final routes = response['routes'] as List<dynamic>?;
      if (routes == null || routes.isEmpty) {
        _routeError = 'Rute tidak ditemukan';
        _isRouting = false;
        notifyListeners();
        return;
      }

      final route = routes.first as Map<String, dynamic>;
      final encoded = route['geometry']?.toString() ?? '';
      _routePoints = encoded.isEmpty ? [] : _decodePolyline(encoded);
      _routeDistanceMeters = (route['distance'] as num?)?.toDouble();
      _routeDurationSeconds = (route['duration'] as num?)?.toDouble();
    } catch (e) {
      _routeError = 'Terjadi kesalahan rute: $e';
      debugPrint('ROUTE ERROR: $e');
    }

    _isRouting = false;
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

  @override
  void dispose() {
    super.dispose();
  }
}
