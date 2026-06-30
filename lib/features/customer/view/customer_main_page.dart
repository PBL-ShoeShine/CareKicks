import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/constants/app_colors.dart';
import '../../../core/auth/session_manager.dart';
import '../../../core/network/api_service.dart';
import '../../customer/beranda/views/beranda_page.dart';
import '../../customer/riwayat/views/riwayat_page.dart';
import '../../customer/profile/views/customer_profile_page.dart';
import '../../admin/views/admin_main_page.dart';

class CustomerMainPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const CustomerMainPage({super.key, required this.token, required this.user});

  @override
  State createState() => _CustomerMainPageState();
}

class _CustomerMainPageState extends State<CustomerMainPage>
    with WidgetsBindingObserver {
  int _currentIndex = 0;
  Timer? _roleCheckTimer;
  bool _isDialogShowing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Poll every 15 seconds to detect role change
    _roleCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkRoleChange();
    });

    // Also check once after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkRoleChange();
    });
  }

  @override
  void dispose() {
    _roleCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkRoleChange();
    }
  }

  Future<void> _checkRoleChange() async {
    debugPrint("CustomerMainPage: Polling checkRole...");
    if (_isDialogShowing) {
      debugPrint("CustomerMainPage: Dialog already showing, skipping");
      return;
    }

    try {
      final response = await ApiService.checkRole(token: widget.token);
      debugPrint("CustomerMainPage: checkRole response: $response");
      if (response == null || response['success'] != true) {
        debugPrint(
          "CustomerMainPage: checkRole response is null or success is false",
        );
        return;
      }

      final data = response['data'];
      if (data == null) {
        debugPrint("CustomerMainPage: data is null");
        return;
      }

      final newRole = data['jenis_role']?.toString();
      final shop = data['shop'];
      final shopStatus = shop?['status_verifikasi']?.toString().toLowerCase();
      debugPrint("CustomerMainPage: newRole=$newRole, shopStatus=$shopStatus");

      // Customer's shop got approved → role changed to shops_admin
      if (newRole == 'shops_admin' && shopStatus == 'approved' && mounted) {
        debugPrint(
          "CustomerMainPage: Approval condition met! Showing dialog...",
        );
        _roleCheckTimer?.cancel();
        _isDialogShowing = true;

        // Update saved session with new role
        final updatedUser = Map<String, dynamic>.from(widget.user);
        updatedUser['jenis_role'] = 'shops_admin';
        if (shop != null) {
          updatedUser['shop'] = shop;
        }
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          AuthSessionManager.userKey,
          jsonEncode(updatedUser),
        );

        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            contentPadding: const EdgeInsets.all(24),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Icon(
                    Icons.check_circle_rounded,
                    size: 42,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Selamat! 🎉',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Toko "${shop?['nm_toko'] ?? 'Anda'}" telah disetujui!',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Anda sekarang adalah pemilik toko.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black45),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(ctx).pop();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => AdminMainPage(
                            token: widget.token,
                            user: updatedUser,
                          ),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: const Text(
                      'Pergi ke Beranda',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Role check error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      BerandaPage(token: widget.token, user: widget.user),
      RiwayatPage(token: widget.token),
      CustomerProfilePage(token: widget.token),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      body: pages[_currentIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          backgroundColor: Colors.white,
          elevation: 0, // Hilangkan bayangan bawaan agar lebih flat
          selectedItemColor: AppColors.primaryBlue,
          unselectedItemColor: Colors.grey.shade400,
          showUnselectedLabels: true,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
          unselectedLabelStyle: const TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 12,
          ),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_rounded),
              ),
              label:
                  'Home', // Mengikuti gaya referensi (Home, Orders, Favorites, Profile)
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.inventory_2_outlined), // Ikon orders
              ),
              label: 'Orders',
            ),
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.person_outline_rounded),
              ),
              label: 'Profile',
            ),
          ],
        ),
      ),
    );
  }
}
