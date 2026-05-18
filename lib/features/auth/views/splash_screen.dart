import 'package:flutter/material.dart';
import '../../../core/widgets/custom_scaffold.dart';
import '../../../core/constants/app_colors.dart';
import '../../admin/views/admin_main_page.dart';
import '../controllers/auth_controller.dart';
import 'login_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late final AuthController _authController;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _checkSession();
  }

  @override
  void dispose() {
    _authController.dispose();
    super.dispose();
  }

  Future<void> _checkSession() async {
    await Future<void>.delayed(const Duration(seconds: 2));

    final isLoggedIn = await _authController.checkLoginStatus();
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isLoggedIn
            ? AdminMainPage(
                token: _authController.token ?? '',
                user: _authController.user ?? {},
              )
            : const LoginPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      useSafeArea: false,
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo.png', width: 150),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
