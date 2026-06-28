import 'package:carekicks/core/widgets/custom_scaffold.dart';
import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/widgets/custom_filter_bar.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../controllers/history_controller.dart';
import '../../../../core/utils/date_utils.dart';

class HistoryPage extends StatefulWidget {
  final String token;

  const HistoryPage({super.key, required this.token});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late HistoryController _historyController;
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'all';

  final List<CustomFilterItem<String>> _statusFilters = const [
    CustomFilterItem(value: 'all', label: 'Semua'),
    CustomFilterItem(value: 'pending', label: 'Pesanan Masuk'),
    CustomFilterItem(value: 'menunggu_pembayaran', label: 'Menunggu Pembayaran'),
    CustomFilterItem(value: 'menunggu_konfirmasi', label: 'Konfirmasi Pembayaran'),
    CustomFilterItem(value: 'dikonfirmasi', label: 'Dikonfirmasi'),
    CustomFilterItem(value: 'menunggu_dijemput', label: 'Menunggu Jemput'),
    CustomFilterItem(value: 'sedang_dijemput', label: 'Sedang Jemput'),
    CustomFilterItem(value: 'sudah_dijemput', label: 'Sudah Jemput'),
    CustomFilterItem(value: 'washing', label: 'Sedang Dicuci'),
    CustomFilterItem(value: 'selesai_cuci', label: 'Selesai Cuci'),
    CustomFilterItem(value: 'sedang_diantar', label: 'Sedang Diantar'),
    CustomFilterItem(value: 'selesai', label: 'Selesai'),
    CustomFilterItem(value: 'dibatalkan', label: 'Dibatalkan'),
  ];

  @override
  void initState() {
    super.initState();
    _historyController = HistoryController();
    _fetchData();
  }

  void _fetchData() {
    _historyController.fetchHistory(
      token: widget.token,
      status: _selectedStatus,
      search: _searchController.text.trim(),
      limit: 50,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  String _formatCurrency(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    final intValue = number.toInt();

    final formatted = intValue.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]}.',
    );

    return 'Rp $formatted';
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';

    try {
      final date = DateTimeUtils.parseToWib(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _formatStatus(String? status) {
    if (status == null || status.isEmpty) return 'PESANAN MASUK';
    switch (status.toLowerCase()) {
      case 'pending':
        return 'PESANAN MASUK';
      case 'menunggu_pembayaran':
        return 'MENUNGGU PEMBAYARAN';
      case 'menunggu_konfirmasi':
        return 'KONFIRMASI PEMBAYARAN';
      case 'dikonfirmasi':
        return 'DIKONFIRMASI';
      case 'menunggu_dijemput':
        return 'MENUNGGU JEMPUT';
      case 'sedang_dijemput':
        return 'SEDANG JEMPUT';
      case 'sudah_dijemput':
        return 'SUDAH JEMPUT';
      case 'washing':
        return 'SEDANG DICUCI';
      case 'selesai_cuci':
        return 'SELESAI DICUCI';
      case 'sedang_diantar':
        return 'SEDANG DIANTAR';
      case 'selesai':
        return 'SELESAI';
      case 'dibatalkan':
      case 'cancel':
      case 'cancelled':
        return 'DIBATALKAN';
      default:
        return status.toUpperCase().replaceAll('_', ' ');
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'menunggu_pembayaran':
      case 'menunggu_konfirmasi':
        return Colors.amber.shade700;
      case 'dikonfirmasi':
        return AppColors.primaryBlue;
      case 'menunggu_dijemput':
        return AppColors.successGreen;
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
      case 'cancel':
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const CustomAppBar(title: 'Riwayat Aktivitas'),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingMd,
              0,
              AppSizes.paddingMd,
              AppSizes.paddingMd,
            ),
            color: AppColors.primaryBlue,
            child: Column(
              children: [
                CustomSearchField(
                  controller: _searchController,
                  onChanged: (_) => _fetchData(),
                  onClear: () {
                    _searchController.clear();
                    _fetchData();
                  },
                  hintText: 'Cari merk atau jenis sepatu...',
                ),

                const SizedBox(height: AppSizes.gapMd),
                CustomFilterBar<String>(
                  items: _statusFilters,
                  selectedValue: _selectedStatus,
                  padding: EdgeInsets.zero,
                  onSelected: (value) {
                    setState(() => _selectedStatus = value);
                    _fetchData();
                  },
                ),
              ],
            ),
          ),

          Expanded(
            child: ListenableBuilder(
              listenable: _historyController,
              builder: (context, child) {
                if (_historyController.isLoading &&
                    _historyController.historyData == null) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_historyController.errorMessage != null &&
                    _historyController.historyData == null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_historyController.errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final history = _historyController.historyData ?? [];

                if (history.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada riwayat aktivitas ditemukan'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _fetchData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: history.length,
                    itemBuilder: (context, index) {
                      final item = history[index];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors.primaryBlue
                                  .withOpacity(0.2),
                              child: const Icon(
                                Icons.shop_outlined,
                                color: AppColors.primaryBlue,
                              ),
                            ),

                            const SizedBox(width: 12),

                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['nama_sepatu']?.toString() ?? 'Sepatu',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),

                                  const SizedBox(height: 2),

                                  Text(
                                    '${item['layanan'] ?? '-'} - ${item['customer'] ?? '-'}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),

                                  const SizedBox(height: 4),

                                  Text(
                                    _formatDate(
                                      item['tanggal_order']?.toString(),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: _getStatusColor(
                                      item['status_order']?.toString(),
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    _formatStatus(
                                      item['status_order']?.toString(),
                                    ),
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),

                                const SizedBox(height: 8),

                                Text(
                                  _formatCurrency(item['total_harga']),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
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
}
