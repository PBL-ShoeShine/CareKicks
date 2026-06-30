import 'dart:async';
import 'package:flutter/material.dart';
import 'package:pinput/pinput.dart';
import '../../../core/constants/app_colors.dart';
import '../controllers/auth_controller.dart';
import '../../customer/view/customer_main_page.dart';

class RegisterOtpPage extends StatefulWidget {
  final String email;
  const RegisterOtpPage({super.key, required this.email});

  @override
  State<RegisterOtpPage> createState() => _RegisterOtpPageState();
}

class _RegisterOtpPageState extends State<RegisterOtpPage> {
  final _otpCtrl = TextEditingController();
  final AuthController _controller = AuthController();

  int _secondsRemaining = 60;
  Timer? _timer;
  bool _canResend = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

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
    _otpCtrl.dispose();
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
    final defaultPinTheme = PinTheme(
      width: 54,
      height: 60,
      textStyle: const TextStyle(
        fontSize: 22,
        color: AppColors.primaryDark,
        fontWeight: FontWeight.bold,
      ),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.transparent),
      ),
    );

    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      appBar: AppBar(
        title: const Text(
          'Verifikasi Email',
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
                  "Kode OTP 6-digit telah dikirimkan ke email ${widget.email}. Periksa kotak masuk atau folder spam Anda.",
                  style: const TextStyle(fontSize: 13, color: Colors.grey),
                ),
                const SizedBox(height: 32),

                Center(
                  child: Pinput(
                    controller: _otpCtrl,
                    length: 6,
                    defaultPinTheme: defaultPinTheme,
                    focusedPinTheme: defaultPinTheme.copyDecorationWith(
                      border: Border.all(
                        color: AppColors.primaryBlue,
                        width: 2,
                      ),
                    ),
                    showCursor: true,
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
                      onTap: !_canResend || _controller.isLoading
                          ? null
                          : () async {
                              bool success = await _controller
                                  .resendRegisterOtp(widget.email);
                              if (success) {
                                _startTimer();
                                _showSnackBar(
                                  "Kode OTP berhasil dikirim ulang!",
                                  false,
                                );
                              } else {
                                _showSnackBar(
                                  _controller.errorMessage ??
                                      "Gagal mengirim ulang OTP",
                                  true,
                                );
                              }
                            },
                      child: Text(
                        _canResend
                            ? "Kirim Ulang"
                            : "Tunggu ${_secondsRemaining}d",
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: _canResend
                              ? AppColors.primaryBlue
                              : Colors.grey,
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
                              _showSnackBar(
                                "Masukkan 6 digit kode OTP lengkap",
                                true,
                              );
                              return;
                            }
                            bool success = await _controller.verifyRegisterOtp(
                              widget.email,
                              _otpCtrl.text.trim(),
                            );
                            if (success && mounted) {
                              _showSnackBar(
                                "Registrasi berhasil! Mengalihkan...",
                                false,
                              );
                              Navigator.of(context).pushAndRemoveUntil(
                                MaterialPageRoute(
                                  builder: (_) => CustomerMainPage(
                                    token: _controller.token ?? '',
                                    user: _controller.user ?? {},
                                  ),
                                ),
                                (route) => false,
                              );
                            } else if (mounted) {
                              _showSnackBar(
                                _controller.errorMessage ??
                                    "OTP salah atau kedaluwarsa",
                                true,
                              );
                            }
                          },
                    child: _controller.isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
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
            ),
          );
        },
      ),
    );
  }
}
