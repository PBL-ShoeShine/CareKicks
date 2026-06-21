import 'package:flutter/material.dart';
import 'package:carekicks/core/constants/app_colors.dart';
import 'package:carekicks/features/customer/ulasan/controllers/ulasan_controller.dart';

class UlasanAdminPage extends StatefulWidget {
  final String token;
  final int? idShops;

  const UlasanAdminPage({super.key, required this.token, this.idShops});

  @override
  State<UlasanAdminPage> createState() => _UlasanAdminPageState();
}

class _UlasanAdminPageState extends State<UlasanAdminPage> {
  late UlasanController _controller;
  final List<String> _filters = ['Semua', '5', '4', '3', '2', '1'];

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
      final date = DateTime.parse(dateStr).toLocal();
      return '${date.day}/${date.month}/${date.year}';
    } catch (_) {
      return dateStr;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Ulasan Pelanggan',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.ulasanList.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          return Column(
            children: [
              // ─── FILTER RATING ROW ─────────────────────────────────────────
              Container(
                color: Colors.white,
                height: 60,
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (context, index) {
                    final filter = _filters[index];
                    final isSelected = _controller.selectedRating == filter;
                    final isAll = filter == 'Semua';

                    return ChoiceChip(
                      label: Row(
                        children: [
                          Text(isAll ? filter : '$filter '),
                          if (!isAll)
                            Icon(
                              Icons.star_rounded,
                              size: 14,
                              color: isSelected ? Colors.white : Colors.amber,
                            ),
                        ],
                      ),
                      selected: isSelected,
                      onSelected: (_) {
                        _controller.setRatingFilter(filter);
                        _controller.fetchUlasan(idShops: widget.idShops);
                      },
                      selectedColor: AppColors.primaryBlue,
                      backgroundColor: const Color(0xFFF1F5F9),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? Colors.white
                            : const Color(0xFF64748B),
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 8),

              // ─── MAIN LIST ULASAN ──────────────────────────────────────────
              Expanded(
                child: _controller.ulasanList.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        padding: const EdgeInsets.all(20),
                        itemCount: _controller.ulasanList.length,
                        itemBuilder: (context, index) {
                          final ulasan = _controller.ulasanList[index];
                          return _buildUlasanCard(ulasan);
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildUlasanCard(Map<String, dynamic> item) {
    final user = item['user'] as Map<String, dynamic>?;
    final String namaUser = user?['nama'] ?? 'Pelanggan';
    final String? fotoUser = user?['foto'];
    final int rating = int.tryParse(item['rating']?.toString() ?? '0') ?? 0;
    final String teksUlasan = item['ulasan'] ?? '';
    final List<dynamic> fotoUlasan = item['foto_ulasan'] ?? [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: AppColors.lightBlue,
                backgroundImage: fotoUser != null && fotoUser.startsWith('http')
                    ? NetworkImage(fotoUser)
                    : null,
                child: fotoUser == null
                    ? const Icon(
                        Icons.person,
                        color: AppColors.primaryBlue,
                        size: 20,
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaUser,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(item['created_at']?.toString()),
                      style: const TextStyle(color: Colors.grey, fontSize: 11),
                    ),
                  ],
                ),
              ),
              Row(
                children: List.generate(5, (i) {
                  return Icon(
                    Icons.star_rounded,
                    size: 16,
                    color: i < rating ? Colors.amber : Colors.grey.shade200,
                  );
                }),
              ),
            ],
          ),
          const Divider(height: 24, color: Color(0xFFF1F5F9)),
          Text(
            teksUlasan,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF334155),
              height: 1.4,
            ),
          ),
          if (fotoUlasan.isNotEmpty) ...[
            const SizedBox(height: 12),
            SizedBox(
              height: 70,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: fotoUlasan.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, i) {
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      fotoUlasan[i].toString(),
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.star_outline_rounded,
            size: 64,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          const Text(
            'Belum ada ulasan',
            style: TextStyle(
              color: Color(0xFF64748B),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _controller.selectedRating == 'Semua'
                ? 'Toko kamu belum menerima ulasan dari pelanggan.'
                : 'Tidak ada ulasan dengan rating bintang ${_controller.selectedRating}.',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
