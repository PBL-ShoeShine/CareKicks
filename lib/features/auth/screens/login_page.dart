import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../controller/auth_controller.dart';
import 'register_page.dart';

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
        const SnackBar(content: Text('Email dan password tidak boleh kosong')),
      );
      return;
    }

    final success = await _authController.login(email, password);

    if (success && mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Login berhasil!')));
      // Navigate to home page atau dashboard
      // Navigator.of(context).pushReplacementNamed('/home');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_authController.errorMessage ?? 'Login gagal')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFEFEF),
      body: ListenableBuilder(
        listenable: _authController,
        builder: (context, child) {
          return SingleChildScrollView(
            child: Column(
              children: [
                // TOP HEADER
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryBlue,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(40),
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "Login",
                          style: TextStyle(color: Colors.white, fontSize: 20),
                        ),
                        SizedBox(height: 10),
                        Text(
                          "Welcome Back!",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 50),

                // FORM
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 30),
                  child: Column(
                    children: [
                      // EMAIL
                      TextField(
                        controller: _emailController,
                        enabled: !_authController.isLoading,
                        decoration: InputDecoration(
                          hintText: "Email",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: AppColors.lightBlue,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: AppColors.lightBlue,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // PASSWORD
                      TextField(
                        controller: _passwordController,
                        enabled: !_authController.isLoading,
                        obscureText: isHidden,
                        decoration: InputDecoration(
                          hintText: "Password",
                          filled: true,
                          fillColor: Colors.white,
                          suffixIcon: IconButton(
                            icon: Icon(
                              isHidden
                                  ? Icons.visibility_off
                                  : Icons.visibility,
                            ),
                            onPressed: () {
                              setState(() {
                                isHidden = !isHidden;
                              });
                            },
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: AppColors.lightBlue,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(
                              color: AppColors.lightBlue,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 50),

                      // BUTTON
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primaryDark,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          onPressed: _authController.isLoading
                              ? null
                              : _handleLogin,
                          child: _authController.isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Text(
                                  "Sign in",
                                  style: TextStyle(color: Colors.white),
                                ),
                        ),
                      ),

                      const SizedBox(height: 20),

                      // REGISTER LINK
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Belum punya akun? "),
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
                              style: TextStyle(color: AppColors.primaryBlue),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),
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
