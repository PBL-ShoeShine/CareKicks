import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carekicks/core/constants/app_colors.dart';
import '../controllers/customer_profile_controller.dart';

class UbahTeleponView extends StatefulWidget {
  final String token;
  final CustomerProfileController profileController;

  const UbahTeleponView({
    super.key,
    required this.token,
    required this.profileController,
  });

  @override
  State<UbahTeleponView> createState() => _UbahTeleponViewState();
}

class _UbahTeleponViewState extends State<UbahTeleponView> {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _simpanNomorBaru() async {
    final noHpBaru = _phoneController.text.trim();

    if (noHpBaru.isEmpty) {
      _showSnack('Nomor telepon tidak boleh kosong!');
      return;
    }
    if (noHpBaru.length < 10) {
      _showSnack('Nomor telepon minimal 10 digit!');
      return;
    }
    if (!noHpBaru.startsWith('08') && !noHpBaru.startsWith('62')) {
      _showSnack('Nomor telepon harus diawali 08 atau 62');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showSnack('Kata sandi wajib diisi untuk keamanan!');
      return;
    }

    setState(() => _isLoading = true);

    final success = await widget.profileController.updateNoHp(
      token: widget.token,
      noHp: noHpBaru,
      password: _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nomor telepon berhasil diperbarui!'),
          backgroundColor: AppColors.successGreen,
        ),
      );
    } else {
      _showSnack(
        widget.profileController.errorMessage.isNotEmpty
            ? widget.profileController.errorMessage
            : 'Gagal menyimpan. Pastikan kata sandi Anda benar.',
      );
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: AppColors.errorRed),
    );
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
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan nomor telepon baru dan kata sandi Anda untuk konfirmasi.',
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 15,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: InputDecoration(
                labelText: 'Nomor Telepon Baru',
                counterText: '',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.phone_outlined),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Kata Sandi Akun',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
            else
              ElevatedButton(
                onPressed: _simpanNomorBaru,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Simpan Perubahan',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
