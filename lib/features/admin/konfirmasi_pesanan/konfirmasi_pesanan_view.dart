import 'package:flutter/material.dart';
import 'konfirmasi_service.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_text_styles.dart';

class KonfirmasiPesananView extends StatefulWidget {
  const KonfirmasiPesananView({super.key});

  @override
  State<KonfirmasiPesananView> createState() => _KonfirmasiPesananViewState();
}

class _KonfirmasiPesananViewState extends State<KonfirmasiPesananView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = false;
  List<dynamic> _orders = [];

  final List<Map<String, String>> _tabs = [
    {'label': 'Pesanan Masuk', 'status': 'pesanan_masuk'},
    {'label': 'Pembayaran', 'status': 'pembayaran'},
    {'label': 'Pesanan Baru', 'status': 'pesanan_baru'},
    {'label': 'Sedang Dicuci', 'status': 'sedang_dicuci'},
    {'label': 'Siap', 'status': 'siap'},
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _tabController.addListener(_handleTabChange);
    _fetchOrders();
  }

  void _handleTabChange() {
    if (!_tabController.indexIsChanging) {
      _fetchOrders();
    }
  }

  Future<void> _fetchOrders() async {
    setState(() => _isLoading = true);
    final status = _tabs[_tabController.index]['status']!;
    try {
      final data = await KonfirmasiService.getOrders(status);
      setState(() => _orders = data);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal mengambil data: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Manajemen Antrean', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: _tabs.map((tab) => Tab(text: tab['label'])).toList(),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : _orders.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: _fetchOrders,
                  color: AppColors.primary,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _orders.length,
                    itemBuilder: (context, index) {
                      final order = _orders[index];
                      return _buildOrderCard(order);
                    },
                  ),
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            'Tidak ada antrean',
            style: AppTextStyles.body.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(dynamic order) {
    final statusTab = _tabs[_tabController.index]['status'];
    final customer = order['customers'] ?? {};
    final details = (order['detail_orders'] as List?)?.first ?? {};

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  order['kode_order'] ?? '-',
                  style: AppTextStyles.title.copyWith(fontWeight: FontWeight.bold),
                ),
                _buildStatusChip(order['status_order']),
              ],
            ),
            const Divider(height: 24),
            _buildInfoRow(Icons.person, 'Pelanggan', customer['nama'] ?? '-'),
            _buildInfoRow(Icons.phone, 'No. HP', customer['nomor_hp'] ?? '-'),
            _buildInfoRow(Icons.cleaning_services, 'Layanan', details['services']?['nama_layanan'] ?? '-'),
            if (statusTab == 'pembayaran' && order['upload_bkt_byr'] != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: TextButton.icon(
                  onPressed: () => _showImagePreview(order['upload_bkt_byr']),
                  icon: const Icon(Icons.image, size: 18),
                  label: const Text('Lihat Bukti Bayar'),
                ),
              ),
            const SizedBox(height: 16),
            if (statusTab == 'pesanan_masuk' || statusTab == 'pembayaran')
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _showConfirmationDialog(order, 'reject'),
                      style: OutlinedButton.styleFrom(foregroundColor: AppColors.errorRed),
                      child: const Text('Tolak'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _showConfirmationDialog(order, 'approve'),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                      child: const Text('Setujui', style: TextStyle(color: Colors.white)),
                    ),
                  ),
                ],
              )
            else
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(
                    'Pesanan sedang diproses',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text('$label: ', style: AppTextStyles.caption.copyWith(color: Colors.grey)),
          Expanded(child: Text(value, style: AppTextStyles.caption)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String? status) {
    Color color = Colors.grey;
    String label = status?.toUpperCase() ?? '-';

    if (status == 'pending') {
      color = AppColors.primary;
      label = 'PESANAN MASUK';
    } else if (status == 'menunggu_pembayaran') {
      color = AppColors.warning;
      label = 'MENUNGGU BAYAR';
    } else if (status == 'pesanan_baru') {
      color = AppColors.successGreen;
      label = 'PESANAN BARU';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  void _showImagePreview(String url) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(url, fit: BoxFit.contain),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tutup')),
          ],
        ),
      ),
    );
  }

  void _showConfirmationDialog(dynamic order, String action) {
    final reasonController = TextEditingController();
    final isReject = action == 'reject';
    final statusTab = _tabs[_tabController.index]['status'];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(isReject ? 'Tolak Pesanan' : 'Setujui Pesanan'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(isReject 
              ? 'Apakah Anda yakin ingin menolak pesanan ini?' 
              : 'Apakah Anda yakin ingin menyetujui pesanan ini?'),
            if (isReject)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: TextField(
                  controller: reasonController,
                  decoration: const InputDecoration(
                    hintText: 'Masukkan alasan penolakan...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              if (isReject && reasonController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Alasan harus diisi')),
                );
                return;
              }
              
              Navigator.pop(context);
              setState(() => _isLoading = true);

              Map<String, dynamic> result;
              if (statusTab == 'pembayaran') {
                result = await KonfirmasiService.processPayment(
                  idOrders: order['id_orders'],
                  action: action,
                  reason: isReject ? reasonController.text : null,
                );
              } else {
                result = await KonfirmasiService.processOrder(
                  idOrders: order['id_orders'],
                  action: action,
                  reason: isReject ? reasonController.text : null,
                );
              }

              if (result['success'] == true) {
                _fetchOrders();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'] ?? 'Berhasil diproses')),
                  );
                }
              } else {
                if (mounted) {
                  setState(() => _isLoading = false);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result['message'] ?? 'Gagal memproses')),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: isReject ? AppColors.errorRed : AppColors.primary,
            ),
            child: Text(isReject ? 'Tolak' : 'Setujui', style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
