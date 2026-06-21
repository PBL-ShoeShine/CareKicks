import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/widgets/custom_scaffold.dart';
import '../../../../core/widgets/custom_tab_bar.dart';
import '../controllers/antrean_controller.dart';
import '../models/antrean_model.dart';
import '../views/antrean_detail_screen.dart';

class AntreanScreen extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;
  const AntreanScreen({super.key, required this.token, required this.user});

  @override
  State<AntreanScreen> createState() => _AntreanScreenState();
}

class _AntreanScreenState extends State<AntreanScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late AntreanController _controller;
  int _currentTab = 0;

  final _tabs = const [
    {'label': 'Pesanan Masuk', 'status': 'pesanan_masuk'},
    {'label': 'Pembayaran', 'status': 'pembayaran'},
    {'label': 'Pesanan Baru', 'status': 'pesanan_baru'},
    {'label': 'Sedang Dicuci', 'status': 'sedang_dicuci'},
    {'label': 'Siap', 'status': 'siap'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = AntreanController();
    _controller.setToken(widget.token);
    _controller.setRole(widget.user['jenis_role']); // ← role-based endpoint
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _currentTab = _tabController.index);
        _loadData();
      }
    });
    _loadData();
  }

  Future<void> _loadData() async {
    await _controller.fetchAntrean(_tabs[_currentTab]['status']!);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: CustomAppBar(
        title: 'Manajemen Antrean',
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        bottom: CustomTabBar(
          controller: _tabController,
          labels: _tabs.map((t) => t['label']!).toList(),
          isScrollable: true,
        ),
      ),
      body: _buildList(),
    );
  }

  Widget _buildList() {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        if (_controller.isLoading) {
          return const Center(
            child: CircularProgressIndicator(color: AppColors.primaryBlue),
          );
        }
        if (_controller.errorMessage != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.wifi_off, size: 48, color: Colors.grey.shade400),
                const SizedBox(height: 12),
                Text(
                  _controller.errorMessage!,
                  style: TextStyle(color: Colors.grey.shade600),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadData,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  child: const Text(
                    'Coba Lagi',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          );
        }
        if (_controller.antreanList.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inbox_outlined,
                  size: 48,
                  color: Colors.grey.shade400,
                ),
                const SizedBox(height: 12),
                Text(
                  'Tidak ada antrean',
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: _loadData,
          color: AppColors.primaryBlue,
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: _controller.antreanList.length,
            itemBuilder: (context, i) => _buildCard(_controller.antreanList[i]),
          ),
        );
      },
    );
  }

  Widget _buildCard(AntreanModel antrean) {
    final detail = antrean.detail;
    final nextStatus = _nextStatus(antrean.statusOrder);
    final btnLabel = _btnLabel(antrean.statusOrder);
    final statusColor = _statusColor(antrean.statusOrder);

    return GestureDetector(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                AntreanDetailScreen(token: widget.token, antrean: antrean),
          ),
        );
        if (result == true) _loadData();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Foto
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Builder(
                      builder: (context) {
                        final fotoSebelumUrl = detail?.fotoSebelum?.split(',').first.trim();
                        return (fotoSebelumUrl != null && fotoSebelumUrl.isNotEmpty)
                            ? Image.network(
                                fotoSebelumUrl,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => _placeholder(),
                              )
                            : _placeholder();
                      }
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '#${antrean.kodeOrder}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: statusColor.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                // --- PERBAIKAN: MENGHILANGKAN UNDERSCORE DI SINI ---
                                antrean.statusOrder
                                    .replaceAll('_', ' ')
                                    .toUpperCase(),
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          antrean.customer?.nama ?? '-',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          detail != null
                              ? '${detail.namaLayanan ?? 'Layanan'} - ${detail.merk}'
                              : '-',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 12,
                              color: Colors.orange.shade400,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatTgl(antrean.tglOrder),
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.orange.shade600,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Tombol aksi
              nextStatus != null
                  ? _buildActionButtons(antrean, nextStatus, btnLabel)
                  : Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.successGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.check_circle,
                            color: AppColors.successGreen,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Pesanan Selesai',
                            style: TextStyle(
                              color: AppColors.successGreen,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButtons(
    AntreanModel antrean,
    String nextStatus,
    String btnLabel,
  ) {
    // 1. Tab Pesanan Masuk (pending)
    if (antrean.statusOrder == 'pending') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                side: const BorderSide(color: AppColors.errorRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text(
                'Tolak',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () =>
                  _handleConfirmation(antrean, 'reject', isPayment: false),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.check, color: Colors.white, size: 18),
              label: const Text(
                'Setujui',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () =>
                  _handleConfirmation(antrean, 'approve', isPayment: false),
            ),
          ),
        ],
      );
    }

    // 2. Tab Pembayaran (menunggu_pembayaran)
    if (antrean.statusOrder == 'menunggu_pembayaran') {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.errorRed,
                side: const BorderSide(color: AppColors.errorRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.close_rounded, size: 18),
              label: const Text(
                'Tolak',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              onPressed: () =>
                  _handleConfirmation(antrean, 'reject', isPayment: true),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.successGreen,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.check, color: Colors.white, size: 18),
              label: const Text(
                'Setujui',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onPressed: () =>
                  _handleConfirmation(antrean, 'approve', isPayment: true),
            ),
          ),
        ],
      );
    }

    // 3. Tab Pesanan Baru, Sedang Dicuci, Siap (Update status manual)
    return SizedBox(
      width: double.infinity,
      child: _buildPrimaryActionButton(antrean, nextStatus, btnLabel),
    );
  }

  Future<void> _handleConfirmation(
    AntreanModel antrean,
    String action, {
    required bool isPayment,
  }) async {
    String? reason;
    if (action == 'reject') {
      reason = await _showRejectReasonDialog();
      if (reason == null || reason.trim().isEmpty) return;
    } else {
      final confirm = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(isPayment ? 'Setujui Pembayaran' : 'Setujui Pesanan'),
          content: Text(
            'Apakah Anda yakin ingin menyetujui pesanan #${antrean.kodeOrder}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, Setujui'),
            ),
          ],
        ),
      );
      if (confirm != true) return;
    }

    final result = isPayment
        ? await _controller.processPayment(
            idOrders: antrean.idOrders,
            action: action,
            reason: reason,
          )
        : await _controller.processOrder(
            idOrders: antrean.idOrders,
            action: action,
            reason: reason,
          );

    if (mounted) {
      if (result['success'] == true) {
        _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Berhasil diproses'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Gagal memproses'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Widget _buildPrimaryActionButton(
    AntreanModel antrean,
    String nextStatus,
    String btnLabel,
  ) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primaryBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      icon: const Icon(Icons.play_arrow, color: Colors.white, size: 18),
      label: Text(
        btnLabel,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
      onPressed: () async {
        final ok = await _controller.updateStatus(antrean.idOrders, nextStatus);
        if (ok && mounted) {
          _loadData();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Status diubah ke ${nextStatus.replaceAll('_', ' ')}',
              ),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      },
    );
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
                                'Tolak Pesanan/Pembayaran',
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
                        hintText:
                            'Contoh: Bukti transfer tidak valid / Stok habis',
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
                              disabledBackgroundColor: AppColors.errorRed
                                  .withOpacity(0.32),
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

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(Icons.photo_outlined, color: Colors.grey.shade400),
    );
  }

  String? _nextStatus(String s) {
    switch (s) {
      case 'pending':
        return 'menunggu_pembayaran';
      case 'menunggu_pembayaran':
        return 'pesanan_baru';
      case 'pesanan_baru':
        return 'washing';
      case 'washing':
        return 'selesai_cuci';
      case 'selesai_cuci':
        return 'selesai';
      default:
        return null;
    }
  }

  String _btnLabel(String s) {
    switch (s) {
      case 'pending':
        return 'Setujui Pesanan';
      case 'menunggu_pembayaran':
        return 'Cek Pembayaran';
      case 'pesanan_baru':
        return 'Mulai Cuci';
      case 'washing':
        return 'Selesai Cuci';
      case 'selesai_cuci':
        return 'Selesaikan Order';
      default:
        return '';
    }
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'pending':
        return AppColors.primaryBlue;
      case 'menunggu_pembayaran':
        return Colors.amber.shade700;
      case 'pesanan_baru':
        return AppColors.successGreen;
      case 'washing':
        return Colors.purple;
      case 'selesai_cuci':
        return Colors.teal;
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
      return '${dt.day}/${dt.month}/${dt.year} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return tgl;
    }
  }
}
