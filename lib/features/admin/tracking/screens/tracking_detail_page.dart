import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_scaffold.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/constants/app_colors.dart';
import '../controller/tracking_detail_controller.dart';

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

  @override
  void initState() {
    super.initState();
    _mapController = MapController();
    _controller = TrackingDetailController();
    _initTracking();
  }

  Future<void> _initTracking() async {
    final ok = await _controller.fetchTrackingDetail(
      token: widget.token,
      orderId: widget.orderId,
    );

    if (ok) {
      _controller.startAutoRefresh(widget.token, widget.orderId);
      
      final status = _controller.detailData?['order']?['status_order']?.toString().toLowerCase();
      if (status == 'diantar') {
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
        CameraFit.bounds(
          bounds: bounds,
          padding: const EdgeInsets.all(100),
        ),
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

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTime.parse(dateStr);
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
    if (status == null || status.isEmpty) return 'PENDING';
    return status.toUpperCase();
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

    if (courierLocation == null && customerLocation == null && shopLocation == null) {
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
    final markers = <Marker>[
      // 1. SHOP MARKER (GREEN) - Always from shop data
      if (shopLocation != null) ...[
        Marker(
          point: shopLocation,
          width: 40,
          height: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
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
                child: const Text('Toko', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],
      
      // 2. CUSTOMER MARKER (RED) - Always from customer data
      if (customerLocation != null) ...[
        Marker(
          point: customerLocation,
          width: 40,
          height: 40,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                ),
                child: const Icon(Icons.location_on, color: Colors.white, size: 28),
              ),
              const SizedBox(height: 2),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text('Tujuan', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ],

      // 3. COURIER MARKER (BLUE) - GPS stream or latest log
      if (courierLocation != null) ...[
        Marker(
          point: courierLocation,
          width: 50,
          height: 50,
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
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4)],
                    ),
                    child: const Icon(Icons.delivery_dining, color: Colors.white, size: 20),
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
                child: const Text('Kurir', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
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

    debugPrint('POLYLINE POINTS: ${polylinePoints.length} (${routePoints.isNotEmpty ? 'OSRM' : 'FALLBACK'})');

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
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'carekicks',
                ),
                // POLYLINE LAYER (before markers)
                if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                // MARKER LAYER (on top)
                MarkerLayer(markers: markers),
              ],
            ),
          ),
        ),
        // Fit map after build
        if (allMapPoints.length >= 2)
          Positioned(
            width: 0,
            height: 0,
            child: Builder(
              builder: (context) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fitMapToPoints(allMapPoints);
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
                  style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold),
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
                        ? '${(distanceMeters/1000).toStringAsFixed(1)} km' 
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
            right: 12,
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
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
    Color color;
    switch (status.toLowerCase()) {
      case 'selesai':
        color = Colors.green;
        break;
      case 'diantar':
        color = Colors.blue;
        break;
      default:
        color = Colors.orange;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        status.toUpperCase(),
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
        color: isLive ? Colors.green.withOpacity(0.08) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLive ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
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
                    color: isLive ? Colors.green.shade700 : Colors.grey.shade700,
                  ),
                ),
                Text(
                  isLive ? 'Lokasi Anda dikirim ke sistem tiap 10m' : 'Tekan Mulai untuk mengaktifkan GPS',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          if (isLive)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.green),
            ),
        ],
      ),
    );
  }

  Widget _instructionCard(String? instruction, double? nextDist, double? totalDist) {
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
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  instruction ?? 'Ikuti rute pada peta',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                nextDist != null 
                  ? (nextDist > 1000 ? '${(nextDist/1000).toStringAsFixed(1)}km' : '${nextDist.round()}m')
                  : (totalDist != null ? (totalDist > 1000 ? '${(totalDist/1000).toStringAsFixed(1)}km' : '${totalDist.round()}m') : '--'),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryBlue),
              ),
              const Text('jarak', style: TextStyle(fontSize: 10, color: Colors.grey)),
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
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _deliveryDetailCard(Map<String, dynamic> order, Map<String, dynamic>? lastLog) {
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
              const Text(
                'Detail Pengantaran',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              Text(
                'ID: ${order['kode_order'] ?? order['id_orders'] ?? '-'}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            ],
          ),
          const Divider(height: 24),
          _detailRow(
            icon: Icons.person_outline,
            label: 'Pelanggan',
            value: order['customers']?['nama']?.toString() ?? '-',
          ),
          _detailRow(
            icon: Icons.phone_outlined,
            label: 'Nomor HP',
            value: order['customers']?['nomor_hp']?.toString() ?? '-',
          ),
          _detailRow(
            icon: Icons.location_on_outlined,
            label: 'Alamat Tujuan',
            value: order['customers']?['alamat']?.toString() ?? '-',
          ),
          _detailRow(
            icon: Icons.inventory_2_outlined,
            label: 'Item Pesanan',
            value: _itemsLabel(order['detail_orders']),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total Pembayaran', style: TextStyle(color: Colors.grey, fontSize: 12)),
              Text(
                _formatCurrency(_totalHarga(order['detail_orders'])),
                style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryBlue, fontSize: 16),
              ),
            ],
          ),
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
                  const Icon(Icons.info_outline, size: 16, color: Colors.orange),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Catatan: ${order['catatan_pengiriman']}',
                      style: TextStyle(fontSize: 12, color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 16),
          Text(
            'Terakhir update: ${_formatDateTime(lastLog?['waktu']?.toString())}',
            style: const TextStyle(fontSize: 10, color: Colors.grey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Future<void> _submitFinish(File image, int? idStaff) async {
    final success = await _controller.finishDelivery(
      token: widget.token,
      orderId: widget.orderId,
      foto: image,
      idStaff: idStaff,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan berhasil diselesaikan'),
          backgroundColor: Colors.green,
        ),
      );
      _controller.fetchTrackingDetail(
        token: widget.token,
        orderId: widget.orderId,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Gagal menyelesaikan pesanan'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final idStaff = widget.user['id_staff'] ?? widget.user['id_user'];
    final parsedIdStaff = idStaff is int ? idStaff : int.tryParse(idStaff.toString());

    return CustomScaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Tracking Delivery',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
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
                  Icon(Icons.error_outline, size: 64, color: Colors.red.shade300),
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
          final lastLog = logs.isNotEmpty ? logs.first as Map<String, dynamic>? : null;
          final shop = order['shops'] as Map<String, dynamic>? ?? {};
          final customer = order['customers'] as Map<String, dynamic>? ?? {};

          // 1. SHOP LOCATION (GREEN)
          final shopLocation = _toLatLng(shop['lat_toko'], shop['long_toko']);
          
          // 2. CUSTOMER LOCATION (RED)
          final customerLocation = _toLatLng(
            customer['latitude'],
            customer['longitude'],
          );
          
          // 3. COURIER LOCATION (BLUE) - Priority: GPS Stream > Latest Log
          final courierLocation = _controller.currentCourierLocation ?? 
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
          final isSelesai = status == 'selesai';
          final isDiantar = status == 'diantar';
          
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
                            isSelesai ? 'Pengantaran Selesai' : 'Sedang Mengantar',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            isSelesai 
                              ? 'Paket telah diterima oleh pelanggan'
                              : 'Pantau lokasi Anda dan rute tercepat',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
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
                
                if (!isSelesai)
                  _instructionCard(nextInstruction, nextDistanceMeters, distanceMeters),
                
                const SizedBox(height: 16),
                
                if (!isSelesai) ...[
                  const Text(
                    'Kontrol Kurir',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (!isDiantar || !isLive)
                        Expanded(
                          child: _actionButton(
                            label: isDiantar ? 'Lanjut Tracking' : 'Mulai Antar',
                            icon: Icons.play_arrow,
                            color: Colors.green,
                            onPressed: _controller.isUpdating ? null : () {
                              _controller.startDelivery(
                                token: widget.token,
                                orderId: widget.orderId,
                                idStaff: parsedIdStaff,
                              );
                            },
                          ),
                        ),
                      if (isLive) ...[
                        if (!isDiantar || isLive) const SizedBox(width: 12),
                        Expanded(
                          child: _actionButton(
                            label: 'Berhenti',
                            icon: Icons.stop,
                            color: Colors.orange,
                            onPressed: () => _controller.stopRealtimeLocation(),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 12),
                  _actionButton(
                    label: 'Selesai Antar (Foto)',
                    icon: Icons.check_circle,
                    color: AppColors.primaryBlue,
                    isFullWidth: true,
                    onPressed: _controller.isUpdating ? null : () => _showImagePickerOption(
                      currentLocation: courierLocation ?? shopLocation,
                      idStaff: parsedIdStaff,
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                _deliveryDetailCard(order, lastLog),
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
    required LatLng? currentLocation,
    int? idStaff,
  }) async {
    if (_controller.isUpdating) return;

    showModalBottomSheet(
      context: context,
      shape:  RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Center(
                    child: Text(
                      'Foto Bukti Pengantaran',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.camera_alt, color: AppColors.primaryBlue),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _pickImage(ImageSource.camera);
                    if (image != null && mounted) {
                      await _submitFinish(image, idStaff);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library, color: AppColors.primaryBlue),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _pickImage(ImageSource.gallery);
                    if (image != null && mounted) {
                      await _submitFinish(image, idStaff);
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
