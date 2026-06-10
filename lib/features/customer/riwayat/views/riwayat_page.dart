import 'package:flutter/material.dart';
import '../controllers/riwayat_controller.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../detail_order/views/detail_order_page.dart';

class RiwayatPage extends StatefulWidget {
  final String token;

  const RiwayatPage({super.key, required this.token});

  @override
  State<RiwayatPage> createState() => _RiwayatPageState();
}

class _RiwayatPageState extends State<RiwayatPage> {
  late RiwayatController _controller;
  final TextEditingController _searchController = TextEditingController();

  // Dropdown filter options sesuai enum baru
  final List<Map<String, String>> _statusFilters = [
    {'label': 'Semua Status', 'value': ''},
    {'label': 'Menunggu Konfirmasi Admin', 'value': 'pending'},
    {'label': 'Menunggu Pembayaran', 'value': 'menunggu_pembayaran'},
    {'label': 'Menunggu Verifikasi Bayar', 'value': 'menunggu_konfirmasi'},
    {'label': 'Menunggu Dijemput', 'value': 'menunggu_dijemput'},
    {'label': 'Sedang Dijemput', 'value': 'sedang_dijemput'},
    {'label': 'Sedang Dicuci', 'value': 'washing'},
    {'label': 'Sedang Diantar', 'value': 'sedang_diantar'},
    {'label': 'Selesai', 'value': 'selesai'},
    {'label': 'Dibatalkan', 'value': 'dibatalkan'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = RiwayatController();
    _controller.fetchRiwayat(widget.token);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'pending':
        return 'Menunggu';
      case 'menunggu_pembayaran':
        return 'Menunggu Bayar';
      case 'menunggu_konfirmasi':
        return 'Verifikasi';
      case 'dikonfirmasi':
        return 'Dikonfirmasi';
      case 'menunggu_dijemput':
        return 'Menunggu Jemput';
      case 'sedang_dijemput':
        return 'Dijemput';
      case 'sudah_dijemput':
        return 'Sudah Dijemput';
      case 'washing':
        return 'Dicuci';
      case 'selesai_cuci':
        return 'Selesai Cuci';
      case 'sedang_diantar':
        return 'Dikirim';
      case 'selesai':
        return 'Selesai';
      case 'dibatalkan':
        return 'Dibatalkan';
      default:
        return status?.replaceAll('_', ' ') ?? '-';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'selesai':
        return AppColors.successGreen;
      case 'sedang_diantar':
      case 'selesai_cuci':
        return AppColors.primaryBlue;
      case 'washing':
        return Colors.purple;
      case 'menunggu_dijemput':
      case 'sedang_dijemput':
      case 'sudah_dijemput':
        return Colors.orange;
      case 'dibatalkan':
        return Colors.red;
      default:
        return Colors.grey;
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
      return '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/'
          '${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  List<dynamic> _filterOrders(List<dynamic> orders) {
    var result = orders;

    final selectedStatus = _controller.selectedStatus;
    if (selectedStatus.isNotEmpty) {
      // Beberapa status di-group karena satu fase bisa punya beberapa status
      final Map<String, List<String>> faseMap = {
        'pending': ['pending'],
        'menunggu_pembayaran': ['menunggu_pembayaran'],
        'menunggu_konfirmasi': ['menunggu_konfirmasi'],
        'menunggu_dijemput': ['dikonfirmasi', 'menunggu_dijemput'],
        'sedang_dijemput': ['sedang_dijemput', 'sudah_dijemput'],
        'washing': ['washing', 'selesai_cuci'],
        'sedang_diantar': ['sedang_diantar'],
        'selesai': ['selesai'],
        'dibatalkan': ['dibatalkan'],
      };
      final allowed = faseMap[selectedStatus] ?? [selectedStatus];
      result = result.where((o) {
        final s = o['status_order']?.toString() ?? '';
        return allowed.contains(s);
      }).toList();
    }

    final search = _searchController.text.trim().toLowerCase();
    if (search.isNotEmpty) {
      result = result.where((o) {
        final kode = o['kode_order']?.toString().toLowerCase() ?? '';
        final toko = o['shops']?['nm_toko']?.toString().toLowerCase() ?? '';
        return kode.contains(search) || toko.contains(search);
      }).toList();
    }

    return result;
  }

  // Ambil label dropdown yang sedang dipilih
  String get _selectedFilterLabel {
    return _statusFilters.firstWhere(
      (f) => f['value'] == _controller.selectedStatus,
      orElse: () => _statusFilters.first,
    )['label']!;
  }

  void _showFilterDropdown(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true, // ← tambah ini
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Filter Status',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Bungkus list dengan Flexible + SingleChildScrollView
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ..._statusFilters.map((filter) {
                        final isSelected =
                            _controller.selectedStatus == filter['value'];
                        return ListTile(
                          title: Text(
                            filter['label']!,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: isSelected
                                  ? AppColors.primaryBlue
                                  : Colors.black87,
                            ),
                          ),
                          trailing: isSelected
                              ? const Icon(
                                  Icons.check,
                                  color: AppColors.primaryBlue,
                                  size: 18,
                                )
                              : null,
                          onTap: () {
                            _controller.setStatus(filter['value']!);
                            Navigator.pop(context);
                            setState(() {});
                          },
                        );
                      }),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _navigateToDetail(Map<String, dynamic> order) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => DetailOrderPage(
          token: widget.token,
          orderId: order['id_orders'].toString(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Riwayat',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              children: [
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Cari kode order atau nama toko',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) => setState(() {}),
                ),
                const SizedBox(height: 10),

                // Dropdown filter
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) {
                    final hasFilter = _controller.selectedStatus.isNotEmpty;
                    return GestureDetector(
                      onTap: () => _showFilterDropdown(context),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: hasFilter
                              ? AppColors.primaryBlue.withOpacity(0.05)
                              : const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: hasFilter
                                ? AppColors.primaryBlue.withOpacity(0.4)
                                : Colors.grey.shade300,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.filter_list,
                              size: 18,
                              color: hasFilter
                                  ? AppColors.primaryBlue
                                  : Colors.grey,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _selectedFilterLabel,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: hasFilter
                                      ? AppColors.primaryBlue
                                      : Colors.grey.shade600,
                                  fontWeight: hasFilter
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.keyboard_arrow_down,
                              size: 18,
                              color: hasFilter
                                  ? AppColors.primaryBlue
                                  : Colors.grey,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          // List pesanan
          Expanded(
            child: ListenableBuilder(
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
                          onPressed: () =>
                              _controller.fetchRiwayat(widget.token),
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final filtered = _filterOrders(_controller.orders);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 48,
                          color: Colors.grey.shade300,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _controller.selectedStatus.isEmpty
                              ? 'Belum ada riwayat pesanan'
                              : 'Tidak ada pesanan dengan status ini',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _controller.fetchRiwayat(widget.token),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final order = filtered[index] as Map<String, dynamic>;
                      return _buildOrderCard(order);
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
    final detailOrders = order['detail_orders'] as List<dynamic>? ?? [];
    final totalHargaLayanan = detailOrders.fold<int>(0, (sum, item) {
      final value =
          double.tryParse(item['total_harga']?.toString() ?? '0') ?? 0;
      return sum + value.toInt();
    });
    final ongkir = int.tryParse(order['total_ongkir']?.toString() ?? '0') ?? 0;
    final totalKeseluruhan = totalHargaLayanan + ongkir;
    final nmToko = order['shops']?['nm_toko']?.toString() ?? '-';
    final statusOrder = order['status_order']?.toString() ?? '';
    final metodeOrder = order['metode_order']?.toString().toLowerCase() ?? '';
    final isOnline = metodeOrder == 'online';

    return GestureDetector(
      onTap: () => _navigateToDetail(order),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      nmToko,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Badge status
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getStatusColor(statusOrder).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: _getStatusColor(statusOrder).withOpacity(0.4),
                      ),
                    ),
                    child: Text(
                      _getStatusLabel(statusOrder),
                      style: TextStyle(
                        color: _getStatusColor(statusOrder),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Badge online/offline
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: isOnline
                          ? AppColors.primaryBlue.withOpacity(0.08)
                          : Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isOnline
                            ? AppColors.primaryBlue.withOpacity(0.3)
                            : Colors.orange.withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      isOnline ? 'Online' : 'Offline',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: isOnline ? AppColors.primaryBlue : Colors.orange,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              Text(
                _formatDate(order['tgl_order']),
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Id Pemesanan: ${order['kode_order'] ?? '-'}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Jumlah: ${detailOrders.length} item',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
              const SizedBox(height: 4),
              Text(
                'Total Biaya: ${_formatCurrency(totalKeseluruhan)}',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
