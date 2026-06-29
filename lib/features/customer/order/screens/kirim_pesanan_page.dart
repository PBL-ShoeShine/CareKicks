import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/order_controller.dart';
import '../../detail_order/views/detail_order_page.dart';
import '../../profile/services/customer_profile_service.dart';
import '../../profile/services/tambah_alamat_service.dart';
import '../../profile/views/alamat_saya_view.dart';
import '../../profile/views/tambah_alamat_view.dart';
import '../../profile/controllers/customer_profile_controller.dart';

class KirimPesananPage extends StatefulWidget {
  final String token;
  final int idShops;
  final String? prefillNama;
  final String? prefillNoHp;
  final int? prefillServiceId;

  const KirimPesananPage({
    super.key,
    required this.token,
    required this.idShops,
    this.prefillNama,
    this.prefillNoHp,
    this.prefillServiceId,
  });

  @override
  State<KirimPesananPage> createState() => _KirimPesananPageState();
}

class _KirimPesananPageState extends State<KirimPesananPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final OrderController _controller;

  final _namaCtrl = TextEditingController();
  final _noHpCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();
  final _merkCtrl = TextEditingController();
  final _warnaCtrl = TextEditingController();
  final _jenisSepatuCtrl = TextEditingController();

  late final CustomerProfileController _profileController;

  // ─── State Alamat ────────────────────────────────────────────────────────
  List<Map<String, dynamic>> _alamatList = [];
  Map<String, dynamic>? _selectedAlamat; // dari saved addresses
  bool _isLoadingAlamat = false;

  // Alamat custom (jika bukan dari saved)
  String? _customAddress;
  double? _customLat;
  double? _customLng;

  // Getters untuk alamat efektif
  String get _effectiveAddress =>
      _customAddress ?? _selectedAlamat?['full_address']?.toString() ?? '';
  double? get _effectiveLat =>
      _customLat ??
      double.tryParse(_selectedAlamat?['latitude']?.toString() ?? '');
  double? get _effectiveLng =>
      _customLng ??
      double.tryParse(_selectedAlamat?['longitude']?.toString() ?? '');
  bool get _hasCoords => _effectiveLat != null && _effectiveLng != null;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _blue = Color(0xFF2563EB);
  static const _softBlue = Color(0xFFEFF6FF);
  static const _surface = Color(0xFFF8FAFF);

  @override
  void initState() {
    super.initState();
    _controller = OrderController();
    _profileController = CustomerProfileController();
    _namaCtrl.text = widget.prefillNama ?? '';
    _noHpCtrl.text = widget.prefillNoHp ?? '';

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    _controller.addListener(() {
      if (!_controller.isLoadingServices && _controller.services.isNotEmpty) {
        _animCtrl.forward();
        if (widget.prefillServiceId != null &&
            !_controller.selectedServiceIds.contains(
              widget.prefillServiceId!,
            )) {
          _controller.toggleService(widget.prefillServiceId!);
        }
      }
      if (_controller.errorMessage != null) {
        _showError(_controller.errorMessage!);
        _controller.clearError();
      }
    });

    _controller.fetchServices(token: widget.token, idShops: widget.idShops);
    _loadAlamat();
    _loadProfile();
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _noHpCtrl.dispose();
    _catatanCtrl.dispose();
    _merkCtrl.dispose();
    _warnaCtrl.dispose();
    _jenisSepatuCtrl.dispose();
    _animCtrl.dispose();
    _controller.dispose();
    _profileController.dispose();
    super.dispose();
  }

  // ─── Load alamat dari profil ──────────────────────────────────────────────

  Future<void> _loadAlamat() async {
    setState(() => _isLoadingAlamat = true);
    try {
      final result = await CustomerProfileService.fetchAlamat(widget.token);
      if (result['success'] == true) {
        final list = List<Map<String, dynamic>>.from(result['data'] ?? []);
        if (mounted) {
          setState(() {
            _alamatList = list;
            // Pilih yang is_default=true, fallback ke pertama
            final def = list.where((a) => a['is_default'] == true).toList();
            _selectedAlamat = def.isNotEmpty
                ? def.first
                : (list.isNotEmpty ? list.first : null);

            // Reset custom address jika beralih ke saved
            _customAddress = null;
            _customLat = null;
            _customLng = null;

            // Update lokasi di controller untuk hitung ongkir
            _controller.updateLocation(_effectiveLat, _effectiveLng);
          });
        }
      }
    } catch (e) {
      debugPrint('loadAlamat error: $e');
    } finally {
      if (mounted) setState(() => _isLoadingAlamat = false);
    }
  }

  // ─── Load profile data ───────────────────────────────────────────────────

  Future<void> _loadProfile() async {
    try {
      final result = await CustomerProfileService.fetchProfile(widget.token);
      if (result['success'] == true) {
        final data = result['data'];
        if (data != null && mounted) {
          setState(() {
            _namaCtrl.text = data['nama']?.toString() ?? _namaCtrl.text;
            _noHpCtrl.text = data['no_hp']?.toString() ?? _noHpCtrl.text;
          });
        }
      }
    } catch (e) {
      debugPrint('loadProfile error: $e');
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────

  String _fmt(int amount) =>
      'Rp ${amount.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}';

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Expanded(child: Text(msg, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showInfo(String msg, {Color? color}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        backgroundColor: color ?? Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─── Foto ─────────────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _SimpleSheet(
        children: [
          _SheetTile(
            icon: Icons.camera_alt_outlined,
            label: 'Kamera',
            onTap: () async {
              Navigator.pop(context);
              final pic = await ImagePicker().pickImage(
                source: ImageSource.camera,
                imageQuality: 80,
                maxWidth: 1080,
              );
              if (pic != null) _controller.addFotoSepatu(File(pic.path));
            },
          ),
          _SheetTile(
            icon: Icons.photo_library_outlined,
            label: 'Galeri',
            onTap: () async {
              Navigator.pop(context);
              final pic = await ImagePicker().pickImage(
                source: ImageSource.gallery,
                imageQuality: 80,
                maxWidth: 1080,
              );
              if (pic != null) _controller.addFotoSepatu(File(pic.path));
            },
          ),
        ],
      ),
    );
  }

  // ─── Alamat bottom sheet ──────────────────────────────────────────────────

  void _showAlamatOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _AlamatOptionsSheet(
        alamatList: _alamatList,
        selectedId: _selectedAlamat?['id_address'],
        onSelectSaved: (alamat) {
          setState(() {
            _selectedAlamat = alamat;
            _customAddress = null;
            _customLat = null;
            _customLng = null;
            _controller.updateLocation(_effectiveLat, _effectiveLng);
          });
          Navigator.pop(context);
        },
        onManageAddresses: () async {
          Navigator.pop(context);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AlamatSayaView(
                token: widget.token,
                profileController: _profileController,
              ),
            ),
          );
          _loadAlamat();
        },
        onAddNewAddress: () async {
          Navigator.pop(context);
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => TambahAlamatView(
                token: widget.token,
                profileController: _profileController,
              ),
            ),
          );
          _loadAlamat();
        },
      ),
    );
  }

  // ─── Submit ───────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_controller.selectedServiceIds.isEmpty) {
      _showError('Pilih minimal satu layanan');
      return;
    }
    if (_effectiveAddress.isEmpty) {
      _showError('Pilih alamat pengiriman terlebih dahulu');
      return;
    }

    HapticFeedback.mediumImpact();

    final result = await _controller.submitOrder(
      token: widget.token,
      idShops: widget.idShops,
      namaPemilik: _namaCtrl.text.trim(),
      noHp: _noHpCtrl.text.trim(),
      alamat: _effectiveAddress,
      merk: _merkCtrl.text.trim(),
      jenisSepatu: _jenisSepatuCtrl.text.trim(),
      warna: _warnaCtrl.text.trim(),
      catatan: _catatanCtrl.text.trim().isEmpty
          ? null
          : _catatanCtrl.text.trim(),
      latOrder: _effectiveLat,
      longOrder: _effectiveLng,
    );

    if (!mounted) return;
    if (result != null) {
      HapticFeedback.heavyImpact();
      _showSuccessDialog(result);
    }
  }

  void _showSuccessDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OrderSuccessDialog(
        kodeOrder: data['kode_order']?.toString() ?? '-',
        totalHarga: _controller.totalHargaKeseluruhan,
        nmToko: _controller.nmToko,
        qrCodeUrl: data['qr_code']?.toString(),
        onLihatPesanan: () {
          Navigator.of(context).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => DetailOrderPage(
                token: widget.token,
                orderId: data['id_orders'].toString(),
              ),
            ),
          );
        },
        onKembali: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (_, __) {
                if (_controller.isLoadingServices) return const _LoadingState();
                return Form(
                  key: _formKey,
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 120),
                      children: [
                        _buildFotoSection(),
                        const SizedBox(height: 16),
                        _buildInfoSection(),
                        const SizedBox(height: 16),
                        _buildDetailSepatuSection(),
                        const SizedBox(height: 16),
                        _buildAlamatSection(),
                        const SizedBox(height: 16),
                        _buildServiceSection(),
                        const SizedBox(height: 16),
                        _buildCatatanSection(),
                        const SizedBox(height: 16),
                        _buildTotalSection(),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  Widget _buildAppBar() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(4, 8, 16, 16),
          child: Row(
            children: [
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kirim Pesanan',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (_, __) {
                        if (_controller.nmToko.isEmpty)
                          return const SizedBox.shrink();
                        return Text(
                          _controller.nmToko,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Foto ─────────────────────────────────────────────────────────────────

  Widget _buildFotoSection() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (_, __) {
        final fotos = _controller.fotoSepatuList;
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Label(
                icon: Icons.camera_alt_outlined,
                label: 'Foto Sepatu',
                suffix: _Badge(text: '${fotos.length}/5 (Wajib)'),
              ),
              const SizedBox(height: 12),
              if (fotos.isNotEmpty)
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: fotos.length < 5 ? fotos.length + 1 : 5,
                    separatorBuilder: (_, __) => const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      if (index == fotos.length && fotos.length < 5) {
                        return GestureDetector(
                          onTap: _pickPhoto,
                          child: Container(
                            width: 100,
                            decoration: BoxDecoration(
                              color: _softBlue,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _blue.withOpacity(0.25),
                                width: 1.5,
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 28,
                                color: _blue,
                              ),
                            ),
                          ),
                        );
                      }
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: _blue.withOpacity(0.4),
                                width: 1.5,
                              ),
                              image: DecorationImage(
                                image: FileImage(fotos[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: -6,
                            right: -6,
                            child: GestureDetector(
                              onTap: () => _controller.removeFotoSepatu(index),
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                )
              else
                GestureDetector(
                  onTap: _pickPhoto,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _softBlue,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _blue.withOpacity(0.25),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _blue.withOpacity(0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add_photo_alternate_outlined,
                            size: 24,
                            color: _blue,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Tap untuk upload foto sepatu',
                          style: TextStyle(
                            fontSize: 13,
                            color: _blue,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Format JPG/PNG · Maks 5 Foto',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── Info Pemilik ─────────────────────────────────────────────────────────

  Widget _buildInfoSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label(icon: Icons.person_outline, label: 'Informasi Pemilik'),
          const SizedBox(height: 16),
          _Field(
            controller: _namaCtrl,
            label: 'Nama Pemilik Sepatu',
            hint: 'Mengambil data...',
            icon: Icons.badge_outlined,
            readOnly: true,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          _Field(
            controller: _noHpCtrl,
            label: 'Nomor HP',
            hint: 'Mengambil data...',
            icon: Icons.phone_outlined,
            keyboard: TextInputType.phone,
            readOnly: true,
            formatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nomor HP wajib diisi';
              if (v.trim().length < 9) return 'Nomor HP tidak valid';
              return null;
            },
          ),
        ],
      ),
    );
  }

  // ─── Detail Sepatu ────────────────────────────────────────────────────────

  Widget _buildDetailSepatuSection() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (_, __) {
        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const _Label(
                icon: Icons.ice_skating_outlined,
                label: 'Detail Sepatu',
              ),
              const SizedBox(height: 16),
              _Field(
                controller: _merkCtrl,
                label: 'Merk Sepatu',
                hint: 'Contoh: Nike, Adidas, dll',
                icon: Icons.branding_watermark_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Merk sepatu wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _jenisSepatuCtrl,
                label: 'Jenis Sepatu',
                hint: 'Contoh: Sneakers, Boots, dll',
                icon: Icons.category_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Jenis sepatu wajib diisi'
                    : null,
              ),
              const SizedBox(height: 12),
              _Field(
                controller: _warnaCtrl,
                label: 'Warna Sepatu',
                hint: 'Contoh: Putih, Hitam, Merah',
                icon: Icons.color_lens_outlined,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Warna sepatu wajib diisi'
                    : null,
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Alamat ───────────────────────────────────────────────────────────────

  Widget _buildAlamatSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Label(
            icon: Icons.location_on_outlined,
            label: 'Alamat Pengiriman',
            suffix: GestureDetector(
              onTap: _showAlamatOptions,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.edit_outlined, size: 13, color: _blue),
                    SizedBox(width: 4),
                    Text(
                      'Ubah',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _blue,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),

          if (_isLoadingAlamat)
            const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: _blue,
                  ),
                ),
              ),
            )
          else if (_effectiveAddress.isEmpty)
            GestureDetector(
              onTap: _showAlamatOptions,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade200),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.add_location_alt_outlined,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _alamatList.isEmpty
                            ? 'Belum ada alamat. Tambah di Profil → Alamat Saya'
                            : 'Pilih alamat pengiriman',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.orange.shade800,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    Icon(Icons.chevron_right, color: Colors.orange.shade400),
                  ],
                ),
              ),
            )
          else
            GestureDetector(
              onTap: _showAlamatOptions,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _softBlue,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _blue.withOpacity(0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.location_on, color: _blue, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label: saved address label or "Custom"
                          if (_customAddress != null)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.orange,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: const Text(
                                'Lokasi Manual',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            )
                          else if (_selectedAlamat?['address_label'] != null &&
                              _selectedAlamat!['address_label']
                                  .toString()
                                  .isNotEmpty)
                            Container(
                              margin: const EdgeInsets.only(bottom: 4),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: _blue,
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: Text(
                                _selectedAlamat!['address_label'].toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),

                          if (_selectedAlamat != null && _customAddress == null)
                            Text(
                              _selectedAlamat!['recipient_name']?.toString() ??
                                  '',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: Color(0xFF1E293B),
                              ),
                            ),

                          Text(
                            _effectiveAddress,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                              height: 1.4,
                            ),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),

                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                _hasCoords ? Icons.gps_fixed : Icons.gps_off,
                                size: 11,
                                color: _hasCoords
                                    ? Colors.green.shade600
                                    : Colors.orange.shade600,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  _hasCoords
                                      ? 'Koordinat tersimpan — jemput otomatis ✓'
                                      : 'Koordinat belum terdeteksi',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _hasCoords
                                        ? Colors.green.shade600
                                        : Colors.orange.shade600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: _blue, size: 18),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─── Layanan ──────────────────────────────────────────────────────────────

  Widget _buildServiceSection() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (_, __) {
        final displayServices = widget.prefillServiceId != null
            ? _controller.services
                  .where((s) => s['id_services'] == widget.prefillServiceId)
                  .toList()
            : _controller.services;

        return _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Label(
                icon: Icons.cleaning_services_outlined,
                label: 'Pilih Layanan',
                suffix: _controller.selectedServiceIds.isEmpty
                    ? null
                    : Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: _blue,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${_controller.selectedServiceIds.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: 4),
              Text(
                widget.prefillServiceId != null
                    ? 'Layanan yang Anda pilih'
                    : 'Pilih satu atau lebih layanan',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
              ),
              const SizedBox(height: 14),
              if (displayServices.isEmpty && !_controller.isLoadingServices)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(
                      'Tidak ada layanan tersedia',
                      style: TextStyle(color: Colors.grey.shade400),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 8,
                  runSpacing: 10,
                  children: displayServices.map((svc) {
                    final id = svc['id_services'] as int;
                    final isSelected = _controller.isServiceSelected(id);
                    return _ServiceChip(
                      nama: svc['nama_layanan']?.toString() ?? '-',
                      harga: _fmt(
                        int.tryParse(svc['harga']?.toString() ?? '0') ?? 0,
                      ),
                      estimasi: svc['estimasi_waktu']?.toString(),
                      isSelected: isSelected,
                      onTap: () {
                        HapticFeedback.selectionClick();
                        _controller.toggleService(id);
                      },
                    );
                  }).toList(),
                ),
            ],
          ),
        );
      },
    );
  }

  // ─── Catatan ──────────────────────────────────────────────────────────────

  Widget _buildCatatanSection() {
    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _Label(
            icon: Icons.note_outlined,
            label: 'Catatan',
            suffix: _Badge(text: 'Opsional'),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _catatanCtrl,
            maxLines: 3,
            maxLength: 300,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText: 'Catatan khusus (kondisi noda, jenis bahan, dll.)',
              hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: _surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _blue, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
              counterStyle: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Ringkasan Total ──────────────────────────────────────────────────────

  Widget _buildTotalSection() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (_, __) {
        final selected = _controller.services
            .where(
              (s) => _controller.selectedServiceIds.contains(s['id_services']),
            )
            .toList();
        if (selected.isEmpty) return const SizedBox.shrink();

        final dist = _controller.distanceKm;
        final ongkir = _controller.totalOngkir;

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1D4ED8), Color(0xFF3B82F6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _blue.withOpacity(0.28),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ringkasan Pesanan',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 12),
              ...selected.map((s) {
                final h = int.tryParse(s['harga']?.toString() ?? '0') ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          s['nama_layanan']?.toString() ?? '-',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        _fmt(h),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: _controller.isFetchingOsrm
                        ? Row(
                            children: [
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                    strokeWidth: 1.5, color: Colors.white70),
                              ),
                              const SizedBox(width: 6),
                              const Text('Menghitung jarak...',
                                  style: TextStyle(color: Colors.white70, fontSize: 13)),
                            ],
                          )
                        : Text(
                            'Ongkos Kirim (${dist.toStringAsFixed(1)} km)',
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                  ),
                  const SizedBox(width: 8),
                  _controller.isFetchingOsrm
                      ? const SizedBox(width: 0)
                      : Text(ongkir == 0 ? 'Gratis' : _fmt(ongkir),
                          style: TextStyle(
                              color: ongkir == 0 ? Colors.greenAccent : Colors.white,
                              fontWeight: ongkir == 0 ? FontWeight.bold : FontWeight.normal,
                              fontSize: 13)),
                ],
              ),

              Divider(color: Colors.white.withOpacity(0.3), height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total Pembayaran',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      _fmt(_controller.totalHargaKeseluruhan),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Bottom Bar ───────────────────────────────────────────────────────────

  Widget _buildBottomBar() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (_, __) {
        final ready =
            !_controller.isSubmitting &&
            !_controller.isLoadingServices &&
            _controller.selectedServiceIds.isNotEmpty;

        return Container(
          padding: EdgeInsets.fromLTRB(
            16,
            12,
            16,
            12 + MediaQuery.of(context).padding.bottom,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: ready ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _blue,
                disabledBackgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: ready ? 4 : 0,
                shadowColor: _blue.withOpacity(0.4),
              ),
              child: _controller.isSubmitting
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.send_rounded, size: 18),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            _controller.selectedServiceIds.isEmpty
                                ? 'Pilih Layanan Terlebih Dahulu'
                                : 'Konfirmasi Pesanan',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        );
      },
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// ALAMAT OPTIONS SHEET
// ════════════════════════════════════════════════════════════════════════════

class _AlamatOptionsSheet extends StatelessWidget {
  final List<Map<String, dynamic>> alamatList;
  final dynamic selectedId;
  final ValueChanged<Map<String, dynamic>> onSelectSaved;
  final VoidCallback onManageAddresses;
  final VoidCallback onAddNewAddress;

  const _AlamatOptionsSheet({
    required this.alamatList,
    required this.selectedId,
    required this.onSelectSaved,
    required this.onManageAddresses,
    required this.onAddNewAddress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.75,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 4),
            width: 36,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Pilih Alamat',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                // Opsi: Tambah Alamat Baru
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_location_alt_outlined,
                      color: Colors.blue.shade700,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Tambah Alamat Baru',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Tambahkan alamat pengiriman baru',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: onAddNewAddress,
                ),
                // Opsi: Kelola Alamat
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.settings_outlined,
                      color: Colors.orange.shade700,
                      size: 20,
                    ),
                  ),
                  title: const Text(
                    'Kelola Alamat Saya',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  subtitle: Text(
                    'Ubah atau hapus alamat tersimpan',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                  trailing: const Icon(Icons.chevron_right, size: 18),
                  onTap: onManageAddresses,
                ),

                if (alamatList.isNotEmpty) ...[
                  const Divider(height: 1, indent: 20, endIndent: 20),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 10, 20, 4),
                    child: Text(
                      'Alamat Tersimpan',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade500,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  ...alamatList.take(5).map((a) {
                    final isSelected = selectedId == a['id_address'];
                    final hasCoords =
                        a['latitude'] != null && a['longitude'] != null;
                    final label = a['address_label']?.toString() ?? '';
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 2,
                      ),
                      leading: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEFF6FF)
                              : Colors.grey.shade100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on,
                          color: isSelected
                              ? const Color(0xFF2563EB)
                              : Colors.grey.shade500,
                          size: 18,
                        ),
                      ),
                      title: Row(
                        children: [
                          Expanded(
                            child: Text(
                              a['recipient_name']?.toString() ?? '-',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                                color: isSelected
                                    ? const Color(0xFF2563EB)
                                    : const Color(0xFF1E293B),
                              ),
                            ),
                          ),
                          if (label.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 5,
                                vertical: 1,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFF2563EB),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                label,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            a['full_address']?.toString() ?? '-',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Row(
                            children: [
                              Icon(
                                hasCoords ? Icons.gps_fixed : Icons.gps_off,
                                size: 10,
                                color: hasCoords
                                    ? Colors.green.shade600
                                    : Colors.orange.shade600,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                hasCoords
                                    ? 'Koordinat tersimpan'
                                    : 'Koordinat belum ada',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: hasCoords
                                      ? Colors.green.shade600
                                      : Colors.orange.shade600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF2563EB),
                              size: 20,
                            )
                          : null,
                      onTap: () => onSelectSaved(a),
                    );
                  }),
                ],
                const SizedBox(height: 8),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// SUCCESS DIALOG WITH QR CODE
// ════════════════════════════════════════════════════════════════════════════

class _OrderSuccessDialog extends StatefulWidget {
  final String kodeOrder;
  final int totalHarga;
  final String nmToko;
  final String? qrCodeUrl;
  final VoidCallback onLihatPesanan;
  final VoidCallback onKembali;

  const _OrderSuccessDialog({
    required this.kodeOrder,
    required this.totalHarga,
    required this.nmToko,
    this.qrCodeUrl,
    required this.onLihatPesanan,
    required this.onKembali,
  });

  @override
  State<_OrderSuccessDialog> createState() => _OrderSuccessDialogState();
}

class _OrderSuccessDialogState extends State<_OrderSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _fmt(int v) =>
      'Rp ${v.toString().replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+$)'), (m) => '${m[1]}.')}';

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.12),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF059669)],
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Pesanan Berhasil!',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 20,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Pesanan Anda telah dikirim ke ${widget.nmToko}.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade600,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Info box
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFF),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E7FF)),
                  ),
                  child: Column(
                    children: [
                      _row('Kode Order', widget.kodeOrder, bold: true),
                      const Divider(height: 14),
                      _row('Total', _fmt(widget.totalHarga)),
                      const Divider(height: 14),
                      _row('Status', 'Menunggu Verifikasi'),
                    ],
                  ),
                ),
                const SizedBox(height: 10),

                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFFBEB),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFDE68A)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.info_outline,
                        color: Color(0xFFF59E0B),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Upload bukti pembayaran di halaman detail pesanan.',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange.shade800,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onKembali,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.grey.shade700,
                          side: BorderSide(color: Colors.grey.shade300),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Kembali'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton(
                        onPressed: widget.onLihatPesanan,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2563EB),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Lihat Pesanan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13,
              fontWeight: bold ? FontWeight.bold : FontWeight.w600,
              color: const Color(0xFF1E293B),
            ),
          ),
        ),
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// REUSABLE WIDGETS
// ════════════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final Widget child;
  const _Card({required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

class _Label extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? suffix;
  const _Label({required this.icon, required this.label, this.suffix});

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: const Color(0xFFEFF6FF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF2563EB)),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1E293B),
          ),
        ),
      ),
      if (suffix != null) ...[const SizedBox(width: 8), suffix!],
    ],
  );
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      fontSize: 11,
      color: Colors.grey,
      fontStyle: FontStyle.italic,
    ),
  );
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icon;
  final TextInputType? keyboard;
  final List<TextInputFormatter>? formatters;
  final String? Function(String?)? validator;
  final bool readOnly;

  const _Field({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icon,
    this.keyboard,
    this.formatters,
    this.validator,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Color(0xFF374151),
        ),
      ),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller,
        keyboardType: keyboard,
        inputFormatters: formatters,
        validator: validator,
        readOnly: readOnly,
        style: TextStyle(
          fontSize: 14,
          color: readOnly ? Colors.grey.shade600 : const Color(0xFF111827),
        ),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          prefixIcon: Icon(icon, size: 20, color: Colors.grey.shade400),
          filled: true,
          fillColor: readOnly ? Colors.grey.shade100 : const Color(0xFFF8FAFF),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade200),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: readOnly
                ? BorderSide(color: Colors.grey.shade200)
                : const BorderSide(color: Color(0xFF2563EB), width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
          ),
          contentPadding: EdgeInsets.zero,
        ),
      ),
    ],
  );
}

class _ServiceChip extends StatelessWidget {
  final String nama;
  final String harga;
  final String? estimasi;
  final bool isSelected;
  final VoidCallback onTap;

  const _ServiceChip({
    required this.nama,
    required this.harga,
    this.estimasi,
    required this.isSelected,
    required this.onTap,
  });

  static const _blue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? _blue : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected ? _blue : Colors.grey.shade300,
          width: isSelected ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isSelected
                ? _blue.withOpacity(0.25)
                : Colors.black.withOpacity(0.04),
            blurRadius: isSelected ? 8 : 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isSelected) ...[
            const Icon(Icons.check_circle, color: Colors.white, size: 15),
            const SizedBox(width: 6),
          ],
          Flexible(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.white : const Color(0xFF1E293B),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  harga,
                  style: TextStyle(
                    color: isSelected ? Colors.white.withOpacity(0.9) : _blue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (estimasi != null && estimasi!.isNotEmpty)
                  Text(
                    '~$estimasi',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isSelected ? Colors.white60 : Colors.grey.shade500,
                      fontSize: 10,
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

class _SimpleSheet extends StatelessWidget {
  final List<Widget> children;
  const _SimpleSheet({required this.children});

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 12),
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.grey.shade300,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(height: 12),
        ...children,
        const SizedBox(height: 8),
      ],
    ),
  );
}

class _SheetTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) => ListTile(
    leading: Icon(icon, color: color ?? const Color(0xFF2563EB)),
    title: Text(
      label,
      style: TextStyle(
        color: color ?? const Color(0xFF1E293B),
        fontWeight: FontWeight.w500,
        fontSize: 14,
      ),
    ),
    onTap: onTap,
    contentPadding: const EdgeInsets.symmetric(horizontal: 24),
    dense: true,
  );
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();
  @override
  Widget build(BuildContext context) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: const BoxDecoration(
            color: Color(0xFFEFF6FF),
            shape: BoxShape.circle,
          ),
          child: const CircularProgressIndicator(
            color: Color(0xFF2563EB),
            strokeWidth: 3,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Memuat layanan...',
          style: TextStyle(color: Colors.grey, fontSize: 14),
        ),
      ],
    ),
  );
}
