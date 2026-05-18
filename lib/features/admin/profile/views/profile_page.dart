import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/widgets/custom_scaffold.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../controllers/profile_controller.dart';
import '../../manajemen_layanan/views/m_layanan_page.dart';
import '../../manajemen_staff/views/manajemen_staff_screen.dart';
import '../../toko/views/jam_operasional_page.dart';
import '../../toko/views/profil_toko_page.dart';
import '../../../auth/controllers/auth_controller.dart';
import '../../../auth/views/login_page.dart';

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

  @override
  void initState() {
    super.initState();
    _profileController = ProfileController();
    _authController = AuthController();
    _profileController.fetchProfile(widget.token);
  }

  @override
  void dispose() {
    _profileController.dispose();
    _authController.dispose();
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
              await _profileController.updateProfile(
                token: widget.token,
                nama: namaController.text,
                email: emailController.text,
                noHp: phoneController.text,
              );

              if (mounted) {
                Navigator.pop(context);
                if (_profileController.errorMessage != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(_profileController.errorMessage!),
                      backgroundColor: AppColors.errorRed,
                    ),
                  );
                } else {
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

  void _pickProfileImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Fitur upload foto sedang dikembangkan')),
      );
    }
  }

  String _formatCurrency(int? value) {
    if (value == null) return 'Rp 0';
    final formatter = value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatter';
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
                              backgroundImage:
                                  _profileController.userPhoto != null &&
                                      _profileController.userPhoto!.isNotEmpty
                                  ? NetworkImage(_profileController.userPhoto!)
                                  : null,
                              child:
                                  _profileController.userPhoto == null ||
                                      _profileController.userPhoto!.isEmpty
                                  ? const Icon(
                                      Icons.person_rounded,
                                      size: 58,
                                      color: AppColors.primaryBlue,
                                    )
                                  : null,
                            ),
                          ),

                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: _pickProfileImage,
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
                          _profileController.userRole == 'admin'
                              ? 'Owner Toko'
                              : _profileController.userRole ?? 'User',
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
                const SizedBox(height: 24),

                // OPERATIONAL MANAGEMENT SECTION
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
                        icon: Icons.inventory_2,
                        title: 'Manajemen Inventaris',
                        subtitle: 'Stok barang dan pengadaan',
                        onTap: () {
                          // Navigate to inventory management
                        },
                      ),
                      const SizedBox(height: 12),
                      // ── DISAMBUNGKAN KE ManajemenStaffScreen ──
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
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // STORE INFO SECTION
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

                // SECURITY & ACCOUNT SECTION
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
                        onTap: _showEditProfileDialog,
                      ),
                      const SizedBox(height: 12),
                      _buildMenuCard(
                        icon: Icons.lock_outline,
                        title: 'Ubah Kata Sandi',
                        subtitle: 'Perbarui keamanan akun Anda',
                        onTap: () {},
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // LOGOUT BUTTON
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.errorRed),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Keluar Akun'),
                              content: const Text(
                                'Apakah Anda yakin ingin keluar?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Batal'),
                                ),
                                ElevatedButton(
                                  onPressed: () async {
                                    Navigator.pop(context);
                                    await _handleLogout();
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.errorRed,
                                  ),
                                  child: const Text('Keluar'),
                                ),
                              ],
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.exit_to_app,
                                color: AppColors.errorRed,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Keluar Akun',
                                style: TextStyle(
                                  color: AppColors.errorRed,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
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
