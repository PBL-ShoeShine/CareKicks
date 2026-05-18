import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/widgets/custom_scaffold.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:vibration/vibration.dart';
import '../../../../core/network/api_service.dart';
import 'scanner_detail_page.dart';

const _brand = Color(0xFF1FB6C1);
const _scanLine = Color(0xFF7CE7F1);

class ScannerPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const ScannerPage({super.key, required this.token, required this.user});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
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
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator) Vibration.vibrate(duration: 120, amplitude: 128);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: CustomAppBar(
        title: 'Pemindai',
        subtitle: 'Scan kode pesanan',
        backgroundColor: Colors.white,
        actions: [
          IconButton(
            tooltip: 'Notifikasi',
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(children: [Expanded(child: _viewfinder())]),
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
          const Spacer(),
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined),
                onPressed: () {},
              ),
              const Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(radius: 4, backgroundColor: Colors.red),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _viewfinder() {
    return Stack(
      fit: StackFit.expand,
      children: [
        MobileScanner(
          controller: _scannerController,
          onDetect: (capture) async {
            if (!isScanCompleted) {
              final code = capture.barcodes.firstOrNull?.rawValue;
              if (code != null) {
                setState(() => isScanCompleted = true);
                _playFeedback();

                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => const Center(
                    child: CircularProgressIndicator(color: _brand),
                  ),
                );

                final resultData = await ApiService.cekSepatu(code);

                if (mounted) Navigator.pop(context);

                if (resultData != null && resultData['success'] == true) {
                  if (mounted) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            ScannerDetailPage(dataOrder: resultData['data']),
                      ),
                    ).then((_) {
                      if (mounted) setState(() => isScanCompleted = false);
                    });
                  }
                } else {
                  if (mounted) {
                    _showErrorDialog(code, resultData?['message']);
                  }
                }
              }
            }
          },
        ),
        Container(color: Colors.black.withOpacity(0.15)),
        Positioned(
          top: 24,
          left: 16,
          right: 16,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
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
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Center(child: _ScannerFrame()),
        Positioned(
          bottom: 32,
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
                  color: _torchOn ? _brand : Colors.white.withOpacity(0.9),
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
  }

  void _showErrorDialog(String code, String? errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text(
          "Data Tidak Ditemukan",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
        ),
        content: Text(errorMessage ?? "Kode QR tidak terdaftar di sistem."),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Scan Lagi", style: TextStyle(color: _brand)),
          ),
        ],
      ),
    ).then((_) {
      if (mounted) setState(() => isScanCompleted = false);
    });
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
  )..repeat(reverse: true);

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const size = 260.0;
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
            builder: (_, _) => Positioned(
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
  bool shouldRepaint(covariant CustomPainter _) => false;
}
