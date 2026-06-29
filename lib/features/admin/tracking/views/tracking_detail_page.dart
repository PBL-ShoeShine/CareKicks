import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/widgets/custom_scaffold.dart';
import '../controllers/tracking_detail_controller.dart';
import '../../../../core/utils/date_utils.dart';

class TrackingDetailPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;
  final int orderId;

  const TrackingDetailPage({
    super.key,
    required this.token,
    required this.user,
    required this.orderId,
  });

  @override
  State<TrackingDetailPage> createState() => _TrackingDetailPageState();
}

class _TrackingDetailPageState extends State<TrackingDetailPage> {
  late TrackingDetailController _controller;
  late final MapController _mapController;
  bool _initialFitDone = false;
  bool _followMe = false;

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _controller = TrackingDetailController();
    _controller.addListener(_onControllerChanged);
    _initTracking();
  }

  void _onControllerChanged() {
    if (!mounted) return;
    setState(() {});
    if (_followMe && _controller.currentCourierLocation != null) {
      _mapController.move(_controller.currentCourierLocation!, 16);
    }
  }

  Future<void> _initTracking() async {
    final ok = await _controller.fetchTrackingDetail(
      token: widget.token,
      orderId: widget.orderId,
    );

    if (ok) {
      _controller.startAutoRefresh(widget.token, widget.orderId);

      final status = _controller.detailData?['order']?['status_order']
          ?.toString()
          .toLowerCase();
      final isActiveTracking =
          status == 'sedang_diantar' ||
          status == 'sedang_dijemput' ||
          status == 'diantar';
      if (isActiveTracking) {
        final idStaff = widget.user['id_staff'] ?? widget.user['id_user'];
        _controller.startRealtimeLocation(
          widget.token,
          widget.orderId,
          idStaff is int ? idStaff : int.tryParse(idStaff.toString()),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onControllerChanged);
    _controller.stopAutoRefresh();
    _controller.stopRealtimeLocation();
    _controller.dispose();
    super.dispose();
  }

  double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is num) return value.toDouble();
    return double.tryParse(value.toString());
  }

  LatLng? _toLatLng(dynamic lat, dynamic lng) {
    final latValue = _toDouble(lat);
    final lngValue = _toDouble(lng);
    if (latValue == null || lngValue == null) return null;
    return LatLng(latValue, lngValue);
  }

  double _distanceKm(LatLng a, LatLng b) {
    const earthRadiusKm = 6371.0;
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);

    final h =
        (math.sin(dLat / 2) * math.sin(dLat / 2)) +
        (math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLon / 2) *
            math.sin(dLon / 2));
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusKm * c;
  }

  double _degToRad(double deg) => deg * (3.141592653589793 / 180.0);

  void _fitMapToPoints(List<LatLng> points) {
    if (points.length < 2) return;

    try {
      final bounds = LatLngBounds.fromPoints(points);
      _mapController.fitCamera(
        CameraFit.bounds(bounds: bounds, padding: const EdgeInsets.all(100)),
      );
      debugPrint('MAP FIT TO ${points.length} POINTS');
    } catch (e) {
      debugPrint('MAP FIT ERROR: $e');
    }
  }

  String _formatCurrency(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    final intValue = number.toInt();

    final formatted = intValue.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]}.',
    );

    return 'Rp $formatted';
  }

  String _formatDistance(double meters) {
    if (meters >= 1000) {
      final km = meters / 1000;
      return 'Jarak: ${km.toStringAsFixed(1)} km';
    }
    return 'Jarak: ${meters.toInt()} m';
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTimeUtils.parseToWib(dateStr);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      final hour = date.hour.toString().padLeft(2, '0');
      final minute = date.minute.toString().padLeft(2, '0');
      return '$day/$month/$year $hour:$minute';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatStatus(String? status) {
    final raw = status?.trim();
    if (raw == null || raw.isEmpty) return 'Pending';
    final normalized = raw.replaceAll('_', ' ').toLowerCase();
    return normalized.isEmpty
        ? 'Pending'
        : '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  String _statusTitle(String? status) {
    final normalized = status?.toLowerCase() ?? '';
    switch (normalized) {
      case 'menunggu_jemput':
      case 'menunggu_dijemput':
        return 'Menunggu Penjemputan';
      case 'sedang_dijemput':
        return 'Sedang Menjemput';
      case 'diterima_toko':
      case 'sudah_dijemput':
        return 'Penjemputan Selesai';
      case 'siap_diantar':
        return 'Siap Diantar';
      case 'sedang_diantar':
      case 'diantar':
        return 'Sedang Mengantar';
      case 'selesai':
        return 'Pengantaran Selesai';
      default:
        return 'Tracking Kurir';
    }
  }

  String _statusSubtitle(String? status) {
    final normalized = status?.toLowerCase() ?? '';
    switch (normalized) {
      case 'menunggu_jemput':
      case 'menunggu_dijemput':
        return 'Kurir menunggu mulai penjemputan';
      case 'sedang_dijemput':
        return 'Pantau lokasi Anda menuju pelanggan';
      case 'diterima_toko':
      case 'sudah_dijemput':
        return 'Pesanan telah diterima di toko';
      case 'siap_diantar':
        return 'Pesanan siap diantar ke pelanggan';
      case 'sedang_diantar':
      case 'diantar':
        return 'Pantau lokasi Anda dan rute tercepat';
      case 'selesai':
        return 'Paket telah diterima oleh pelanggan';
      default:
        return 'Pantau lokasi dan status pesanan';
    }
  }

  Future<File?> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  Widget _mapCard({
    required LatLng? courierLocation,
    required LatLng? customerLocation,
    required LatLng? shopLocation,
    required List<LatLng> routePoints,
    required double? distanceMeters,
    required double? durationSeconds,
  }) {
    // ========== EXPLICIT DEBUG PRINTS ==========
    debugPrint('========== MAP CARD BUILD ==========');
    debugPrint('SHOP LOCATION: $shopLocation');
    debugPrint('CUSTOMER LOCATION: $customerLocation');
    debugPrint('COURIER LOCATION: $courierLocation');
    debugPrint('ROUTE POINTS LENGTH: ${routePoints.length}');
    debugPrint('DISTANCE METERS: $distanceMeters');
    debugPrint('DURATION SECONDS: $durationSeconds');
    debugPrint('ROUTE ERROR: ${_controller.routeError}');
    debugPrint('====================================');

    if (courierLocation == null &&
        customerLocation == null &&
        shopLocation == null) {
      return Container(
        height: 250,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('Lokasi belum tersedia')),
      );
    }

    // Center map on courier location first, fallback to shop, then customer
    final LatLng center = courierLocation ?? shopLocation ?? customerLocation!;

    // ========== MARKER CREATION ==========
    const shopMarkerSize = Size(44, 52);
    const customerMarkerSize = Size(44, 52);
    const courierMarkerSize = Size(56, 60);

    final markers = <Marker>[
      // 1. SHOP MARKER (GREEN) - Always from shop data
      if (shopLocation != null) ...[
        Marker(
          point: shopLocation,
          width: shopMarkerSize.width,
          height: shopMarkerSize.height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.store, color: Colors.white, size: 24),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Toko',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],

      // 2. CUSTOMER MARKER (RED) - Always from customer data
      if (customerLocation != null) ...[
        Marker(
          point: customerLocation,
          width: customerMarkerSize.width,
          height: customerMarkerSize.height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.location_on,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Tujuan',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],

      // 3. COURIER MARKER (BLUE) - GPS stream or latest log
      if (courierLocation != null) ...[
        Marker(
          point: courierLocation,
          width: courierMarkerSize.width,
          height: courierMarkerSize.height,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 25,
                    height: 25,
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.delivery_dining,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'Kurir',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ];

    // ========== POLYLINE LOGIC ==========
    final origin = courierLocation ?? shopLocation;
    final destination = customerLocation;

    // Always show polyline: either route from OSRM or fallback straight line
    final polylinePoints = routePoints.isNotEmpty
        ? routePoints
        : (origin != null && destination != null)
        ? [origin, destination]
        : <LatLng>[];

    debugPrint(
      'POLYLINE POINTS: ${polylinePoints.length} (${routePoints.isNotEmpty ? 'OSRM' : 'FALLBACK'})',
    );

    final polylines = <Polyline>[
      if (polylinePoints.isNotEmpty)
        Polyline(
          points: polylinePoints,
          color: AppColors.primaryBlue,
          strokeWidth: 5.0,
          isDotted: false,
        ),
    ];

    // Collect all points for map fitting
    final allMapPoints = <LatLng>[
      ...polylinePoints,
      if (shopLocation != null) shopLocation,
      if (customerLocation != null) customerLocation,
      if (courierLocation != null) courierLocation,
    ];

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 250,
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14,
                minZoom: 11,
                maxZoom: 18,
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'carekicks',
                  maxNativeZoom: 19,
                ),
                // POLYLINE LAYER (before markers)
                if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                // MARKER LAYER (on top)
                MarkerLayer(markers: markers),
              ],
            ),
          ),
        ),
        // Fit map once on initial load
        if (allMapPoints.length >= 2 && !_initialFitDone)
          Positioned(
            width: 0,
            height: 0,
            child: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (!_initialFitDone) {
                    _initialFitDone = true;
                    _fitMapToPoints(allMapPoints);
                  }
                });
                return const SizedBox.shrink();
              },
            ),
          ),
        Positioned(
          top: 12,
          left: 12,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Estimasi Tiba',
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  durationSeconds == null && distanceMeters == null
                      ? '--'
                      : '${_estimateMinutes(distanceMeters, durationSeconds)} menit',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                  ),
                ),
                if (distanceMeters != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    distanceMeters > 1000
                        ? '${(distanceMeters / 1000).toStringAsFixed(1)} km'
                        : '${distanceMeters.round()} m',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ],
            ),
          ),
        ),
        if (_controller.isRouting)
          const Positioned(
            top: 12,
            right: 52,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
        Positioned(
          bottom: 12,
          right: 12,
          child: GestureDetector(
            onTap: () {
              setState(() {
                _followMe = !_followMe;
                if (_followMe && _controller.currentCourierLocation != null) {
                  _mapController.move(_controller.currentCourierLocation!, 16);
                }
              });
            },
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _followMe ? AppColors.primaryBlue : Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.my_location_rounded,
                color: _followMe ? Colors.white : AppColors.primaryBlue,
                size: 22,
              ),
            ),
          ),
        ),
      ],
    );
  }

  int _estimateMinutes(double? distanceMeters, double? durationSeconds) {
    if (durationSeconds != null) {
      return (durationSeconds / 60).ceil();
    }

    if (distanceMeters == null) return 0;

    const averageSpeedKmH = 20.0;
    final distanceKm = distanceMeters / 1000;
    final minutes = (distanceKm / averageSpeedKmH) * 60;
    return minutes.isFinite ? minutes.ceil() : 0;
  }

  Widget _statusBadge(String status) {
    final normalized = status.toLowerCase();
    Color color;
    switch (normalized) {
      case 'selesai':
      case 'diterima_toko':
      case 'sudah_dijemput':
        color = AppColors.success;
        break;
      case 'sedang_dijemput':
      case 'sedang_diantar':
      case 'diproses':
        color = AppColors.primaryBlue;
        break;
      case 'menunggu_jemput':
      case 'menunggu_dijemput':
      case 'siap_diantar':
      case 'pending':
        color = AppColors.warning;
        break;
      default:
        color = AppColors.textSecondary;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: AppRadius.extraLarge,
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        _formatStatus(status),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _locationStatusBanner(bool isLive) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isLive
            ? Colors.green.withOpacity(0.08)
            : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLive
              ? Colors.green.withOpacity(0.2)
              : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isLive ? Icons.gps_fixed : Icons.gps_off,
            size: 20,
            color: isLive ? Colors.green : Colors.grey,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLive ? 'Tracking Aktif' : 'Tracking Nonaktif',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: isLive
                        ? Colors.green.shade700
                        : Colors.grey.shade700,
                  ),
                ),
                Text(
                  isLive
                      ? 'Lokasi Anda dikirim ke sistem tiap 10m'
                      : 'Tekan Mulai untuk mengaktifkan GPS',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (isLive)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.green,
              ),
            ),
        ],
      ),
    );
  }

  Widget _instructionCard(
    String? instruction,
    double? nextDist,
    double? totalDist,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.lightBlue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.navigation, color: AppColors.primaryBlue),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Instruksi Berikutnya',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  instruction ?? 'Ikuti rute pada peta',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                nextDist != null
                    ? (nextDist > 1000
                          ? '${(nextDist / 1000).toStringAsFixed(1)}km'
                          : '${nextDist.round()}m')
                    : (totalDist != null
                          ? (totalDist > 1000
                                ? '${(totalDist / 1000).toStringAsFixed(1)}km'
                                : '${totalDist.round()}m')
                          : '--'),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.primaryBlue,
                ),
              ),
              const Text(
                'jarak',
                style: TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback? onPressed,
    bool isFullWidth = false,
  }) {
    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 20),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(
            vertical: AppSizes.paddingMd,
            horizontal: AppSizes.paddingLg,
          ),
          shape: RoundedRectangleBorder(borderRadius: AppRadius.medium),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _deliveryDetailCard(String title, Map<String, dynamic> order, {double? distanceMeters}) {
    final items = order['detail_orders'] as List<dynamic>? ?? [];
    final ongkir = double.tryParse(order['total_ongkir']?.toString() ?? '0') ?? 0;
    final subtotal = _totalHarga(items);
    final total = subtotal + ongkir.toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                '#${order['kode_order'] ?? order['id_orders'] ?? '-'}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 24),
          if (distanceMeters != null) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                children: [
                  Icon(Icons.straighten, size: 18, color: Colors.grey),
                  const SizedBox(width: 10),
                  Text(
                    _formatDistance(distanceMeters),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ],
          _detailRow(
            icon: Icons.person_outline,
            label: 'Pelanggan',
            value: order['customers']?['nama']?.toString() ?? '-',
          ),
          _detailRow(
            icon: Icons.phone_outlined,
            label: 'Nomor HP',
            value: order['customers']?['nomor_hp']?.toString()
                ?? order['customers']?['no_hp']?.toString()
                ?? order['no_hp']?.toString()
                ?? '-',
          ),
          _detailRow(
            icon: Icons.location_on_outlined,
            label: 'Alamat Tujuan',
            value: order['alamat_pengantaran']?.toString()
                ?? order['customers']?['alamat']?.toString()
                ?? '-',
          ),
          const SizedBox(height: 8),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value as Map<String, dynamic>;
            return Padding(
              padding: EdgeInsets.only(top: index > 0 ? 12 : 0),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF7F8FA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pesanan ${index + 1}',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1A1A2E),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoColumn(
                            'Merk',
                            item['merk']?.toString() ?? '-',
                          ),
                        ),
                        Expanded(
                          child: _buildInfoColumn(
                            'Warna',
                            item['warna']?.toString() ?? '-',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoColumn(
                            'Jenis Layanan',
                            item['services']?['nama_layanan']?.toString() ??
                                '-',
                          ),
                        ),
                        Expanded(
                          child: _buildInfoColumn(
                            'Harga',
                            _formatCurrency(
                              double.tryParse(
                                    item['total_harga']?.toString() ?? '0',
                                  ) ??
                                  0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          if (items.isNotEmpty) ...[
            const SizedBox(height: 12),
            // Biaya layanan subtotal
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Biaya Layanan',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  _formatCurrency(subtotal.toDouble()),
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (ongkir > 0) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Ongkir',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    _formatCurrency(ongkir),
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            const Divider(height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Pembayaran',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
                Text(
                  _formatCurrency(total.toDouble()),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryBlue,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ],
          if (order['catatan_pengiriman'] != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Catatan: ${order['catatan_pengiriman']}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoColumn(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Future<File> _addWatermark(
    File imageFile,
    String name,
    String timestamp,
  ) async {
    try {
      final bytes = await imageFile.readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frameInfo = await codec.getNextFrame();
      final image = frameInfo.image;

      double scale = 1.0;
      ByteData? pngBytes;
      bool sizeOk = false;

      // Loop to scale down image dimensions if the output size exceeds 2MB
      while (!sizeOk && scale > 0.1) {
        final currentWidth = (image.width * scale).toInt();
        final currentHeight = (image.height * scale).toInt();

        final recorder = ui.PictureRecorder();
        final canvas = Canvas(recorder);
        final paint = Paint();

        // Draw scaled original image
        canvas.drawImageRect(
          image,
          Rect.fromLTWH(0, 0, image.width.toDouble(), image.height.toDouble()),
          Rect.fromLTWH(
            0,
            0,
            currentWidth.toDouble(),
            currentHeight.toDouble(),
          ),
          paint,
        );

        // Draw a black semi-transparent banner at the bottom of the image for readability
        final double bannerHeight = currentHeight * 0.08; // 8% of image height
        final bannerPaint = Paint()
          ..color = Colors.black.withOpacity(0.6)
          ..style = PaintingStyle.fill;
        canvas.drawRect(
          Rect.fromLTWH(
            0,
            currentHeight - bannerHeight,
            currentWidth.toDouble(),
            bannerHeight,
          ),
          bannerPaint,
        );

        // Draw the watermark text
        final textStyle = TextStyle(
          color: Colors.white,
          fontSize: currentHeight * 0.025, // Scale text size to image height
          fontWeight: FontWeight.bold,
        );

        final watermarkText = 'Kurir: $name | $timestamp';

        final textPainter = TextPainter(textDirection: TextDirection.ltr);
        textPainter.text = TextSpan(text: watermarkText, style: textStyle);
        textPainter.layout();

        // Position the text in the banner (horizontal padding: 20)
        final xOffset = 20.0;
        final yOffset =
            currentHeight -
            bannerHeight +
            (bannerHeight - textPainter.height) / 2;

        textPainter.paint(canvas, Offset(xOffset, yOffset));

        final picture = recorder.endRecording();
        final img = await picture.toImage(currentWidth, currentHeight);
        pngBytes = await img.toByteData(format: ui.ImageByteFormat.png);

        if (pngBytes == null) break;

        final sizeInBytes = pngBytes.lengthInBytes;
        if (sizeInBytes <= 2 * 1024 * 1024) {
          sizeOk = true;
        } else {
          // Reduce dimensions by 30% for the next try
          scale *= 0.7;
        }
      }

      if (pngBytes == null) return imageFile;

      // Save back to a temporary file
      final tempDir = Directory.systemTemp;
      final watermarkedFile = File(
        '${tempDir.path}/delivery_proof_${DateTime.now().millisecondsSinceEpoch}.png',
      );
      await watermarkedFile.writeAsBytes(pngBytes.buffer.asUint8List());
      return watermarkedFile;
    } catch (e) {
      debugPrint('Error watermarking image: $e');
      return imageFile; // Return original image on failure
    }
  }

  String _getFormattedTimestamp() {
    final now = DateTime.now();
    final y = now.year;
    final m = now.month.toString().padLeft(2, '0');
    final d = now.day.toString().padLeft(2, '0');
    final h = now.hour.toString().padLeft(2, '0');
    final min = now.minute.toString().padLeft(2, '0');
    final s = now.second.toString().padLeft(2, '0');
    return '$y-$m-$d $h:$min:$s';
  }

  Future<void> _submitDelivery(File image, int? idStaff) async {
    File watermarkedImage = image;
    try {
      final uploaderName =
          widget.user['nama'] ?? widget.user['username'] ?? 'Staff / Admin';
      final timestamp = _getFormattedTimestamp();
      watermarkedImage = await _addWatermark(image, uploaderName, timestamp);
    } catch (e) {
      debugPrint('Error adding watermark: $e');
    }

    final success = await _controller.finishDelivery(
      token: widget.token,
      orderId: widget.orderId,
      foto: watermarkedImage,
      idStaff: idStaff,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pengantaran berhasil diselesaikan'),
          backgroundColor: AppColors.success,
        ),
      );
      _controller.fetchTrackingDetail(
        token: widget.token,
        orderId: widget.orderId,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage ?? 'Gagal menyelesaikan pengantaran',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _submitPickup(File image, int? idStaff) async {
    File watermarkedImage = image;
    try {
      final uploaderName =
          widget.user['nama'] ?? widget.user['username'] ?? 'Staff / Admin';
      final timestamp = _getFormattedTimestamp();
      watermarkedImage = await _addWatermark(image, uploaderName, timestamp);
    } catch (e) {
      debugPrint('Error adding watermark: $e');
    }

    final success = await _controller.finishPickup(
      token: widget.token,
      orderId: widget.orderId,
      foto: watermarkedImage,
      idStaff: idStaff,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Penjemputan berhasil diselesaikan'),
          backgroundColor: AppColors.success,
        ),
      );
      _controller.fetchTrackingDetail(
        token: widget.token,
        orderId: widget.orderId,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage ?? 'Gagal menyelesaikan penjemputan',
          ),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final idStaff = widget.user['id_staff'] ?? widget.user['id_user'];
    final parsedIdStaff = idStaff is int
        ? idStaff
        : int.tryParse(idStaff.toString());

    return CustomScaffold(
      backgroundColor: AppColors.background,
      appBar: CustomAppBar(
        title: 'Tracking Kurir',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.fetchTrackingDetail(
              token: widget.token,
              orderId: widget.orderId,
            ),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoading && _controller.detailData == null) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.errorMessage != null &&
              _controller.detailData == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 64,
                    color: Colors.red.shade300,
                  ),
                  const SizedBox(height: 16),
                  Text(_controller.errorMessage!, textAlign: TextAlign.center),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _controller.fetchTrackingDetail(
                      token: widget.token,
                      orderId: widget.orderId,
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final detail = _controller.detailData ?? {};
          final order = detail['order'] as Map<String, dynamic>? ?? {};
          final logs = detail['tracking_logs'] as List<dynamic>? ?? [];
          final lastLog = logs.isNotEmpty
              ? logs.first as Map<String, dynamic>?
              : null;
          final shop = order['shops'] as Map<String, dynamic>? ?? {};
          final customer = order['customers'] as Map<String, dynamic>? ?? {};

          // 1. SHOP LOCATION (GREEN)
          final shopLocation = _toLatLng(shop['lat_toko'], shop['long_toko']);

          // 2. CUSTOMER LOCATION (RED)
          // PENTING: Gunakan lat_order/long_order dari order (koordinat yang dipilih customer saat pesan),
          // bukan dari profil customer — keduanya bisa berbeda jika customer punya banyak alamat.
          final customerLocation = _toLatLng(
                order['lat_order'],
                order['long_order'],
              ) ??
              _toLatLng(
                customer['latitude'],
                customer['longitude'],
              );

          // 3. COURIER LOCATION (BLUE) - Priority: GPS Stream > Latest Log
          final courierLocation =
              _controller.currentCourierLocation ??
              _toLatLng(lastLog?['latitude'], lastLog?['longitude']);

          final isLive = _controller.isTrackingActive;

          final routeDistance = _controller.routeDistanceMeters;
          final routeDuration = _controller.routeDurationSeconds;

          // Final Distance logic for display
          final originForFallback = courierLocation ?? shopLocation;
          final fallbackDistance =
              (originForFallback != null && customerLocation != null)
              ? _distanceKm(originForFallback, customerLocation) * 1000
              : null;
          final distanceMeters = routeDistance ?? fallbackDistance;

          final nextInstruction = _controller.nextInstruction;
          final nextDistanceMeters = _controller.nextDistanceMeters;

          final status = order['status_order']?.toString().toLowerCase();
          final isPickupWaiting =
              status == 'menunggu_jemput' || status == 'menunggu_dijemput';
          final isPickupActive = status == 'sedang_dijemput';
          final isPickupReceived =
              status == 'diterima_toko' || status == 'sudah_dijemput';
          final isPickupPhase =
              isPickupWaiting || isPickupActive || isPickupReceived;
          final isDeliveryReady = status == 'siap_diantar';
          final isDeliveryActive =
              status == 'sedang_diantar' || status == 'diantar';
          final isDeliveryPhase =
              isDeliveryReady || isDeliveryActive || status == 'selesai';
          final shouldShowPreview =
              (isPickupPhase && isPickupReceived) ||
              (isDeliveryPhase && status == 'selesai');
          final showControls =
              isPickupWaiting ||
              isPickupActive ||
              isPickupReceived ||
              isDeliveryReady ||
              isDeliveryActive;
          final statusTitle = _statusTitle(status);
          final statusSubtitle = _statusSubtitle(status);
          final detailTitle = isPickupPhase
              ? 'Detail Penjemputan'
              : isDeliveryPhase
              ? 'Detail Pengantaran'
              : 'Detail Pesanan';
          final actionButtons = <Widget>[];

          if (isPickupWaiting) {
            actionButtons.add(
              Expanded(
                child: _actionButton(
                  label: 'Mulai Jemput',
                  icon: Icons.play_arrow,
                  color: AppColors.success,
                  onPressed: _controller.isUpdating
                      ? null
                      : () {
                          _controller.startPickup(
                            token: widget.token,
                            orderId: widget.orderId,
                            idStaff: parsedIdStaff,
                          );
                        },
                ),
              ),
            );
          } else if (isPickupReceived) {
            actionButtons.add(
              Expanded(
                child: _actionButton(
                  label: 'Cuci Sekarang',
                  icon: Icons.local_laundry_service,
                  color: AppColors.primaryBlue,
                  onPressed: _controller.isUpdating
                      ? null
                      : () async {
                          final ok = await _controller.updateStatus(
                            token: widget.token,
                            orderId: widget.orderId,
                            status: 'washing',
                            keterangan: 'Sepatu mulai dicuci',
                            idStaff: parsedIdStaff,
                          );
                          if (ok && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Status berhasil diubah ke Washing',
                                ),
                                backgroundColor: AppColors.success,
                              ),
                            );
                            _controller.fetchTrackingDetail(
                              token: widget.token,
                              orderId: widget.orderId,
                            );
                          }
                        },
                ),
              ),
            );
          } else if (isDeliveryReady) {
            actionButtons.add(
              Expanded(
                child: _actionButton(
                  label: 'Mulai Antar',
                  icon: Icons.play_arrow,
                  color: AppColors.success,
                  onPressed: _controller.isUpdating
                      ? null
                      : () {
                          _controller.startDelivery(
                            token: widget.token,
                            orderId: widget.orderId,
                            idStaff: parsedIdStaff,
                          );
                        },
                ),
              ),
            );
          } else if (isPickupActive || isDeliveryActive) {
            if (!isLive) {
              actionButtons.add(
                Expanded(
                  child: _actionButton(
                    label: 'Lanjut Tracking',
                    icon: Icons.play_arrow,
                    color: AppColors.success,
                    onPressed: _controller.isUpdating
                        ? null
                        : () => _controller.startRealtimeLocation(
                            widget.token,
                            widget.orderId,
                            parsedIdStaff,
                          ),
                  ),
                ),
              );
            } else {
              actionButtons.add(
                Expanded(
                  child: _actionButton(
                    label: 'Jeda',
                    icon: Icons.pause,
                    color: AppColors.warning,
                    onPressed: _controller.stopRealtimeLocation,
                  ),
                ),
              );
            }
          }

          return RefreshIndicator(
            onRefresh: () async => _controller.fetchTrackingDetail(
              token: widget.token,
              orderId: widget.orderId,
            ),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusTitle,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            statusSubtitle,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _statusBadge(status ?? 'pending'),
                  ],
                ),
                const SizedBox(height: 16),

                _locationStatusBanner(isLive),

                const SizedBox(height: 16),
                _mapCard(
                  courierLocation: courierLocation,
                  customerLocation: customerLocation,
                  shopLocation: shopLocation,
                  routePoints: _controller.routePoints,
                  distanceMeters: distanceMeters,
                  durationSeconds: routeDuration,
                ),
                const SizedBox(height: 16),

                if (showControls && !isPickupReceived)
                  _instructionCard(
                    nextInstruction,
                    nextDistanceMeters,
                    distanceMeters,
                  ),

                const SizedBox(height: 16),

                if (showControls) ...[
                  const Text(
                    'Kontrol Kurir',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  if (actionButtons.isNotEmpty) Row(children: actionButtons),
                  if (actionButtons.isNotEmpty) const SizedBox(height: 12),
                  if (isPickupActive)
                    _actionButton(
                      label: 'Barang Diterima Kurir',
                      icon: Icons.check_circle,
                      color: AppColors.primaryBlue,
                      isFullWidth: true,
                      onPressed: _controller.isUpdating
                          ? null
                          : () => _showImagePickerOption(
                              title: 'Foto Barang Diterima',
                              onImagePicked: (image) =>
                                  _submitPickup(image, parsedIdStaff),
                            ),
                    ),
                  if (isDeliveryActive)
                    _actionButton(
                      label: 'Selesai Antar',
                      icon: Icons.check_circle,
                      color: AppColors.primaryBlue,
                      isFullWidth: true,
                      onPressed: _controller.isUpdating
                          ? null
                          : () => _showImagePickerOption(
                              title: 'Foto Bukti Pengantaran',
                              onImagePicked: (image) =>
                                  _submitDelivery(image, parsedIdStaff),
                            ),
                    ),
                  const SizedBox(height: 10),
                ],

                if (shouldShowPreview &&
                    order['foto_validasi'] != null &&
                    order['foto_validasi'].toString().isNotEmpty) ...[
                  const Text(
                    'Foto Bukti',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: Image.network(
                      order['foto_validasi'].toString(),
                      width: double.infinity,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          height: 200,
                          color: Colors.grey.shade200,
                          child: const Center(
                            child: Icon(Icons.broken_image, color: Colors.grey),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                _deliveryDetailCard(
                  detailTitle,
                  order,
                  distanceMeters: distanceMeters,
                ),
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _itemsLabel(dynamic items) {
    if (items is! List || items.isEmpty) return '-';
    final first = items.first as Map<String, dynamic>? ?? {};
    final layanan = first['services']?['nama_layanan']?.toString();
    final jenis = first['jenis_sepatu']?.toString();
    final merk = first['merk']?.toString();
    final name = layanan ?? 'Layanan';
    final detail = [
      if (jenis != null && jenis.isNotEmpty) jenis,
      if (merk != null && merk.isNotEmpty) merk,
    ].join(' ');
    final count = items.length;
    return '$count x $name${detail.isEmpty ? '' : ' ($detail)'}';
  }

  int _totalHarga(dynamic items) {
    if (items is! List || items.isEmpty) return 0;
    return items.fold<int>(0, (sum, item) {
      final value = double.tryParse(item['total_harga'].toString()) ?? 0;
      return sum + value.toInt();
    });
  }

  Future<void> _showImagePickerOption({
    required String title,
    required Future<void> Function(File image) onImagePicked,
  }) async {
    if (_controller.isUpdating) return;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.extraLarge),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(
                    Icons.camera_alt,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _pickImage(ImageSource.camera);
                    if (image != null && mounted) {
                      await onImagePicked(image);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(
                    Icons.photo_library,
                    color: AppColors.primaryBlue,
                  ),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _pickImage(ImageSource.gallery);
                    if (image != null && mounted) {
                      await onImagePicked(image);
                    }
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
