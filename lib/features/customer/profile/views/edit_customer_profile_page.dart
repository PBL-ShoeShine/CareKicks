import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:carekicks/core/constants/app_colors.dart';
import '../controllers/customer_profile_controller.dart';

class EditCustomerProfilePage extends StatefulWidget {
  final String token;
  final CustomerProfileController controller;

  const EditCustomerProfilePage({
    super.key,
    required this.token,
    required this.controller,
  });

  @override
  State<EditCustomerProfilePage> createState() =>
      _EditCustomerProfilePageState();
}

class _EditCustomerProfilePageState extends State<EditCustomerProfilePage> {
  late TextEditingController _namaCtrl;
  late TextEditingController _tglLahirCtrl;
  String? _selectedGender;

  @override
  void initState() {
    super.initState();
    final data = widget.controller.userData;
    _namaCtrl = TextEditingController(text: data['nama']);
    _tglLahirCtrl = TextEditingController(text: data['birthday'] ?? '');
    _selectedGender = data['gender'];
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _tglLahirCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    DateTime initialDate = DateTime(2000);
    if (_tglLahirCtrl.text.isNotEmpty) {
      try {
        initialDate = DateTime.parse(_tglLahirCtrl.text);
      } catch (_) {}
    }
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primaryBlue),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(
        () => _tglLahirCtrl.text =
            '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}',
      );
    }
  }

  Future<void> _changePhoto() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    final ok = await widget.controller.uploadFoto(
      widget.token,
      ImageSource.gallery,
    );

    if (!mounted) return;
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Foto berhasil diubah' : 'Gagal ubah foto'),
        backgroundColor: ok ? AppColors.successGreen : AppColors.errorRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Edit Profil',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Foto profil
            GestureDetector(
              onTap: _changePhoto,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: AppColors.lightBlue,
                    backgroundImage:
                        (widget.controller.userData['path_gambar']
                                ?.toString()
                                .startsWith('http') ??
                            false)
                        ? NetworkImage(
                            widget.controller.userData['path_gambar'],
                          )
                        : null,
                    child:
                        (widget.controller.userData['path_gambar'] == null ||
                            !(widget.controller.userData['path_gambar']
                                    ?.toString()
                                    .startsWith('http') ??
                                false))
                        ? const Icon(
                            Icons.person,
                            size: 50,
                            color: AppColors.primaryBlue,
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: CircleAvatar(
                      backgroundColor: AppColors.primaryBlue,
                      radius: 18,
                      child: const Icon(
                        Icons.camera_alt,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),

            // Nama
            TextField(
              controller: _namaCtrl,
              decoration: InputDecoration(
                labelText: 'Nama Lengkap',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 16),

            // Gender
            DropdownButtonFormField<String>(
              value: _selectedGender,
              decoration: InputDecoration(
                labelText: 'Gender',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.transgender),
              ),
              items: [
                'Laki-laki',
                'Perempuan',
              ].map((g) => DropdownMenuItem(value: g, child: Text(g))).toList(),
              onChanged: (val) => setState(() => _selectedGender = val),
            ),
            const SizedBox(height: 16),

            // Tanggal Lahir
            TextField(
              controller: _tglLahirCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                labelText: 'Tanggal Lahir',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.cake_outlined),
                suffixIcon: const Icon(Icons.calendar_today),
              ),
            ),
            const SizedBox(height: 40),

            // Tombol simpan
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () async {
                  final ok = await widget.controller.updateProfile(
                    token: widget.token,
                    nama: _namaCtrl.text.trim(),
                    gender: _selectedGender ?? '',
                    birthday: _tglLahirCtrl
                        .text, // ✅ FIX: 'birthday' bukan 'tglLahir'
                  );
                  if (ok && mounted) Navigator.pop(context);
                },
                child: const Text(
                  'Simpan Perubahan',
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
      ),
    );
  }
}
