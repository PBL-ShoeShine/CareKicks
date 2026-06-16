import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../controller/order_controller.dart';
import '../../detail_order/views/detail_order_page.dart';
import '../../../../../core/constants/app_colors.dart';

class KirimPesananPage extends StatefulWidget {
  final String token;
  final int idShops;

  /// Data profil customer — pre-fill form (opsional)
  final String? prefillNama;
  final String? prefillNoHp;
  final String? prefillAlamat;
  final double? prefillLat;
  final double? prefillLng;

  /// ID Layanan yang dipilih dari halaman detail
  final int? prefillServiceId;

  const KirimPesananPage({
    super.key,
    required this.token,
    required this.idShops,
    this.prefillNama,
    this.prefillNoHp,
    this.prefillAlamat,
    this.prefillLat,
    this.prefillLng,
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
  final _alamatCtrl = TextEditingController();
  final _catatanCtrl = TextEditingController();

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  static const _primaryBlue = Color(0xFF2563EB);
  static const _softBlue = Color(0xFFEFF6FF);
  static const _surfaceColor = Color(0xFFF8FAFF);

  @override
  void initState() {
    super.initState();
    _controller = OrderController();

    // Pre-fill data dari profil
    _namaCtrl.text = widget.prefillNama ?? '';
    _noHpCtrl.text = widget.prefillNoHp ?? '';
    _alamatCtrl.text = widget.prefillAlamat ?? '';

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    _controller.addListener(() {
      if (!_controller.isLoadingServices && _controller.services.isNotEmpty) {
        _animCtrl.forward();
      }
      if (_controller.errorMessage != null) {
        _showErrorSnackBar(_controller.errorMessage!);
        _controller.clearError();
      }
    });

    _controller.fetchServices(
      token: widget.token,
      idShops: widget.idShops,
      prefillServiceId: widget.prefillServiceId,
    );
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _noHpCtrl.dispose();
    _alamatCtrl.dispose();
    _catatanCtrl.dispose();
    _animCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  String _formatCurrency(int amount) {
    final str = amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
    return 'Rp $str';
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  Future<void> _pickPhoto() async {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PhotoPickerSheet(
        onCamera: () async {
          Navigator.pop(context);
          final pic = await ImagePicker().pickImage(
            source: ImageSource.camera,
            imageQuality: 80,
            maxWidth: 1080,
          );
          if (pic != null) _controller.setFotoSepatu(File(pic.path));
        },
        onGallery: () async {
          Navigator.pop(context);
          final pic = await ImagePicker().pickImage(
            source: ImageSource.gallery,
            imageQuality: 80,
            maxWidth: 1080,
          );
          if (pic != null) _controller.setFotoSepatu(File(pic.path));
        },
        onRemove: _controller.fotoSepatu != null
            ? () {
                Navigator.pop(context);
                _controller.setFotoSepatu(null);
              }
            : null,
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    if (_controller.selectedServiceIds.isEmpty) {
      _showErrorSnackBar('Pilih minimal satu layanan');
      return;
    }

    HapticFeedback.mediumImpact();

    final result = await _controller.submitOrder(
      token: widget.token,
      idShops: widget.idShops,
      namaPemilik: _namaCtrl.text.trim(),
      noHp: _noHpCtrl.text.trim(),
      alamat: _alamatCtrl.text.trim(),
      catatan: _catatanCtrl.text.trim().isEmpty
          ? null
          : _catatanCtrl.text.trim(),
      latOrder: widget.prefillLat,
      longOrder: widget.prefillLng,
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
        totalHarga: _controller.totalHarga,
        nmToko: _controller.nmToko,
        onLihatPesanan: () {
          Navigator.of(context).pop(); // tutup dialog
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
          Navigator.of(context).pop(); // tutup dialog
          Navigator.of(context).pop(); // kembali ke sebelumnya
        },
      ),
    );
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      body: Column(
        children: [
          _buildAppBar(),
          Expanded(
            child: ListenableBuilder(
              listenable: _controller,
              builder: (_, __) {
                if (_controller.isLoadingServices) {
                  return const _LoadingState();
                }
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

  // ─── App Bar ──────────────────────────────────────────────────────────────

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
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Kirim Pesanan',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                      ),
                    ),
                    ListenableBuilder(
                      listenable: _controller,
                      builder: (_, __) {
                        final toko = _controller.nmToko;
                        if (toko.isEmpty) return const SizedBox.shrink();
                        return Text(
                          toko,
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

  // ─── Foto Sepatu ──────────────────────────────────────────────────────────

  Widget _buildFotoSection() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (_, __) {
        final foto = _controller.fotoSepatu;
        return _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(
                icon: Icons.camera_alt_outlined,
                label: 'Foto Sepatu',
                suffix: const Text(
                  'Opsional',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: _pickPhoto,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: foto != null ? Colors.transparent : _softBlue,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: foto != null
                          ? _primaryBlue.withOpacity(0.4)
                          : _primaryBlue.withOpacity(0.25),
                      width: 1.5,
                      // Simulate dashed by using a thin border
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: foto != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.file(foto, fit: BoxFit.cover),
                            Positioned(
                              top: 8,
                              right: 8,
                              child: GestureDetector(
                                onTap: _pickPhoto,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Icon(
                                    Icons.edit_outlined,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: _primaryBlue.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.add_photo_alternate_outlined,
                                size: 32,
                                color: _primaryBlue,
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Text(
                              'Tap untuk upload foto sepatu',
                              style: TextStyle(
                                fontSize: 13,
                                color: _primaryBlue,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Format JPG/PNG · Maks 3MB',
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

  // ─── Info Customer ────────────────────────────────────────────────────────

  Widget _buildInfoSection() {
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionLabel(
            icon: Icons.person_outline,
            label: 'Informasi Pemilik',
          ),
          const SizedBox(height: 16),
          _OrderTextField(
            controller: _namaCtrl,
            label: 'Nama Pemilik Sepatu',
            hint: 'Masukkan nama pemilik',
            prefixIcon: Icons.badge_outlined,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
          ),
          const SizedBox(height: 12),
          _OrderTextField(
            controller: _noHpCtrl,
            label: 'Nomor HP',
            hint: 'Contoh: 08xxxxxxxxxx',
            prefixIcon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Nomor HP wajib diisi';
              if (v.trim().length < 9) return 'Nomor HP tidak valid';
              return null;
            },
          ),
          const SizedBox(height: 12),
          _OrderTextField(
            controller: _alamatCtrl,
            label: 'Alamat Lengkap',
            hint: 'Masukkan alamat penjemputan',
            prefixIcon: Icons.location_on_outlined,
            maxLines: 2,
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Alamat wajib diisi' : null,
          ),
        ],
      ),
    );
  }

  // ─── Pilih Layanan ────────────────────────────────────────────────────────

  Widget _buildServiceSection() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (_, __) {
        final services = _controller.services;
        return _SectionCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SectionLabel(
                icon: Icons.cleaning_services_outlined,
                label: widget.prefillServiceId != null ? 'Layanan Terpilih' : 'Pilih Layanan',
                suffix: _controller.selectedServiceIds.isEmpty
                    ? null
                    : Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _primaryBlue,
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
                    ? 'Layanan ini sudah dipilih dari halaman sebelumnya'
                    : 'Pilih satu atau lebih layanan',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                ),
              ),
              const SizedBox(height: 16),
              if (services.isEmpty)
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
                  children: services.where((svc) {
                    if (widget.prefillServiceId != null) {
                      return svc['id_services'] == widget.prefillServiceId;
                    }
                    return true;
                  }).map((svc) {
                    final id = svc['id_services'] as int;
                    final nama = svc['nama_layanan']?.toString() ?? '-';
                    final harga =
                        int.tryParse(svc['harga']?.toString() ?? '0') ?? 0;
                    final estimasi = svc['estimasi_waktu']?.toString();
                    final isSelected = _controller.isServiceSelected(id);

                    return _ServiceChip(
                      nama: nama,
                      harga: _formatCurrency(harga),
                      estimasi: estimasi,
                      isSelected: isSelected,
                      onTap: () {
                        // Kunci pilihan jika ini adalah layanan spesifik dari halaman sebelumnya
                        if (widget.prefillServiceId != null &&
                            widget.prefillServiceId == id) {
                          return; // Tidak melakukan apa-apa jika di-tap
                        }
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
    return _SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionLabel(
            icon: Icons.note_outlined,
            label: 'Catatan',
            suffix: const Text(
              'Opsional',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _catatanCtrl,
            maxLines: 3,
            maxLength: 300,
            style: const TextStyle(fontSize: 14),
            decoration: InputDecoration(
              hintText:
                  'Tulis catatan khusus (misal: kondisi noda, jenis bahan)',
              hintStyle:
                  TextStyle(color: Colors.grey.shade400, fontSize: 13),
              filled: true,
              fillColor: const Color(0xFFF8FAFF),
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
                borderSide: const BorderSide(color: _primaryBlue, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(14),
              counterStyle:
                  TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Total Harga ──────────────────────────────────────────────────────────

  Widget _buildTotalSection() {
    return ListenableBuilder(
      listenable: _controller,
      builder: (_, __) {
        final services = _controller.services
            .where((s) =>
                _controller.selectedServiceIds.contains(s['id_services']))
            .toList();

        if (services.isEmpty) return const SizedBox.shrink();

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
                color: _primaryBlue.withOpacity(0.3),
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
              ...services.map((svc) {
                final harga =
                    int.tryParse(svc['harga']?.toString() ?? '0') ?? 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        svc['nama_layanan']?.toString() ?? '-',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13),
                      ),
                      Text(
                        _formatCurrency(harga),
                        style: const TextStyle(
                            color: Colors.white, fontSize: 13),
                      ),
                    ],
                  ),
                );
              }),
              Divider(color: Colors.white.withOpacity(0.3), height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Total',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  Text(
                    _formatCurrency(_controller.totalHarga),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
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
        final canSubmit = !_controller.isSubmitting &&
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
              onPressed: canSubmit ? _submit : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                disabledBackgroundColor: Colors.grey.shade300,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: canSubmit ? 4 : 0,
                shadowColor: _primaryBlue.withOpacity(0.4),
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
                        Text(
                          _controller.selectedServiceIds.isEmpty
                              ? 'Pilih Layanan Terlebih Dahulu'
                              : 'Konfirmasi Pesanan',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
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

// ─── Sub-Widgets ────────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final Widget child;
  const _SectionCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
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
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget? suffix;
  const _SectionLabel({
    required this.icon,
    required this.label,
    this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: Color(0xFF1E293B),
          ),
        ),
        if (suffix != null) ...[
          const Spacer(),
          suffix!,
        ],
      ],
    );
  }
}

class _OrderTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? Function(String?)? validator;
  final int maxLines;

  const _OrderTextField({
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.keyboardType,
    this.inputFormatters,
    this.validator,
    this.maxLines = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
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
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(fontSize: 14, color: Color(0xFF111827)),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: Colors.grey.shade400,
              fontSize: 13,
            ),
            prefixIcon: Icon(prefixIcon, size: 20, color: Colors.grey.shade400),
            filled: true,
            fillColor: const Color(0xFFF8FAFF),
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
              borderSide:
                  const BorderSide(color: Color(0xFF2563EB), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
            ),
            contentPadding: EdgeInsets.symmetric(
              vertical: maxLines > 1 ? 14 : 0,
              horizontal: maxLines > 1 ? 14 : 0,
            ),
          ),
        ),
      ],
    );
  }
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

  static const _primaryBlue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? _primaryBlue : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected ? _primaryBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryBlue.withOpacity(0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  )
                ]
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 1),
                  )
                ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isSelected) ...[
              const Icon(Icons.check_circle, color: Colors.white, size: 16),
              const SizedBox(width: 6),
            ],
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
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
                    color: isSelected
                        ? Colors.white.withOpacity(0.9)
                        : _primaryBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (estimasi != null && estimasi!.isNotEmpty)
                  Text(
                    '~$estimasi hari',
                    style: TextStyle(
                      color: isSelected
                          ? Colors.white60
                          : Colors.grey.shade500,
                      fontSize: 10,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoPickerSheet extends StatelessWidget {
  final VoidCallback onCamera;
  final VoidCallback onGallery;
  final VoidCallback? onRemove;

  const _PhotoPickerSheet({
    required this.onCamera,
    required this.onGallery,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
          const SizedBox(height: 16),
          const Text(
            'Pilih Sumber Foto',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 16),
          _sheetTile(
            icon: Icons.camera_alt_outlined,
            label: 'Ambil Foto dari Kamera',
            onTap: onCamera,
          ),
          _sheetTile(
            icon: Icons.photo_library_outlined,
            label: 'Pilih dari Galeri',
            onTap: onGallery,
          ),
          if (onRemove != null)
            _sheetTile(
              icon: Icons.delete_outline,
              label: 'Hapus Foto',
              color: Colors.red,
              onTap: onRemove!,
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _sheetTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Color? color,
  }) {
    return ListTile(
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
}

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              shape: BoxShape.circle,
            ),
            child: const CircularProgressIndicator(
              color: Color(0xFF2563EB),
              strokeWidth: 3,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Memuat layanan tersedia...',
            style: TextStyle(color: Colors.grey, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

// ─── Success Dialog ──────────────────────────────────────────────────────────

class _OrderSuccessDialog extends StatefulWidget {
  final String kodeOrder;
  final int totalHarga;
  final String nmToko;
  final VoidCallback onLihatPesanan;
  final VoidCallback onKembali;

  const _OrderSuccessDialog({
    required this.kodeOrder,
    required this.totalHarga,
    required this.nmToko,
    required this.onLihatPesanan,
    required this.onKembali,
  });

  @override
  State<_OrderSuccessDialog> createState() => _OrderSuccessDialogState();
}

class _OrderSuccessDialogState extends State<_OrderSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnim = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _formatCurrency(int amount) {
    final str = amount.toString().replaceAllMapped(
          RegExp(r'(\d)(?=(\d{3})+$)'),
          (m) => '${m[1]}.',
        );
    return 'Rp $str';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnim,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Checkmark animated
              Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 40,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Pesanan Berhasil!',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                  color: Color(0xFF1E293B),
                ),
              ),
              const SizedBox(height: 8),
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
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFE0E7FF)),
                ),
                child: Column(
                  children: [
                    _infoRow(
                      'Kode Order',
                      widget.kodeOrder,
                      isBold: true,
                    ),
                    const Divider(height: 16),
                    _infoRow('Total', _formatCurrency(widget.totalHarga)),
                    const Divider(height: 16),
                    _infoRow('Status', 'Menunggu Pembayaran'),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFFDE68A)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline,
                        color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Silakan lakukan pembayaran untuk melanjutkan proses.',
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
    );
  }

  Widget _infoRow(String label, String value, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: const Color(0xFF1E293B),
          ),
        ),
      ],
    );
  }
}
