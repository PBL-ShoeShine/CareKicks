import 'package:flutter/material.dart';
import '../../../core/widgets/custom_scaffold.dart';
import '../../../core/constants/app_colors.dart';
import '../../admin/views/admin_main_page.dart';
import '../../customer/view/customer_main_page.dart';
import '../controllers/auth_controller.dart';
import 'login_page.dart';
import 'suspended_shop_page.dart';

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

    Widget nextPage = const LoginPage();
    if (isLoggedIn) {
      final token = _authController.token ?? '';
      final user = _authController.user ?? {};
      final role = user['jenis_role'];

      if (role == 'shops_admin' || role == 'staff') {
        final shop = user['shop'];
        if (role == 'shops_admin' &&
            shop is Map &&
            shop['status_verifikasi'] == 'suspended') {
          nextPage = SuspendedShopPage(
            shop: Map<String, dynamic>.from(shop),
          );
        } else {
          nextPage = AdminMainPage(token: token, user: user);
        }
      } else if (role == 'customer') {
        nextPage = CustomerMainPage(token: token, user: user);
      } else {
        await _authController.logout();
      }
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextPage),
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
