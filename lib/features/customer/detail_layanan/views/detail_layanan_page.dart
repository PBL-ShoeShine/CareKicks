import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../../core/constants/app_colors.dart';
import '../controllers/detail_layanan_controller.dart';
import 'semua_ulasan_page.dart';
import '../../order/screens/kirim_pesanan_page.dart';
import '../../shop/views/shop_profile_page.dart';
import '../../cart/controllers/cart_controller.dart';

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
  late CartController _cartController;

  @override
  void initState() {
    super.initState();
    _controller = DetailLayananController();
    _cartController = CartController();
    _controller.fetchDetail(token: widget.token, serviceId: widget.serviceId);
  }

  @override
  void dispose() {
    _controller.dispose();
    _cartController.dispose();
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
        'January',
        'February',
        'March',
        'April',
        'May',
        'June',
        'July',
        'August',
        'September',
        'October',
        'November',
        'December',
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
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black87,
            size: 20,
          ),
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
          final rekomendasi = List<Map<String, dynamic>>.from(
            data['rekomendasi'] ?? [],
          );

          return Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.only(
                  bottom: 100,
                ), // Ruang untuk tombol fixed
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Image
                    if (data['foto_layanan'] != null)
                      CachedNetworkImage(
                        imageUrl: data['foto_layanan'],
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: double.infinity,
                          height: 250,
                          color: Colors.grey.shade100,
                          child: const Center(
                            child: SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                        ),
                        errorWidget: (context, url, error) => _buildPlaceholderImage(),
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
                                    backgroundImage: CachedNetworkImageProvider(
                                      toko['foto_toko'],
                                    ),
                                    backgroundColor: Colors.grey.shade200,
                                  )
                                else
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundColor: Colors.grey.shade200,
                                    child: const Icon(
                                      Icons.storefront,
                                      size: 16,
                                      color: Colors.grey,
                                    ),
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
                              color: AppColors
                                  .primaryBlue, // Atau warna biru muda dari referensi
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
                              const Text(
                                'Jenis Layanan:',
                                style: TextStyle(color: Colors.black87),
                              ),
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
                              const Text(
                                'Estimasi Waktu:',
                                style: TextStyle(color: Colors.black87),
                              ),
                              Text(
                                data['estimasi_waktu'] ?? '-',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'Deskripsi Singkat:',
                            style: TextStyle(color: Colors.black87),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            data['deskripsi'] ?? '-',
                            style: const TextStyle(
                              color: Colors.grey,
                              height: 1.5,
                            ),
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
                                    padding: EdgeInsets.symmetric(
                                      vertical: 4.0,
                                      horizontal: 8.0,
                                    ),
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
                            const Text(
                              'Belum ada ulasan untuk toko ini.',
                              style: TextStyle(color: Colors.grey),
                            )
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
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 12),
                                itemBuilder: (context, index) {
                                  return _buildRecommendationCard(
                                    rekomendasi[index],
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Bottom Fixed Buttons
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
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
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 50,
                          child: OutlinedButton(
                            onPressed: !isOpen
                                ? null
                                : () => _showAddToCartSheet(data, toko),
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(
                                color: isOpen
                                    ? AppColors.primaryBlue
                                    : Colors.grey.shade300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
                            ),
                            child: Text(
                              isOpen ? '+ Keranjang' : 'Toko Tutup',
                              style: TextStyle(
                                color: isOpen
                                    ? AppColors.primaryBlue
                                    : Colors.grey.shade400,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: SizedBox(
                          height: 50,
                          child: ElevatedButton(
                            onPressed: !isOpen
                                ? null
                                : () {
                                    final idShops = toko['id_shops'];
                                    if (idShops == null) {
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            'Data toko tidak ditemukan',
                                          ),
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
                              backgroundColor: isOpen
                                  ? AppColors.primaryBlue
                                  : Colors.grey,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              isOpen ? 'Pesan Langsung' : 'Toko Sedang Tutup',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
              backgroundImage: user['foto'] != null
                  ? CachedNetworkImageProvider(user['foto'])
                  : null,
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
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF223263),
                  ),
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
                  child: CachedNetworkImage(
                    imageUrl: photos[index],
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade100,
                      child: const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 60,
                      height: 60,
                      color: Colors.grey.shade100,
                      child: const Icon(Icons.error, size: 16),
                    ),
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
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(12),
                ),
                 child: service['foto_layanan'] != null
                     ? CachedNetworkImage(
                         imageUrl: service['foto_layanan'],
                         width: double.infinity,
                         fit: BoxFit.cover,
                         placeholder: (context, url) => Container(
                           width: double.infinity,
                           color: Colors.grey.shade100,
                           child: const Center(
                             child: SizedBox(
                               width: 20,
                               height: 20,
                               child: CircularProgressIndicator(strokeWidth: 2),
                             ),
                           ),
                         ),
                         errorWidget: (context, url, error) =>
                             Container(color: Colors.grey.shade100),
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

  void _showAddToCartSheet(
    Map<String, dynamic> data,
    Map<String, dynamic> toko,
  ) {
    final merkCtrl = TextEditingController();
    final jenisCtrl = TextEditingController();
    final warnaCtrl = TextEditingController();
    final catatanCtrl = TextEditingController();
    final selectedImages = List<XFile?>.filled(5, null);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final hasAny = selectedImages.any((img) => img != null);
            final filledCount = selectedImages
                .where((img) => img != null)
                .length;

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                20 + MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Detail Kondisi Sepatu',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF223263),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Isi detail sepatu dan upload 5 foto kondisi sepatu',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: merkCtrl,
                      decoration: InputDecoration(
                        labelText: 'Merk Sepatu *',
                        hintText: 'Contoh: Nike, Adidas, Vans',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: jenisCtrl,
                      decoration: InputDecoration(
                        labelText: 'Jenis Sepatu *',
                        hintText: 'Contoh: Sneakers, Canvas, Leather',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: warnaCtrl,
                      decoration: InputDecoration(
                        labelText: 'Warna Sepatu *',
                        hintText: 'Contoh: Putih, Hitam, Abu-abu',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: catatanCtrl,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: 'Catatan (opsional)',
                        hintText: 'Misal: Tolong sikat bagian bawah perlahan',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Text(
                          'Foto Kondisi Sepatu',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF223263),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$filledCount/5',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: hasAny
                                ? AppColors.primaryBlue
                                : Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 5,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                      itemCount: 5,
                      itemBuilder: (ctx, index) {
                        final image = selectedImages[index];
                        return GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );
                            if (picked != null) {
                              setSheetState(
                                () => selectedImages[index] = picked,
                              );
                            }
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              color: image != null
                                  ? null
                                  : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: image != null
                                    ? AppColors.primaryBlue
                                    : Colors.grey.shade300,
                              ),
                              image: image != null
                                  ? DecorationImage(
                                      image: FileImage(File(image.path)),
                                      fit: BoxFit.cover,
                                    )
                                  : null,
                            ),
                            child: image == null
                                ? Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.grey.shade400,
                                        size: 22,
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        '${index + 1}',
                                        style: TextStyle(
                                          color: Colors.grey.shade400,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  )
                                : Stack(
                                    children: [
                                      Positioned(
                                        top: 2,
                                        right: 2,
                                        child: GestureDetector(
                                          onTap: () {
                                            setSheetState(
                                              () =>
                                                  selectedImages[index] = null,
                                            );
                                          },
                                          child: Container(
                                            padding: const EdgeInsets.all(2),
                                            decoration: BoxDecoration(
                                              color: Colors.black.withOpacity(
                                                0.6,
                                              ),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              Icons.close,
                                              color: Colors.white,
                                              size: 12,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: () async {
                          final merk = merkCtrl.text.trim();
                          final jenis = jenisCtrl.text.trim();
                          final warna = warnaCtrl.text.trim();

                          if (merk.isEmpty || jenis.isEmpty || warna.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Merk, jenis, dan warna sepatu wajib diisi',
                                ),
                              ),
                            );
                            return;
                          }

                          if (!hasAny) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Upload minimal 1 foto kondisi sepatu',
                                ),
                              ),
                            );
                            return;
                          }

                          final files = <File>[];
                          for (final img in selectedImages) {
                            if (img != null) {
                              final file = File(img.path);
                              if (await file.exists()) {
                                files.add(file);
                              }
                            }
                          }

                          if (files.isEmpty) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Gagal membaca file foto, coba pilih ulang',
                                ),
                              ),
                            );
                            return;
                          }

                          final idShops = toko['id_shops'];
                          if (idShops == null) return;

                          final success = await _cartController.addToCart(
                            token: widget.token,
                            idShops: idShops.toString(),
                            idServices: widget.serviceId.toString(),
                            hargaLayanan: data['harga'].toString(),
                            catatan: catatanCtrl.text.trim().isEmpty
                                ? null
                                : catatanCtrl.text.trim(),
                            merk: merk,
                            jenisSepatu: jenis,
                            warna: warna,
                            fotoSebelumList: files,
                          );

                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                          }

                          if (success && mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Berhasil ditambahkan ke keranjang',
                                ),
                                backgroundColor: AppColors.successGreen,
                              ),
                            );
                          } else if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  _cartController.errorMessage ??
                                      'Gagal menambahkan ke keranjang',
                                ),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Simpan ke Keranjang',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
