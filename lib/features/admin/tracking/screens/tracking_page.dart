import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_scaffold.dart';
import '../../../../core/constants/app_colors.dart';
import '../controller/tracking_list_controller.dart';
import 'tracking_detail_page.dart';

class TrackingPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const TrackingPage({super.key, required this.token, required this.user});

  @override
  State<TrackingPage> createState() => _TrackingPageState();
}

class _TrackingPageState extends State<TrackingPage> {
  late TrackingListController _controller;
  final TextEditingController _searchController = TextEditingController();

  String _selectedStatus = 'all';

  final List<String> _statusList = [
    'all',
    'pending',
    'diproses',
    'washing',
    'pickup',
    'selesai',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TrackingListController();
    _fetchData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _fetchData() {
    _controller.fetchTrackingList(
      token: widget.token,
      status: _selectedStatus,
      search: _searchController.text.trim(),
    );
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'all':
        return 'Semua';
      case 'pending':
        return 'Pending';
      case 'diproses':
        return 'Diproses';
      case 'washing':
        return 'Washing';
      case 'pickup':
        return 'Pickup';
      case 'selesai':
        return 'Selesai';
      default:
        return status;
    }
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'pending':
        return Colors.orange;
      case 'diproses':
        return Colors.blue;
      case 'washing':
        return Colors.purple;
      case 'pickup':
        return Colors.teal;
      case 'selesai':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';

    try {
      final date = DateTime.parse(dateStr);
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
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

  int _totalHarga(List<dynamic>? details) {
    if (details == null || details.isEmpty) return 0;
    return details.fold<int>(0, (sum, item) {
      final value = double.tryParse(item['total_harga'].toString()) ?? 0;
      return sum + value.toInt();
    });
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: AppBar(
        title: const Text(
          'Tracking Kurir',
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
          Container(
            padding: const EdgeInsets.all(16),
            color: AppColors.primaryBlue,
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  onChanged: (_) => _fetchData(),
                  decoration: InputDecoration(
                    hintText: 'Cari kode order...',
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
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _statusList.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final status = _statusList[index];
                      final isSelected = _selectedStatus == status;

                      return ChoiceChip(
                        label: Text(_statusLabel(status)),
                        selected: isSelected,
                        selectedColor: Colors.white,
                        backgroundColor: AppColors.primaryBlue.withOpacity(
                          0.25,
                        ),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppColors.primaryBlue
                              : Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? Colors.white
                              : Colors.white.withOpacity(0.4),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _selectedStatus = status;
                          });
                          _fetchData();
                        },
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
              builder: (context, child) {
                if (_controller.isLoading && _controller.orders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_controller.errorMessage != null &&
                    _controller.orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_controller.errorMessage!),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: _fetchData,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  );
                }

                final orders = _controller.orders;

                if (orders.isEmpty) {
                  return const Center(
                    child: Text('Tidak ada tracking ditemukan'),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => _fetchData(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: orders.length,
                    itemBuilder: (context, index) {
                      final item = orders[index];
                      final details = item['detail_orders'] as List<dynamic>?;
                      final totalHarga = _totalHarga(details);

                      return InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TrackingDetailPage(
                                token: widget.token,
                                user: widget.user,
                                orderId: item['id_orders'],
                              ),
                            ),
                          );
                        },
                        child: Container(
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
                                  Icons.local_shipping_outlined,
                                  color: AppColors.primaryBlue,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item['kode_order']?.toString() ??
                                          'Kode Order',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      item['customers']?['nama']?.toString() ??
                                          '-',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatDate(
                                        item['tgl_order']?.toString(),
                                      ),
                                      style: const TextStyle(
                                        fontSize: 11,
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
                                      color: _statusColor(
                                        item['status_order']?.toString(),
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
                                    _formatCurrency(totalHarga),
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
