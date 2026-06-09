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

  final List<Map<String, String>> _statusFilters = [
    {'label': 'Semua', 'value': ''},
    {'label': 'Menunggu', 'value': 'menunggu_jemput'},
    {'label': 'Dijemput', 'value': 'sedang_dijemput'},
    {'label': 'Di Toko', 'value': 'diterima_toko'},
    {'label': 'Dikirim', 'value': 'siap_diantar'},
    {'label': 'Selesai', 'value': 'selesai'},
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
      case 'menunggu_jemput':
        return 'Menunggu';
      case 'sedang_dijemput':
        return 'Dijemput';
      case 'diterima_toko':
      case 'dicuci':
      case 'diproses':
        return 'Di Toko';
      case 'siap_diantar':
      case 'sedang_diantar':
      case 'diantar':
        return 'Dikirim';
      case 'selesai':
        return 'Selesai';
      default:
        return status?.replaceAll('_', ' ') ?? '-';
    }
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'selesai':
        return AppColors.successGreen;
      case 'siap_diantar':
      case 'sedang_diantar':
      case 'diantar':
        return AppColors.primaryBlue;
      case 'diterima_toko':
      case 'dicuci':
      case 'diproses':
        return Colors.orange;
      case 'menunggu_jemput':
      case 'sedang_dijemput':
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
      final Map<String, List<String>> faseMap = {
        'menunggu_jemput': ['menunggu_jemput'],
        'sedang_dijemput': ['sedang_dijemput'],
        'diterima_toko': ['diterima_toko', 'dicuci', 'diproses'],
        'siap_diantar': ['siap_diantar', 'sedang_diantar', 'diantar'],
        'selesai': ['selesai'],
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
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search',
                    prefixIcon: const Icon(Icons.search, color: Colors.grey),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onChanged: (value) {
                    setState(() {});
                  },
                ),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ListenableBuilder(
                    listenable: _controller,
                    builder: (context, _) {
                      return Row(
                        children: _statusFilters.map((filter) {
                          final isSelected =
                              _controller.selectedStatus == filter['value'];
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () {
                                _controller.setStatus(filter['value']!);
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppColors.primaryBlue
                                      : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isSelected
                                        ? AppColors.primaryBlue
                                        : Colors.grey.shade300,
                                  ),
                                ),
                                child: Text(
                                  filter['label']!,
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : Colors.black87,
                                    fontSize: 13,
                                    fontWeight: isSelected
                                        ? FontWeight.w600
                                        : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
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
                  return const Center(child: Text('Belum ada riwayat pesanan'));
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
    
    // Kalkulasi Biaya Layanan
    final totalHargaLayanan = detailOrders.fold<int>(0, (sum, item) {
      final value =
          double.tryParse(item['total_harga']?.toString() ?? '0') ?? 0;
      return sum + value.toInt();
    });

    // Kalkulasi Ongkir
    final ongkir = int.tryParse(order['total_ongkir']?.toString() ?? '0') ?? 0;
    
    // Total Keseluruhan
    final totalKeseluruhan = totalHargaLayanan + ongkir;

    final nmToko = order['shops']?['nm_toko']?.toString() ?? '-';
    final statusOrder = order['status_order']?.toString() ?? '';

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
                'Jumlah: ${detailOrders.length}',
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