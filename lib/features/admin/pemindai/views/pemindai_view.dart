import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import 'package:carekicks/core/network/api_service.dart';
import '../../../../core/utils/location_utils.dart';

const _brand = Color(0xFF1FB6C1);
const _brandDark = Color(0xFF0E8A93);
const _scanLine = Color(0xFF7CE7F1);
const _darkBlue = Color(0xFF2C3E50);
const _bgGray = Color(0xFFF4F6F8);
const _scanBoxSize = 260.0;

class PemindaiView extends StatefulWidget {
  const PemindaiView({super.key});

  @override
  State<PemindaiView> createState() => _PemindaiViewState();
}

class _PemindaiViewState extends State<PemindaiView> {
  int _tab = 2;
  bool isScanCompleted = false;
  bool _torchOn = false;

  final MobileScannerController _scannerController = MobileScannerController(
    torchEnabled: false,
    detectionSpeed: DetectionSpeed.normal,
  );

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _playFeedback() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) Vibration.vibrate(duration: 120, amplitude: 128);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _topBar(),
            Expanded(child: _viewfinder()),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  Widget _topBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
      color: Colors.white,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: _brand.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: const Text(
              'CK',
              style: TextStyle(color: _brand, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Care Kicks',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
              Text(
                'Admin Toko',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
          ),
          const Spacer(), // Ikon lonceng sudah dipastikan bersih dari sini
        ],
      ),
    );
  }

  Widget _viewfinder() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final scanRect = Rect.fromCenter(
          center: Offset(constraints.maxWidth / 2, constraints.maxHeight / 2),
          width: _scanBoxSize,
          height: _scanBoxSize,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            MobileScanner(
              controller: _scannerController,
              scanWindow: scanRect,
              onDetect: (capture) async {
                if (isScanCompleted) return;

                String? code;
                for (final barcode in capture.barcodes) {
                  final raw = barcode.rawValue?.trim();
                  if (raw != null && raw.isNotEmpty) {
                    code = raw;
                    break;
                  }
                }
                if (code == null) return;

                setState(() => isScanCompleted = true);
                _playFeedback();

                if (!mounted) return;
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (_) => const Center(
                    child: CircularProgressIndicator(color: _brand),
                  ),
                );

                final resultData = await ApiService.cekSepatu(code);
                if (mounted) Navigator.pop(context);

                if (resultData != null && resultData['success'] == true) {
                  _showDetailDialog({
                    ...resultData['data'],
                    'scanned_qr': code,
                  });
                } else {
                  _showErrorDialog(resultData?['message']);
                }
              },
            ),

            Positioned.fill(
              child: IgnorePointer(
                child: CustomPaint(
                  painter: _OverlayPainter(scanRect: scanRect),
                ),
              ),
            ),

            Positioned(
              top: 24,
              left: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black26,
                      blurRadius: 12,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(Icons.center_focus_strong, size: 20, color: _brand),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Arahkan kamera ke Kode QR pada label sepatu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Center(child: _ScannerFrame()),

            Positioned(
              bottom: 80,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: () async {
                    await _scannerController.toggleTorch();
                    setState(() => _torchOn = !_torchOn);
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _torchOn ? _brand : Colors.white.withOpacity(0.95),
                      boxShadow: const [
                        BoxShadow(
                          color: Colors.black38,
                          blurRadius: 12,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _torchOn ? Icons.flash_on : Icons.flash_off,
                      color: _torchOn ? Colors.white : _brand,
                      size: 30,
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showDetailDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DetailDialog(data: data),
    ).then((_) {
      if (mounted) setState(() => isScanCompleted = false);
    });
  }

  void _showErrorDialog(String? errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: const BoxDecoration(
                  color: Color(0xFFFFEBEE),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.search_off_rounded,
                  color: Color(0xFFE74C3C),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Data Tidak Ditemukan',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: _darkBlue,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage ??
                    'QR Code yang dipindai tidak terdaftar di sistem.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.black54),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _brand,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Scan Lagi',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ).then((_) {
      if (mounted) setState(() => isScanCompleted = false);
    });
  }

  Widget _bottomNav() {
    final items = const [
      (Icons.dashboard_outlined, 'Dashboard'),
      (Icons.assignment_outlined, 'Antrean'),
      (Icons.qr_code_scanner, 'Pemindai'),
      (Icons.inventory_2_outlined, 'Inventaris'),
      (Icons.local_shipping_outlined, 'Logistik'),
    ];
    final bottomInset = MediaQuery.of(context).padding.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(8, 10, 8, (bottomInset + 16).clamp(24, 60)),
      child: Row(
        children: List.generate(items.length, (i) {
          final active = i == _tab;
          return Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _tab = i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: active ? _brand.withOpacity(0.10) : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      items[i].$1,
                      size: 22,
                      color: active ? _brand : Colors.grey.shade500,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      items[i].$2,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: active ? _brand : Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}

// =============================================================================
// DIALOG DETAIL (1 QR = 1 SEPATU SPESIFIK)
// =============================================================================
class _DetailDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  const _DetailDialog({required this.data});

  @override
  State<_DetailDialog> createState() => _DetailDialogState();
}

class _DetailDialogState extends State<_DetailDialog> {
  late String currentStatus;
  bool isUpdating = false;

  late final String kodeOrder;
  late final String namaCustomer;
  late final bool isDelivery;
  late final String? alamat;
  late final Map<String, dynamic> layananSpesifik;
  late final String catatan;

  @override
  void initState() {
    super.initState();
    final d = widget.data;

    kodeOrder = d['kode_order']?.toString().trim() ?? '-';
    currentStatus = d['status_order']?.toString().trim() ?? 'antrean';
    namaCustomer = d['customers']?['nama']?.toString() ?? 'Pelanggan';

    final metode =
        d['metode_pengambilan']?.toString().toLowerCase().trim() ?? '';
    isDelivery = metode == 'delivery';

    // SISTEM CADANGAN ALAMAT: Membaca aman dari root orders maupun customers fallback
    var alamatRaw = d['alamat_pengantaran']?.toString().trim();
    if (alamatRaw == null || alamatRaw.isEmpty || alamatRaw == 'null') {
      alamatRaw = d['customers']?['alamat']?.toString().trim();
    }
    alamat = (alamatRaw != null && alamatRaw.isNotEmpty && alamatRaw != 'null')
        ? alamatRaw
        : null;

    final List rawList = d['detail_orders'] as List? ?? [];
    final scannedQr = d['scanned_qr']?.toString().trim() ?? '';

    Map<String, dynamic>? matchItem;
    for (var item in rawList) {
      if (item is Map) {
        final itemQr = item['link_qr']?.toString().trim();
        if (itemQr != null && itemQr == scannedQr) {
          matchItem = Map<String, dynamic>.from(item);
          break;
        }
      }
    }

    if (matchItem == null && rawList.isNotEmpty) {
      matchItem = Map<String, dynamic>.from(rawList.first);
    }

    layananSpesifik = matchItem ?? {};

    final catRaw = layananSpesifik['catatan']?.toString().trim() ?? '';
    catatan = catRaw.isEmpty ? 'Tidak ada catatan khusus.' : catRaw;
  }

  int _stepIndex(String status) {
    final s = status.toLowerCase();
    if (s == 'pending' || s == 'antrean') return 0;
    if (s == 'dicuci' || s == 'washing') return 1;
    return 2;
  }

  ({
    String label,
    String? nextStatus,
    IconData icon,
    String confirmTitle,
    String confirmMsg,
    bool enabled,
  })
  get _action {
    final s = currentStatus.toLowerCase();
    if (s == 'pending' || s == 'antrean') {
      return (
        label: 'Mulai Cuci',
        nextStatus: 'dicuci',
        icon: Icons.cleaning_services_rounded,
        confirmTitle: 'Mulai Proses Cuci Sepatu?',
        confirmMsg: 'Status pesanan akan diubah menjadi Dicuci. Lanjutkan?',
        enabled: true,
      );
    } else if (s == 'dicuci' || s == 'washing') {
      return (
        label: 'Selesai Cuci',
        nextStatus: 'siap_ambil',
        icon: Icons.task_alt_rounded,
        confirmTitle: 'Selesaikan Proses Cuci?',
        confirmMsg:
            'Pastikan sepatu sudah bersih, kering, dan siap dikemas sebelum melanjutkan.',
        enabled: true,
      );
    } else {
      return (
        label: 'Pesanan Selesai Di-scan',
        nextStatus: null,
        icon: Icons.verified_rounded,
        confirmTitle: '',
        confirmMsg: '',
        enabled: false,
      );
    }
  }

  Future<bool> _konfirmasi({
    required String title,
    required String message,
    required IconData icon,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: _brand.withOpacity(0.12),
              child: Icon(icon, color: _brand, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: Colors.black54),
            ),
            const SizedBox(height: 16),
          ],
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade300),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Batal',
                      style: TextStyle(color: Colors.black54),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _brand,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ya, Lanjutkan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return result ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final act = _action;
    final stepLabels = ['Pending', 'Proses', 'Selesai'];
    final activeStep = _stepIndex(currentStatus);

    final namaLayanan =
        layananSpesifik['services']?['nama_layanan']?.toString() ??
        'Layanan Umum';
    final jenisSepatu = layananSpesifik['jenis_sepatu']?.toString() ?? '-';
    final merkSepatu = layananSpesifik['merk']?.toString() ?? '';
    final warnaSepatu = layananSpesifik['warna']?.toString() ?? '';

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: _bgGray,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [_brand, _brandDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.receipt_long_rounded,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'Detail Pesanan',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        namaCustomer,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.qr_code_2,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '#$kodeOrder',
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _StatusChip(status: currentStatus, light: true),
                    ],
                  ),
                ],
              ),
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        children: List.generate(stepLabels.length, (i) {
                          final passed = i <= activeStep;
                          final current = i == activeStep;
                          final last = i == stepLabels.length - 1;
                          return Expanded(
                            flex: last ? 0 : 1,
                            child: Row(
                              children: [
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: passed ? _brand : Colors.white,
                                        border: Border.all(
                                          color: passed
                                              ? _brand
                                              : Colors.grey.shade300,
                                          width: current ? 3.5 : 1.5,
                                        ),
                                      ),
                                      child: Center(
                                        child: passed
                                            ? const Icon(
                                                Icons.check,
                                                size: 12,
                                                color: Colors.white,
                                              )
                                            : Container(
                                                width: 4,
                                                height: 4,
                                                decoration: const BoxDecoration(
                                                  color: Colors.grey,
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      stepLabels[i],
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: current
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: current
                                            ? _brand
                                            : (passed
                                                  ? _darkBlue
                                                  : Colors.grey),
                                      ),
                                    ),
                                  ],
                                ),
                                if (!last)
                                  Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(
                                        bottom: 14,
                                      ),
                                      child: Container(
                                        height: 3,
                                        color: i < activeStep
                                            ? _brand
                                            : Colors.grey.shade200,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                      ),
                    ),
                    const SizedBox(height: 14),

                    _DeliveryBanner(isDelivery: isDelivery, alamat: alamat),
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.cleaning_services_rounded,
                                  size: 14,
                                  color: _darkBlue,
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'LAYANAN PESANAN KARTU QR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _darkBlue,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Divider(height: 1),
                          Padding(
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _brand.withOpacity(0.08),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.check_circle_outline,
                                    color: _brand,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        namaLayanan,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: _darkBlue,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Merk: $merkSepatu\nJenis: $jenisSepatu\nWarna: ${warnaSepatu.isEmpty ? "-" : warnaSepatu}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          height: 1.3,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EBE1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.notes,
                                size: 14,
                                color: Color(0xFF8D6E63),
                              ),
                              SizedBox(width: 6),
                              Text(
                                'CATATAN KHUSUS SEPATU',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF8D6E63),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            catatan,
                            style: const TextStyle(
                              color: Color(0xFF795548),
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(24),
                  bottomRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 8,
                    offset: Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 50,
                      child: ElevatedButton.icon(
                        onPressed: (act.enabled && !isUpdating)
                            ? () async {
                                final yakin = await _konfirmasi(
                                  title: act.confirmTitle,
                                  message: act.confirmMsg,
                                  icon: act.icon,
                                );
                                if (!yakin || !mounted) return;
                                setState(() => isUpdating = true);
                                final result =
                                    await ApiService.updateStatusPesanan(
                                      kodeOrder,
                                      act.nextStatus!,
                                    );
                                if (!mounted) return;
                                if (result != null &&
                                    result['success'] == true) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Informasi aktivitas pesanan berhasil diperbarui!',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  setState(() => isUpdating = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Gagal memperbarui status order.',
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            : null,
                        icon: isUpdating
                            ? const SizedBox.shrink()
                            : Icon(act.icon, color: Colors.white),
                        label: isUpdating
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : Text(
                                act.label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _darkBlue,
                          disabledBackgroundColor: Colors.grey.shade400,
                          disabledForegroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverlayPainter extends CustomPainter {
  final Rect scanRect;
  _OverlayPainter({required this.scanRect});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path()
      ..addRect(Offset.zero & size)
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(16)))
      ..fillType = PathFillType.evenOdd;
    canvas.drawPath(path, Paint()..color = Colors.black.withOpacity(0.55));
  }

  @override
  bool shouldRepaint(covariant _OverlayPainter old) => old.scanRect != scanRect;
}

class _StatusChip extends StatelessWidget {
  final String status;
  final bool light;
  const _StatusChip({required this.status, this.light = false});

  @override
  Widget build(BuildContext context) {
    final s = status.toLowerCase();
    Color bg = Colors.blue.shade50;
    Color fg = _brand;
    IconData icon = Icons.hourglass_top_rounded;

    if (s == 'pending' || s == 'antrean') {
      bg = Colors.blue.shade50;
      fg = _brand;
      icon = Icons.hourglass_top_rounded;
    } else if (s == 'dicuci' || s == 'washing') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
      icon = Icons.cleaning_services_rounded;
    } else if (s == 'siap_ambil' || s == 'selesai') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      icon = Icons.task_alt_rounded;
    } else if (s == 'sedang diantar' || s == 'diantar' || s == 'delivered') {
      bg = Colors.purple.shade50;
      fg = Colors.purple.shade700;
      icon = Icons.local_shipping_rounded;
    } else if (s == 'selesai diantar' || s == 'diambil') {
      bg = Colors.teal.shade50;
      fg = Colors.teal.shade700;
      icon = Icons.verified_rounded;
    }

    if (light) {
      bg = Colors.white;
      fg = _brandDark;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: fg),
          const SizedBox(width: 4),
          Text(
            status.toUpperCase().replaceAll('_', ' '),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeliveryBanner extends StatelessWidget {
  final bool isDelivery;
  final String? alamat;
  const _DeliveryBanner({required this.isDelivery, this.alamat});

  @override
  Widget build(BuildContext context) {
    final color = isDelivery ? const Color(0xFFE67E22) : _brand;
    final bg = isDelivery ? const Color(0xFFFFF7EE) : const Color(0xFFE8F7F8);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(
            isDelivery ? Icons.local_shipping_rounded : Icons.store_rounded,
            color: color,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isDelivery
                      ? 'Perlu Diantar ke Alamat Pelanggan'
                      : 'Pickup di Toko Mandiri',
                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
                Text(
                  isDelivery
                      ? (LocationUtils.cleanAddress(alamat).isNotEmpty
                            ? LocationUtils.cleanAddress(alamat)
                            : 'Alamat tidak ditemukan / Belum diisi')
                      : 'Ambil di Toko',
                  style: TextStyle(
                    fontSize: 12,
                    color: (isDelivery && alamat == null)
                        ? Colors.orange.shade400
                        : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ScannerFrame extends StatefulWidget {
  const _ScannerFrame();

  @override
  State<_ScannerFrame> createState() => _ScannerFrameState();
}

class _ScannerFrameState extends State<_ScannerFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  );

  @override
  void initState() {
    super.initState();
    _c.repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = _scanBoxSize;
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          _corner(Alignment.topLeft, 0),
          _corner(Alignment.topRight, 1),
          _corner(Alignment.bottomRight, 2),
          _corner(Alignment.bottomLeft, 3),
          AnimatedBuilder(
            animation: _c,
            builder: (_, __) => Positioned(
              left: 20,
              right: 20,
              top: 20 + (_c.value * (size - 40)),
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: _scanLine,
                  boxShadow: [
                    BoxShadow(
                      color: _scanLine.withOpacity(0.8),
                      blurRadius: 15,
                      spreadRadius: 1,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _corner(Alignment a, int rotate) {
    return Align(
      alignment: a,
      child: Transform.rotate(
        angle: rotate * 1.5708,
        child: CustomPaint(size: const Size(32, 32), painter: _CornerPainter()),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(const Offset(0, 0), Offset(size.width, 0), p);
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), p);
  }

  @override
  bool shouldRepaint(covariant _CornerPainter _) => false;
}
