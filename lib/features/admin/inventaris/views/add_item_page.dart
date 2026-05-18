import 'dart:io';
import 'package:carekicks/core/widgets/custom_scaffold.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../controllers/inventory_controller.dart';

class AddItemPage extends StatefulWidget {
  final String token;

  const AddItemPage({super.key, required this.token});

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _stokAwalController = TextEditingController(text: '0');
  final _stokMinimumController = TextEditingController(text: '5');
  String _selectedKategori = 'Pilih Kategori';
  String _selectedSatuan = 'pcs';
  File? _selectedImage;
  late InventoryController _controller;
  final ImagePicker _picker = ImagePicker();

  final List<String> _kategoriList = [
    'Pilih Kategori',
    'Cairan Pembersih',
    'Alat Gosok',
    'Finishing',
    'Alat Lap',
    'Accessories',
  ];

  final List<String> _satuanList = ['pcs', 'ml', 'unit', 'gram', 'kg'];

  @override
  void initState() {
    super.initState();
    _controller = InventoryController();
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 70, // Reduce quality to save bandwidth
      );
      if (image != null) {
        setState(() {
          _selectedImage = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal mengambil gambar: $e')));
      }
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _deskripsiController.dispose();
    _stokAwalController.dispose();
    _stokMinimumController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: Colors.white,
      appBar: const CustomAppBar(
        title: 'Tambah Barang Baru',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Photo Upload Section
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  width: 280,
                  height: 280,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFC5C6D1),
                      width: 2,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: _selectedImage != null
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(_selectedImage!, fit: BoxFit.cover),
                              Positioned(
                                right: 8,
                                top: 8,
                                child: GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedImage = null),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
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
                                width: 56,
                                height: 56,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFB3C5FF),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_a_photo_outlined,
                                  color: Colors.white,
                                  size: 25,
                                ),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Upload Foto Barang',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: const Color(0xFF444650),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Format JPG, PNG (Max 5MB)',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: const Color(0xFF757681),
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Form Fields
              _buildLabel('Nama Barang'),
              _buildTextField(
                controller: _namaController,
                hint: 'Contoh: Sikat Sepatu Bulu Kuda',
                validator: (v) =>
                    v == null || v.isEmpty ? 'Nama barang harus diisi' : null,
              ),
              const SizedBox(height: 24),

              _buildLabel('Deskripsi'),
              _buildTextField(
                controller: _deskripsiController,
                hint: 'Jelaskan spesifikasi detail barang...',
                maxLines: 4,
              ),
              const SizedBox(height: 24),

              _buildLabel('Kategori'),
              _buildDropdownField(
                value: _selectedKategori,
                items: _kategoriList,
                onChanged: (v) => setState(() => _selectedKategori = v!),
              ),
              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Stok Awal'),
                        _buildTextField(
                          controller: _stokAwalController,
                          hint: '0',
                          keyboardType: TextInputType.number,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildLabel('Satuan'),
                        _buildDropdownField(
                          value: _selectedSatuan,
                          items: _satuanList,
                          onChanged: (v) =>
                              setState(() => _selectedSatuan = v!),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              _buildLabel('Minimum Stok'),
              _buildTextField(
                controller: _stokMinimumController,
                hint: '5',
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Trigger peringatan stok rendah',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: const Color(0xFF757681),
                  ),
                ),
              ),
              const SizedBox(height: 120), // Space for bottom button
            ],
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.grey.shade200, width: 1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: ListenableBuilder(
            listenable: _controller,
            builder: (context, child) {
              return SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _controller.isLoading ? null : _submit,
                  icon: _controller.isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.save_outlined, size: 20),
                  label: Text(
                    _controller.isLoading
                        ? 'Menyimpan...'
                        : 'Simpan Barang Baru',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF000C2E),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: const Color(0xFF191C1E),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFC5C6D1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF001F5B), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String value,
    required List<String> items,
    required void Function(String?) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFC5C6D1)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down),
          items: items.map((String item) {
            return DropdownMenuItem<String>(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: item == 'Pilih Kategori'
                      ? Colors.grey.shade500
                      : const Color(0xFF191C1E),
                ),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedKategori == 'Pilih Kategori') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih kategori terlebih dahulu')),
      );
      return;
    }

    final success = await _controller.createItem(
      token: widget.token,
      namaItem: _namaController.text,
      kategori: _selectedKategori,
      stokSaatIni: double.tryParse(_stokAwalController.text) ?? 0,
      stokMaksimum:
          (double.tryParse(_stokAwalController.text) ?? 0) *
          2, // Mocking max stock
      stokMinimum: double.tryParse(_stokMinimumController.text) ?? 5,
      satuan: _selectedSatuan,
      fotoInven: _selectedImage,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Barang baru berhasil disimpan')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Gagal menyimpan barang'),
        ),
      );
    }
  }
}
