import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

// --- PERBAIKAN: Menggunakan versi PLUS yang bebas error namespace ---
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';

// --- PERBAIKAN: Import package SVG untuk memuat logo bank ---
import 'package:flutter_svg/flutter_svg.dart';
// -------------------------------------------------------------------

import '../../../../../core/constants/app_colors.dart';
import '../controllers/payment_controller.dart';
import 'payment_success_page.dart';

// ─── WIDGET LOGO BANK (SAMA SEPERTI DI ADMIN) ────────────────────────────────
class _BankLogo extends StatelessWidget {
  final String? slug;
  final String name;
  final double size;

  const _BankLogo({required this.name, this.slug, this.size = 40});

  static const _base =
      'https://raw.githubusercontent.com/hafidznoor/idn-finlogos/main/icons';

  String? get _url {
    if (slug == null || slug!.isEmpty) return null;
    return '$_base/$slug.svg';
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    if (url == null) return _fallback();

    return SvgPicture.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => _shimmer(),
    );
  }

  Widget _shimmer() => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
    ),
  );

  Widget _fallback() => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.primaryBlue.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.primaryBlue,
        fontSize: 16,
      ),
    ),
  );
}

// ─── MAIN CLASS PAYMENT PAGE ──────────────────────────────────────────────────
class PaymentPage extends StatefulWidget {
  final String token;
  final String orderId;
  final int totalAmount;
  final String paymentDeadline;

  const PaymentPage({
    super.key,
    required this.token,
    required this.orderId,
    required this.totalAmount,
    required this.paymentDeadline,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  late PaymentController _controller;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  bool _isDownloading = false;

  // ─── DATABASE LOGO BANK & E-WALLET UNTUK SINKRONISASI ────────────────────────
  static const List<Map<String, String?>> daftarBankLengkap = [
    {'name': 'BCA', 'slug': 'bca', 'type': 'Bank'},
    {'name': 'Mandiri', 'slug': 'mandiri', 'type': 'Bank'},
    {'name': 'BNI', 'slug': 'bni', 'type': 'Bank'},
    {'name': 'BRI', 'slug': 'bri', 'type': 'Bank'},
    {'name': 'BSI', 'slug': 'bsi', 'type': 'Bank'},
    {'name': 'BTN', 'slug': 'btn', 'type': 'Bank'},
    {'name': 'CIMB Niaga', 'slug': 'cimb-niaga', 'type': 'Bank'},
    {'name': 'Permata Bank', 'slug': 'permata', 'type': 'Bank'},
    {'name': 'Danamon', 'slug': 'danamon', 'type': 'Bank'},
    {'name': 'Bank Mega', 'slug': 'mega', 'type': 'Bank'},
    {'name': 'Maybank', 'slug': 'maybank', 'type': 'Bank'},
    {'name': 'OCBC NISP', 'slug': 'ocbc-nisp', 'type': 'Bank'},
    {'name': 'Panin Bank', 'slug': null, 'type': 'Bank'},
    {'name': 'Bukopin', 'slug': null, 'type': 'Bank'},
    {'name': 'Sinarmas', 'slug': 'sinarmas', 'type': 'Bank'},
    {'name': 'Muamalat', 'slug': null, 'type': 'Bank'},
    {'name': 'Jenius', 'slug': 'jenius', 'type': 'Bank'},
    {'name': 'Bank Jago', 'slug': 'jago', 'type': 'Bank'},
    {'name': 'SeaBank', 'slug': 'seabank', 'type': 'Bank'},
    {'name': 'Allo Bank', 'slug': 'allo', 'type': 'Bank'},
    {'name': 'Bank Neo Commerce', 'slug': 'bnc', 'type': 'Bank'},
    {'name': 'Bank DKI', 'slug': 'bank-dki', 'type': 'Bank'},
    {'name': 'Bank Jateng', 'slug': null, 'type': 'Bank'},
    {'name': 'Bank Jatim', 'slug': null, 'type': 'Bank'},
    {'name': 'HSBC Indonesia', 'slug': 'hsbc', 'type': 'Bank'},
    {'name': 'Citibank', 'slug': 'citibank', 'type': 'Bank'},
    {'name': 'Commonwealth', 'slug': 'commonwealth', 'type': 'Bank'},
    {
      'name': 'Standard Chartered',
      'slug': 'standard-chartered',
      'type': 'Bank',
    },
    {'name': 'GoPay', 'slug': 'gopay', 'type': 'E-Wallet'},
    {'name': 'OVO', 'slug': null, 'type': 'E-Wallet'},
    {'name': 'DANA', 'slug': 'dana', 'type': 'E-Wallet'},
    {'name': 'ShopeePay', 'slug': 'shopee-pay', 'type': 'E-Wallet'},
    {'name': 'LinkAja', 'slug': 'linkaja', 'type': 'E-Wallet'},
    {'name': 'Doku', 'slug': 'doku', 'type': 'E-Wallet'},
    {'name': 'Sakuku', 'slug': null, 'type': 'E-Wallet'},
    {'name': 'Akulaku', 'slug': 'akulaku', 'type': 'E-Wallet'},
  ];

  // Fungsi pencari slug berdasarkan nama bank dari API
  String? _getSlug(String namaBankFull) {
    try {
      final match = daftarBankLengkap.firstWhere((e) {
        final eName = e['name']!.toLowerCase();
        final qName = namaBankFull.toLowerCase();
        return eName == qName || qName.contains(eName) || eName.contains(qName);
      });
      return match['slug'];
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    _controller = PaymentController();
    _controller.fetchBankAccounts(token: widget.token, orderId: widget.orderId);
    _checkLostData();
  }

  Future<void> _checkLostData() async {
    try {
      final LostDataResponse response = await _picker.retrieveLostData();
      if (response.isEmpty) return;
      if (response.file != null) {
        setState(() {
          _selectedImage = File(response.file!.path);
        });
      }
    } catch (e) {
      debugPrint('Error retrieving lost data: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatCurrency(int value) {
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picked = await _picker.pickImage(
        source: source,
        imageQuality: 50,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
        });
      }
    } on PlatformException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengambil gambar: ${e.message}'),
          backgroundColor: Colors.red,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Terjadi kesalahan saat memilih gambar'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Pilih Sumber Gambar',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(
                  Icons.camera_alt,
                  color: AppColors.primaryBlue,
                ),
                title: const Text('Kamera'),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 300));
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.photo_library,
                  color: AppColors.primaryBlue,
                ),
                title: const Text('Galeri'),
                onTap: () async {
                  Navigator.pop(context);
                  await Future.delayed(const Duration(milliseconds: 300));
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleKonfirmasi() async {
    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pilih bukti transfer terlebih dahulu'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final success = await _controller.confirmPayment(
      token: widget.token,
      orderId: widget.orderId,
      imageFile: _selectedImage!,
    );

    if (!mounted) return;

    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PaymentSuccessPage(
            orderNumber: _controller.paymentResult?['kode_order'] ?? '-',
            totalAmount: widget.totalAmount,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Gagal konfirmasi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _downloadQris(String url) async {
    if (_isDownloading) return;

    setState(() {
      _isDownloading = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sedang mengunduh QRIS...'),
        duration: Duration(seconds: 2),
      ),
    );

    try {
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final Uint8List bytes = response.bodyBytes;

        final result = await ImageGallerySaverPlus.saveImage(
          bytes,
          quality: 100,
          name: "QRIS_CareKicks_${DateTime.now().millisecondsSinceEpoch}",
        );

        if (!mounted) return;

        if (result['isSuccess'] == true) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Berhasil! Gambar QRIS tersimpan di Galeri.'),
              backgroundColor: Colors.green,
              duration: Duration(seconds: 3),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Gagal menyimpan gambar ke galeri.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal mengunduh gambar dari server.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Terjadi kesalahan: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
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
          'Detail Pembayaran',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          return Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // GRADIENT CARD TOTAL TAGIHAN
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [AppColors.primaryBlue, Color(0xFF4A90E2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.primaryBlue.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'TOTAL TAGIHAN',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                    letterSpacing: 1,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _formatCurrency(widget.totalAmount),
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long,
                                color: Colors.white,
                                size: 30,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      const Text(
                        'PILIHAN REKENING TRANSFER',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),

                      if (_controller.isLoading)
                        const Center(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_controller.bankAccounts.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Text('Tidak ada rekening tersedia'),
                          ),
                        )
                      else
                        ..._controller.bankAccounts.map((bank) {
                          final String pathQris = bank['path_qris'] ?? '';
                          final bool isQris =
                              bank['nama_bank']?.toString().toUpperCase() ==
                                  'QRIS' ||
                              pathQris.isNotEmpty;

                          // --- PERBAIKAN: Dapatkan nama bank dan slug logo ---
                          final String namaBankFull =
                              bank['nama_bank'] ?? 'BANK';
                          final String? slug = _getSlug(namaBankFull);
                          // --------------------------------------------------

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: Colors.grey.shade200),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.02),
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
                                    // --- PERBAIKAN UI CONTAINER LOGO ---
                                    Container(
                                      width: 44,
                                      height: 44,
                                      padding: isQris
                                          ? const EdgeInsets.all(10)
                                          : const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: isQris
                                            ? Colors.blue.shade50
                                            : Colors.white,
                                        borderRadius: BorderRadius.circular(10),
                                        border: isQris
                                            ? null
                                            : Border.all(
                                                color: Colors.grey.shade200,
                                              ),
                                      ),
                                      child: isQris
                                          ? const Icon(
                                              Icons.qr_code_2,
                                              color: AppColors.primaryBlue,
                                              size: 22,
                                            )
                                          : Center(
                                              child: _BankLogo(
                                                name: namaBankFull,
                                                slug: slug,
                                                size: 32,
                                              ),
                                            ),
                                    ),
                                    // -----------------------------------
                                    const SizedBox(width: 14),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          bank['nama_bank'] ?? '-',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                        Text(
                                          'a.n. ${bank['atas_nama'] ?? '-'}',
                                          style: TextStyle(
                                            fontSize: 13,
                                            color: Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 16),

                                if (!isQris) ...[
                                  // Tampilan Transfer Bank
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade50,
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            bank['no_rek'] ?? '-',
                                            style: const TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.5,
                                              color: Colors.black87,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        GestureDetector(
                                          onTap: () {
                                            Clipboard.setData(
                                              ClipboardData(
                                                text: bank['no_rek'] ?? '',
                                              ),
                                            );
                                            ScaffoldMessenger.of(
                                              context,
                                            ).showSnackBar(
                                              const SnackBar(
                                                content: Text('Nomor disalin'),
                                                duration: Duration(seconds: 1),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 14,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: AppColors.primaryBlue,
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text(
                                              'Salin',
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  // Tampilan QRIS
                                  if (pathQris.isNotEmpty) ...[
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: Colors.grey.shade200,
                                        ),
                                      ),
                                      child: Column(
                                        children: [
                                          // --- PERBAIKAN: Gunakan ClipRRect dan BoxFit.cover ---
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              pathQris,
                                              width: double.infinity,
                                              height: 320,
                                              fit: BoxFit.cover,
                                              alignment: Alignment.center,
                                              errorBuilder: (_, __, ___) =>
                                                  const Padding(
                                                    padding: EdgeInsets.all(
                                                      16.0,
                                                    ),
                                                    child: Text(
                                                      'Gagal memuat QRIS',
                                                    ),
                                                  ),
                                            ),
                                          ),
                                          // -----------------------------------------------------
                                          const SizedBox(height: 12),
                                          SizedBox(
                                            width: double.infinity,
                                            child: OutlinedButton.icon(
                                              onPressed: _isDownloading
                                                  ? null
                                                  : () =>
                                                        _downloadQris(pathQris),
                                              icon: _isDownloading
                                                  ? const SizedBox(
                                                      width: 16,
                                                      height: 16,
                                                      child:
                                                          CircularProgressIndicator(
                                                            strokeWidth: 2,
                                                          ),
                                                    )
                                                  : const Icon(
                                                      Icons.download_rounded,
                                                      size: 18,
                                                    ),
                                              label: Text(
                                                _isDownloading
                                                    ? 'Mengunduh...'
                                                    : 'Unduh QRIS',
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    Colors.grey.shade800,
                                                side: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 12,
                                                    ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ],
                              ],
                            ),
                          );
                        }),

                      const SizedBox(height: 24),
                      const Text(
                        'UNGGAH BUKTI TRANSFER',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: _showImageSourceDialog,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _selectedImage != null
                                  ? AppColors.primaryBlue
                                  : Colors.grey.shade300,
                              width: _selectedImage != null ? 2 : 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: _selectedImage != null
                              ? Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        _selectedImage!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.check_circle,
                                          color: Colors.green,
                                          size: 16,
                                        ),
                                        SizedBox(width: 6),
                                        Text(
                                          'Gambar dipilih, tap untuk ganti',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                )
                              : Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(16),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue
                                            .withOpacity(0.1),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.cloud_upload_outlined,
                                        size: 36,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Unggah Bukti Transfer',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    const Text(
                                      'Tap untuk pilih dari kamera atau galeri',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _controller.isConfirming
                        ? null
                        : _handleKonfirmasi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _selectedImage != null
                          ? AppColors.primaryBlue
                          : Colors.grey.shade300,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _controller.isConfirming
                        ? const CircularProgressIndicator(color: Colors.white)
                        : Text(
                            'Kirim Bukti Pembayaran',
                            style: TextStyle(
                              color: _selectedImage != null
                                  ? Colors.white
                                  : Colors.grey,
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
