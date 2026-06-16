import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/widgets/custom_scaffold.dart';
import '../models/antrean_model.dart';
import '../controllers/antrean_controller.dart';

class AntreanDetailScreen extends StatefulWidget {
  final String token;
  final AntreanModel antrean;

  const AntreanDetailScreen({
    super.key,
    required this.token,
    required this.antrean,
  });

  @override
  State<AntreanDetailScreen> createState() => _AntreanDetailScreenState();
}

class _AntreanDetailScreenState extends State<AntreanDetailScreen> {
  late AntreanController _controller;
  bool _isLoading = false;
  bool _isDownloadingQr = false;
  late String _currentStatus;
  bool _isStatusUpdated = false; // Penanda jika ada perubahan status

  @override
  void initState() {
    super.initState();
    _controller = AntreanController();
    _controller.setToken(widget.token);
    _currentStatus = widget.antrean.statusOrder;
  }

  Future<void> _updateStatus(String nextStatus, {String? keterangan}) async {
    setState(() => _isLoading = true);
    try {
      final success = await _controller.updateStatus(
        widget.antrean.idOrders,
        nextStatus,
        keterangan: keterangan,
      );
      if (success && mounted) {
        setState(() {
          _currentStatus = nextStatus;
          _isStatusUpdated = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Status berhasil diubah ke $nextStatus'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengubah status: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Bawa fungsi utilitas dari layar sebelumnya
  String? _nextStatus(String s) {
    switch (s) {
      case 'menunggu_konfirmasi':
        return 'dikonfirmasi';
      case 'dikonfirmasi':
        return 'menunggu_dijemput';
      case 'menunggu_dijemput':
        return 'sedang_dijemput';
      case 'sedang_dijemput':
        return 'sudah_dijemput';
      case 'sudah_dijemput':
        return 'washing';
      case 'washing':
        return 'selesai_cuci';
      case 'selesai_cuci':
        return 'sedang_diantar';
      case 'sedang_diantar':
        return 'selesai';
      default:
        return null;
    }
  }

  String _btnLabel(String s) {
    switch (s) {
      case 'menunggu_konfirmasi':
        return 'ACC Pembayaran';
      case 'dikonfirmasi':
        return 'Tugaskan Kurir';
      case 'menunggu_dijemput':
        return 'Mulai Jemput';
      case 'sedang_dijemput':
        return 'Sepatu Dijemput';
      case 'sudah_dijemput':
        return 'Mulai Cuci';
      case 'washing':
        return 'Selesai Cuci';
      case 'selesai_cuci':
        return 'Mulai Antar';
      case 'sedang_diantar':
        return 'Selesaikan Order';
      default:
        return '';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'menunggu_konfirmasi':
        return Colors.amber.shade700;
      case 'dikonfirmasi':
        return AppColors.primaryBlue;
      case 'menunggu_dijemput':
        return Colors.blue.shade300;
      case 'sedang_dijemput':
        return Colors.orange;
      case 'sudah_dijemput':
        return Colors.orange.shade700;
      case 'washing':
        return Colors.purple;
      case 'selesai_cuci':
        return Colors.teal;
      case 'sedang_diantar':
        return AppColors.primaryBlue;
      case 'selesai':
        return AppColors.successGreen;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatTgl(String tgl) {
    try {
      final dt = DateTime.parse(tgl).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return tgl;
    }
  }

  String? get _qrImageUrl {
    final qrImage = widget.antrean.qrImage?.trim();
    if (qrImage != null && qrImage.isNotEmpty && qrImage.startsWith('http')) {
      return qrImage;
    }

    final linkQr = widget.antrean.linkQr?.trim();
    if (linkQr != null && linkQr.isNotEmpty && linkQr.startsWith('http')) {
      return linkQr;
    }

    return null;
  }

  Future<void> _rejectPayment() async {
    final reason = await _showRejectReasonDialog();
    if (reason == null || reason.trim().isEmpty) return;
    await _updateStatus('menunggu_pembayaran', keterangan: reason);
  }

  Future<String?> _showRejectReasonDialog() async {
    final reasonController = TextEditingController();
    return showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canSubmit = reasonController.text.trim().isNotEmpty;

            return Dialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: AppColors.errorRed.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.receipt_long_outlined,
                            color: AppColors.errorRed,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tolak Pembayaran',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Alasan akan ditampilkan ke customer.',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    TextField(
                      controller: reasonController,
                      autofocus: true,
                      maxLines: 4,
                      minLines: 3,
                      maxLength: 180,
                      textInputAction: TextInputAction.newline,
                      onChanged: (_) => setDialogState(() {}),
                      decoration: InputDecoration(
                        hintText: 'Contoh: Nominal transfer tidak sesuai',
                        filled: true,
                        fillColor: const Color(0xFFF9FAFB),
                        counterStyle: const TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                        contentPadding: const EdgeInsets.all(14),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: AppColors.errorRed,
                            width: 1.4,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              foregroundColor: AppColors.textPrimary,
                              side: const BorderSide(color: AppColors.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              'Batal',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: canSubmit
                                ? () => Navigator.pop(
                                      context,
                                      reasonController.text.trim(),
                                    )
                                : null,
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                              backgroundColor: AppColors.errorRed,
                              disabledBackgroundColor:
                                  AppColors.errorRed.withOpacity(0.32),
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Tolak',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? get _paymentProofUrl {
    final proofUrl = widget.antrean.uploadBktByr?.trim();
    if (proofUrl != null &&
        proofUrl.isNotEmpty &&
        proofUrl.startsWith('http')) {
      return proofUrl;
    }
    return null;
  }

  Future<void> _downloadQr() async {
    final qrUrl = _qrImageUrl;
    if (qrUrl == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR belum tersedia'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isDownloadingQr = true);
    try {
      final response = await http.get(Uri.parse(qrUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception('Gagal mengunduh gambar QR');
      }

      final imageBytes = Uint8List.fromList(response.bodyBytes);
      final result = await ImageGallerySaverPlus.saveImage(
        imageBytes,
        quality: 100,
        name: 'qr_order_${widget.antrean.kodeOrder}',
      );

      final isSuccess = result is Map
          ? result['isSuccess'] == true
          : result != null;

      if (!isSuccess) {
        throw Exception('Gagal menyimpan QR ke gallery');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('QR berhasil disimpan ke gallery'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh QR: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingQr = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final detail = widget.antrean.detail;
    final nextStatus = _nextStatus(_currentStatus);
    final statusColor = _statusColor(_currentStatus);
    final qrImageUrl = _qrImageUrl;
    final paymentProofUrl = _paymentProofUrl;

    return WillPopScope(
      onWillPop: () async {
        // Kembalikan nilai _isStatusUpdated saat tombol back bawaan ditekan
        Navigator.pop(context, _isStatusUpdated);
        return false;
      },
      child: CustomScaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: CustomAppBar(
          title: 'Detail Pesanan',
          showBackButton: true,
          onBack: () => Navigator.pop(context, _isStatusUpdated),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Card 1: Informasi Status & Kode
              Container(
                padding: const EdgeInsets.all(20),
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
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Expanded ditambahkan di sini agar teks tidak overflow
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Kode Order',
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '#${widget.antrean.kodeOrder}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                                overflow: TextOverflow
                                    .ellipsis, // Menambahkan titik-titik jika kepanjangan
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _currentStatus.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 16,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tanggal Masuk: ${_formatTgl(widget.antrean.tglOrder)}',
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Card 2: Foto Sepatu & Detail Merek
              const Text(
                'Detail Sepatu',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1A1A2E),
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
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
                    // Foto Sepatu
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: detail?.fotoSebelum != null
                            ? Image.network(
                                detail!.fotoSebelum!,
                                width: double.infinity,
                                height: 200,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPlaceholderImage(),
                              )
                            : _buildPlaceholderImage(),
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Info Merek & Warna
                    Row(
                      children: [
                        Expanded(
                          child: _buildInfoItem(
                            'Merk Sepatu',
                            detail?.merk ?? '-',
                          ),
                        ),
                        Expanded(
                          child: _buildInfoItem('Warna', detail?.warna ?? '-'),
                        ),
                      ],
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Divider(height: 1, color: Color(0xFFEEEEEE)),
                    ),
                    _buildInfoItem(
                      'Jenis Layanan',
                      detail?.namaLayanan ?? '-',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              if (_currentStatus == 'menunggu_konfirmasi') ...[
                const Text(
                  'Bukti Pembayaran',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
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
                      _buildInfoItem(
                        'Status Pembayaran',
                        widget.antrean.statusPembayaran.isEmpty
                            ? '-'
                            : widget.antrean.statusPembayaran,
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: paymentProofUrl != null
                            ? Image.network(
                                paymentProofUrl,
                                width: double.infinity,
                                height: 260,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _buildPaymentProofPlaceholder(),
                              )
                            : _buildPaymentProofPlaceholder(),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ],
          ),
        ),

        // Bottom Navigation Bar untuk Tombol Aksi
        bottomNavigationBar: nextStatus != null
            ? Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: _buildBottomActions(nextStatus),
              )
            : null,
      ),
    );
  }

  Widget _buildBottomActions(String nextStatus) {
    if (_isLoading) {
      return const SizedBox(
        height: 54,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.primaryBlue,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_currentStatus == 'menunggu_konfirmasi') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                side: const BorderSide(color: AppColors.errorRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                minimumSize: const Size.fromHeight(54),
              ),
              onPressed: _rejectPayment,
              icon: const Icon(Icons.close_rounded),
              label: const Text(
                'Tolak',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildPrimaryBottomButton(nextStatus),
          ),
        ],
      );
    }

    return _buildPrimaryBottomButton(nextStatus);
  }

  Widget _buildPrimaryBottomButton(String nextStatus) {
    return SizedBox(
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        onPressed: () => _updateStatus(nextStatus),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              child: Text(
                _btnLabel(_currentStatus),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.arrow_forward_rounded,
              color: Colors.white,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 15,
            color: Color(0xFF1A1A2E),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 200,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.image_not_supported_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Foto tidak tersedia',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentProofPlaceholder() {
    return Container(
      width: double.infinity,
      height: 260,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.receipt_long_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 8),
          Text(
            'Bukti pembayaran tidak tersedia',
            style: TextStyle(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildQrPlaceholder({bool isLoading = false}) {
    return Container(
      width: 220,
      height: 220,
      decoration: BoxDecoration(
        color: AppColors.lightBlue.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primaryBlue.withOpacity(0.18)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (isLoading)
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: AppColors.primaryBlue,
                strokeWidth: 2.5,
              ),
            )
          else
            Icon(
              Icons.qr_code_2_rounded,
              size: 56,
              color: AppColors.primaryBlue.withOpacity(0.55),
            ),
          const SizedBox(height: 10),
          Text(
            isLoading ? 'Memuat QR...' : 'QR belum tersedia',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
