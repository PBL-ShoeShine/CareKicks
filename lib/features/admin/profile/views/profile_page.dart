import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import 'package:carekicks/features/admin/edit_profile/views/edit_profile_view.dart';
import 'package:carekicks/features/admin/edit_profile/views/ubah_email_view.dart';
// --- INI TAMBAHAN IMPORT UNTUK UBAH PASSWORD ---
import 'package:carekicks/features/admin/ubah_password/views/ubah_password_view.dart';
// -----------------------------------------------

// --- TAMBAHAN IMPORT CONTROLLER BARU UNTUK UPLOAD FOTO ---
import 'package:carekicks/features/admin/edit_profile/controllers/edit_profile_controller.dart';
// ---------------------------------------------------------

import 'package:carekicks/core/widgets/custom_scaffold.dart';
import 'package:carekicks/core/constants/app_colors.dart';
import 'package:carekicks/core/widgets/custom_appbar.dart';
import 'package:carekicks/features/admin/profile/controllers/profile_controller.dart';
import 'package:carekicks/features/admin/manajemen_layanan/views/m_layanan_page.dart';
import 'package:carekicks/features/admin/manajemen_staff/views/manajemen_staff_screen.dart';
import 'package:carekicks/features/admin/toko/views/jam_operasional_page.dart';
import 'package:carekicks/features/admin/toko/views/profil_toko_page.dart';
import 'package:carekicks/features/auth/controllers/auth_controller.dart';
import 'package:carekicks/features/auth/views/login_page.dart';
import 'package:carekicks/features/admin/metode_pembayaran/views/metode_pembayaran_view.dart';
import 'package:carekicks/features/admin/ongkir/views/manajemen_ongkir_page.dart';

class ProfilePage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const ProfilePage({super.key, required this.token, required this.user});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late ProfileController _profileController;
  late AuthController _authController;
  late EditProfileController _editController;

  @override
  void initState() {
    super.initState();
    _profileController = ProfileController();
    _authController = AuthController();
    _editController = EditProfileController();
    _profileController.fetchProfile(widget.token);
  }

  @override
  void dispose() {
    _profileController.dispose();
    _authController.dispose();
    _editController.dispose();
    super.dispose();
  }

  Future<void> _handleLogout() async {
    await _authController.logout();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Berhasil logout')));
  }

  void _showEditProfileDialog() {
    final namaController = TextEditingController(
      text: _profileController.userName,
    );
    final emailController = TextEditingController(
      text: _profileController.userEmail,
    );
    final phoneController = TextEditingController(
      text: _profileController.userPhone,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Profil'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: namaController,
                decoration: const InputDecoration(
                  labelText: 'Nama',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: phoneController,
                decoration: const InputDecoration(
                  labelText: 'Nomor Telepon',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () async {
              final success = await _editController.updateProfil(
                token: widget.token,
                nama: namaController.text,
                email: emailController.text,
                noHp: phoneController.text,
              );

              if (mounted) {
                Navigator.pop(context);
                if (!success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _editController.message.isNotEmpty
                            ? _editController.message
                            : 'Gagal memperbarui profil',
                      ),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                } else {
                  await _profileController.fetchProfile(widget.token);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profil berhasil diperbarui'),
                      backgroundColor: AppColors.successGreen,
                    ),
                  );
                }
              }
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickProfileImage(ImageSource source) async {
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

    final newImageUrl = await _editController.uploadProfilePicture(
      token: widget.token,
      imageFile: File(image.path),
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (newImageUrl != null) {
      await _profileController.fetchProfile(widget.token);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil berhasil diperbarui'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _editController.message.isNotEmpty
                ? _editController.message
                : 'Gagal memperbarui foto profil',
          ),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  void _showProfilePhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_rounded),
              title: const Text('Ambil dari Kamera'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded),
              title: const Text('Pilih dari Galeri'),
              onTap: () {
                Navigator.pop(context);
                _pickProfileImage(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.close_rounded),
              title: const Text('Batal'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToEditProfile() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditProfilView(
          token: widget.token,
          user: {
            'nama': _profileController.userName ?? '',
            'email': _profileController.userEmail ?? '',
            'no_hp': _profileController.userPhone ?? '',
            'foto': _profileController.userPhoto ?? '',
          },
        ),
      ),
    ).then((_) => _profileController.fetchProfile(widget.token));
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: const CustomAppBar(title: 'Profil Saya', showBackButton: true),
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      body: ListenableBuilder(
        listenable: _profileController,
        builder: (context, child) {
          if (_profileController.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (_profileController.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(_profileController.errorMessage!),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      _profileController.fetchProfile(widget.token);
                    },
                    child: const Text('Coba Lagi'),
                  ),
                ],
              ),
            );
          }

          final currentPhotoUrl = _profileController.userPhoto;
          final isValidImageUrl =
              currentPhotoUrl != null &&
              currentPhotoUrl.trim().isNotEmpty &&
              currentPhotoUrl.startsWith('http');

          return SingleChildScrollView(
            child: Column(
              children: [
                // PROFILE HEADER
                Container(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 18,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primaryBlue.withOpacity(0.2),
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 56,
                              backgroundColor: AppColors.lightBlue,
                              backgroundImage: isValidImageUrl
                                  ? NetworkImage(currentPhotoUrl)
                                  : null,
                              child: !isValidImageUrl
                                  ? const Icon(
                                      Icons.person_rounded,
                                      size: 58,
                                      color: AppColors.primaryBlue,
                                    )
                                  : null,
                            ),
                          ),
                          if (_profileController.isUploadingPhoto ||
                              _editController.isLoading)
                            Positioned.fill(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.35),
                                  shape: BoxShape.circle,
                                ),
                                child: const Center(
                                  child: SizedBox(
                                    width: 28,
                                    height: 28,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 3,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap:
                                  (_profileController.isUploadingPhoto ||
                                      _editController.isLoading)
                                  ? null
                                  : _showProfilePhotoSourceSheet,
                              child: Container(
                                width: 42,
                                height: 42,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.15),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.camera_alt_rounded,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        _profileController.userName ?? 'User',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          letterSpacing: 0.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(30),
                        ),
                        child: Text(
                          (_profileController.userRole == 'admin' ||
                                  _profileController.userRole == 'shops_admin')
                              ? 'Owner Toko'
                              : (_profileController.userRole == 'user'
                                    ? 'Pelanggan'
                                    : _profileController.userRole ??
                                          'Staf Toko'),
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryDark,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 22),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withOpacity(
                                      0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.email_outlined,
                                    color: AppColors.primaryDark,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _profileController.userEmail ?? '-',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    color: AppColors.primaryBlue.withOpacity(
                                      0.08,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Icon(
                                    Icons.phone_outlined,
                                    color: AppColors.primaryDark,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    _profileController.userPhone ?? '-',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.black87,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // 👇 INI BAGIAN YANG DITAMBAHKAN PENGECEKAN ROLE
                if (_profileController.userRole == 'admin' ||
                    _profileController.userRole == 'shops_admin') ...[
                  // MANAJEMEN OPERASIONAL
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'MANAJEMEN OPERASIONAL',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          icon: Icons.receipt,
                          title: 'Manajemen Layanan',
                          subtitle: 'Atur katalog produk dan jasa',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MLayananPage(token: widget.token),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          icon: Icons.people,
                          title: 'Manajemen Karyawan',
                          subtitle: 'Akses staf dan jadwal kerja',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    ManajemenStaffScreen(token: widget.token),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          icon: Icons.account_balance_wallet_outlined,
                          title: 'Metode Pembayaran',
                          subtitle: 'Atur rekening bank dan QRIS',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MetodePembayaranView(token: widget.token),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          icon: Icons.local_shipping_outlined,
                          title: 'Manajemen Ongkir',
                          subtitle: 'Atur tarif antar-jemput toko',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ManajemenOngkirPage(token: widget.token),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // INFORMASI TOKO
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'INFORMASI TOKO',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          icon: Icons.storefront,
                          title: 'Profil Toko',
                          subtitle: 'Lokasi, deskripsi, dan kontak',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    ProfilTokoPage(token: widget.token),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        _buildMenuCard(
                          icon: Icons.schedule,
                          title: 'Jam Operasional',
                          subtitle: 'Waktu buka dan tutup layanan',
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    JamOperasionalPage(token: widget.token),
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                // 👆 BATAS PENGECEKAN ROLE SELESAI DI SINI

                // KEAMANAN & AKUN (Semua role bisa melihat)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'KEAMANAN & AKUN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        icon: Icons.person_outline,
                        title: 'Edit Profil',
                        subtitle: 'Nama, email, dan nomor telepon',
                        onTap: _navigateToEditProfile,
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        icon: Icons.lock_outline,
                        title: 'Ubah Kata Sandi',
                        subtitle: 'Perbarui keamanan akun Anda',
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  UbahPasswordView(token: widget.token),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // LOGOUT BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            titlePadding: const EdgeInsets.fromLTRB(
                              20,
                              20,
                              20,
                              0,
                            ),
                            contentPadding: const EdgeInsets.fromLTRB(
                              20,
                              12,
                              20,
                              20,
                            ),
                            actionsPadding: const EdgeInsets.fromLTRB(
                              16,
                              0,
                              16,
                              16,
                            ),
                            title: Row(
                              children: const [
                                Icon(
                                  Icons.logout_rounded,
                                  color: AppColors.errorRed,
                                  size: 22,
                                ),
                                SizedBox(width: 10),
                                Text(
                                  'Keluar Akun',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            content: const Text(
                              'Apakah Anda yakin ingin keluar dari akun ini?',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.black54,
                                height: 1.4,
                              ),
                            ),
                            actions: [
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => Navigator.pop(context),
                                      style: OutlinedButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 13,
                                        ),
                                        side: BorderSide(
                                          color: Colors.grey.shade400,
                                        ),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Batal',
                                        style: TextStyle(
                                          color: Colors.black54,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () async {
                                        Navigator.pop(context);
                                        await _handleLogout();
                                      },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.errorRed,
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 13,
                                        ),
                                        elevation: 0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            10,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Keluar',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.logout_rounded, size: 20),
                      label: const Text(
                        'Keluar Akun',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.errorRed,
                        side: const BorderSide(
                          color: AppColors.errorRed,
                          width: 1.5,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // APP VERSION
                const Padding(
                  padding: EdgeInsets.only(bottom: 20),
                  child: Text(
                    'App Version 2.4.1 (Build 120)',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppColors.lightBlue,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: AppColors.primaryBlue, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
