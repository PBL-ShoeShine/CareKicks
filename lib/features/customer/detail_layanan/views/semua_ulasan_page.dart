import 'package:flutter/material.dart';

class SemuaUlasanPage extends StatelessWidget {
  final List<dynamic> reviews;
  final String shopName;

  const SemuaUlasanPage({
    super.key,
    required this.reviews,
    required this.shopName,
  });

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

  // --- FUNGSI BARU: Menampilkan Foto Fullscreen & Slider ---
  void _showFullscreenImage(
    BuildContext context,
    List<String> photos,
    int initialPage,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(10),
          child: Stack(
            alignment: Alignment.center,
            children: [
              PageView.builder(
                itemCount: photos.length,
                controller: PageController(initialPage: initialPage),
                itemBuilder: (context, index) {
                  return InteractiveViewer(
                    panEnabled: true,
                    boundaryMargin: const EdgeInsets.all(20),
                    minScale: 0.5,
                    maxScale: 4.0,
                    child: Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          photos[index],
                          fit: BoxFit.contain,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: CircularProgressIndicator(
                                color: Colors.white,
                              ),
                            );
                          },
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.white,
                            padding: const EdgeInsets.all(20),
                            child: const Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.broken_image,
                                  size: 48,
                                  color: Colors.grey,
                                ),
                                SizedBox(height: 8),
                                Text(
                                  'Gagal memuat gambar',
                                  style: TextStyle(color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              Positioned(
                top: 10,
                right: 10,
                child: CircleAvatar(
                  backgroundColor: Colors.black.withOpacity(0.5),
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              if (photos.length > 1) ...[
                Positioned(
                  left: 10,
                  child: IgnorePointer(
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 36,
                    ),
                  ),
                ),
                Positioned(
                  right: 10,
                  child: IgnorePointer(
                    child: Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white.withOpacity(0.5),
                      size: 36,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Semua Ulasan',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text(
              shopName,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
      ),
      body: reviews.isEmpty
          ? const Center(child: Text('Belum ada ulasan.'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: reviews.length,
              separatorBuilder: (_, __) => const Divider(height: 32),
              itemBuilder: (context, index) {
                // Melempar 'context' agar bisa memanggil showDialog
                return _buildReviewItem(context, reviews[index]);
              },
            ),
    );
  }

  // Parameter ditambahkan BuildContext
  Widget _buildReviewItem(BuildContext context, Map<String, dynamic> review) {
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
              backgroundImage:
                  user['foto'] != null && user['foto'].toString().isNotEmpty
                  ? NetworkImage(user['foto'])
                  : null,
              backgroundColor: Colors.grey.shade200,
              child: (user['foto'] == null || user['foto'].toString().isEmpty)
                  ? const Icon(Icons.person, color: Colors.grey)
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
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
                    children: [
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
                      const SizedBox(width: 8),
                      Text(
                        _formatDate(review['created_at']),
                        style: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          review['ulasan'] ?? '',
          style: const TextStyle(
            color: Colors.black87,
            height: 1.5,
            fontSize: 13,
          ),
        ),
        const SizedBox(height: 12),
        if (photos.isNotEmpty)
          SizedBox(
            height: 80,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                return GestureDetector(
                  onTap: () => _showFullscreenImage(context, photos, index),
                  // --- PERBAIKAN: Dibungkus dengan Container ---
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey.shade100,
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        photos[index],
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => const Center(
                          child: Icon(Icons.broken_image, color: Colors.grey),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
