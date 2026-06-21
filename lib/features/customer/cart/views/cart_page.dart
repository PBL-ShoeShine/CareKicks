import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../shop/views/shop_profile_page.dart';
import '../controllers/cart_controller.dart';
import 'cart_checkout_page.dart';

class CartPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const CartPage({super.key, required this.token, required this.user});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  late CartController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CartController();
    _controller.fetchCart(token: widget.token);
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

  final _editMerkCtrl = TextEditingController();
  final _editJenisCtrl = TextEditingController();
  final _editWarnaCtrl = TextEditingController();
  final _editCatatanCtrl = TextEditingController();
  List<String> _editExistingPhotos = [];
  Map<int, File> _editNewPhotoMap = {};

  void _showEditSheet(Map<String, dynamic> item) {
    _editMerkCtrl.text = item['merk']?.toString() ?? '';
    _editJenisCtrl.text = item['jenis_sepatu']?.toString() ?? '';
    _editWarnaCtrl.text = item['warna']?.toString() ?? '';
    _editCatatanCtrl.text = item['catatan']?.toString() ?? '';

    final raw = item['foto_sebelum'];
    if (raw is List) {
      _editExistingPhotos = raw.cast<String>();
    } else if (raw is String && raw.isNotEmpty) {
      _editExistingPhotos = [raw];
    } else {
      _editExistingPhotos = [];
    }
    _editNewPhotoMap = {};

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 24,
                right: 24,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Edit Item',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF223263),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _editField('Merk', _editMerkCtrl),
                    const SizedBox(height: 12),
                    _editField('Jenis Sepatu', _editJenisCtrl),
                    const SizedBox(height: 12),
                    _editField('Warna', _editWarnaCtrl),
                    const SizedBox(height: 12),
                    _editField('Catatan', _editCatatanCtrl, maxLines: 3),
                    const SizedBox(height: 16),
                    const Text(
                      'Foto',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF223263),
                      ),
                    ),
                    const SizedBox(height: 8),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        crossAxisSpacing: 8,
                        mainAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemCount: 5,
                      itemBuilder: (ctx2, index) {
                        final newFile = _editNewPhotoMap[index];
                        final existingUrl = index < _editExistingPhotos.length ? _editExistingPhotos[index] : null;

                        return GestureDetector(
                          onTap: () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickImage(
                              source: ImageSource.gallery,
                              imageQuality: 80,
                            );
                            if (picked != null) {
                              setSheetState(() {
                                _editNewPhotoMap[index] = File(picked.path);
                              });
                            }
                          },
                          child: Stack(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: (newFile != null || existingUrl != null)
                                        ? AppColors.primaryBlue
                                        : Colors.grey.shade300,
                                  ),
                                  image: newFile != null
                                      ? DecorationImage(
                                          image: FileImage(newFile),
                                          fit: BoxFit.cover,
                                        )
                                      : existingUrl != null
                                          ? DecorationImage(
                                              image: NetworkImage(existingUrl),
                                              fit: BoxFit.cover,
                                            )
                                          : null,
                                ),
                                child: (newFile == null && existingUrl == null)
                                    ? Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.camera_alt_outlined,
                                              color: Colors.grey.shade400, size: 22),
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
                                    : null,
                              ),
                              if (newFile != null)
                                Positioned(
                                  top: 2, right: 2,
                                  child: GestureDetector(
                                    onTap: () => setSheetState(() => _editNewPhotoMap.remove(index)),
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.6),
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(Icons.close, color: Colors.white, size: 12),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          final changedFiles = _editNewPhotoMap.entries.toList();
                          await _controller.updateItem(
                            token: widget.token,
                            idCartItem: item['id_cart_item'] as int,
                            catatan: _editCatatanCtrl.text,
                            merk: _editMerkCtrl.text,
                            jenisSepatu: _editJenisCtrl.text,
                            warna: _editWarnaCtrl.text,
                            fotoIndices: changedFiles.isEmpty
                                ? null
                                : changedFiles.map((e) => e.key.toString()).join(','),
                            fotoSebelumList: changedFiles.isEmpty
                                ? null
                                : changedFiles.map((e) => e.value).toList(),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Simpan Perubahan',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _editField(String label, TextEditingController ctrl, {int maxLines = 1}) {
    return TextField(
      controller: ctrl,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primaryBlue),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }

  Future<void> _confirmDeleteItem(int idCartItem) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Item'),
        content: const Text('Yakin ingin menghapus item ini dari keranjang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _controller.deleteItem(
        token: widget.token,
        idCartItem: idCartItem,
      );
    }
  }

  void _handleCheckout() {
    if (_controller.selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih minimal satu item untuk checkout')),
      );
      return;
    }

    if (!_controller.allSelectedSameShop) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Checkout hanya bisa untuk item dari 1 toko yang sama'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CartCheckoutPage(
          token: widget.token,
          user: widget.user,
          controller: _controller,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Keranjang',
          style: TextStyle(
            color: Color(0xFF223263),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
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
                    onPressed: () => _controller.fetchCart(token: widget.token),
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          if (_controller.cartData.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 80, color: Colors.grey.shade300),
                  const SizedBox(height: 16),
                  Text(
                    'Keranjang masih kosong',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Temukan layanan favoritmu di halaman beranda',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return Stack(
            children: [
              ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                itemCount: _controller.cartData.length,
                itemBuilder: (context, index) {
                  final shop = _controller.cartData[index] as Map<String, dynamic>;
                  return _buildShopCard(shop);
                },
              ),
              _buildBottomBar(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildShopCard(Map<String, dynamic> shop) {
    final idCart = shop['id_cart'] as int;
    final shopInfo = shop['shop'] as Map<String, dynamic>? ?? {};
    final items = shop['items'] as List<dynamic>? ?? [];
    final shopSelected = _controller.isShopSelected(idCart);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
            child: Row(
              children: [
                Checkbox(
                  value: shopSelected,
                  onChanged: (_) => _controller.toggleShop(idCart),
                  activeColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    final idShops = shopInfo['id_shops'];
                    if (idShops != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ShopProfilePage(
                            token: widget.token,
                            idShops: idShops is int ? idShops : int.parse(idShops.toString()),
                            user: widget.user,
                          ),
                        ),
                      );
                    }
                  },
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircleAvatar(
                        radius: 14,
                        backgroundImage: shopInfo['foto_toko'] != null
                            ? NetworkImage(shopInfo['foto_toko'])
                            : null,
                        backgroundColor: Colors.grey.shade200,
                        child: shopInfo['foto_toko'] == null
                            ? const Icon(Icons.storefront, size: 14, color: Colors.grey)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        shopInfo['nm_toko'] ?? 'Toko',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: Color(0xFF223263),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...items.asMap().entries.map((entry) {
            final item = entry.value as Map<String, dynamic>;
            return GestureDetector(
              onTap: () => _showEditSheet(item),
              child: _buildCartItem(item),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildCartItem(Map<String, dynamic> item) {
    final idCartItem = item['id_cart_item'] as int;
    final service = item['services'] as Map<String, dynamic>? ?? {};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(
                value: _controller.isSelected(idCartItem),
                onChanged: (_) => _controller.toggleSelection(idCartItem),
                activeColor: AppColors.primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: service['foto_layanan'] != null
                    ? Image.network(
                        service['foto_layanan'],
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 64,
                          height: 64,
                          color: Colors.grey.shade100,
                          child: const Icon(Icons.image_outlined, color: Colors.grey),
                        ),
                      )
                    : Container(
                        width: 64,
                        height: 64,
                        color: Colors.grey.shade100,
                        child: const Icon(Icons.image_outlined, color: Colors.grey),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service['nama_layanan'] ?? 'Layanan',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color: Color(0xFF223263),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatCurrency(item['harga_layanan']),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                    if (item['merk'] != null || item['warna'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${item['merk'] ?? '-'} • ${item['warna'] ?? '-'}',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                    if (item['catatan'] != null && item['catatan'].toString().isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        'Catatan: ${item['catatan']}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: () => _confirmDeleteItem(idCartItem),
                icon: Icon(Icons.delete_outline, color: Colors.red.shade300, size: 20),
                constraints: const BoxConstraints(),
                padding: const EdgeInsets.all(4),
              ),
            ],
          ),
        ),
        _buildFotoThumbnails(item['foto_sebelum']),
        const Divider(height: 1, indent: 16, endIndent: 16),
      ],
    );
  }

  Widget _buildFotoThumbnails(dynamic fotoList) {
    if (fotoList == null) return const SizedBox.shrink();
    List<String> urls;
    if (fotoList is List) {
      urls = fotoList.cast<String>();
    } else if (fotoList is String) {
      try {
        final parsed = Uri.tryParse(fotoList);
        urls = parsed != null ? [fotoList] : [];
      } catch (_) {
        urls = [];
      }
    } else {
      urls = [];
    }
    if (urls.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: SizedBox(
        height: 48,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: urls.length,
          separatorBuilder: (_, __) => const SizedBox(width: 6),
          itemBuilder: (context, index) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.network(
                urls[index],
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 48,
                  height: 48,
                  color: Colors.grey.shade100,
                  child: Icon(Icons.broken_image, size: 20, color: Colors.grey.shade300),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Positioned(
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
        child: ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final total = _controller.totalSelectedPrice;
            final hasSelection = _controller.selectedItems.isNotEmpty;

            return Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Total Harga',
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatCurrency(total),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF223263),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 140,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: hasSelection ? _handleCheckout : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Checkout',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
