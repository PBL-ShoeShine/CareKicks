import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carekicks/features/admin/profile/controllers/profile_controller.dart';
// Buka komentar di bawah ini jika kamu pakai AppColors terpisah
// import 'package:carekicks/core/constants/app_colors.dart';

class UbahEmailView extends StatefulWidget {
  final String token;

  const UbahEmailView({super.key, required this.token});

  @override
  State<UbahEmailView> createState() => _UbahEmailViewState();
}

class _UbahEmailViewState extends State<UbahEmailView> {
  late ProfileController _profileController;
  final TextEditingController _emailController = TextEditingController();

  bool _isLoading = false;
  bool _isWaitingVerification = false;
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    _profileController = ProfileController();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _emailController.dispose();
    _profileController.dispose();
    super.dispose();
  }

  void _showSuccessAndExit() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.green, size: 90),
                SizedBox(height: 16),
                Text(
                  'Berhasil!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'Email Anda telah berhasil diperbarui.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey, fontSize: 14),
                ),
              ],
            ),
          ),
        );
      },
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context);
        Navigator.pop(context);
      }
    });
  }

  Future<void> _kirimVerifikasi() async {
    final emailBaru = _emailController.text.trim();

    // 1. Validasi Kosong
    if (emailBaru.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email tidak boleh kosong!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // 2. Validasi Format Email pakai Regex
    final bool emailValid = RegExp(
      r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
    ).hasMatch(emailBaru);
    if (!emailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format email tidak valid! (Contoh: budi@gmail.com)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    bool success = await _profileController.updateProfile(
      token: widget.token,
      email: emailBaru,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isLoading = false;
        _isWaitingVerification = true;
      });

      _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
        await _profileController.fetchProfile(widget.token);

        if (_profileController.userEmail == emailBaru) {
          timer.cancel();
          _showSuccessAndExit();
        }
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Gagal mengirim tautan. Email mungkin sudah digunakan.',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue =
        Colors.blue; // Ganti jadi AppColors.primaryBlue kalau error

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Ubah Email',
          style: TextStyle(color: Colors.black87, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan alamat email baru Anda.',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              enabled: !_isWaitingVerification,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Baru',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 32),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_isWaitingVerification)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: const [
                        Icon(
                          Icons.mark_email_unread_outlined,
                          color: primaryBlue,
                          size: 40,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Tautan verifikasi telah dikirim ke kotak masuk email Anda. Menunggu konfirmasi...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: primaryBlue,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: CircularProgressIndicator(color: primaryBlue),
                  ),
                ],
              )
            else
              ElevatedButton(
                onPressed: _kirimVerifikasi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Kirim Verifikasi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
