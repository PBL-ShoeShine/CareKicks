import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:carekicks/core/constants/app_colors.dart';
import '../controllers/customer_profile_controller.dart';
import 'ubah_email_view.dart';
import 'ubah_telepon_view.dart';
import 'ubah_password_view.dart';
import 'alamat_saya_view.dart';
import 'syarat_ketentuan_view.dart';

import 'package:carekicks/features/auth/controllers/auth_controller.dart';
import 'package:carekicks/features/auth/views/login_page.dart';

class CustomerProfilePage extends StatefulWidget {
  final String token;
  const CustomerProfilePage({super.key, required this.token});

  @override
  State<CustomerProfilePage> createState() => _CustomerProfilePageState();
}

class _CustomerProfilePageState extends State<CustomerProfilePage> {
  final CustomerProfileController _controller = CustomerProfileController();
  late AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _controller.fetchProfile(widget.token);
  }

  @override
  void dispose() {
    _controller.dispose();
    _authController.dispose();
    super.dispose();
  }

  // ─── HELPERS ──────────────────────────────────────────────────────────────

  Future<void> _handleLogout() async {
    await _authController.logout();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _openTambahToko() async {
    final Uri url = Uri.parse('https://shoeshine/daftar-toko');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showSnack('Tidak bisa membuka halaman web.', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
      ),
    );
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty || dateStr == 'Belum diatur') {
      return 'Belum diatur';
    }
    try {
      DateTime dt = DateTime.parse(dateStr);
      List<String> months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
    } catch (e) {
      return dateStr;
    }
  }

  String _display(dynamic val) {
    if (val == null || val.toString().trim().isEmpty) return 'Belum diatur';
    return val.toString();
  }

  // ─── DIALOGS / NAVIGASI ───────────────────────────────────────────────────

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.logout, color: AppColors.errorRed),
            const SizedBox(width: 8),
            const Text(
              'Keluar Akun',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
          ],
        ),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    side: BorderSide(color: Colors.grey.shade400),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: Colors.black54,
                      fontWeight: FontWeight.w600,
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
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Keluar',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 🔥 DESAIN BARU: EDIT NAMA DENGAN MODERN BOTTOM SHEET 🔥
  void _showEditNamaDialog() {
    final ctrl = TextEditingController(
      text: _controller.userData['nama'] ?? '',
    );

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true, // Agar konten terangkat saat keyboard muncul
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Grey handle atas
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Judul
                const Text(
                  'Ubah Nama Lengkap',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Gunakan nama asli Anda untuk memudahkan verifikasi.',
                  style: TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 24),

                // Input Nama Bergaya Modern
                Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: TextField(
                    controller: ctrl,
                    autofocus: true,
                    style: const TextStyle(fontSize: 15, color: Colors.black87),
                    decoration: InputDecoration(
                      prefixIcon: const Icon(
                        Icons.person_outline,
                        color: AppColors.primaryBlue,
                      ),
                      hintText: 'Masukkan nama lengkap Anda...',
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Tombol Aksi Stacked
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      Navigator.pop(context); // Tutup Bottom Sheet
                      final ok = await _controller.updateProfile(
                        token: widget.token,
                        nama: ctrl.text.trim(),
                        gender: _controller.userData['gender'] ?? '',
                        birthday: _controller.userData['birthday'] ?? '',
                      );
                      _showSnack(
                        ok
                            ? 'Nama berhasil diperbarui'
                            : 'Gagal memperbarui nama',
                        isError: !ok,
                      );
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
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: () => Navigator.pop(context),
                    child: const Text(
                      'Batal',
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showEditGenderDialog() {
    String? tempSelected = _controller.userData['gender'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setStateSheet) {
              return Padding(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: 24,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 16,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Pilih Gender',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _buildGenderCard(
                      title: 'Laki-laki',
                      icon: Icons.male_rounded,
                      isSelected: tempSelected == 'Laki-laki',
                      onTap: () =>
                          setStateSheet(() => tempSelected = 'Laki-laki'),
                    ),
                    const SizedBox(height: 12),
                    _buildGenderCard(
                      title: 'Perempuan',
                      icon: Icons.female_rounded,
                      isSelected: tempSelected == 'Perempuan',
                      onTap: () =>
                          setStateSheet(() => tempSelected = 'Perempuan'),
                    ),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        onPressed: () async {
                          Navigator.pop(context);
                          final ok = await _controller.updateProfile(
                            token: widget.token,
                            nama: _controller.userData['nama'] ?? '',
                            gender: tempSelected ?? '',
                            birthday: _controller.userData['birthday'] ?? '',
                          );
                          _showSnack(
                            ok
                                ? 'Gender berhasil diperbarui'
                                : 'Gagal memperbarui gender',
                            isError: !ok,
                          );
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
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildGenderCard({
    required String title,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primaryBlue.withOpacity(0.08)
              : Colors.white,
          border: Border.all(
            color: isSelected ? AppColors.primaryBlue : Colors.grey.shade300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primaryBlue
                    : Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isSelected ? Colors.white : Colors.grey.shade600,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                  color: isSelected ? AppColors.primaryDark : Colors.black87,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primaryBlue,
                size: 24,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditTglLahirDialog() async {
    final current = _controller.userData['birthday'];
    DateTime initialDate = DateTime(2000);
    if (current != null && current.toString().isNotEmpty) {
      try {
        initialDate = DateTime.parse(current);
      } catch (_) {}
    }

    DateTime tempPickedDate = initialDate;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: SizedBox(
            height: 350,
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text(
                          'Batal',
                          style: TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const Text(
                        'Pilih Tanggal Lahir',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87,
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          final tglStr =
                              '${tempPickedDate.year}-${tempPickedDate.month.toString().padLeft(2, '0')}-${tempPickedDate.day.toString().padLeft(2, '0')}';
                          final ok = await _controller.updateProfile(
                            token: widget.token,
                            nama: _controller.userData['nama'] ?? '',
                            gender: _controller.userData['gender'] ?? '',
                            birthday: tglStr,
                          );
                          _showSnack(
                            ok
                                ? 'Tanggal lahir diperbarui'
                                : 'Gagal memperbarui',
                            isError: !ok,
                          );
                        },
                        child: const Text(
                          'Simpan',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Divider(height: 1, color: Colors.grey.shade200, thickness: 1),
                Expanded(
                  child: CupertinoTheme(
                    data: const CupertinoThemeData(
                      textTheme: CupertinoTextThemeData(
                        dateTimePickerTextStyle: TextStyle(
                          fontSize: 18,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    child: CupertinoDatePicker(
                      mode: CupertinoDatePickerMode.date,
                      initialDateTime: initialDate,
                      minimumDate: DateTime(1950),
                      maximumDate: DateTime.now(),
                      onDateTimeChanged: (DateTime newDate) {
                        tempPickedDate = newDate;
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickAndUploadPhoto() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.photo_library,
                color: AppColors.primaryBlue,
              ),
              title: const Text('Pilih dari Galeri'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(
                Icons.camera_alt,
                color: AppColors.primaryBlue,
              ),
              title: const Text('Ambil Foto'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (source == null || !mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppColors.primaryBlue),
      ),
    );
    final ok = await _controller.uploadFoto(widget.token, source);
    if (!mounted) return;
    Navigator.pop(context);
    _showSnack(
      ok ? 'Foto berhasil diubah' : 'Gagal mengubah foto',
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBlue,
        elevation: 0,
        centerTitle: false,
        title: const Text(
          'Profil Saya',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        // Menghilangkan tombol back karena ini adalah tab utama di Main Page
        automaticallyImplyLeading: false, 
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading && _controller.userData.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          final data = _controller.userData;
          final avatarUrl = data['path_gambar'];
          final isValidAvatar =
              avatarUrl != null && avatarUrl.toString().startsWith('http');

          return SingleChildScrollView(
            child: Column(
              children: [
                // HEADER PROFIL
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    vertical: 28,
                    horizontal: 20,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.08),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: _pickAndUploadPhoto,
                        child: Stack(
                          children: [
                            CircleAvatar(
                              radius: 52,
                              backgroundColor: AppColors.lightBlue,
                              backgroundImage: isValidAvatar
                                  ? NetworkImage(avatarUrl)
                                  : null,
                              child: !isValidAvatar
                                  ? const Icon(
                                      Icons.person,
                                      size: 52,
                                      color: AppColors.primaryBlue,
                                    )
                                  : null,
                            ),
                            Positioned(
                              bottom: 0,
                              right: 0,
                              child: CircleAvatar(
                                backgroundColor: AppColors.primaryBlue,
                                radius: 16,
                                child: const Icon(
                                  Icons.camera_alt,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 14),
                      GestureDetector(
                        onTap: _showEditNamaDialog,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              data['nama'] ?? 'Pelanggan',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primaryDark,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.edit_outlined,
                              size: 16,
                              color: Colors.grey,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            _contactRow(
                              Icons.email_outlined,
                              data['email'] ?? '-',
                            ),
                            const SizedBox(height: 10),
                            _contactRow(
                              Icons.phone_outlined,
                              _display(data['no_hp']),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // INFORMASI PROFIL
                _sectionLabel('INFORMASI PROFIL'),
                const SizedBox(height: 8),
                _card([
                  _buildTile(
                    icon: Icons.transgender,
                    title: 'Gender',
                    value: _display(data['gender']),
                    onTap: _showEditGenderDialog,
                  ),
                  _divider(),
                  _buildTile(
                    icon: Icons.cake_outlined,
                    title: 'Tanggal Lahir',
                    value: _formatDate(data['birthday']),
                    onTap: _showEditTglLahirDialog,
                  ),
                  _divider(),
                  _buildTile(
                    icon: Icons.email_outlined,
                    title: 'Email',
                    value: data['email'] ?? '-',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UbahEmailView(
                          token: widget.token,
                          profileController: _controller,
                        ),
                      ),
                    ),
                  ),
                  _divider(),
                  _buildTile(
                    icon: Icons.phone_android_outlined,
                    title: 'Nomor Telepon',
                    value: _display(data['no_hp']),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UbahTeleponView(
                          token: widget.token,
                          profileController: _controller,
                        ),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 20),

                // KEAMANAN
                _sectionLabel('KEAMANAN & LAINNYA'),
                const SizedBox(height: 8),
                _card([
                  _buildNavTile(
                    icon: Icons.lock_outline,
                    title: 'Ubah Kata Sandi',
                    subtitle: 'Perbarui keamanan akun Anda',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => UbahPasswordView(token: widget.token),
                      ),
                    ),
                  ),
                  _divider(),
                  _buildNavTile(
                    icon: Icons.location_on_outlined,
                    title: 'Alamat Saya',
                    subtitle: 'Kelola daftar alamat pengiriman',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AlamatSayaView(
                          token: widget.token,
                          profileController: _controller,
                        ),
                      ),
                    ),
                  ),
                  _divider(),
                  _buildNavTile(
                    icon: Icons.store_outlined,
                    title: 'Tambah Toko',
                    subtitle: 'Daftarkan toko Anda melalui website',
                    trailing: const Icon(
                      Icons.open_in_new,
                      color: Colors.grey,
                      size: 18,
                    ),
                    onTap: _openTambahToko,
                  ),
                ]),
                const SizedBox(height: 20),

                // BANTUAN
                _sectionLabel('BANTUAN & INFORMASI'),
                const SizedBox(height: 8),
                _card([
                  _buildNavTile(
                    icon: Icons.article_outlined,
                    title: 'Syarat dan Ketentuan',
                    subtitle: 'Kebijakan penggunaan layanan',
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SyaratKetentuanView(),
                      ),
                    ),
                  ),
                ]),
                const SizedBox(height: 32),

                // LOGOUT
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(
                          color: AppColors.errorRed,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      icon: const Icon(Icons.logout, color: AppColors.errorRed),
                      label: const Text(
                        'Keluar Akun',
                        style: TextStyle(
                          color: AppColors.errorRed,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      onPressed: _showLogoutDialog,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'App Version 2.4.1 (Build 120)',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }

  // WIDGET HELPERS
  Widget _sectionLabel(String label) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade500,
              letterSpacing: 0.8,
            ),
          ),
        ),
      );
  Widget _card(List<Widget> children) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(children: children),
      );
  Widget _buildTile({
    required IconData icon,
    required String title,
    required String value,
    required VoidCallback onTap,
  }) =>
      ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        subtitle: Text(
          value,
          style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
      );
  Widget _buildNavTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) =>
      ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppColors.primaryBlue, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            color: AppColors.primaryDark,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        trailing:
            trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      );
  Widget _contactRow(IconData icon, String value) => Row(
        children: [
          Icon(icon, size: 18, color: AppColors.primaryBlue),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(fontSize: 13, color: AppColors.primaryDark),
            ),
          ),
        ],
      );
  Widget _divider() => Divider(
        color: Colors.grey.shade100,
        height: 1,
        thickness: 1,
        indent: 16,
        endIndent: 16,
      );
}