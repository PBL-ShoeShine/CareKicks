import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/notification_registration_service.dart';
import '../../../core/widgets/custom_scaffold.dart';
import '../controllers/auth_controller.dart';
import 'register_page.dart';
import '../../admin/views/admin_main_page.dart';
import '../../customer/view/customer_main_page.dart';
import 'suspended_shop_page.dart';
import 'lupa_password_view.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool isHidden = true;
  late AuthController _authController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _authController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email dan password tidak boleh kosong'),
          backgroundColor: AppColors.errorRed,
        ),
      );
      return;
    }

    final success = await _authController.login(email, password);

    if (success && mounted) {
      final token = _authController.token ?? '';
      final user = _authController.user ?? {};
      final role = user['jenis_role'];

      if (role == 'superadmin') {
        await _authController.clearSession();
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Akun superadmin hanya dapat digunakan di website.'),
          ),
        );
        return;
      }

      if (role == 'shops_admin' || role == 'staff') {
        final shop = user['shop'];
        final shopStatus = shop is Map ? shop['status_verifikasi']?.toString().toLowerCase() : null;
        if (shop is Map && (shopStatus == 'suspended' || shopStatus == 'appealed')) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) =>
                  SuspendedShopPage(shop: Map<String, dynamic>.from(shop)),
            ),
            (route) => false,
          );
          return;
        }

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login berhasil!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => AdminMainPage(token: token, user: user),
          ),
          (route) => false,
        );
        return;
      }

      if (role == 'customer') {
        await NotificationRegistrationService.registerForUser(
          token: token,
          user: user,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Login berhasil!'),
            backgroundColor: AppColors.successGreen,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => CustomerMainPage(token: token, user: user),
          ),
          (route) => false,
        );
        return;
      }

      await _authController.clearSession();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Role tidak dikenali.')));
    } else if (mounted) {
      final suspendedShop = _authController.suspendedShop;
      if (suspendedShop != null) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => SuspendedShopPage(shop: suspendedShop),
          ),
          (route) => false,
        );
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_authController.errorMessage ?? 'Login gagal'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  // DESAIN INPUT FORM YANG LEBIH RAPI
  InputDecoration _buildInputDecoration(
    String hint,
    IconData prefixIcon, {
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey.shade500),
      prefixIcon: Icon(
        prefixIcon,
        color: AppColors.primaryBlue.withOpacity(0.7),
      ),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey.shade200, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      useSafeArea: false, // Penting agar header nabrak atas layar dengan cantik
      backgroundColor: const Color(
        0xFFF8F9FA,
      ), // Sedikit lebih terang dari EFEFEF
      body: ListenableBuilder(
        listenable: _authController,
        builder: (context, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // TOP HEADER MELENGKUNG
                Container(
                  height: 280,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(50),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 10,
                        offset: Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const SafeArea(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.lock_person_rounded,
                          size: 60,
                          color: Colors.white,
                        ),
                        SizedBox(height: 16),
                        Text(
                          "Welcome Back!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Silakan login untuk melanjutkan",
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // AREA FORM
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      // EMAIL
                      TextFormField(
                        controller: _emailController,
                        enabled: !_authController.isLoading,
                        keyboardType: TextInputType.emailAddress,
                        decoration: _buildInputDecoration(
                          "Email Address",
                          Icons.email_outlined,
                        ),
                      ),

                      const SizedBox(height: 20),

                      // PASSWORD
                      TextFormField(
                        controller: _passwordController,
                        enabled: !_authController.isLoading,
                        obscureText: isHidden,
                        decoration: _buildInputDecoration(
                          "Password",
                          Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              isHidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: Colors.grey,
                            ),
                            onPressed: () =>
                                setState(() => isHidden = !isHidden),
                          ),
                        ),
                      ),

                      // LUPA PASSWORD
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: _authController.isLoading
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LupaPasswordView(),
                                    ),
                                  );
                                },
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.only(top: 12, bottom: 8),
                            minimumSize: Size.zero,
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: const Text(
                            "Lupa Password?",
                            style: TextStyle(
                              color: AppColors.primaryBlue,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 25),

                      // TOMBOL SIGN IN
                      SizedBox(
                        width: double.infinity,
                        height: 55,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: _authController.isLoading
                              ? null
                              : _handleLogin,
                          child: _authController.isLoading
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : const Text(
                                  "Sign In",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      // REGISTER LINK
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Belum punya akun? ",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                          GestureDetector(
                            onTap: _authController.isLoading
                                ? null
                                : () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => const RegisterPage(),
                                      ),
                                    );
                                  },
                            child: const Text(
                              "Register",
                              style: TextStyle(
                                color: AppColors.primaryBlue,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 30),
                    ],
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
