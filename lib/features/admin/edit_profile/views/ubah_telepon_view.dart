import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Wajib untuk input formatter
import 'package:carekicks/features/admin/profile/controllers/profile_controller.dart';

class UbahTeleponView extends StatefulWidget {
  final String token;

  const UbahTeleponView({super.key, required this.token});

  @override
  State<UbahTeleponView> createState() => _UbahTeleponViewState();
}

class _UbahTeleponViewState extends State<UbahTeleponView> {
  late ProfileController _profileController;
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _profileController = ProfileController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  Future<void> _simpanNomorBaru() async {
    final noHpBaru = _phoneController.text.trim();

    // 1. Validasi Kosong
    if (noHpBaru.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor telepon tidak boleh kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Validasi Panjang Nomor (Minimal 10 digit)
    if (noHpBaru.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor telepon terlalu pendek! (Minimal 10 angka)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 3. Validasi awalan 08 atau 62
    if (!noHpBaru.startsWith('08') && !noHpBaru.startsWith('62')) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor telepon harus diawali dengan 08 atau 62'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 4. Validasi Password Kosong
    if (_passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi wajib diisi untuk keamanan!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    // Mengirim noHp DAN password ke backend
    bool success = await _profileController.updateProfile(
      token: widget.token,
      noHp: noHpBaru,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      await _profileController.fetchProfile(widget.token);

      if (!mounted) return;
      Navigator.pop(context); // Kembali ke halaman edit profil utama

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor telepon berhasil diperbarui!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan. Pastikan kata sandi Anda benar.'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Ubah Nomor Telepon',
          style: TextStyle(color: Colors.black87, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan nomor telepon baru dan kata sandi Anda untuk konfirmasi.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),

            // Input Nomor HP
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 15, // Batas 15 angka
              inputFormatters: [
                FilteringTextInputFormatter
                    .digitsOnly, // Blokir semua huruf dan simbol
              ],
              decoration: InputDecoration(
                labelText: 'Nomor Telepon Baru',
                counterText: "", // Sembunyikan tulisan penghitung 0/15
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 20),

            // Input Kata Sandi
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Kata Sandi Akun',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () {
                    setState(() => _obscurePassword = !_obscurePassword);
                  },
                ),
              ),
            ),
            const SizedBox(height: 32),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else
              ElevatedButton(
                onPressed: _simpanNomorBaru,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Simpan Perubahan',
                  style: TextStyle(color: Colors.white, fontSize: 16),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
