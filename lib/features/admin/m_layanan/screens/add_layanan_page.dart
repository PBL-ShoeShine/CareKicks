import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../controller/m_layanan_controller.dart';

class AddLayananPage extends StatefulWidget {
  final String token;
  final dynamic service; // If null, it's "Add", if not null, it's "Edit"

  const AddLayananPage({super.key, required this.token, this.service});

  @override
  State<AddLayananPage> createState() => _AddLayananPageState();
}

class _AddLayananPageState extends State<AddLayananPage> {
  final _formKey = GlobalKey<FormState>();
  late MLayananController _controller;

  late TextEditingController _namaController;
  late TextEditingController _hargaController;
  late TextEditingController _estimasiController;
  late TextEditingController _deskripsiController;

  File? _selectedImage;
  String? _existingImageUrl;

  @override
  void initState() {
    super.initState();
    _controller = MLayananController();
    
    final s = widget.service;
    _namaController = TextEditingController(text: s?['nama_layanan'] ?? '');
    _hargaController = TextEditingController(text: s?['harga']?.toString() ?? '');
    _estimasiController = TextEditingController(text: s?['estimasi_waktu'] ?? '');
    _deskripsiController = TextEditingController(text: s?['deskripsi'] ?? '');
    _existingImageUrl = s?['foto_layanan'];
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _estimasiController.dispose();
    _deskripsiController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final bool isEdit = widget.service != null;
    bool success;

    if (isEdit) {
      success = await _controller.updateService(
        token: widget.token,
        serviceId: widget.service['id_services'],
        namaLayanan: _namaController.text,
        harga: int.parse(_hargaController.text),
        estimasiWaktu: _estimasiController.text,
        deskripsi: _deskripsiController.text,
        foto: _selectedImage,
      );
    } else {
      success = await _controller.createService(
        token: widget.token,
        namaLayanan: _namaController.text,
        harga: int.parse(_hargaController.text),
        estimasiWaktu: _estimasiController.text,
        deskripsi: _deskripsiController.text,
        foto: _selectedImage,
      );
    }

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isEdit ? 'Layanan berhasil diperbarui' : 'Layanan berhasil ditambahkan')),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_controller.errorMessage ?? 'Gagal menyimpan layanan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool isEdit = widget.service != null;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          isEdit ? 'Edit Layanan' : 'Tambah Layanan',
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        backgroundColor: AppColors.primaryBlue,
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image Upload Area
                  Center(
                    child: GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: 150,
                        height: 150,
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: Colors.grey[300]!, width: 2),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: Image.file(_selectedImage!, fit: BoxFit.cover),
                              )
                            : _existingImageUrl != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(18),
                                    child: Image.network(_existingImageUrl!, fit: BoxFit.cover),
                                  )
                                : Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.add_a_photo, size: 40, color: Colors.grey[400]),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Tambah Foto',
                                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  _buildLabel('Nama Layanan'),
                  TextFormField(
                    controller: _namaController,
                    decoration: _buildInputDecoration('Contoh: Deep Cleaning'),
                    validator: (v) => v!.isEmpty ? 'Nama layanan harus diisi' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Harga (Rp)'),
                  TextFormField(
                    controller: _hargaController,
                    keyboardType: TextInputType.number,
                    decoration: _buildInputDecoration('Contoh: 50000'),
                    validator: (v) {
                      if (v!.isEmpty) return 'Harga harus diisi';
                      if (int.tryParse(v) == null) return 'Harga harus berupa angka';
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Estimasi Waktu'),
                  TextFormField(
                    controller: _estimasiController,
                    decoration: _buildInputDecoration('Contoh: 1-2 Hari'),
                    validator: (v) => v!.isEmpty ? 'Estimasi waktu harus diisi' : null,
                  ),
                  const SizedBox(height: 20),

                  _buildLabel('Deskripsi (Opsional)'),
                  TextFormField(
                    controller: _deskripsiController,
                    maxLines: 4,
                    decoration: _buildInputDecoration('Jelaskan detail layanan ini...'),
                  ),
                  const SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton(
                      onPressed: _controller.isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _controller.isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isEdit ? 'Perbarui Layanan' : 'Simpan Layanan',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
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
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Color(0xFF334155),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 2),
      ),
    );
  }
}
