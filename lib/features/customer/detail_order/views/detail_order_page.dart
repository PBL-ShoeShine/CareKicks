import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../../../../../core/constants/app_colors.dart';
import '../controllers/detail_order_controller.dart';
import '../../payment/views/payment_page.dart';

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

  // REVISI LOGIKA: Step Indicator Anti-Tabrakan
  int _getPhaseIndex(String? status, String? paymentStatus) {
    final isPaid =
        paymentStatus == 'paid' ||
        paymentStatus == 'lunas' ||
        paymentStatus == 'selesai';

    // Daftar status pesanan yang menandakan sudah lewat tahap awal
    final activeStatuses = [
      'menunggu_jemput',
      'sedang_dijemput',
      'diterima_toko',
      'dicuci',
      'diproses',
      'siap_diantar',
      'sedang_diantar',
      'diantar',
      'selesai',
    ];
    final isAlreadyProcessed = activeStatuses.contains(status);

    // Kalau belum lunas DAN pesanan belum diproses admin, tahan di fase 0 (Diterima)
    if (!isPaid && !isAlreadyProcessed) {
      return 0;
    }

    // Jika sudah lunas ATAU pesanan sudah diproses, jalankan indikator normal
    switch (status) {
      case 'menunggu_konfirmasi':
        return 0;
      case 'menunggu_jemput':
      case 'sedang_dijemput':
        return 1;
      case 'diterima_toko':
      case 'dicuci':
      case 'diproses':
        return 2;
      case 'siap_diantar':
      case 'sedang_diantar':
      case 'diantar':
      case 'selesai':
        return 3;
      default:
        return 0;
    }
  }

  String _getPhaseLabel(int index) {
    switch (index) {
      case 0:
        return 'Diterima';
      case 1:
        return 'Dijemput';
      case 2:
        return 'Di Toko';
      case 3:
        return 'Selesai';
      default:
        return '';
    }
  }

  IconData _getPhaseIcon(int index) {
    switch (index) {
      case 0:
        return Icons.receipt_long;
      case 1:
        return Icons.directions_bike;
      case 2:
        return Icons.store;
      case 3:
        return Icons.check_circle;
      default:
        return Icons.circle;
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
      final date = DateTime.parse(dateStr);
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

  String _formatStatusText(String? status) {
    if (status == null || status.isEmpty) return '-';
    return status
        .split('_')
        .map((word) {
          if (word.isEmpty) return '';
          return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
        })
        .join(' ');
  }

  Widget _buildStepIndicator() {
    final currentPhase = _getPhaseIndex(
      _controller.status,
      _controller.paymentStatus,
    );

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: List.generate(4 * 2 - 1, (index) {
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

          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isActive ? 44 : 36,
                height: isActive ? 44 : 36,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isCompleted || isActive
                      ? Colors.white
                      : Colors.grey.shade100,
                  border: Border.all(
                    color: isCompleted || isActive
                        ? AppColors.primaryBlue
                        : Colors.grey.shade300,
                    width: isActive ? 2 : 1.5,
                  ),
                ),
                child: Icon(
                  _getPhaseIcon(stepIndex),
                  color: isCompleted || isActive
                      ? AppColors.primaryBlue
                      : Colors.grey.shade400,
                  size: isActive ? 22 : 18,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _getPhaseLabel(stepIndex),
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

  Widget _buildMapCard() {
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
          _buildDetailRow(
            'Status Pesanan',
            _formatStatusText(_controller.status),
          ),
          _buildDetailRow('Alamat', _controller.address ?? '-'),

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
                      'Catatan pengiriman: $catatanPengiriman',
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

  // REVISI LOGIKA: Button Pembayaran Anti-Tabrakan
  Widget _buildPaymentButton() {
    final orderStatus = _controller.status;
    final paymentStatus = _controller.paymentStatus;

    final isPaid =
        paymentStatus == 'paid' ||
        paymentStatus == 'lunas' ||
        paymentStatus == 'selesai';

    final activeStatuses = [
      'menunggu_jemput',
      'sedang_dijemput',
      'diterima_toko',
      'dicuci',
      'diproses',
      'siap_diantar',
      'sedang_diantar',
      'diantar',
      'selesai',
    ];
    final isAlreadyProcessed = activeStatuses.contains(orderStatus);

    if (orderStatus == 'menunggu_konfirmasi') {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.grey.shade300,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: const Text(
          'Menunggu Konfirmasi Order',
          style: TextStyle(
            color: Colors.grey,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    // LOGIKA KUNCI: Jika sudah lunas ATAU pesanan sudah diproses admin (bypass validasi)
    if (isPaid || isAlreadyProcessed) {
      return ElevatedButton(
        onPressed: null,
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
    } else if (paymentStatus == 'menunggu_verifikasi') {
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
    } else {
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
                      _buildMapCard(),
                      const SizedBox(height: 16),

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
                                      child: item['foto_sebelum'] != null
                                          ? Image.network(
                                              item['foto_sebelum'],
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
