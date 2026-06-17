import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../controllers/detail_layanan_controller.dart';
import 'semua_ulasan_page.dart';
import '../../order/screens/kirim_pesanan_page.dart';
import '../../shop/views/shop_profile_page.dart';

class DetailLayananPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;
  final int serviceId;

  const DetailLayananPage({
    super.key,
    required this.token,
    required this.user,
    required this.serviceId,
  });

  @override
  State<DetailLayananPage> createState() => _DetailLayananPageState();
}

class _DetailLayananPageState extends State<DetailLayananPage> {
  late DetailLayananController _controller;

  @override
  void initState() {
    super.initState();
    _controller = DetailLayananController();
    _controller.fetchDetail(token: widget.token, serviceId: widget.serviceId);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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

  String _formatDate(String? isoString) {
    if (isoString == null) return '-';
    try {
      final date = DateTime.parse(isoString);
      final months = [
        'January', 'February', 'March', 'April', 'May', 'June',
        'July', 'August', 'September', 'October', 'November', 'December'
      ];
      return '${months[date.month - 1]} ${date.day}, ${date.year}';
    } catch (_) {
      return isoString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final shopName = _controller.serviceData?['toko']?['nm_toko'] ?? '';
            return Text(
              shopName,
              style: const TextStyle(
                color: Color(0xFF223263),
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            );
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.grey),
            onPressed: () {},
          ),
        ],
      ),
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
                    onPressed: () => _controller.fetchDetail(
                      token: widget.token,
                      serviceId: widget.serviceId,
                    ),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final data = _controller.serviceData;
          if (data == null) return const SizedBox.shrink();

          final toko = data['toko'] ?? {};
          final rating = toko['rating'] ?? 0.0;
          final isOpen = toko['is_open'] == true;
          final rekomendasi = List<Map<String, dynamic>>.from(data['rekomendasi'] ?? []);

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 100), // Ruang untuk tombol fixed
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Image
                    if (data['foto_layanan'] != null)
                      Image.network(
                        data['foto_layanan'],
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    else
                      _buildPlaceholderImage(),

                    Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Toko Info (Bisa diklik menuju profil toko)
                          GestureDetector(
                            onTap: () {
                              final idShops = toko['id_shops'];
                              if (idShops != null) {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ShopProfilePage(
                                      token: widget.token,
                                      idShops: idShops is int
                                          ? idShops
                                          : int.parse(idShops.toString()),
                                      user: widget.user,
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Row(
                              children: [
                                if (toko['foto_toko'] != null)
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: NetworkImage(toko['foto_toko']),
                                    backgroundColor: Colors.grey.shade200,
                                  )
                                else
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey.shade200,
                                    child: const Icon(Icons.storefront, size: 16, color: Colors.grey),
                                  ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    toko['nm_toko'] ?? '-',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF223263),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Rating
                          Row(
                            children: List.generate(5, (index) {
                              return Icon(
                                Icons.star,
                                size: 18,
                                color: index < rating.floor() 
                                    ? Colors.orange 
                                    : Colors.grey.shade300,
                              );
                            }),
                          ),
                          const SizedBox(height: 16),

                          // Harga
                          Text(
                            _formatCurrency(data['harga']),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primaryBlue, // Atau warna biru muda dari referensi
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Detail Layanan
                          const Text(
                            'Detail Layanan',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF223263),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Jenis Layanan:', style: TextStyle(color: Colors.black87)),
                              Text(
                                data['nama_layanan'] ?? '-',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Estimasi Waktu:', style: TextStyle(color: Colors.black87)),
                              Text(
                                data['estimasi_waktu'] ?? '-',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text('Deskripsi Singkat:', style: TextStyle(color: Colors.black87)),
                          const SizedBox(height: 8),
                          Text(
                            data['deskripsi'] ?? '-',
                            style: const TextStyle(color: Colors.grey, height: 1.5),
                          ),
                          const SizedBox(height: 32),

                          // Review Product
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'Review Product',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF223263),
                                ),
                              ),
                              if (_controller.reviews.isNotEmpty)
                                GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => SemuaUlasanPage(
                                          reviews: _controller.reviews,
                                          shopName: toko['nm_toko'] ?? '',
                                        ),
                                      ),
                                    );
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
                                    child: Text(
                                      'Selengkapnya',
                                      style: TextStyle(
                                        color: AppColors.primaryBlue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          
                          if (_controller.isLoadingReviews)
                            const Center(child: CircularProgressIndicator())
                          else if (_controller.reviews.isEmpty)
                            const Text('Belum ada ulasan untuk toko ini.', style: TextStyle(color: Colors.grey))
                          else
                            _buildReviewItem(_controller.reviews.first),

                          const SizedBox(height: 32),

                          // Rekomendasi
                          if (rekomendasi.isNotEmpty) ...[
                            const Text(
                              'Mungkin Anda Cari',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF223263),
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: 180,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: rekomendasi.length,
                                separatorBuilder: (_, __) => const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  return _buildRecommendationCard(rekomendasi[index]);
                                },
                              ),
                            ),
                          ]
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              
              // Bottom Fixed Button
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, -4),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: !isOpen ? null : () {
                        final idShops = toko['id_shops'];
                        if (idShops == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Data toko tidak ditemukan'),
                            ),
                          );
                          return;
                        }

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KirimPesananPage(
                              token: widget.token,
                              idShops: idShops is int
                                  ? idShops
                                  : int.parse(idShops.toString()),
                              prefillNama: widget.user['nama'],
                              prefillNoHp: widget.user['no_hp'],
                              prefillServiceId: widget.serviceId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isOpen ? AppColors.primaryBlue : Colors.grey,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        isOpen ? 'Pesan Jasa' : 'Toko Sedang Tutup',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildReviewItem(Map<String, dynamic> review) {
    final user = review['user'] ?? {};
    final rating = (review['rating'] as num?)?.toDouble() ?? 0.0;
    final photos = List<String>.from(review['foto_ulasan'] ?? []);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundImage: user['foto'] != null ? NetworkImage(user['foto']) : null,
              backgroundColor: Colors.grey.shade200,
              child: user['foto'] == null
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user['nama'] ?? 'User',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF223263)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: List.generate(5, (index) {
                    return Icon(
                      Icons.star,
                      size: 14,
                      color: index < rating.floor() 
                          ? Colors.orange 
                          : Colors.grey.shade300,
                    );
                  }),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          review['ulasan'] ?? '',
          style: const TextStyle(color: Colors.grey, height: 1.5, fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (photos.isNotEmpty)
          SizedBox(
            height: 60,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photos[index],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
        const SizedBox(height: 12),
        Text(
          _formatDate(review['created_at']),
          style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
        ),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> service) {
    return GestureDetector(
      onTap: () {
        // Mengganti halaman saat ini agar tidak menumpuk stack navigasi terlalu dalam
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => DetailLayananPage(
              token: widget.token,
              user: widget.user,
              serviceId: service['id_services'],
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: service['foto_layanan'] != null
                    ? Image.network(
                        service['foto_layanan'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade100),
                      )
                    : Container(color: Colors.grey.shade100),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['nama_layanan'] ?? '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF223263),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(service['harga']),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
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

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 250,
      color: Colors.grey.shade100,
      child: Icon(Icons.image_outlined, size: 64, color: Colors.grey.shade400),
    );
  }
}
