import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../controller/history_controller.dart';

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

  // final List<String> _statusList = [
  //   'all',
  //   'pending',
  //   'diproses',
  //   'washing',
  //   'pickup',
  //   'selesai'
  // ];

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
      search: _searchController.text,
      limit: 50,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _historyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Riwayat Aktivitas',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search and Filter Section
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryBlue,
            child: Column(
              children: [
                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (value) => _fetchData(),
                  decoration: InputDecoration(
                    hintText: 'Cari merk atau jenis sepatu...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Filter Chips
                // SizedBox(
                //   height: 40,
                //   child: ListView.builder(
                //     scrollDirection: Axis.horizontal,
                //     itemCount: _statusList.length,
                //     itemBuilder: (context, index) {
                //       final status = _statusList[index];
                //       final isSelected = _selectedStatus == status;
                //       return Padding(
                //         padding: const EdgeInsets.only(right: 8),
                //         child: FilterChip(
                //           label: Text(
                //             status[0].toUpperCase() + status.substring(1),
                //             style: TextStyle(
                //               color: isSelected ? Colors.white : Colors.black87,
                //               fontSize: 12,
                //             ),
                //           ),
                //           selected: isSelected,
                //           onSelected: (selected) {
                //             setState(() {
                //               _selectedStatus = status;
                //             });
                //             _fetchData();
                //           },
                //           selectedColor: AppColors.primaryDark,
                //           backgroundColor: Colors.white,
                //           checkmarkColor: Colors.white,
                //           shape: RoundedRectangleBorder(
                //             borderRadius: BorderRadius.circular(20),
                //           ),
                //         ),
                //       );
                //     },
                //   ),
                // ),
              ],
            ),
          ),

          // List Section
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
                                    item['nama_sepatu'] ?? 'Sepatu',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${item['layanan']} - ${item['customer']}',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    item['tanggal_order'] != null
                                        ? _formatDate(item['tanggal_order'])
                                        : '-',
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
                                      item['status_order'],
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    item['status_order']
                                            ?.toString()
                                            .toUpperCase() ??
                                        'PENDING',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Rp ${item['total_harga']}',
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

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return dateStr;
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'diproses':
        return Colors.blue;
      case 'selesai':
        return Colors.green;
      case 'washing':
        return Colors.purple;
      case 'pickup':
        return Colors.teal;
      default:
        return Colors.grey;
    }
  }
}
