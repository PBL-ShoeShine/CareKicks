import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/utils/location_utils.dart';
import '../controllers/cart_controller.dart';
import '../../profile/services/customer_profile_service.dart';
import '../../profile/controllers/customer_profile_controller.dart';
import '../../profile/views/tambah_alamat_view.dart';
import '../../payment/views/payment_page.dart';

class CartCheckoutPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;
  final CartController controller;

  const CartCheckoutPage({
    super.key,
    required this.token,
    required this.user,
    required this.controller,
  });

  @override
  State<CartCheckoutPage> createState() => _CartCheckoutPageState();
}

class _CartCheckoutPageState extends State<CartCheckoutPage> {
  final _namaCtrl = TextEditingController();
  final _noHpCtrl = TextEditingController();
  final _profileCtrl = CustomerProfileController();

  Map<String, dynamic>? _selectedAlamat;
  bool _isLoadingAlamat = false;
  bool _isSubmitting = false;

  double? _shopLat;
  double? _shopLng;

  static const _blue = Color(0xFF2563EB);

  String get _effectiveAddress =>
      _selectedAlamat?['full_address']?.toString() ?? '';
  double? get _effectiveLat =>
      double.tryParse(_selectedAlamat?['latitude']?.toString() ?? '');
  double? get _effectiveLng =>
      double.tryParse(_selectedAlamat?['longitude']?.toString() ?? '');

  double get _distanceKm {
    if (_shopLat == null || _shopLng == null || _effectiveLat == null || _effectiveLng == null) {
      return 0.0;
    }
    return LocationUtils.calculateDistanceKm(
      _shopLat!, _shopLng!, _effectiveLat!, _effectiveLng!,
    );
  }

  int get _ongkir => LocationUtils.calculateOngkir(_distanceKm);

  @override
  void initState() {
    super.initState();
    final nama = widget.user['nama']?.toString() ?? '';
    final noHp = (widget.user['no_hp'] ?? widget.user['nomor_hp'] ?? '').toString();
    _namaCtrl.text = nama;
    _noHpCtrl.text = noHp;
    _extractShopCoords();
    _loadAlamat();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _noHpCtrl.dispose();
    _profileCtrl.dispose();
    super.dispose();
  }

  void _extractShopCoords() {
    if (widget.controller.cartData.isNotEmpty) {
      final shop = (widget.controller.cartData.first as Map<String, dynamic>)['shop'] as Map<String, dynamic>?;
      if (shop != null) {
        _shopLat = double.tryParse(shop['lat_toko']?.toString() ?? '');
        _shopLng = double.tryParse(shop['long_toko']?.toString() ?? '');
      }
    }
  }

  Future<void> _loadAlamat() async {
    setState(() => _isLoadingAlamat = true);
    final result = await CustomerProfileService.fetchAlamat(widget.token);
    if (result['success'] == true && result['data'] != null) {
      final list = (result['data'] as List).cast<Map<String, dynamic>>();
      final defaultAlamat = list.cast<Map<String, dynamic>?>().firstWhere(
        (a) => a?['is_default'] == true,
        orElse: () => list.isNotEmpty ? list.first : null,
      );
      if (defaultAlamat != null && _selectedAlamat == null) {
        _selectedAlamat = defaultAlamat;
      }
    }
    if (mounted) setState(() => _isLoadingAlamat = false);
  }

  Future<void> _showAddressPicker() async {
    await _profileCtrl.fetchAlamat(widget.token);
    final addresses = List<Map<String, dynamic>>.from(_profileCtrl.alamatList);

    final picked = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Pilih Alamat',
                        style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF223263),
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (addresses.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Belum ada alamat tersimpan',
                          style: TextStyle(color: Colors.grey.shade400),
                        ),
                      ),
                    )
                  else
                    ...addresses.map((addr) {
                      final isSelected = _selectedAlamat != null &&
                          _selectedAlamat!['id_address'] == addr['id_address'];
                      return ListTile(
                        leading: Radio<bool>(
                          value: true,
                          groupValue: isSelected ? true : null,
                          onChanged: (_) => Navigator.pop(ctx, addr),
                          activeColor: _blue,
                        ),
                        title: Text(
                          addr['recipient_name'] ?? '-',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (addr['phone_number'] != null)
                              Text(addr['phone_number'], style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                            Text(
                              addr['full_address'] ?? '',
                              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                        contentPadding: EdgeInsets.zero,
                        onTap: () => Navigator.pop(ctx, addr),
                      );
                    }),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        final saved = await Navigator.push<bool>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TambahAlamatView(
                              token: widget.token,
                              profileController: _profileCtrl,
                            ),
                          ),
                        );
                        if (saved == true) {
                          await _profileCtrl.fetchAlamat(widget.token);
                          final updated = _profileCtrl.alamatList;
                          if (updated.isNotEmpty) {
                            setState(() {
                              _selectedAlamat = Map<String, dynamic>.from(updated.last);
                            });
                          }
                        }
                      },
                      icon: const Icon(Icons.add_location_alt_outlined, size: 18),
                      label: const Text('Tambah Alamat Baru'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _blue,
                        side: BorderSide(color: _blue.withOpacity(0.5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );

    if (picked != null && mounted) {
      setState(() {
        _selectedAlamat = picked;
      });
    }
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

  Future<void> _submitOrder() async {
    if (_namaCtrl.text.trim().isEmpty) {
      _showSnackBar('Nama pemilik wajib diisi');
      return;
    }
    if (_noHpCtrl.text.trim().isEmpty) {
      _showSnackBar('No HP wajib diisi');
      return;
    }
    if (_effectiveAddress.isEmpty) {
      _showSnackBar('Alamat pengantaran wajib diisi');
      return;
    }
    if (widget.controller.selectedItems.isEmpty) {
      _showSnackBar('Tidak ada item yang dipilih');
      return;
    }

    setState(() => _isSubmitting = true);

    final result = await widget.controller.createOrderFromCart(
      token: widget.token,
      namaPemilik: _namaCtrl.text.trim(),
      noHp: _noHpCtrl.text.trim(),
      alamat: _effectiveAddress,
      latOrder: _effectiveLat,
      longOrder: _effectiveLng,
      totalOngkir: _ongkir,
    );

    setState(() => _isSubmitting = false);

    if (result != null && result['success'] == true) {
      final orderData = result['data'] as Map<String, dynamic>? ?? {};
      final orderId = orderData['id_orders'] as int?;
      final totalHarga = orderData['total_harga'] as int? ?? 0;

      if (!mounted) return;

      final deadlineStr = DateTime.now()
          .add(const Duration(hours: 24))
          .toIso8601String();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => PaymentPage(
            token: widget.token,
            orderId: (orderId ?? 0).toString(),
            totalAmount: totalHarga,
            paymentDeadline: deadlineStr,
          ),
        ),
        (route) => route.isFirst,
      );
    } else {
      _showSnackBar(result?['message'] ?? 'Gagal membuat pesanan');
    }
  }

  void _showSnackBar(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.red.shade400),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedItems = widget.controller.selectedItems;
    final subtotalLayanan = widget.controller.totalSelectedPrice;
    final grandTotal = subtotalLayanan + _ongkir;

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
          'Checkout',
          style: TextStyle(
            color: Color(0xFF223263),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      body: _isSubmitting
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildAlamatSection(),
                const SizedBox(height: 16),
                _buildContactSection(),
                const SizedBox(height: 16),
                _buildItemsSection(selectedItems),
                const SizedBox(height: 16),
                _buildOngkirSection(),
                const SizedBox(height: 16),
                _buildTotalSection(subtotalLayanan, grandTotal),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      'Buat Pesanan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildAlamatSection() {
    return GestureDetector(
      onTap: _showAddressPicker,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_outlined, color: _blue, size: 20),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Alamat Pengantaran',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Color(0xFF223263),
                    ),
                  ),
                ),
                Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            if (_isLoadingAlamat)
              const SizedBox(
                height: 40,
                child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else if (_selectedAlamat != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _selectedAlamat!['recipient_name'] ?? '',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                  ),
                  if (_selectedAlamat!['address_label'] != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _blue.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _selectedAlamat!['address_label'],
                        style: const TextStyle(fontSize: 11, color: _blue, fontWeight: FontWeight.w600),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                _selectedAlamat!['phone_number'] ?? '',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 4),
              Text(
                _selectedAlamat!['full_address'] ?? '',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
            ] else
              Text(
                'Tap untuk pilih alamat pengantaran',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.person_outline, color: _blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Kontak Pemilik',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF223263),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Nama dan no hp akun Anda digunakan untuk dihubungi kurir',
            style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _namaCtrl,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              labelText: 'Nama Pemilik',
              labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _blue),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _noHpCtrl,
            style: const TextStyle(fontSize: 14),
            keyboardType: TextInputType.phone,
            decoration: InputDecoration(
              labelText: 'No HP',
              labelStyle: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: _blue),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection(List<Map<String, dynamic>> items) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shopping_bag_outlined, color: _blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Item Dipilih',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF223263),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...items.asMap().entries.map((entry) {
            final item = entry.value;
            final service = item['services'] as Map<String, dynamic>? ?? {};
            return Padding(
              padding: EdgeInsets.only(top: entry.key > 0 ? 12 : 0),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: service['foto_layanan'] != null
                        ? Image.network(
                            service['foto_layanan'],
                            width: 48, height: 48, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              width: 48, height: 48,
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.image_outlined, color: Colors.grey, size: 20),
                            ),
                          )
                        : Container(
                            width: 48, height: 48,
                            color: Colors.grey.shade100,
                            child: const Icon(Icons.image_outlined, color: Colors.grey, size: 20),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service['nama_layanan'] ?? 'Layanan',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                        if (item['merk'] != null)
                          Text(
                            '${item['merk']} ${item['warna'] != null ? '• ${item['warna']}' : ''}',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    _formatCurrency(item['harga_layanan']),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryBlue,
                    ),
                  ),
                ],
              ),
            );
          }),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${items.length} item',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
              ),
              Text(
                _formatCurrency(
                  items.fold<int>(0, (s, i) => s + (int.tryParse(i['harga_layanan']?.toString() ?? '0') ?? 0)),
                ),
                style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF223263),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOngkirSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.local_shipping_outlined, color: _blue, size: 20),
              SizedBox(width: 8),
              Text(
                'Ongkos Kirim',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: Color(0xFF223263),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Jarak ${_distanceKm.toStringAsFixed(1)} km',
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
              Text(
                _ongkir == 0 ? 'Gratis' : _formatCurrency(_ongkir),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: _ongkir == 0 ? FontWeight.bold : FontWeight.w600,
                  color: _ongkir == 0 ? Colors.green : const Color(0xFF223263),
                ),
              ),
            ],
          ),
          if (_shopLat == null || _effectiveLat == null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Pilih alamat pengantaran untuk menghitung ongkos kirim',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade400, fontStyle: FontStyle.italic),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTotalSection(int subtotal, int grandTotal) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal Layanan', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              Text(_formatCurrency(subtotal), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Ongkos Kirim', style: TextStyle(fontSize: 14, color: Colors.grey.shade600)),
              Text(
                _ongkir == 0 ? 'Gratis' : _formatCurrency(_ongkir),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _ongkir == 0 ? Colors.green : null,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Total',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF223263)),
              ),
              Text(
                _formatCurrency(grandTotal),
                style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
