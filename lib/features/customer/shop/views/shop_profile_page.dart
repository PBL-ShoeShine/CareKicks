import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../detail_layanan/views/detail_layanan_page.dart';
import '../controllers/shop_profile_controller.dart';

class ShopProfilePage extends StatefulWidget {
  final String token;
  final int idShops;
  final Map<String, dynamic> user;

  const ShopProfilePage({
    super.key,
    required this.token,
    required this.idShops,
    required this.user,
  });

  @override
  State<ShopProfilePage> createState() => _ShopProfilePageState();
}

class _ShopProfilePageState extends State<ShopProfilePage> {
  late final ShopProfileController _controller;

  @override
  void initState() {
    super.initState();
    _controller = ShopProfileController();
    _controller.fetchShopProfile(token: widget.token, idShops: widget.idShops);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'Rp 0';
    final number = int.tryParse(value.toString()) ?? 0;
    return NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(number);
  }

  String _formatDate(String? isoString) {
    if (isoString == null) return '-';
    try {
      final date = DateTime.parse(isoString);
      return DateFormat('MMMM yyyy').format(date);
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFF),
      body: ListenableBuilder(
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
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_controller.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _controller.fetchShopProfile(
                      token: widget.token,
                      idShops: widget.idShops,
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final data = _controller.shopData;
          if (data == null) return const SizedBox.shrink();

          return DefaultTabController(
            length: 2,
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) {
                return [
                  _buildAppBar(data),
                  SliverToBoxAdapter(
                    child: _buildShopInfo(data),
                  ),
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverAppBarDelegate(
                      const TabBar(
                        labelColor: AppColors.primaryBlue,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: AppColors.primaryBlue,
                        indicatorSize: TabBarIndicatorSize.tab,
                        tabs: [
                          Tab(text: 'Layanan'),
                          Tab(text: 'Ulasan'),
                        ],
                      ),
                    ),
                  ),
                ];
              },
              body: TabBarView(
                children: [
                  _buildServicesList(),
                  _buildReviewsList(),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildAppBar(Map<String, dynamic> data) {
    return SliverAppBar(
      expandedHeight: 160.0,
      floating: false,
      pinned: true,
      backgroundColor: AppColors.primaryBlue,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
            if (data['foto_toko'] != null)
              Opacity(
                opacity: 0.3,
                child: Image.network(data['foto_toko'], fit: BoxFit.cover),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 60, 20, 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: Colors.white,
                    child: CircleAvatar(
                      radius: 30,
                      backgroundImage: data['foto_toko'] != null ? NetworkImage(data['foto_toko']) : null,
                      child: data['foto_toko'] == null ? const Icon(Icons.storefront, size: 30) : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data['nm_toko'] ?? '-',
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star, color: Colors.orange, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${data['rating_avg'] ?? 0.0} (${data['total_reviews'] ?? 0} ulasan)',
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        _buildStatusBadge(data['is_open']),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(bool? isOpen) {
    final color = isOpen == true ? Colors.greenAccent : Colors.redAccent;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Text(
        isOpen == true ? 'BUKA' : 'TUTUP',
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildShopInfo(Map<String, dynamic> data) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tentang Toko', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          Text(data['desk_toko'] ?? 'Tidak ada deskripsi.', style: const TextStyle(color: Colors.grey, height: 1.4, fontSize: 13)),
          const SizedBox(height: 20),
          _buildInfoRow(Icons.location_on_outlined, 'Alamat', data['alamat_toko'] ?? '-'),
          _buildInfoRow(Icons.access_time_outlined, 'Jam Operasional', '${data['jam_buka']} - ${data['jam_tutup']}'),
          _buildInfoRow(Icons.calendar_today_outlined, 'Bergabung Sejak', _formatDate(data['tgl_berdiri'])),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                const SizedBox(height: 2),
                Text(value, style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesList() {
    if (_controller.services.isEmpty) {
      return const Center(child: Text('Toko belum memiliki layanan aktif.'));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: _controller.services.length,
      itemBuilder: (context, index) {
        final svc = _controller.services[index];
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DetailLayananPage(
                  token: widget.token,
                  user: widget.user,
                  serviceId: svc['id_services'],
                ),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade100),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    child: svc['foto_layanan'] != null
                        ? Image.network(svc['foto_layanan'], width: double.infinity, fit: BoxFit.cover)
                        : Container(color: Colors.grey.shade100),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(svc['nama_layanan'] ?? '-', maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      const SizedBox(height: 4),
                      Text(_formatCurrency(svc['harga']), style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold, fontSize: 13)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildReviewsList() {
    if (_controller.recentReviews.isEmpty) {
      return const Center(child: Text('Belum ada ulasan untuk toko ini.'));
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: _controller.recentReviews.length,
      separatorBuilder: (_, __) => const Divider(height: 32),
      itemBuilder: (context, index) {
        final review = _controller.recentReviews[index];
        final customer = review['customers'] ?? {};
        final rating = review['rating'] ?? 0;
        final service = review['services']?['nama_layanan'] ?? 'Layanan';

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundImage: customer['foto'] != null ? NetworkImage(customer['foto']) : null,
                  backgroundColor: Colors.grey.shade200,
                  child: customer['foto'] == null ? const Icon(Icons.person, size: 20) : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(customer['nama'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          ...List.generate(5, (i) => Icon(Icons.star, size: 12, color: i < rating ? Colors.orange : Colors.grey.shade300)),
                          const SizedBox(width: 8),
                          Text(DateFormat('dd MMM yyyy').format(DateTime.parse(review['created_at'])), style: TextStyle(color: Colors.grey.shade400, fontSize: 10)),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(4)),
              child: Text(service, style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),
            const SizedBox(height: 8),
            Text(review['ulasan'] ?? '', style: const TextStyle(fontSize: 13, height: 1.5)),
          ],
        );
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);
  final TabBar _tabBar;
  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;
  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(color: Colors.white, child: _tabBar);
  }
  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
