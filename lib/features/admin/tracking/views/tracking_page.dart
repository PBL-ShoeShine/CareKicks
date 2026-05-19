import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_scaffold.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_radius.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/widgets/custom_filter_chip.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../controllers/tracking_list_controller.dart';
import 'tracking_detail_page.dart';

enum TrackingMode { pickup, delivery }

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
  TrackingMode _activeMode = TrackingMode.pickup;

  static const Set<String> _pickupStatuses = {
    'menunggu_jemput',
    'sedang_dijemput',
    'diterima_toko',
  };

  static const Set<String> _deliveryStatuses = {
    'siap_diantar',
    'sedang_diantar',
    'diantar',
    'selesai',
  };

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
      search: _searchController.text.trim(),
    );
  }

  Color _statusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'menunggu_jemput':
      case 'pending':
      case 'siap_diantar':
        return AppColors.warning;
      case 'sedang_dijemput':
      case 'diproses':
      case 'sedang_diantar':
      case 'diantar':
        return AppColors.primaryBlue;
      case 'diterima_toko':
      case 'selesai':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
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

  String _displayStatus(dynamic value) {
    final raw = value?.toString().trim();
    if (raw == null || raw.isEmpty) return 'Pending';
    final normalized = raw.replaceAll('_', ' ').toLowerCase();
    return normalized.isEmpty
        ? 'Pending'
        : '${normalized[0].toUpperCase()}${normalized.substring(1)}';
  }

  List<dynamic> _filterByMode(List<dynamic> orders) {
    if (orders.isEmpty) return orders;
    final allowed = _activeMode == TrackingMode.pickup
        ? _pickupStatuses
        : _deliveryStatuses;
    return orders.where((item) {
      final status = item['status_order']?.toString().toLowerCase();
      return allowed.contains(status);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: AppColors.background,
      appBar: const CustomAppBar(title: 'Tracking Kurir'),
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
                  hintText: 'Cari kode order...',
                ),
                const SizedBox(height: AppSizes.gapMd),
                Align(
                  alignment: Alignment.center,
                  child: Container(
                    padding: const EdgeInsets.all(AppSizes.paddingSm),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: AppRadius.large,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CustomFilterChip(
                          label: 'Pickup',
                          selected: _activeMode == TrackingMode.pickup,
                          icon: Icons.call_received_rounded,
                          onSelected: () {
                            setState(() {
                              _activeMode = TrackingMode.pickup;
                            });
                          },
                        ),
                        const SizedBox(width: AppSizes.gapSm),
                        CustomFilterChip(
                          label: 'Delivery',
                          selected: _activeMode == TrackingMode.delivery,
                          icon: Icons.call_made_rounded,
                          onSelected: () {
                            setState(() {
                              _activeMode = TrackingMode.delivery;
                            });
                          },
                        ),
                      ],
                    ),
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

                final orders = _filterByMode(_controller.orders);

                if (orders.isEmpty) {
                  final emptyMessage = _activeMode == TrackingMode.pickup
                      ? 'Tidak ada tracking pickup'
                      : 'Tidak ada tracking delivery';
                  return Center(child: Text(emptyMessage));
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
                                      _displayStatus(item['status_order']),
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
