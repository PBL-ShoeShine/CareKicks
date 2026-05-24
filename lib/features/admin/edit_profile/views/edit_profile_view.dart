import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:carekicks/features/admin/edit_profile/views/ubah_email_view.dart';
import 'package:carekicks/features/admin/edit_profile/views/ubah_telepon_view.dart'
    hide UbahEmailView;
import 'package:carekicks/core/constants/app_colors.dart';
import 'package:carekicks/features/admin/profile/controllers/profile_controller.dart';

class EditProfilView extends StatefulWidget {
  final Map<String, dynamic> user;
  final String token;

  const EditProfilView({super.key, required this.user, required this.token});

  @override
  State<EditProfilView> createState() => _EditProfilViewState();
}

// Tambahkan WidgetsBindingObserver untuk mendeteksi kapan aplikasi dibuka kembali
class _EditProfilViewState extends State<EditProfilView>
    with WidgetsBindingObserver {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _namaController;
  late ProfileController _profileController;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this); // Nyalakan radar pemantau layar

    _namaController = TextEditingController(text: widget.user['nama']);
    _profileController = ProfileController();

    // Langsung tarik data terbaru dari server saat halaman dibuka
    _profileController.fetchProfile(widget.token);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this); // Matikan radar
    _namaController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  // Fungsi sakti: Berjalan otomatis saat kita kembali dari aplikasi Gmail/Browser ke aplikasi ini
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _profileController.fetchProfile(widget.token);
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: source);

    if (image == null) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      ),
    );

    final success = await _profileController.updateProfilePicture(
      token: widget.token,
      imageFile: File(image.path),
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (success) {
      await _profileController.fetchProfile(widget.token);
      _showSuccessDialog(
        'Berhasil Update Foto Profil',
        'Foto profil baru Anda telah berhasil diperbarui di server.',
        false,
      );
    } else {
      _showErrorSnackBar(
        _profileController.photoUploadError ?? 'Gagal memperbarui foto',
      );
    }
  }

  // PERBAIKAN: Hanya mengirim "nama" ke backend, tidak membawa email & noHp
  Future<void> _saveGeneralProfile() async {
    if (_formKey.currentState!.validate()) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(color: AppColors.primaryBlue),
        ),
      );

      final success = await _profileController.updateProfile(
        token: widget.token,
        nama: _namaController.text, // <-- Hanya kirim nama!
      );

      if (!mounted) return;
      Navigator.pop(context);

      if (success) {
        _showSuccessDialog(
          'Profil Berhasil Diperbarui',
          'Perubahan data nama profil Anda telah berhasil disimpan.',
          true,
        );
      } else {
        _showErrorSnackBar(
          _profileController.errorMessage ?? 'Gagal menyimpan perubahan profil',
        );
      }
    }
  }

  void _showSuccessDialog(String title, String subtitle, bool shouldRedirect) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.successGreen.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  color: AppColors.successGreen,
                  size: 70,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 140,
                height: 42,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    if (shouldRedirect) Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primaryBlue,
                  ),
                  child: const Text(
                    'Selesai',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
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

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.errorRed),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Edit Profil")),
      // ListenableBuilder akan membuat UI otomatis nge-refresh kalau data di server berubah
      body: ListenableBuilder(
        listenable: _profileController,
        builder: (context, child) {
          // Ambil data terbaru dari controller, kalau kosong pakai data widget lama
          final currentPhotoUrl =
              _profileController.userPhoto ?? widget.user['foto'];
          final currentEmail =
              _profileController.userEmail ?? widget.user['email'];
          final currentPhone =
              _profileController.userPhone ?? widget.user['no_hp'];

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Avatar edit photo section
                  GestureDetector(
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        builder: (context) => SafeArea(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: const Icon(Icons.camera_alt),
                                title: const Text('Kamera'),
                                onTap: () {
                                  Navigator.pop(context);
                                  _pickImage(ImageSource.camera);
                                },
                              ),
                              ListTile(
                                leading: const Icon(Icons.photo_library),
                                title: const Text('Galeri'),
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
                    child: Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        CircleAvatar(
                          radius: 50,
                          backgroundColor: Colors.blue.shade50,
                          backgroundImage:
                              currentPhotoUrl != null &&
                                  currentPhotoUrl.isNotEmpty
                              ? NetworkImage(currentPhotoUrl)
                              : null,
                          child:
                              currentPhotoUrl == null || currentPhotoUrl.isEmpty
                              ? const Icon(Icons.person, size: 50)
                              : null,
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.edit,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),

                  TextFormField(
                    controller: _namaController,
                    decoration: const InputDecoration(
                      labelText: "Nama Lengkap",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Nama lengkap wajib diisi'
                        : null,
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    key: ValueKey(
                      currentEmail,
                    ), // Memaksa field nge-refresh saat email berubah
                    initialValue: currentEmail,
                    readOnly: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UbahEmailView(token: widget.token),
                        ),
                      ).then(
                        (_) => _profileController.fetchProfile(widget.token),
                      );
                    },
                    decoration: InputDecoration(
                      labelText: "Email",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.email_outlined),
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixIcon: const Icon(Icons.chevron_right),
                    ),
                  ),
                  const SizedBox(height: 20),

                  TextFormField(
                    key: ValueKey(
                      currentPhone,
                    ), // Memaksa field nge-refresh saat no HP berubah
                    initialValue: currentPhone,
                    readOnly: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => UbahTeleponView(token: widget.token),
                        ),
                      ).then(
                        (_) => _profileController.fetchProfile(widget.token),
                      );
                    },
                    decoration: InputDecoration(
                      labelText: "Nomor Telepon",
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.phone_android),
                      filled: true,
                      fillColor: Colors.grey[100],
                      suffixIcon: const Icon(Icons.chevron_right),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // ── 2 TOMBOL AKSI DI BAGIAN PALING BAWAH ──
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Batal",
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveGeneralProfile,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            backgroundColor: AppColors.primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text(
                            "Simpan Perubahan",
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
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
