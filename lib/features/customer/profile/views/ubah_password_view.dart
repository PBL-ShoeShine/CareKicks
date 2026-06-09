import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:carekicks/core/constants/app_colors.dart';
import '../controllers/ubah_password_controller.dart';
import 'package:pinput/pinput.dart';

// ============================================================================
// HALAMAN 1: Validasi Keamanan (input sandi lama / pilih lupa sandi)
// ============================================================================
class UbahPasswordView extends StatefulWidget {
  final String token;
  const UbahPasswordView({super.key, required this.token});

  @override
  State<UbahPasswordView> createState() => _UbahPasswordViewState();
}

class _UbahPasswordViewState extends State<UbahPasswordView> {
  late UbahPasswordController _controller;
  final TextEditingController _oldPassController = TextEditingController();
  bool _obscureText = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = UbahPasswordController();
  }

  @override
  void dispose() {
    _oldPassController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showSnack(String msg, Color color) {
    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
    }
  }

  // Verifikasi sandi lama → lanjut ke SetSandiBaruView (mode direct)
  Future<void> _lanjutkan() async {
    final oldPass = _oldPassController.text;
    if (oldPass.isEmpty) {
      _showSnack('Masukkan kata sandi lama Anda', AppColors.errorRed);
      return;
    }

    setState(() => _isLoading = true);
    final errorMsg = await _controller.verifyOldPassword(widget.token, oldPass);
    setState(() => _isLoading = false);

    if (errorMsg == null) {
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SetSandiBaruView(
              token: widget.token,
              mode: 'direct',
              oldPass: oldPass,
            ),
          ),
        );
      }
    } else {
      _showSnack(errorMsg, AppColors.errorRed);
    }
  }

  // Lupa sandi → kirim OTP → lanjut ke InputOtpView
  Future<void> _lupaSandi() async {
    setState(() => _isLoading = true);
    final errorMsg = await _controller.requestOtp(widget.token);
    setState(() => _isLoading = false);

    if (errorMsg == null) {
      _showSnack(
        'Kode OTP berhasil dikirim ke email Anda!',
        AppColors.successGreen,
      );
      if (mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => InputOtpView(token: widget.token)),
        );
      }
    } else {
      _showSnack(errorMsg, AppColors.errorRed);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Ubah Kata Sandi',
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
              'Demi keamanan, silakan masukkan kata sandi Anda saat ini untuk melanjutkan.',
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _oldPassController,
              obscureText: _obscureText,
              decoration: InputDecoration(
                labelText: 'Kata Sandi Saat Ini',
                prefixIcon: const Icon(Icons.lock_open_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureText ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscureText = !_obscureText),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  )
                : ElevatedButton(
                    onPressed: _lanjutkan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Lanjutkan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
            const SizedBox(height: 16),
            Center(
              child: TextButton(
                onPressed: _isLoading ? null : _lupaSandi,
                child: const Text(
                  'Lupa Kata Sandi? Kirim OTP ke Email',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontWeight: FontWeight.w600,
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

// ============================================================================
// HALAMAN 2: Input Kode OTP
// ============================================================================
class InputOtpView extends StatefulWidget {
  final String token;
  const InputOtpView({super.key, required this.token});

  @override
  State<InputOtpView> createState() => _InputOtpViewState();
}

class _InputOtpViewState extends State<InputOtpView> {
  final TextEditingController _otpController = TextEditingController();
  late UbahPasswordController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = UbahPasswordController();
  }

  @override
  void dispose() {
    _otpController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _verifikasiOtp() async {
    if (_otpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Masukkan 6 digit kode OTP'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final errorMsg = await _controller.verifyOtpOnly(
      widget.token,
      _otpController.text,
    );
    setState(() => _isLoading = false);

    if (errorMsg == null) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SetSandiBaruView(
              token: widget.token,
              mode: 'otp',
              otpCode: _otpController.text,
            ),
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // ✅ DESAIN TEMA KOTAK PINPUT
    final defaultPinTheme = PinTheme(
      width: 56,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        color: AppColors.primaryDark,
        fontWeight: FontWeight.w600,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
        borderRadius: BorderRadius.circular(12),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Verifikasi OTP',
          style: TextStyle(color: Colors.black87, fontSize: 16),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: const [
                  Icon(
                    Icons.mark_email_unread_outlined,
                    color: AppColors.primaryBlue,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Kode OTP 6 digit telah dikirim ke email Anda. Berlaku 15 menit.',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            Pinput(
              length: 6,
              controller: _otpController,
              keyboardType: TextInputType.number,
              autofocus: true,
              defaultPinTheme: defaultPinTheme,
              focusedPinTheme: defaultPinTheme.copyDecorationWith(
                border: Border.all(color: AppColors.primaryBlue, width: 2),
                borderRadius: BorderRadius.circular(12),
              ),
              submittedPinTheme: defaultPinTheme.copyDecorationWith(
                border: Border.all(color: AppColors.primaryBlue, width: 1.5),
              ),
              // Otomatis verifikasi jika 6 kotak sudah terisi penuh
              onCompleted: (pin) {
                if (!_isLoading) _verifikasiOtp();
              },
            ),

            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator(color: AppColors.primaryBlue)
                : ElevatedButton(
                    onPressed: _verifikasiOtp,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Verifikasi OTP',
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

// ============================================================================
// HALAMAN 3: Set Sandi Baru
// ============================================================================
class SetSandiBaruView extends StatefulWidget {
  final String token;
  final String mode; // 'direct' atau 'otp'
  final String? oldPass;
  final String? otpCode;

  const SetSandiBaruView({
    super.key,
    required this.token,
    required this.mode,
    this.oldPass,
    this.otpCode,
  });

  @override
  State<SetSandiBaruView> createState() => _SetSandiBaruViewState();
}

class _SetSandiBaruViewState extends State<SetSandiBaruView> {
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  late UbahPasswordController _controller;

  bool _isLoading = false;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    _controller = UbahPasswordController();
  }

  @override
  void dispose() {
    _passController.dispose();
    _confirmController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
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
                  size: 72,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Berhasil!',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kata sandi Anda telah berhasil diperbarui.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );

    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pop(context); // Tutup dialog sukses
        int count = 0;
        Navigator.popUntil(context, (route) => count++ >= 2);
      }
    });
  }

  Future<void> _simpanSandi() async {
    final newPass = _passController.text;
    final confirmPass = _confirmController.text;

    if (newPass.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Kata sandi minimal 8 karakter!'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }
    if (newPass != confirmPass) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Konfirmasi kata sandi tidak cocok!'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    final success = widget.mode == 'direct'
        ? await _controller.changeDirect(widget.token, widget.oldPass!, newPass)
        : await _controller.changeWithOtp(
            widget.token,
            widget.otpCode!,
            newPass,
          );
    setState(() => _isLoading = false);

    if (success) {
      _showSuccessDialog();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal menyimpan kata sandi. Silakan coba lagi.'),
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
          'Buat Kata Sandi Baru',
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
              'Langkah terakhir! Buat kata sandi baru yang kuat untuk akun Anda.',
              style: TextStyle(color: Colors.grey, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _passController,
              obscureText: _obscureNew,
              decoration: InputDecoration(
                labelText: 'Kata Sandi Baru',
                prefixIcon: const Icon(Icons.lock_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureNew ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () => setState(() => _obscureNew = !_obscureNew),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _confirmController,
              obscureText: _obscureConfirm,
              decoration: InputDecoration(
                labelText: 'Konfirmasi Kata Sandi Baru',
                prefixIcon: const Icon(Icons.lock_reset_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                  ),
                  onPressed: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.primaryBlue,
                    ),
                  )
                : ElevatedButton(
                    onPressed: _simpanSandi,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Simpan Kata Sandi',
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
