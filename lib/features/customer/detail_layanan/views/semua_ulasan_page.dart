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
              style: const TextStyle(
                color: Colors.grey,
                fontSize: 12,
              ),
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
                return _buildReviewItem(reviews[index]);
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user['nama'] ?? 'User',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF223263)),
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
                        style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
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
          style: const TextStyle(color: Colors.black87, height: 1.5, fontSize: 13),
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
                return ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    photos[index],
                    width: 80,
                    height: 80,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}
