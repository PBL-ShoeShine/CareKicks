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

  @override
  void initState() {
    super.initState();
    _controller = TrackingDetailController();
    _fetchData();
  }

  Future<void> _fetchData() async {
    final ok = await _controller.fetchTrackingDetail(
      token: widget.token,
      orderId: widget.orderId,
    );

    if (!ok) return;

    final detail = _controller.detailData ?? {};
    final order = detail['order'] as Map<String, dynamic>? ?? {};
    final logs = detail['tracking_logs'] as List<dynamic>? ?? [];
    final lastLog = logs.isNotEmpty ? logs.first : null;

    final origin = _toLatLng(lastLog?['latitude'], lastLog?['longitude']);
    final destination = _toLatLng(
      order['customers']?['latitude'],
      order['customers']?['longitude'],
    );

    if (origin != null && destination != null) {
      await _controller.fetchRoute(origin: origin, destination: destination);
    }
  }

  @override
  void dispose() {
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

  Future<void> _showImagePickerOption({
    required LatLng? currentLocation,
  }) async {
    if (_controller.isUpdating) return;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _pickImage(ImageSource.camera);
                    if (image != null && mounted) {
                      await _submitValidation(image, currentLocation);
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () async {
                    Navigator.pop(context);
                    final image = await _pickImage(ImageSource.gallery);
                    if (image != null && mounted) {
                      await _submitValidation(image, currentLocation);
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

  Future<File?> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile == null) return null;
    return File(pickedFile.path);
  }

  Future<void> _submitValidation(File image, LatLng? currentLocation) async {
    final success = await _controller.submitValidationPhoto(
      token: widget.token,
      orderId: widget.orderId,
      foto: image,
      latitude: currentLocation?.latitude,
      longitude: currentLocation?.longitude,
    );

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Foto validasi berhasil dikirim')),
      );
      _fetchData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage ?? 'Gagal mengirim foto validasi',
          ),
        ),
      );
    }
  }

  Widget _mapCard({
    required LatLng? currentLocation,
    required LatLng? destination,
    required List<LatLng> routePoints,
    required double? distanceMeters,
    required double? durationSeconds,
  }) {
    if (currentLocation == null && destination == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: const Color(0xFFE2E8F0),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text('Lokasi belum tersedia')),
      );
    }

    final LatLng center = destination ?? currentLocation!;
    final markers = <Marker>[
      if (currentLocation != null)
        Marker(
          point: currentLocation,
          width: 40,
          height: 40,
          child: const Icon(Icons.my_location, color: Colors.blue, size: 28),
        ),
      if (destination != null)
        Marker(
          point: destination,
          width: 40,
          height: 40,
          child: const Icon(Icons.location_on, color: Colors.red, size: 30),
        ),
    ];

    final polylinePoints = routePoints.isNotEmpty
        ? routePoints
        : (currentLocation != null && destination != null)
        ? [currentLocation, destination]
        : <LatLng>[];

    final polylines = <Polyline>[
      if (polylinePoints.isNotEmpty)
        Polyline(
          points: polylinePoints,
          color: AppColors.primaryBlue,
          strokeWidth: 3,
        ),
    ];

    final distanceLabel = distanceMeters == null
        ? null
        : '${distanceMeters.round()} m';

    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            height: 200,
            child: FlutterMap(
              options: MapOptions(initialCenter: center, initialZoom: 13),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'carekicks',
                ),
                if (polylines.isNotEmpty) PolylineLayer(polylines: polylines),
                MarkerLayer(markers: markers),
              ],
            ),
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
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Estimasi Tiba',
                  style: TextStyle(fontSize: 10, color: Colors.grey),
                ),
                const SizedBox(height: 4),
                Text(
                  durationSeconds == null && distanceMeters == null
                      ? '--'
                      : '${_estimateMinutes(distanceMeters, durationSeconds)} menit',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  distanceLabel ?? '-',
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              ],
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

    const averageSpeedKmH = 25.0;
    final distanceKm = distanceMeters / 1000;
    final minutes = (distanceKm / averageSpeedKmH) * 60;
    return minutes.isFinite ? minutes.ceil() : 0;
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Tracking Kurir',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
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
                  Text(_controller.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _fetchData,
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final detail = _controller.detailData ?? {};
          final order = detail['order'] as Map<String, dynamic>? ?? {};
          final logs = detail['tracking_logs'] as List<dynamic>? ?? [];
          final lastLog = logs.isNotEmpty ? logs.first : null;

          final currentLocation = _toLatLng(
            lastLog?['latitude'],
            lastLog?['longitude'],
          );
          final destination = _toLatLng(
            order['customers']?['latitude'],
            order['customers']?['longitude'],
          );

          final routeDistance = _controller.routeDistanceMeters;
          final routeDuration = _controller.routeDurationSeconds;
          final fallbackDistance =
              (currentLocation != null && destination != null)
              ? _distanceKm(currentLocation, destination) * 1000
              : null;
          final distanceMeters = routeDistance ?? fallbackDistance;
          final nextInstruction = _controller.nextInstruction;
          final nextDistanceMeters = _controller.nextDistanceMeters;

          final status = order['status_order']?.toString();
          final hasValidation = order['foto_validasi'] != null;
          final canValidate =
              status?.toLowerCase() != 'selesai' && !hasValidation;

          return RefreshIndicator(
            onRefresh: () async => _fetchData(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Tracking Kurir',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Pantau penjemputan dan pengantaran hari ini',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gps_fixed, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          currentLocation == null
                              ? 'GPS belum tersedia'
                              : 'GPS aktif',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF334155),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                _mapCard(
                  currentLocation: currentLocation,
                  destination: destination,
                  routePoints: _controller.routePoints,
                  distanceMeters: distanceMeters,
                  durationSeconds: routeDuration,
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.lightBlue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.navigation,
                          color: AppColors.primaryBlue,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Instruksi berikutnya',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              nextInstruction ??
                                  (distanceMeters == null
                                      ? 'Menunggu lokasi'
                                      : 'Menuju tujuan'),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        nextDistanceMeters != null
                            ? '${nextDistanceMeters.round()}m'
                            : (distanceMeters == null
                                  ? '--'
                                  : '${distanceMeters.round()}m'),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
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
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.lightBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              _formatStatus(status),
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Text(
                            'ID: ${order['kode_order'] ?? order['id_orders'] ?? '-'}',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Detail Pengantaran',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _detailRow(
                        icon: Icons.person,
                        label: 'Pelanggan',
                        value: order['customers']?['nama']?.toString() ?? '-',
                      ),
                      _detailRow(
                        icon: Icons.location_on,
                        label: 'Alamat',
                        value: order['customers']?['alamat']?.toString() ?? '-',
                      ),
                      _detailRow(
                        icon: Icons.inventory_2_outlined,
                        label: 'Item',
                        value: _itemsLabel(order['detail_orders']),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                          Text(
                            _formatCurrency(
                              _totalHarga(order['detail_orders']),
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: canValidate
                              ? () => _showImagePickerOption(
                                  currentLocation: currentLocation,
                                )
                              : null,
                          icon: const Icon(Icons.camera_alt),
                          label: Text(
                            _controller.isUpdating
                                ? 'Mengirim...'
                                : canValidate
                                ? 'Foto Validasi'
                                : 'Sudah divalidasi',
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Catatan: ${order['catatan_pengiriman'] ?? '-'}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Terakhir update: ${_formatDateTime(lastLog?['waktu']?.toString())}',
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
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
}
