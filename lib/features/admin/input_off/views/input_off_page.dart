import 'package:carekicks/core/widgets/custom_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../controllers/input_off_controller.dart';

class InputOffPage extends StatefulWidget {
  final String token;
  const InputOffPage({super.key, required this.token});

  @override
  State<InputOffPage> createState() => _InputOffPageState();
}

class _InputOffPageState extends State<InputOffPage> {
  final _formKey = GlobalKey<FormState>();
  late InputOffController _controller;

  final TextEditingController _namaController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _merkController = TextEditingController();
  final TextEditingController _jenisSepatuController = TextEditingController();
  final TextEditingController _warnaController = TextEditingController();
  final TextEditingController _catatanController = TextEditingController();

  String _selectedMetodeBayar = 'tunai';
  File? _selectedImage;

  final List<String> _metodeBayarList = ['tunai', 'qris'];

  bool _isDownloadingQr = false;

  String _formatRupiah(int amount) {
    String result = amount.toString();
    String formatted = '';
    int count = 0;
    for (int i = result.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) formatted = '.$formatted';
      formatted = result[i] + formatted;
      count++;
    }
    return 'Rp $formatted';
  }

  @override
  void initState() {
    super.initState();
    _controller = InputOffController();
    _controller.fetchServices(widget.token);
  }

  @override
  void dispose() {
    _namaController.dispose();
    _phoneController.dispose();
    _merkController.dispose();
    _jenisSepatuController.dispose();
    _warnaController.dispose();
    _catatanController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source, imageQuality: 80);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    if (_controller.selectedServices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih satu layanan terlebih dahulu')),
      );
      return;
    }

    if (_selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ambil foto kondisi awal sepatu')),
      );
      return;
    }

    final result = await _controller.createOrder(
      token: widget.token,
      namaCustomer: _namaController.text,
      nomorTelepon: _phoneController.text,
      jenisSepatu: _jenisSepatuController.text.trim(),
      merk: _merkController.text,
      warna: _warnaController.text,
      catatan: _catatanController.text,
      metodeBayar: _selectedMetodeBayar,
      fotoSebelum: _selectedImage!,
    );

    if (result != null && mounted) {
      _showSuccessDialog(result);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Gagal membuat pesanan'),
        ),
      );
    }
  }

  void _showSuccessDialog(Map<String, dynamic> data) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => _OfflineOrderSuccessDialog(
        kodeOrder: data['kode_order']?.toString() ?? '-',
        totalHarga: data['total_harga']?.toString() ?? '0',
        qrCodeUrl: data['qr_code']?.toString(),
        onKembali: () {
          Navigator.of(context).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  void _showImagePickerOption() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              children: [
                ListTile(
                  leading: const Icon(Icons.camera_alt),
                  title: const Text('Ambil dari Kamera'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.photo_library),
                  title: const Text('Pilih dari Galeri'),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const CustomAppBar(
        title: 'Input Pesanan Baru',
        subtitle: 'Entri manual untuk pelanggan walk-in',
        showBackButton: true,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoading && _controller.services.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Data Pelanggan'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _namaController,
                    label: 'NAMA LENGKAP',
                    hint: 'Masukkan nama...',
                    validator: (v) =>
                        v!.isEmpty ? 'Nama tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _phoneController,
                    label: 'NOMOR TELEPON',
                    hint: '0812...',
                    keyboardType: TextInputType.phone,
                    maxLength: 15,
                    validator: (v) =>
                        v!.isEmpty ? 'Nomor telepon tidak boleh kosong' : null,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Jenis Sepatu'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _jenisSepatuController,
                    label: '',
                    hint: 'Contoh: Sneakers, Boots, dll',
                    validator: (v) => v!.trim().isEmpty
                        ? 'Jenis sepatu tidak boleh kosong'
                        : null,
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Detail Sepatu'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _merkController,
                    label: 'MERK',
                    hint: 'Contoh: Nike, Adidas...',
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _warnaController,
                    label: 'WARNA',
                    hint: 'Contoh: Putih, Hitam...',
                  ),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Layanan'),
                  const SizedBox(height: 12),
                  _buildServiceSelection(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Kondisi Awal'),
                  const SizedBox(height: 12),
                  _buildPhotoUpload(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Catatan'),
                  const SizedBox(height: 12),
                  _buildTextField(
                    controller: _catatanController,
                    label: '',
                    hint: 'Contoh: Ada lecet di bagian heel...',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 24),
                  _buildTotalSection(),
                  const SizedBox(height: 24),
                  _buildSectionTitle('Metode Pembayaran'),
                  const SizedBox(height: 12),
                  _buildPaymentMethodButtons(),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: _controller.isLoading ? null : _submit,
                      icon: const Icon(Icons.qr_code_2, color: Colors.white),
                      label: _controller.isLoading
                          ? const SizedBox(
                              height: 22,
                              width: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Text(
                              'Proses Pesanan & Buat QR',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF334155),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    int? maxLength,
    String? Function(String?)? validator,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Text(
              label,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          readOnly: readOnly,
          style: TextStyle(
            color: readOnly ? Colors.grey.shade600 : Colors.black,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: icon != null ? Icon(icon, size: 20) : null,
            filled: true,
            fillColor: readOnly ? Colors.grey.shade100 : Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentMethodButtons() {
    return Row(
      children: _metodeBayarList.map((method) {
        final isSelected = _selectedMetodeBayar == method;
        final displayName = method == 'tunai' ? 'Tunai' : 'QRIS';

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                backgroundColor: isSelected
                    ? Colors.white
                    : const Color(0xFFF7F8FA),
                side: BorderSide(
                  color: isSelected
                      ? AppColors.primaryBlue
                      : const Color(0xFFE2E8F0),
                  width: isSelected ? 2 : 1,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => setState(() => _selectedMetodeBayar = method),
              child: Text(
                displayName,
                style: TextStyle(
                  color: isSelected ? AppColors.primaryBlue : Colors.black,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPhotoUpload() {
    return GestureDetector(
      onTap: _showImagePickerOption,
      child: SizedBox(
        width: double.infinity,
        child: Container(
          height: 200,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border.all(color: const Color(0xFFE2E8F0), width: 2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: _selectedImage == null
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.camera_alt_outlined,
                      size: 48,
                      color: Color(0xFFCBD5E1),
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Ambil Foto Kondisi',
                      style: TextStyle(color: Color(0xFFCBD5E1), fontSize: 14),
                    ),
                  ],
                )
              : Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.file(_selectedImage!, fit: BoxFit.cover),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedImage = null),
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.close,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildServiceSelection() {
    if (_controller.services.isEmpty) {
      return const Text('Tidak ada layanan tersedia');
    }

    final int? selectedServiceId = _controller.selectedServices.isNotEmpty
        ? _controller.selectedServices.first['id_services']
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: _controller.services.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
        itemBuilder: (context, index) {
          final service = _controller.services[index];
          final int serviceId = service['id_services'];
          final bool isSelected = selectedServiceId == serviceId;

          return Container(
            color: isSelected
                ? AppColors.primaryBlue.withOpacity(0.1)
                : Colors.transparent,
            child: RadioListTile<int>(
              title: Text(
                service['nama_layanan'] ?? 'Layanan',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              subtitle: Text(
                // ✅ FIX: format titik ribuan
                _formatRupiah(service['harga']),
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.primaryBlue,
                ),
              ),
              value: serviceId,
              groupValue: selectedServiceId,
              activeColor: AppColors.primaryBlue,
              onChanged: (_) {
                _controller.selectSingleService(service);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Total Biaya',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
            ),
          ),
          Text(
            // ✅ FIX: format titik ribuan
            _formatRupiah(_controller.totalHarga.toInt()),
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.primaryBlue,
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

class _OfflineOrderSuccessDialog extends StatefulWidget {
  final String kodeOrder;
  final String totalHarga;
  final String? qrCodeUrl;
  final VoidCallback onKembali;

  const _OfflineOrderSuccessDialog({
    required this.kodeOrder,
    required this.totalHarga,
    this.qrCodeUrl,
    required this.onKembali,
  });

  @override
  State<_OfflineOrderSuccessDialog> createState() =>
      _OfflineOrderSuccessDialogState();
}

class _OfflineOrderSuccessDialogState
    extends State<_OfflineOrderSuccessDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  bool _isDownloadingQr = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _scale = CurvedAnimation(parent: _ctrl, curve: Curves.elasticOut);
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _downloadQr() async {
    final qrUrl = widget.qrCodeUrl;
    if (qrUrl == null || qrUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('QR belum tersedia'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isDownloadingQr = true);
    try {
      final response = await http.get(Uri.parse(qrUrl));
      if (response.statusCode != 200 || response.bodyBytes.isEmpty) {
        throw Exception('Gagal mengunduh gambar QR');
      }

      final imageBytes = Uint8List.fromList(response.bodyBytes);
      final result = await ImageGallerySaverPlus.saveImage(
        imageBytes,
        quality: 100,
        name: 'qr_order_${widget.kodeOrder}',
      );

      final isSuccess = result is Map
          ? result['isSuccess'] == true
          : result != null;

      if (!isSuccess) {
        throw Exception('Gagal menyimpan QR ke gallery');
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('QR berhasil disimpan ke gallery'),
            backgroundColor: AppColors.successGreen,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengunduh QR: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingQr = false);
      }
    }
  }

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
                  offset: const Offset(0, 8))
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
                        colors: [Color(0xFF10B981), Color(0xFF059669)]),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                const Text('Pesanan Berhasil!',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 20,
                        color: Color(0xFF1E293B))),
                const SizedBox(height: 6),
                Text(
                  'QR Code untuk pesanan #${widget.kodeOrder}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 20),

                // QR Code display
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: Column(
                    children: [
                      if (widget.qrCodeUrl != null &&
                          widget.qrCodeUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            widget.qrCodeUrl!,
                            width: 200,
                            height: 200,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.qr_code_2_rounded,
                                size: 80,
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                          ),
                        )
                      else
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.qr_code_2_rounded,
                            size: 80,
                            color: Color(0xFFCBD5E1),
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text(
                        '#${widget.kodeOrder}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Download QR button
                if (widget.qrCodeUrl != null &&
                    widget.qrCodeUrl!.isNotEmpty)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _isDownloadingQr ? null : _downloadQr,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: _isDownloadingQr
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.primaryBlue,
                              ),
                            )
                          : const Icon(Icons.download_rounded, size: 20),
                      label: Text(
                        _isDownloadingQr
                            ? 'Mengunduh...'
                            : 'Simpan QR ke Galeri',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: widget.onKembali,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Selesai',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
