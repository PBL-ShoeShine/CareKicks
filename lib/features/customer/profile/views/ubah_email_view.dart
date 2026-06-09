import 'dart:async';
import 'package:flutter/material.dart';
import 'package:carekicks/core/constants/app_colors.dart';
import '../controllers/customer_profile_controller.dart';

class UbahEmailView extends StatefulWidget {
  final String token;
  final CustomerProfileController profileController;

  const UbahEmailView({
    super.key,
    required this.token,
    required this.profileController,
  });

  @override
  State<UbahEmailView> createState() => _UbahEmailViewState();
}

class _UbahEmailViewState extends State<UbahEmailView> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isWaitingVerification = false;
  Timer? _pollingTimer;

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _emailController.dispose();
    super.dispose();
  }

  void _showSuccessAndExit() {
    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.check_circle_rounded, color: AppColors.successGreen, size: 90),
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
      ),
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

    if (emailBaru.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email tidak boleh kosong!'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final emailValid = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(emailBaru);
    if (!emailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Format email tidak valid!'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final success = await widget.profileController.requestEmailChange(
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
        await widget.profileController.fetchProfile(widget.token);
        if (widget.profileController.userData['email'] == emailBaru) {
          timer.cancel();
          _showSuccessAndExit();
        }
      });
    } else {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal mengirim tautan. Email mungkin sudah digunakan.'),
          backgroundColor: AppColors.errorRed,
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
          'Ubah Email',
          style: TextStyle(color: Colors.black87, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Masukkan alamat email baru Anda. Tautan verifikasi akan dikirim ke email tersebut.',
              style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _emailController,
              enabled: !_isWaitingVerification,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Email Baru',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.email_outlined),
              ),
            ),
            const SizedBox(height: 32),
            if (_isLoading)
              const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue))
            else if (_isWaitingVerification)
              Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: const [
                        Icon(Icons.mark_email_unread_outlined, color: AppColors.primaryBlue, size: 40),
                        SizedBox(height: 12),
                        Text(
                          'Tautan verifikasi telah dikirim. Silakan cek inbox email baru Anda dan klik link verifikasi. Menunggu konfirmasi...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            height: 1.5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(child: CircularProgressIndicator(color: AppColors.primaryBlue)),
                ],
              )
            else
              ElevatedButton(
                onPressed: _kirimVerifikasi,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  minimumSize: const Size(double.infinity, 50),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Kirim Verifikasi',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
