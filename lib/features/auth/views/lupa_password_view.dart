import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/forgot_password_controller.dart';

class LupaPasswordView extends StatefulWidget {
  const LupaPasswordView({super.key});

  @override
  State<LupaPasswordView> createState() => _LupaPasswordViewState();
}

class _LupaPasswordViewState extends State<LupaPasswordView> {
  final ForgotPasswordController _controller = ForgotPasswordController();

  final _emailCtrl = TextEditingController();
  final _otpCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _isPasswordHidden = true;
  bool _isConfirmPasswordHidden = true;

  // Manajemen Timer Hitung Mundur untuk Resend OTP
  int _secondsRemaining = 60;
  Timer? _timer;
  bool _canResend = false;

  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() => _secondsRemaining--);
      } else {
        setState(() => _canResend = true);
        _timer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _emailCtrl.dispose();
    _otpCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _showSnackBar(String msg, bool isError) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        title: const Text(
          'Lupa Password',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 10),
                // Indikator nomor langkah aktif
                Text(
                  "LANGKAH ${_controller.currentStep + 1} DARI 3",
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),

                // TAMPILAN KONTEN BERDASARKAN STEP
                if (_controller.currentStep == 0)
                  _buildEmailStep()
                else if (_controller.currentStep == 1)
                  _buildOtpStep()
                else
                  _buildResetPasswordStep(),
              ],
            ),
          );
        },
      ),
    );
  }

  // ─── STEP 1: INPUT EMAIL ──────────────────────────────────────────────────
  Widget _buildEmailStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Masukkan Alamat Email Anda",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Kami akan mengirimkan kode verifikasi OTP Dual-Mode untuk menyetel ulang kata sandi Anda.",
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(
            labelText: "Email Akun",
            prefixIcon: const Icon(Icons.email_outlined),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _controller.isLoading
                ? null
                : () async {
                    if (_emailCtrl.text.trim().isEmpty) {
                      _showSnackBar("Email tidak boleh kosong", true);
                      return;
                    }
                    bool success = await _controller.sendOtpRequest(
                      _emailCtrl.text.trim(),
                    );
                    if (success) {
                      _startTimer();
                      _showSnackBar(_controller.message, false);
                    } else {
                      _showSnackBar(_controller.message, true);
                    }
                  },
            child: _controller.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Kirim Kode OTP",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ─── STEP 2: VERIFIKASI OTP (MENGGUNAKAN PINPUT) ───────────────────────────
  Widget _buildOtpStep() {
    // Desain kotak OTP saat tidak aktif/kosong
    final defaultPinTheme = PinTheme(
      width: 54,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        color: AppColors.primaryDark,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1), // Biru sangat muda
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
    );

    // Desain kotak OTP saat sedang diketik (aktif)
    final focusedPinTheme = defaultPinTheme.copyDecorationWith(
      border: Border.all(
        color: AppColors.primaryBlue,
        width: 2,
      ), // Border biru/teal
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Verifikasi Kode OTP",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Kode OTP telah dikirimkan ke ${_emailCtrl.text}. Periksa kotak masuk atau spam email Anda.",
          style: const TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 32),

        // PINPUT (KOTAK-KOTAK OTP)
        Center(
          child: Pinput(
            controller: _otpCtrl,
            length: 6, // 6 Kotak
            defaultPinTheme: defaultPinTheme,
            focusedPinTheme: focusedPinTheme,
            submittedPinTheme: defaultPinTheme, // Bisa disamakan atau diubah
            showCursor: true,
            onCompleted: (pin) {
              // Opsional: Bisa otomatis tembak ke server saat 6 digit terisi penuh
            },
          ),
        ),

        const SizedBox(height: 32),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "Belum menerima kode? ",
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            GestureDetector(
              onTap: !_canResend
                  ? null
                  : () async {
                      bool success = await _controller.sendOtpRequest(
                        _emailCtrl.text.trim(),
                      );
                      if (success) {
                        _startTimer();
                        _showSnackBar(
                          "Kode OTP berhasil dikirim ulang!",
                          false,
                        );
                      }
                    },
              child: Text(
                _canResend ? "Kirim Ulang" : "Tunggu ${_secondsRemaining}d",
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: _canResend ? AppColors.primaryBlue : Colors.grey,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _controller.isLoading
                ? null
                : () async {
                    if (_otpCtrl.text.trim().length < 6) {
                      _showSnackBar("Masukkan 6 digit kode OTP lengkap", true);
                      return;
                    }
                    bool success = await _controller.verifyOtpCode(
                      _emailCtrl.text.trim(),
                      _otpCtrl.text.trim(),
                    );
                    if (success) {
                      _showSnackBar(
                        "OTP valid! Silakan atur kata sandi baru.",
                        false,
                      );
                    } else {
                      _showSnackBar(_controller.message, true);
                    }
                  },
            child: _controller.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Verifikasi OTP",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  // ─── STEP 3: RESET PASSWORD BARU ──────────────────────────────────────────
  Widget _buildResetPasswordStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Atur Ulang Kata Sandi",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppColors.primaryDark,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          "Buat kata sandi baru yang kuat dan aman untuk akun Anda.",
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 24),

        // Password Baru
        TextField(
          controller: _passwordCtrl,
          obscureText: _isPasswordHidden,
          decoration: InputDecoration(
            labelText: "Kata Sandi Baru",
            prefixIcon: const Icon(Icons.lock_outline),
            suffixIcon: IconButton(
              icon: Icon(
                _isPasswordHidden ? Icons.visibility_off : Icons.visibility,
              ),
              onPressed: () =>
                  setState(() => _isPasswordHidden = !_isPasswordHidden),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Konfirmasi Password
        TextField(
          controller: _confirmPasswordCtrl,
          obscureText: _isConfirmPasswordHidden,
          decoration: InputDecoration(
            labelText: "Konfirmasi Kata Sandi Baru",
            prefixIcon: const Icon(Icons.lock_reset),
            suffixIcon: IconButton(
              icon: Icon(
                _isConfirmPasswordHidden
                    ? Icons.visibility_off
                    : Icons.visibility,
              ),
              onPressed: () => setState(
                () => _isConfirmPasswordHidden = !_isConfirmPasswordHidden,
              ),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
          ),
        ),
        const SizedBox(height: 32),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            onPressed: _controller.isLoading
                ? null
                : () async {
                    final pass = _passwordCtrl.text;
                    final conf = _confirmPasswordCtrl.text;

                    if (pass.isEmpty || conf.isEmpty) {
                      _showSnackBar(
                        "Semua bidang kata sandi wajib diisi",
                        true,
                      );
                      return;
                    }
                    if (pass != conf) {
                      _showSnackBar("Konfirmasi kata sandi tidak cocok", true);
                      return;
                    }

                    bool success = await _controller.executeResetPassword(
                      email: _emailCtrl.text.trim(),
                      otpCode: _otpCtrl.text.trim(),
                      newPassword: pass,
                    );

                    if (success) {
                      _showSnackBar(
                        "Kata sandi berhasil diperbarui! Silakan login kembali.",
                        false,
                      );
                      if (!mounted) return;
                      Navigator.pop(context); // Kembali ke halaman Login
                    } else {
                      _showSnackBar(_controller.message, true);
                    }
                  },
            child: _controller.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
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
    );
  }
}
