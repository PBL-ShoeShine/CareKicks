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

  Future<void> _updateStatus(String nextStatus) async {
    setState(() => _isLoading = true);
    try {
      final success = await _controller.updateStatus(
        widget.antrean.idOrders,
        nextStatus,
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
    if (s == 'pending') return 'diproses';
    if (s == 'diproses') return 'selesai';
    return null;
  }

  String _btnLabel(String s) {
    if (s == 'pending') return 'Mulai Pengerjaan';
    if (s == 'diproses') return 'Selesaikan Order';
    return '';
  }

  Color _statusColor(String s) {
    if (s == 'pending') return AppColors.primaryBlue;
    if (s == 'diproses') return Colors.orange;
    if (s == 'selesai') return AppColors.successGreen;
    return Colors.grey;
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
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text(
                'QR Order',
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
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: qrImageUrl != null
                          ? Image.network(
                              qrImageUrl,
                              width: 220,
                              height: 220,
                              fit: BoxFit.contain,
                              loadingBuilder:
                                  (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return _buildQrPlaceholder(
                                  isLoading: true,
                                );
                              },
                              errorBuilder: (_, __, ___) =>
                                  _buildQrPlaceholder(),
                            )
                          : _buildQrPlaceholder(),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          disabledBackgroundColor:
                              AppColors.primaryBlue.withOpacity(0.45),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: qrImageUrl == null || _isDownloadingQr
                            ? null
                            : _downloadQr,
                        icon: _isDownloadingQr
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(
                                Icons.download_rounded,
                                color: Colors.white,
                              ),
                        label: Text(
                          _isDownloadingQr ? 'Mengunduh...' : 'Unduh QR',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),

        // Bottom Navigation Bar untuk Tombol Aksi
        bottomNavigationBar: Container(
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
          child: nextStatus != null
              ? SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    onPressed: _isLoading
                        ? null
                        : () => _updateStatus(nextStatus),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _btnLabel(_currentStatus),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
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
                )
              : Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle, color: AppColors.successGreen),
                      const SizedBox(width: 8),
                      Text(
                        'Pesanan Selesai',
                        style: TextStyle(
                          color: AppColors.successGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
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
