import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../controllers/beranda_controller.dart';
import '../../detail_layanan/views/detail_layanan_page.dart';

class BerandaPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const BerandaPage({super.key, required this.token, required this.user});

  @override
  State<BerandaPage> createState() => _BerandaPageState();
}

class _BerandaPageState extends State<BerandaPage> {
  late BerandaController _controller;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller = BerandaController();
    _controller.fetchBeranda(widget.token, isRefresh: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    _searchController.dispose();
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

  void _showSortSheet() {
    // Gunakan state sementara (draft) agar tidak langsung mengubah data utama
    String tempSortOrder = _controller.sortOrder;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Urutkan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Harga Terendah (Termurah)'),
                    trailing: tempSortOrder == 'asc' ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                    onTap: () {
                      setModalState(() => tempSortOrder = 'asc');
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Harga Tertinggi (Termahal)'),
                    trailing: tempSortOrder == 'desc' ? const Icon(Icons.check, color: AppColors.primaryBlue) : null,
                    onTap: () {
                      setModalState(() => tempSortOrder = 'desc');
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Terapkan ke controller dan panggil API
                        _controller.setSorting('harga', tempSortOrder);
                        _controller.fetchBeranda(widget.token, isRefresh: true);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Terapkan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showFilterSheet() {
    // Gunakan state sementara (draft) agar tidak langsung mengubah data utama
    String? tempSpesialisasi = _controller.selectedSpesialisasi;
    double? tempMinRating = _controller.minRating;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Layanan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 10),
                  const Text(
                    'Spesialisasi',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    children: [
                      _buildLocalFilterChip('Semua', null, tempSpesialisasi, (val) => setModalState(() => tempSpesialisasi = val)),
                      _buildLocalFilterChip('Sneakers', 'Sneakers', tempSpesialisasi, (val) => setModalState(() => tempSpesialisasi = val)),
                      _buildLocalFilterChip('Leather', 'Leather', tempSpesialisasi, (val) => setModalState(() => tempSpesialisasi = val)),
                      _buildLocalFilterChip('Canvas', 'Canvas', tempSpesialisasi, (val) => setModalState(() => tempSpesialisasi = val)),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Rating Minimum',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  Slider(
                    value: tempMinRating ?? 0,
                    min: 0,
                    max: 5,
                    divisions: 5,
                    label: (tempMinRating ?? 0).toString(),
                    activeColor: AppColors.primaryBlue,
                    onChanged: (value) {
                      setModalState(() {
                        tempMinRating = value == 0 ? null : value;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Terapkan ke controller dan panggil API
                        _controller.setSpesialisasi(tempSpesialisasi);
                        _controller.setMinRating(tempMinRating);
                        _controller.fetchBeranda(widget.token, isRefresh: true);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Terapkan Filter',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildLocalFilterChip(String label, String? value, String? currentValue, ValueChanged<String?> onSelected) {
    final isSelected = currentValue == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        onSelected(value);
      },
      selectedColor: AppColors.primaryBlue.withOpacity(0.2),
      labelStyle: TextStyle(
        color: isSelected ? AppColors.primaryBlue : Colors.black87,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        titleSpacing: 16,
        title: Container(
          height: 40,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: TextField(
            controller: _searchController,
            textInputAction: TextInputAction.search,
            decoration: const InputDecoration(
              hintText: 'Search Product',
              hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
              prefixIcon: Icon(Icons.search, color: AppColors.primaryBlue, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 10),
            ),
            onSubmitted: (value) {
              _controller.setSearch(value);
              _controller.fetchBeranda(widget.token, isRefresh: true);
            },
          ),
        ),
        actions: [
          IconButton(
            onPressed: _showSortSheet,
            icon: const Icon(Icons.swap_vert, color: Colors.grey),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          IconButton(
            onPressed: _showFilterSheet,
            icon: const Icon(Icons.filter_alt_outlined, color: AppColors.primaryBlue),
            constraints: const BoxConstraints(),
            padding: const EdgeInsets.symmetric(horizontal: 4),
          ),
          IconButton(
            onPressed: () {
              // TODO: Navigasi ke keranjang
            },
            icon: const Icon(Icons.shopping_cart_outlined, color: Colors.grey),
            padding: const EdgeInsets.only(right: 16, left: 4),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.services.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_controller.errorMessage != null && _controller.services.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(_controller.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => _controller.fetchBeranda(widget.token, isRefresh: true),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (_controller.services.isEmpty) {
            return const Center(
              child: Text('Tidak ada layanan yang ditemukan'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => _controller.fetchBeranda(widget.token, isRefresh: true),
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.7,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
              ),
              itemCount: _controller.services.length,
              itemBuilder: (context, index) {
                final service = _controller.services[index];
                return _buildServiceCard(service);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final toko = service['toko'] ?? {};
    final rating = toko['rating'] ?? 0.0;

    return GestureDetector(
      onTap: () {
        Navigator.push(
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
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Service Image
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                child: service['foto_layanan'] != null
                    ? Image.network(
                        service['foto_layanan'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    : _buildPlaceholderImage(),
              ),
            ),

            // Info Section
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service['nama_layanan'] ?? '-',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF223263), // Dark Blue color from image
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Star Rating
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
                  const SizedBox(height: 8),
                  Text(
                    _formatCurrency(service['harga']),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Shop Name (Optional but good for context)
                  Text(
                    toko['nm_toko'] ?? '-',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
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
      color: Colors.grey.shade100,
      child: Icon(Icons.image_outlined, size: 32, color: Colors.grey.shade400),
    );
  }
}
