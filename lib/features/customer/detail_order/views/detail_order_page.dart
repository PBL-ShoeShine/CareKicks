import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/constants/app_colors.dart';
import '../controllers/detail_order_controller.dart';
import '../../payment/views/payment_page.dart';
import '../../../../core/utils/location_utils.dart';
import '../../../../core/utils/date_utils.dart';
import '../../ulasan/views/tulis_ulasan_page.dart';

class DetailOrderPage extends StatefulWidget {
  final String token;
  final String orderId;

  const DetailOrderPage({
    super.key,
    required this.token,
    required this.orderId,
  });

  @override
  State<DetailOrderPage> createState() => _DetailOrderPageState();
}

class _DetailOrderPageState extends State<DetailOrderPage> {
  late DetailOrderController _controller;
  bool _hasReviewedLocal = false;

  @override
  void initState() {
    super.initState();
    _controller = DetailOrderController();
    _controller.fetchDetailOrder(token: widget.token, orderId: widget.orderId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  bool get _isOnline =>
      _controller.order?['metode_order']?.toString().toLowerCase() == 'online';

  // ===== FIX: hitung jarak toko -> customer pakai Haversine formula =====
  double? _calculateDistanceKm() {
    final shopLat = _controller.shopLat;
    final shopLng = _controller.shopLng;
    final custLat = _controller.customerLat;
    final custLng = _controller.customerLng;

    if (shopLat == null ||
        shopLng == null ||
        custLat == null ||
        custLng == null) {
      return null;
    }

    return LocationUtils.calculateDistanceKm(
      shopLat,
      shopLng,
      custLat,
      custLng,
    );
  }

  String _formatDistance(double? km) {
    if (km == null) return '-';
    return '${km.toStringAsFixed(1)} km';
  }
  // ===== END FIX =====

  int _getPhaseIndex(String? status) {
    if (_isOnline) {
      switch (status) {
        case 'pending':
        case 'menunggu_pembayaran':
        case 'menunggu_konfirmasi':
          return 0;
        case 'dikonfirmasi':
        case 'menunggu_dijemput':
        case 'sedang_dijemput':
        case 'sudah_dijemput':
          return 1;
        case 'washing':
        case 'selesai_cuci':
          return 2;
        case 'sedang_diantar':
        case 'selesai':
          return 3;
        default:
          return 0;
      }
    } else {
      switch (status) {
        case 'pending':
        case 'menunggu_pembayaran':
        case 'dikonfirmasi':
          return 0;
        case 'washing':
          return 1;
        case 'selesai_cuci':
        case 'selesai':
          return 2;
        default:
          return 0;
      }
    }
  }

  List<Map<String, dynamic>> _getPhases() {
    if (_isOnline) {
      return [
        {'label': 'Pembayaran', 'icon': Icons.payment},
        {'label': 'Penjemputan', 'icon': Icons.directions_bike},
        {'label': 'Pencucian', 'icon': Icons.local_laundry_service},
        {'label': 'Pengiriman', 'icon': Icons.local_shipping},
      ];
    } else {
      return [
        {'label': 'Pembayaran', 'icon': Icons.payment},
        {'label': 'Pencucian', 'icon': Icons.local_laundry_service},
        {'label': 'Selesai', 'icon': Icons.check_circle},
      ];
    }
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'Rp 0';
    final number = int.tryParse(value.toString()) ?? 0;
    final formatted = number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTimeUtils.parseToWib(dateStr);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agt',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  String _formatDateTime(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final date = DateTimeUtils.parseToWib(dateStr);
      const months = [
        'Jan',
        'Feb',
        'Mar',
        'Apr',
        'Mei',
        'Jun',
        'Jul',
        'Agt',
        'Sep',
        'Okt',
        'Nov',
        'Des',
      ];
      final time =
          '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
      return '${date.day} ${months[date.month - 1]} ${date.year}, $time';
    } catch (_) {
      return dateStr;
    }
  }

  // FIX: mapping eksplisit semua status → label yang benar
  String _formatStatusText(String? status) {
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'menunggu_pembayaran':
        return 'Menunggu Pembayaran';
      case 'menunggu_konfirmasi':
        return 'Menunggu Konfirmasi';
      case 'dikonfirmasi':
        return 'Dikonfirmasi';
      case 'menunggu_dijemput':
        return 'Menunggu Dijemput';
      case 'sedang_dijemput':
        return 'Sedang Dijemput';
      case 'sudah_dijemput':
        return 'Sudah Dijemput';
      case 'washing':
        return 'Sedang Dicuci';
      case 'selesai_cuci':
        return 'Selesai Dicuci';
      case 'sedang_diantar':
        return 'Sedang Diantar';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        if (status == null || status.isEmpty) return '-';
        return status
            .split('_')
            .map(
              (w) => w.isEmpty
                  ? ''
                  : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}',
            )
            .join(' ');
    }
  }

  // FIX: deduplikasi timeline — buang entry dengan status + created_at yang identik
  List<Map<String, dynamic>> _deduplicatedTimeline() {
    final raw = _controller.timeline;
    final seen = <String>{};
    final result = <Map<String, dynamic>>[];
    for (final item in raw) {
      final key = '${item['status']}_${item['created_at']}';
      if (seen.contains(key)) continue;
      seen.add(key);
      result.add(item as Map<String, dynamic>);
    }
    return result;
  }

  // Step indicator — TANPA badge online/offline (dihapus sesuai permintaan)
  Widget _buildStepIndicator() {
    final currentPhase = _getPhaseIndex(_controller.status);
    final phases = _getPhases();
    final totalPhases = phases.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(totalPhases * 2 - 1, (index) {
          if (index.isOdd) {
            final lineIndex = index ~/ 2;
            final isActive = currentPhase > lineIndex;
            return Expanded(
              child: Container(
                height: 2,
                color: isActive ? AppColors.primaryBlue : Colors.grey.shade300,
              ),
            );
          }

          final stepIndex = index ~/ 2;
          final isCompleted = currentPhase > stepIndex;
          final isActive = currentPhase == stepIndex;
          final phase = phases[stepIndex];

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isActive ? 44 : 36,
                height: isActive ? 44 : 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted ? AppColors.primaryBlue : Colors.white,
                  border: Border.all(
                    color: isCompleted || isActive
                        ? AppColors.primaryBlue
                        : Colors.grey.shade300,
                    width: isActive ? 2 : 1.5,
                  ),
                ),
                child: Icon(
                  phase['icon'] as IconData,
                  color: isCompleted
                      ? Colors.white
                      : isActive
                      ? AppColors.primaryBlue
                      : Colors.grey.shade400,
                  size: isActive ? 22 : 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                phase['label'] as String,
                style: TextStyle(
                  fontSize: isActive ? 11 : 10,
                  color: isCompleted || isActive
                      ? AppColors.primaryBlue
                      : Colors.grey.shade400,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 4),
              Container(
                height: 2,
                width: 32,
                color: isActive ? AppColors.primaryBlue : Colors.transparent,
              ),
            ],
          );
        }),
      ),
    );
  }

  // Timeline — pakai _deduplicatedTimeline(), nama staff selalu ditampilkan
  Widget _buildTimeline() {
    final timeline = _deduplicatedTimeline();
    if (timeline.isEmpty) return const SizedBox.shrink();

    String getStatusLabel(String? status) {
      switch (status) {
        case 'pending':
          return 'Pesanan Masuk';
        case 'menunggu_pembayaran':
          return 'Menunggu Pembayaran';
        case 'menunggu_konfirmasi':
          return 'Bukti Bayar Dikirim';
        case 'dikonfirmasi':
          return 'Pembayaran Dikonfirmasi';
        case 'menunggu_dijemput':
          return 'Menunggu Dijemput';
        case 'sedang_dijemput':
          return 'Sedang Dijemput';
        case 'sudah_dijemput':
          return 'Sepatu Sudah Dijemput';
        case 'washing':
          return 'Sedang Dicuci';
        case 'selesai_cuci':
          return 'Pencucian Selesai';
        case 'sedang_diantar':
          return 'Sedang Diantar';
        case 'selesai':
          return 'Pesanan Selesai';
        case 'dibatalkan':
          return 'Pesanan Dibatalkan';
        default:
          return status ?? '-';
      }
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Riwayat Status',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 16),
          ...List.generate(timeline.length, (index) {
            final item = timeline[index];
            final isLast = index == timeline.length - 1;
            final status = item['status']?.toString();
            // FIX: coba beberapa kemungkinan key nama staff dari backend
            final namaStaff =
                (item['nama_staff'] ??
                        item['staff']?['nama'] ??
                        item['user']?['nama'] ??
                        item['staff']?['name'] ??
                        item['user']?['name'])
                    ?.toString();
            final color = isLast
                ? (status == 'dibatalkan' ? Colors.red : Colors.green)
                : Colors.grey.shade400;

            return IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Dot + garis vertikal
                  SizedBox(
                    width: 24,
                    child: Column(
                      children: [
                        Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(top: 3),
                          decoration: BoxDecoration(
                            color: isLast ? color : Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: color, width: 2),
                          ),
                        ),
                        if (!isLast)
                          Expanded(
                            child: Container(
                              width: 2,
                              color: Colors.grey.shade200,
                              margin: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Konten
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            getStatusLabel(status),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: color,
                            ),
                          ),
                          if (item['keterangan'] != null &&
                              item['keterangan'].toString().isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 2),
                              child: Text(
                                item['keterangan'].toString(),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          // FIX: nama staff selalu tampil jika ada
                          if (namaStaff != null && namaStaff.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.person_outline,
                                    size: 12,
                                    color: Colors.grey.shade500,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    namaStaff,
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              _formatDateTime(item['created_at']?.toString()),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildMapCard() {
    if (!_isOnline) return const SizedBox.shrink();

    final shopLat = _controller.shopLat;
    final shopLng = _controller.shopLng;
    final custLat = _controller.customerLat;
    final custLng = _controller.customerLng;

    final shopLocation = (shopLat != null && shopLng != null)
        ? LatLng(shopLat, shopLng)
        : null;
    final customerLocation = (custLat != null && custLng != null)
        ? LatLng(custLat, custLng)
        : null;

    if (shopLocation == null && customerLocation == null) {
      return const SizedBox.shrink();
    }

    final center = shopLocation ?? customerLocation!;
    final routePoints = _controller.routePoints;
    final polylinePoints = routePoints.isNotEmpty
        ? routePoints
        : (shopLocation != null && customerLocation != null)
        ? [shopLocation, customerLocation]
        : <LatLng>[];

    final markers = <Marker>[
      if (shopLocation != null)
        Marker(
          point: shopLocation,
          width: 44,
          height: 52,
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
      if (customerLocation != null)
        Marker(
          point: customerLocation,
          width: 44,
          height: 52,
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
    ];

    final allPoints = <LatLng>[
      ...polylinePoints,
      if (shopLocation != null) shopLocation,
      if (customerLocation != null) customerLocation,
    ];

    final mapController = MapController();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        height: 220,
        child: Stack(
          children: [
            FlutterMap(
              mapController: mapController,
              options: MapOptions(
                initialCenter: center,
                initialZoom: 14,
                minZoom: 11,
                maxZoom: 18,
                cameraConstraint: CameraConstraint.containCenter(
                  bounds: LatLngBounds(
                    const LatLng(-7.04472 - 0.27, 110.45639 - 0.27),
                    const LatLng(-7.04472 + 0.27, 110.45639 + 0.27),
                  ),
                ),
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
              ),
              children: [
                TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'carekicks',
                ),
                if (polylinePoints.isNotEmpty)
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: polylinePoints,
                        color: AppColors.primaryBlue,
                        strokeWidth: 5.0,
                      ),
                    ],
                  ),
                MarkerLayer(markers: markers),
              ],
            ),
            if (allPoints.length >= 2)
              Positioned(
                width: 0,
                height: 0,
                child: Builder(
                  builder: (context) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      try {
                        final bounds = LatLngBounds.fromPoints(allPoints);
                        mapController.fitCamera(
                          CameraFit.bounds(
                            bounds: bounds,
                            padding: const EdgeInsets.all(60),
                          ),
                        );
                      } catch (e) {
                        debugPrint('Map fit error: $e');
                      }
                    });
                    return const SizedBox.shrink();
                  },
                ),
              ),
            if (_controller.isRouting)
              const Positioned(
                top: 10,
                right: 10,
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentRejectionNotice() {
    final reason = _controller.paymentRejectReason?.trim();
    if (!_shouldShowPaymentRejectionNotice) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.info_outline, color: Colors.red.shade700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pembayaran ditolak',
                  style: TextStyle(
                    color: Colors.red.shade800,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  reason ?? '',
                  style: TextStyle(color: Colors.red.shade900, fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool get _shouldShowPaymentRejectionNotice {
    final reason = _controller.paymentRejectReason?.trim();
    return _controller.status == 'menunggu_pembayaran' &&
        reason != null &&
        reason.isNotEmpty;
  }

  Widget _buildRincianPesanan() {
    final items = _controller.detailItems;

    final biayaLayanan = items.fold<int>(0, (sum, item) {
      final value =
          double.tryParse(item['total_harga']?.toString() ?? '0') ?? 0;
      return sum + value.toInt();
    });

    final ongkir =
        int.tryParse((_controller.order?['total_ongkir'] ?? '0').toString()) ??
        0;
    final total = biayaLayanan + ongkir;
    final catatanPengiriman = _controller.order?['catatan_pengiriman']
        ?.toString();
    final cleanAddress = LocationUtils.cleanAddress(_controller.address);

    // FIX: hitung jarak khusus order online
    final distanceKm = _isOnline ? _calculateDistanceKm() : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Rincian Pesanan',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 12),
          _buildDetailRow('Tanggal', _formatDate(_controller.date)),
          // FIX: gunakan _formatStatusText yang sudah punya mapping eksplisit
          _buildDetailRow('Status', _formatStatusText(_controller.status)),
          _buildDetailRow(
            'Metode',
            _isOnline ? 'Online (Antar Jemput)' : 'Offline (Ke Toko)',
          ),
          if (_isOnline)
            _buildDetailRow(
              'Alamat',
              cleanAddress.isNotEmpty ? cleanAddress : '-',
            ),
          // FIX: tampilkan jarak (hanya untuk order online & jika koordinat tersedia)
          if (_isOnline && distanceKm != null)
            _buildDetailRow('Jarak', _formatDistance(distanceKm)),

          if (catatanPengiriman != null && catatanPengiriman.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.shade200),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 14,
                    color: Colors.orange.shade700,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Catatan: $catatanPengiriman',
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

          const Divider(height: 24),
          _buildDetailRow('Jumlah Item', '${items.length} item'),

          if (items.any(
            (item) =>
                item['catatan'] != null &&
                item['catatan'].toString().isNotEmpty,
          )) ...[
            const SizedBox(height: 4),
            const Text(
              'Catatan Sepatu:',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 6),
            ...items
                .where(
                  (item) =>
                      item['catatan'] != null &&
                      item['catatan'].toString().isNotEmpty,
                )
                .map(
                  (item) => Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '• ',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Expanded(
                          child: Text(
                            '${item['merk'] ?? '-'} '
                            '(${item['jenis_sepatu'] ?? '-'}): '
                            '${item['catatan']}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            const SizedBox(height: 8),
          ],

          _buildDetailRow('Biaya Layanan', _formatCurrency(biayaLayanan)),
          if (_isOnline)
            _buildDetailRow('Biaya Ongkir', _formatCurrency(ongkir)),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              Text(
                _formatCurrency(total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentButton() {
    final orderStatus = _controller.status;
    final paymentStatus = _controller.paymentStatus;

    // Cek apakah pesanan sudah diulas (dari backend atau state lokal setelah submit)
    // Asumsi backend mengirimkan flag 'is_reviewed', jika tidak ada, cukup andalkan _hasReviewedLocal
    final bool isReviewedBackend =
        _controller.order?['is_reviewed'] == true ||
        _controller.order?['is_reviewed'] == 1;
    final bool isReviewed = isReviewedBackend || _hasReviewedLocal;

    int? firstIdServices;
    if (_controller.items.isNotEmpty) {
      firstIdServices = int.tryParse(
        _controller.items.first['id_services']?.toString() ?? '',
      );
    }

    if (orderStatus == 'selesai') {
      if (isReviewed) {
        // --- TOMBOL JIKA SUDAH DIULAS ---
        return ElevatedButton.icon(
          onPressed: null, // Tombol dikunci (disabled)
          icon: const Icon(Icons.check_circle, color: AppColors.successGreen),
          label: const Text(
            'Ulasan Terkirim',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.green.shade50,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.green.shade300),
            ),
          ),
        );
      }

      // --- TOMBOL JIKA BELUM DIULAS ---
      return ElevatedButton.icon(
        onPressed: () async {
          // Tunggu hasil dari halaman ulasan
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TulisUlasanPage(
                token: widget.token,
                idOrders: int.tryParse(widget.orderId),
                idServices: firstIdServices,
              ),
            ),
          );

          // Jika result == true (berhasil kirim ulasan), update state agar tombol terkunci
          if (result == true) {
            setState(() {
              _hasReviewedLocal = true;
            });
          }
        },
        icon: const Icon(Icons.star_rate_rounded, color: Colors.white),
        label: const Text(
          'Beri Ulasan Layanan',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor:
              AppColors.primaryBlue, // <--- WARNA SUDAH DISESUAIKAN
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      );
    }

    // 2. Daftar status di mana pembayaran sudah dianggap lunas/sedang diproses
    //    (TAPI pesanan BELUM SELESAI)
    final sudahDiproses = [
      'dikonfirmasi',
      'menunggu_dijemput',
      'sedang_dijemput',
      'sudah_dijemput',
      'washing',
      'selesai_cuci',
      'sedang_diantar',
    ].contains(orderStatus);

    if (orderStatus == 'pending') {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.grey.shade200,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Menunggu Konfirmasi Admin',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (orderStatus == 'menunggu_pembayaran') {
      return ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PaymentPage(
                token: widget.token,
                orderId: widget.orderId,
                totalAmount: _controller.totalAmount,
                paymentDeadline: '',
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Bayar Sekarang',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (orderStatus == 'menunggu_konfirmasi' ||
        paymentStatus == 'menunggu_verifikasi') {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.orange.shade50,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.orange.shade300),
          ),
        ),
        child: Text(
          'Menunggu Verifikasi Pembayaran',
          style: TextStyle(
            color: Colors.orange.shade800,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // 3. Jika sudah diproses (tapi belum selesai), tampilkan tombol Pembayaran Lunas
    if (sudahDiproses) {
      return ElevatedButton(
        onPressed: null, // Disabled karena hanya sekadar info
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.green.shade50,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.green.shade300),
          ),
        ),
        child: const Text(
          'Pembayaran Lunas',
          style: TextStyle(
            color: Colors.green,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return const SizedBox.shrink();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_controller.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _controller.fetchDetailOrder(
                      token: widget.token,
                      orderId: widget.orderId,
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStepIndicator(),
                      const SizedBox(height: 16),

                      _buildPaymentRejectionNotice(),
                      if (_shouldShowPaymentRejectionNotice)
                        const SizedBox(height: 16),

                      _buildMapCard(),
                      if (_isOnline) const SizedBox(height: 16),

                      _buildTimeline(),
                      const SizedBox(height: 16),

                      // Produk
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Produk',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._controller.items.map((item) {
                              final namaLayanan =
                                  item['services']?['nama_layanan']
                                      ?.toString() ??
                                  '-';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child:
                                          item['foto_sebelum'] != null &&
                                              item['foto_sebelum']
                                                  .toString()
                                                  .trim()
                                                  .isNotEmpty
                                          ? Image.network(
                                              item['foto_sebelum']
                                                      .toString()
                                                      .contains(',')
                                                  ? item['foto_sebelum']
                                                        .toString()
                                                        .split(',')
                                                        .first
                                                        .trim()
                                                  : item['foto_sebelum']
                                                        .toString()
                                                        .trim(),
                                              width: 70,
                                              height: 70,
                                              fit: BoxFit.cover,
                                              errorBuilder: (_, __, ___) =>
                                                  _buildPlaceholderImage(),
                                            )
                                          : _buildPlaceholderImage(),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Align(
                                            alignment: Alignment.centerLeft,
                                            child: Container(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 10,
                                                    vertical: 4,
                                                  ),
                                              decoration: BoxDecoration(
                                                border: Border.all(
                                                  color: AppColors.primaryBlue
                                                      .withOpacity(0.5),
                                                ),
                                                borderRadius:
                                                    BorderRadius.circular(20),
                                              ),
                                              child: Text(
                                                namaLayanan,
                                                style: const TextStyle(
                                                  fontSize: 10,
                                                  color: AppColors.primaryBlue,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(height: 6),
                                          Text(
                                            '${item['merk'] ?? '-'} - ${item['jenis_sepatu'] ?? '-'}',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            'Warna: ${item['warna'] ?? '-'}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors.grey,
                                            ),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            _formatCurrency(
                                              item['total_harga'],
                                            ),
                                            style: const TextStyle(
                                              color: AppColors.primaryBlue,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      _buildRincianPesanan(),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),

              if (_isOnline)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: _buildPaymentButton(),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 13)),
          Flexible(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Icon(Icons.image_outlined, color: Colors.grey),
    );
  }
}
