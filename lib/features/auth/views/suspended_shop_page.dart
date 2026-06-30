import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_scaffold.dart';
import '../../../core/auth/session_manager.dart';
import '../../../core/network/api_service.dart';
import '../../admin/views/admin_main_page.dart';
import '../controllers/auth_controller.dart';
import 'login_page.dart';

class SuspendedShopPage extends StatefulWidget {
  final Map<String, dynamic> shop;

  const SuspendedShopPage({super.key, required this.shop});

  @override
  State<SuspendedShopPage> createState() => _SuspendedShopPageState();
}

class _SuspendedShopPageState extends State<SuspendedShopPage> {
  late final AuthController _authController;
  Timer? _unsuspendCheckTimer;
  bool _isTransitioning = false;
  late Map<String, dynamic> _currentShop;

  @override
  void initState() {
    super.initState();
    _authController = AuthController();
    _currentShop = widget.shop;

    // Poll every 15 seconds to check if the shop is unsuspended
    _unsuspendCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkUnsuspend();
    });
  }

  @override
  void dispose() {
    _unsuspendCheckTimer?.cancel();
    _authController.dispose();
    super.dispose();
  }

  Future<void> _checkUnsuspend() async {
    if (_isTransitioning) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(AuthSessionManager.tokenKey);
      final userStr = prefs.getString(AuthSessionManager.userKey);

      if (token == null || token.isEmpty || userStr == null) return;

      final response = await ApiService.getShopProfile(token: token);
      if (response == null || response['success'] != true) return;

      final shopData = response['data'];
      if (shopData == null) return;

      final status = shopData['status_verifikasi']?.toString().toLowerCase();

      // Update local state shop data if it's still suspended or appealed
      if (status == 'suspended' || status == 'appealed') {
        if (mounted) {
          setState(() {
            _currentShop = Map<String, dynamic>.from(shopData);
          });
        }
      }

      if (status != 'suspended' && status != 'appealed' && mounted) {
        _unsuspendCheckTimer?.cancel();
        setState(() {
          _isTransitioning = true;
        });

        // Update stored session with new status
        final user = jsonDecode(userStr);
        final updatedUser = Map<String, dynamic>.from(user);
        updatedUser['shop'] = shopData;
        await prefs.setString(AuthSessionManager.userKey, jsonEncode(updatedUser));

        if (!mounted) return;

        // Redirect back to AdminMainPage
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => AdminMainPage(
              token: token,
              user: updatedUser,
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Unsuspend check error: $e');
    }
  }

  Future<void> _logout() async {
    await _authController.logout();
    if (!mounted) return;

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  Future<void> _openChromeLink() async {
    final Uri url = Uri.parse('http://localhost:5000/toko-saya');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal membuka tautan Chrome.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final shopName = _currentShop['nm_toko']?.toString().trim();
    final reason = _currentShop['alasan_penangguhan']?.toString().trim();
    final status = _currentShop['status_verifikasi']?.toString().toLowerCase();
    final isAppealed = status == 'appealed';

    return CustomScaffold(
      useSafeArea: true,
      backgroundColor: const Color(0xFFEFEFEF),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: isAppealed ? Colors.blue.shade50 : Colors.red.shade50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    isAppealed ? Icons.hourglass_empty_rounded : Icons.warning_amber_rounded,
                    size: 38,
                    color: isAppealed ? Colors.blue.shade600 : Colors.red.shade600,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  isAppealed ? 'Banding Sedang Ditinjau' : 'Maaf, Toko anda disuspend',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  shopName == null || shopName.isEmpty ? '-' : shopName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isAppealed ? Colors.blue.shade50 : Colors.red.shade50,
                    border: Border.all(color: isAppealed ? Colors.blue.shade100 : Colors.red.shade100),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAppealed ? 'Status Banding Anda' : 'Alasan penangguhan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isAppealed ? Colors.blue.shade600 : Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        reason == null || reason.isEmpty
                            ? 'Toko Anda sedang ditinjau oleh SuperAdmin.'
                            : reason,
                        style: TextStyle(
                          fontSize: 14,
                          height: 1.5,
                          fontWeight: FontWeight.w600,
                          color: isAppealed ? Colors.blue.shade900 : Colors.red.shade900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton.icon(
                    onPressed: isAppealed ? null : _openChromeLink,
                    icon: Icon(
                      isAppealed ? Icons.hourglass_bottom_rounded : Icons.open_in_browser,
                      color: isAppealed ? Colors.black38 : Colors.white,
                    ),
                    label: Text(
                      isAppealed ? 'Banding Sedang Ditinjau' : 'Ajukan Banding',
                      style: TextStyle(
                        color: isAppealed ? Colors.black38 : Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isAppealed ? Colors.grey.shade300 : AppColors.primaryBlue,
                      disabledBackgroundColor: Colors.grey.shade300,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton.icon(
                    onPressed: _logout,
                    icon: const Icon(
                      Icons.logout,
                      color: AppColors.primaryDark,
                    ),
                    label: const Text(
                      'Logout',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primaryDark,
                        width: 2,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
