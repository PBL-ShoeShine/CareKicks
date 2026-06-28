import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_button.dart';
import '../controllers/ulasan_controller.dart';
import 'tulis_ulasan_page.dart';

class UlasanPage extends StatefulWidget {
  final String token;
  final int? idShops;

  const UlasanPage({super.key, required this.token, this.idShops});

  @override
  State<UlasanPage> createState() => _UlasanPageState();
}

class _UlasanPageState extends State<UlasanPage> {
  late UlasanController _controller;

  final List<Map<String, String>> _ratingFilters = [
    {'label': 'Semua', 'value': 'Semua'},
    {'label': '1', 'value': '1'},
    {'label': '2', 'value': '2'},
    {'label': '3', 'value': '3'},
    {'label': '4', 'value': '4'},
    {'label': '5', 'value': '5'},
  ];

  @override
  void initState() {
    super.initState();
    _controller = UlasanController();
    _controller.fetchUlasan(idShops: widget.idShops);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '-';
    try {
      final dateTime = DateTime.parse(dateStr);
      return DateFormat('MMMM d, yyyy').format(dateTime);
    } catch (e) {
      return dateStr;
    }
  }

  // --- Menampilkan Foto Fullscreen & Slider ---
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
            color: Colors.black54,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ulasan',
          style: TextStyle(
            color: Color(0xFF1E293B),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListenableBuilder(
                listenable: _controller,
                builder: (context, _) {
                  return Row(
                    children: _ratingFilters.map((filter) {
                      final isSelected =
                          _controller.selectedRating == filter['value'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            _controller.setRatingFilter(filter['value']!);
                            _controller.fetchUlasan(idShops: widget.idShops);
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEFF6FF)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFFDBEAFE)
                                    : Colors.grey.shade100,
                              ),
                            ),
                            child: Row(
                              children: [
                                if (filter['value'] != 'Semua') ...[
                                  const Icon(
                                    Icons.star,
                                    color: Colors.amber,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 4),
                                ],
                                Text(
                                  filter['label']!,
                                  style: TextStyle(
                                    color: isSelected
                                        ? const Color(0xFF3B82F6)
                                        : Colors.grey.shade400,
                                    fontSize: 14,
                                    fontWeight: isSelected
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ),

          // Ulasan List
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (context, _) {
                if (_controller.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (_controller.errorMessage != null) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _controller.errorMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.red),
                          ),
                          const SizedBox(height: 16),
                          CustomButton(
                            label: 'Coba Lagi',
                            onPressed: () => _controller.fetchUlasan(
                              idShops: widget.idShops,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (_controller.ulasanList.isEmpty) {
                  return const Center(child: Text('Belum ada ulasan'));
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _controller.ulasanList.length,
                  itemBuilder: (context, index) {
                    final ulasan = _controller.ulasanList[index];
                    return _buildUlasanItem(ulasan);
                  },
                );
              },
            ),
          ),

          // Bottom Button
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: SizedBox(
              width: double.infinity,
              child: CustomButton(
                label: 'Tulis Ulasan',
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => TulisUlasanPage(
                        token: widget.token,
                        idShops: widget.idShops,
                      ),
                    ),
                  );
                  if (result == true) {
                    _controller.fetchUlasan(idShops: widget.idShops);
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUlasanItem(Map<String, dynamic> ulasan) {
    final user = ulasan['user'] ?? {};
    final rating = ulasan['rating'] ?? 0;
    final List<dynamic> photos = ulasan['foto_ulasan'] ?? [];
    final userPhoto = user['foto']?.toString();

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey.shade100,
                backgroundImage: (userPhoto != null && userPhoto.isNotEmpty)
                    ? NetworkImage(userPhoto)
                    : null,
                child: (userPhoto == null || userPhoto.isEmpty)
                    ? const Icon(Icons.person, color: Colors.grey, size: 20)
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
                      fontSize: 15,
                      color: Color(0xFF1E293B),
                    ),
                  ),
                  Row(
                    children: List.generate(5, (index) {
                      return Icon(
                        Icons.star,
                        size: 16,
                        color: index < rating
                            ? Colors.amber
                            : Colors.grey.shade200,
                      );
                    }),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            ulasan['ulasan'] ?? '',
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 14,
              height: 1.5,
            ),
          ),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 80,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: photos.length,
                itemBuilder: (context, index) {
                  final String photoUrl = photos[index].toString();
                  final List<String> allPhotos = photos
                      .map((e) => e.toString())
                      .toList();

                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: GestureDetector(
                      onTap: () {
                        _showFullscreenImage(context, allPhotos, index);
                      },
                      // --- BUNGKUSAN CONTAINER AGAR UKURAN TETAP 80X80 ---
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
                            photoUrl,
                            width: 80,
                            height: 80,
                            fit: BoxFit.cover, // Wajib agar crop kotak presisi
                            errorBuilder: (_, __, ___) => const Center(
                              child: Icon(
                                Icons.broken_image,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
          const SizedBox(height: 12),
          Text(
            _formatDate(ulasan['created_at']),
            style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
