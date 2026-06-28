import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import 'package:visibility_detector/visibility_detector.dart';
import 'package:carekicks/core/network/api_service.dart';
import '../../../../core/constants/app_colors.dart';
import 'package:carekicks/features/admin/profile/views/profile_page.dart';
import '../../../../core/utils/location_utils.dart';

const _scanLine = Color(0xFF7CE7F1);
const _textColor = Color(0xFF334155);
const _bgGray = Color(0xFFF8F9FA);
const _scanBoxSize = 260.0;

class ScannerPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const ScannerPage({super.key, required this.token, required this.user});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with WidgetsBindingObserver {
  bool isScanCompleted = false;
  bool _torchOn = false;
  bool _isCameraActive = false;

  late MobileScannerController _scannerController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _scannerController = MobileScannerController(
      torchEnabled: false,
      detectionSpeed: DetectionSpeed.normal,
      autoStart: false,
    );
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _startCamera() async {
    if (!_isCameraActive) {
      try {
        await _scannerController.start();
        if (mounted) {
          setState(() {
            _isCameraActive = true;
            isScanCompleted = false;
          });
        }
      } catch (_) {}
    }
  }

  Future<void> _stopCamera() async {
    if (_isCameraActive) {
      try {
        await _scannerController.stop();
        if (mounted) {
          setState(() {
            _isCameraActive = false;
            _torchOn = false;
          });
        }
      } catch (_) {}
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      if (_isCameraActive) {
        _startCamera();
      }
    }
  }

  Future<void> _playFeedback() async {
    try {
      final hasVibrator = await Vibration.hasVibrator() ?? false;
      if (hasVibrator) Vibration.vibrate(duration: 120, amplitude: 128);
    } catch (_) {}
  }

  String? _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  dynamic _userShopValue(String key) {
    try {
      final shop = widget.user['shop'];
      if (shop is Map) return shop[key];
    } catch (_) {}
    return null;
  }

  String get _shopName {
    return _firstString([
          _userShopValue('nama_toko'),
          _userShopValue('nm_toko'),
          widget.user['nama_toko'],
          widget.user['nm_toko'],
        ]) ??
        'Toko Sepatu';
  }

  String get _roleLabel {
    final rawRole = _firstString([
      widget.user['role_label'],
      widget.user['nama_role'],
      widget.user['jenis_role'],
      widget.user['role'],
    ]);

    if (rawRole == null || rawRole.isEmpty) return 'Admin Shoes Clean';

    switch (rawRole.toLowerCase()) {
      case 'shops_admin':
        return 'Admin Shoes Clean';
      case 'staff':
        return 'Staff Toko';
      case 'customer':
        return 'Customer';
      default:
        try {
          return rawRole
              .replaceAll('_', ' ')
              .split(' ')
              .where((word) => word.isNotEmpty)
              .map((word) => word[0].toUpperCase() + word.substring(1))
              .join(' ');
        } catch (_) {
          return rawRole;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return VisibilityDetector(
      key: const Key('scanner_page_visibility_key'),
      onVisibilityChanged: (visibilityInfo) {
        final visiblePercentage = visibilityInfo.visibleFraction * 100;
        if (visiblePercentage < 10) {
          _stopCamera();
        } else {
          _startCamera();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Column(
            children: [
              _topBar(),
              Expanded(child: _viewfinder()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _topBar() {
    final shopName = _shopName;
    final roleLabel = _roleLabel;
    final String? userPhotoUrl = widget.user['foto']?.toString().trim();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                _stopCamera();
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ProfilePage(token: widget.token, user: widget.user),
                  ),
                ).then((_) => _startCamera());
              },
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: ClipOval(
                      child:
                          (userPhotoUrl != null &&
                              userPhotoUrl.isNotEmpty &&
                              userPhotoUrl != 'null')
                          ? Image.network(
                              userPhotoUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                    child: Text(
                                      shopName.isNotEmpty
                                          ? shopName[0].toUpperCase()
                                          : 'C',
                                      style: const TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ),
                            )
                          : Center(
                              child: Text(
                                shopName.isNotEmpty
                                    ? shopName[0].toUpperCase()
                                    : 'C',
                                style: const TextStyle(
                                  color: AppColors.primaryBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          shopName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: _textColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          roleLabel,
                          style: const TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
            if (_isCameraActive)
              MobileScanner(
                controller: _scannerController,
                scanWindow: scanRect,
                onDetect: (capture) async {
                  if (isScanCompleted || !_isCameraActive) return;

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
                      child: CircularProgressIndicator(
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  );

                  // --- PERBAIKAN: MEMBAWA TOKEN SAAT SCAN QR ---
                  final resultData = await ApiService.cekSepatu(
                    widget.token,
                    code,
                  );

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
              )
            else
              const Center(
                child: CircularProgressIndicator(color: AppColors.primaryBlue),
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.center_focus_strong,
                      size: 20,
                      color: AppColors.primaryBlue,
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Arahkan kamera ke Kode QR pada label sepatu',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: _textColor,
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
                    if (_isCameraActive) {
                      await _scannerController.toggleTorch();
                      setState(() => _torchOn = !_torchOn);
                    }
                  },
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _torchOn
                          ? AppColors.primaryBlue
                          : Colors.white.withOpacity(0.95),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.15),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      _torchOn ? Icons.flash_on : Icons.flash_off,
                      color: _torchOn ? Colors.white : AppColors.primaryBlue,
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
      builder: (_) => _DetailDialog(
        data: data,
        user: widget.user,
        token: widget.token, // --- TOKEN DI-PASSING KE DIALOG ---
      ),
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
                  color: _textColor,
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
                    backgroundColor: AppColors.primaryBlue,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'Scan Lagi',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
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
}

// =============================================================================
// DIALOG DETAIL
// =============================================================================
class _DetailDialog extends StatefulWidget {
  final Map<String, dynamic> data;
  final Map<String, dynamic> user;
  final String token; // --- VARIABEL UNTUK TOKEN ---

  const _DetailDialog({
    required this.data,
    required this.user,
    required this.token,
  });

  @override
  State<_DetailDialog> createState() => _DetailDialogState();
}

class _DetailDialogState extends State<_DetailDialog> {
  late String currentStatus;
  bool isUpdating = false;

  late final String kodeOrder;
  late final String namaCustomer;
  late final String namaStaff;
  late final String metodeOrder;
  late final bool isDelivery;
  late final bool isOnline;
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
    metodeOrder = d['metode_order']?.toString().toLowerCase().trim() ?? 'online';

    namaStaff =
        widget.user['nama'] ?? widget.user['username'] ?? 'Staff / Admin';
    isOnline = d['metode_order']?.toString().toLowerCase().trim() == 'online';

    var alamatRaw = d['alamat_pengantaran']?.toString().trim();
    if (alamatRaw == null || alamatRaw.isEmpty || alamatRaw == 'null') {
      alamatRaw = d['customer_alamat']?.toString().trim();
    }
    if (alamatRaw == null || alamatRaw.isEmpty || alamatRaw == 'null') {
      alamatRaw = d['customers']?['alamat']?.toString().trim();
    }

    alamat = (alamatRaw != null && alamatRaw.isNotEmpty && alamatRaw != 'null')
        ? alamatRaw
        : null;

    final metode =
        d['metode_pengambilan']?.toString().toLowerCase().trim() ?? '';
    isDelivery = (metode == 'delivery') || (alamat != null);

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
    if (s == 'menunggu_dijemput' || s == 'sedang_dijemput' || s == 'sudah_dijemput') return 0;
    if (s == 'dikonfirmasi') return 0;
    if (s == 'washing') return 1;
    if (s == 'selesai_cuci' || s == 'sedang_diantar') return 2;
    if (s == 'selesai') return 3;
    return 0;
  }

  bool get _isOffline => metodeOrder == 'offline';

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

    if (s == 'washing' || s == 'dicuci') {
      return (
        label: 'Selesai Cuci',
        nextStatus: 'selesai_cuci',
        icon: Icons.task_alt_rounded,
        confirmTitle: 'Selesaikan Proses Cuci?',
        confirmMsg:
            'Pastikan sepatu sudah bersih, kering, dan siap dikemas. Lanjutkan?',
        enabled: true,
      );
    } else if (s == 'selesai_cuci') {
      return (
        label: 'Telah Selesai Dicuci',
        nextStatus: null,
        icon: Icons.verified_rounded,
        confirmTitle: '',
        confirmMsg: '',
        enabled: false,
      );
    } else if ([
      'sedang_diantar',
      'diantar',
      'delivered',
      'selesai',
      'dibatalkan',
    ].contains(s)) {
      return (
        label: 'Pesanan Telah Selesai',
        nextStatus: null,
        icon: Icons.check_circle_rounded,
        confirmTitle: '',
        confirmMsg: '',
        enabled: false,
      );
    } else if (s == 'sudah_dijemput') {
      return (
        label: 'Mulai Cuci',
        nextStatus: 'washing',
        icon: Icons.cleaning_services_rounded,
        confirmTitle: 'Mulai Proses Cuci Sepatu?',
        confirmMsg:
            'Status pesanan akan diubah menjadi SEDANG DICUCI. Lanjutkan?',
        enabled: true,
      );
    }

    // Offline flow
    if (_isOffline) {
      if (s == 'dikonfirmasi') {
        return (
          label: 'Mulai Cuci',
          nextStatus: 'washing',
          icon: Icons.cleaning_services_rounded,
          confirmTitle: 'Mulai Proses Cuci Sepatu?',
          confirmMsg: 'Status pesanan akan diubah menjadi Dicuci. Lanjutkan?',
          enabled: true,
        );
      } else if (s == 'washing') {
        return (
          label: 'Selesai Cuci',
          nextStatus: 'selesai',
          icon: Icons.task_alt_rounded,
          confirmTitle: 'Selesaikan Proses Cuci?',
          confirmMsg: 'Pastikan sepatu sudah bersih, kering, dan siap dikemas.',
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

    // Online flow
    switch (s) {
      case 'menunggu_dijemput':
        return (
          label: 'Mulai Jemput',
          nextStatus: 'sedang_dijemput',
          icon: Icons.delivery_dining_rounded,
          confirmTitle: 'Mulai Penjemputan?',
          confirmMsg: 'Staff akan diarahkan untuk menjemput sepatu ke alamat pelanggan.',
          enabled: true,
        );
      case 'sedang_dijemput':
        return (
          label: 'Sepatu Dijemput',
          nextStatus: 'sudah_dijemput',
          icon: Icons.inventory_2_rounded,
          confirmTitle: 'Konfirmasi Penjemputan?',
          confirmMsg: 'Pastikan sepatu sudah diterima staff.',
          enabled: true,
        );
      case 'sudah_dijemput':
        return (
          label: 'Mulai Cuci',
          nextStatus: 'washing',
          icon: Icons.cleaning_services_rounded,
          confirmTitle: 'Mulai Proses Cuci Sepatu?',
          confirmMsg: 'Status pesanan akan diubah menjadi Dicuci. Lanjutkan?',
          enabled: true,
        );
      case 'washing':
        return (
          label: 'Selesai Cuci',
          nextStatus: 'selesai_cuci',
          icon: Icons.task_alt_rounded,
          confirmTitle: 'Selesaikan Proses Cuci?',
          confirmMsg: 'Pastikan sepatu sudah bersih, kering, dan siap dikemas sebelum melanjutkan.',
          enabled: true,
        );
      case 'selesai_cuci':
        return (
          label: 'Mulai Antar',
          nextStatus: 'sedang_diantar',
          icon: Icons.local_shipping_rounded,
          confirmTitle: 'Mulai Pengantaran?',
          confirmMsg: 'Staff akan diarahkan untuk mengantar sepatu ke pelanggan.',
          enabled: true,
        );
      case 'sedang_diantar':
        return (
          label: 'Selesaikan Order',
          nextStatus: 'selesai',
          icon: Icons.verified_rounded,
          confirmTitle: 'Selesaikan Pesanan?',
          confirmMsg: 'Pastikan sepatu sudah diterima oleh pelanggan.',
          enabled: true,
        );
      default:
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
              backgroundColor: AppColors.primaryBlue.withOpacity(0.12),
              child: Icon(icon, color: AppColors.primaryBlue, size: 32),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: _textColor,
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
                      backgroundColor: AppColors.primaryBlue,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Ya',
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
    final stepLabels = ['Pengambilan', 'Cuci', 'Pengantaran', 'Selesai'];
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
                color: AppColors.primaryBlue,
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

                  // NAMA PELANGGAN
                  Row(
                    children: [
                      const Icon(
                        Icons.person_outline,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pelanggan: $namaCustomer',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // NAMA STAFF
                  Row(
                    children: [
                      const Icon(
                        Icons.badge_outlined,
                        color: Colors.white70,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Diproses oleh: $namaStaff',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),
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
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(stepLabels.length, (i) {
                          final passed = i <= activeStep;
                          final current = i == activeStep;

                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (i > 0)
                                Container(
                                  width: 28,
                                  height: 2,
                                  margin: const EdgeInsets.only(bottom: 16),
                                  decoration: BoxDecoration(
                                    color: i <= activeStep
                                        ? AppColors.primaryBlue
                                        : Colors.grey.shade200,
                                    borderRadius: BorderRadius.circular(1),
                                  ),
                                ),
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: passed
                                          ? AppColors.primaryBlue
                                          : Colors.white,
                                      border: Border.all(
                                        color: passed
                                            ? AppColors.primaryBlue
                                            : Colors.grey.shade300,
                                        width: current ? 3.5 : 1.5,
                                      ),
                                    ),
                                    child: Center(
                                      child: passed
                                          ? const Icon(
                                              Icons.check,
                                              size: 13,
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
                                  const SizedBox(height: 4),
                                  Text(
                                    stepLabels[i],
                                    textAlign: TextAlign.center,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: current
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: current
                                          ? AppColors.primaryBlue
                                          : (passed
                                                ? _textColor
                                                : Colors.grey),
                                    ),
                                  ),
                                ],
                              ),
                            ],
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
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.cleaning_services_rounded,
                                  size: 14,
                                  color: _textColor,
                                ),
                                SizedBox(width: 6),
                                Text(
                                  'LAYANAN PESANAN KARTU QR',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: _textColor,
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
                                    color: AppColors.primaryBlue.withOpacity(
                                      0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  alignment: Alignment.center,
                                  child: const Icon(
                                    Icons.check_circle_outline,
                                    color: AppColors.primaryBlue,
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
                                          color: _textColor,
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
                        color: const Color(0xFFF2FAFA),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.15),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(
                                Icons.notes,
                                size: 14,
                                color: AppColors.primaryBlue,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'CATATAN KHUSUS SEPATU',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primaryBlue,
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            catatan,
                            style: const TextStyle(
                              color: Color(0xFF475569),
                              height: 1.4,
                              fontSize: 13,
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
                        // --- PERBAIKAN: API DIPANGGIL DENGAN TOKEN ---
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
                                      token: widget.token, // KUNCI UTAMA
                                      kodeOrder: kodeOrder,
                                      statusBaru: act.nextStatus!,
                                    );

                                if (!mounted) return;

                                if (result != null &&
                                    result['success'] == true) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Sepatu berhasil ditandai ${act.nextStatus!.replaceAll('_', ' ').toUpperCase()}!',
                                      ),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                } else {
                                  setState(() => isUpdating = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        result?['message'] ??
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
                          backgroundColor: AppColors.primaryDark,
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
    Color fg = AppColors.primaryBlue;
    IconData icon = Icons.hourglass_top_rounded;

    if (s == 'pending' ||
        s == 'menunggu_pembayaran' ||
        s == 'menunggu_konfirmasi' ||
        s == 'antrean') {
      bg = Colors.blue.shade50;
      fg = AppColors.primaryBlue;
      icon = Icons.hourglass_top_rounded;
    } else if (s == 'menunggu_dijemput') {
      bg = Colors.blue.shade50;
      fg = AppColors.primaryBlue;
      icon = Icons.hourglass_top_rounded;
    } else if (s == 'dikonfirmasi' || s == 'sedang_dijemput') {
      bg = Colors.amber.shade50;
      fg = Colors.amber.shade800;
      icon = Icons.directions_run_rounded;
    } else if (s == 'sudah_dijemput') {
      bg = Colors.indigo.shade50;
      fg = Colors.indigo.shade700;
      icon = Icons.inventory_2_rounded;
    } else if (s == 'washing' || s == 'dicuci') {
      bg = Colors.orange.shade50;
      fg = Colors.orange.shade800;
      icon = Icons.cleaning_services_rounded;
    } else if (s == 'selesai_cuci') {
      bg = Colors.teal.shade50;
      fg = Colors.teal.shade700;
      icon = Icons.check_circle_outline;
    } else if (s == 'sedang_diantar' || s == 'diantar' || s == 'delivered') {
      bg = Colors.purple.shade50;
      fg = Colors.purple.shade700;
      icon = Icons.local_shipping_rounded;
    } else if (s == 'selesai' || s == 'siap_ambil') {
      bg = Colors.green.shade50;
      fg = Colors.green.shade700;
      icon = Icons.task_alt_rounded;
    } else if (s == 'dibatalkan') {
      bg = Colors.red.shade50;
      fg = Colors.red.shade700;
      icon = Icons.cancel_rounded;
    }

    if (light) {
      bg = Colors.white;
      fg = AppColors.primaryDark;
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
    final color = AppColors.primaryBlue;
    final bg = const Color(0xFFF0F9FA);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.2)),
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
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isDelivery
                      ? (LocationUtils.cleanAddress(alamat).isNotEmpty
                            ? LocationUtils.cleanAddress(alamat)
                            : 'Alamat tidak ditemukan / Belum diisi')
                      : 'Ambil di Toko',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textColor.withOpacity(0.85),
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
