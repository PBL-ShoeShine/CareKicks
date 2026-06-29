import 'dart:async';
import 'package:carekicks/features/admin/antrean/views/antrean_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/custom_scaffold.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../../../core/network/api_service.dart';
import '../dashboard/views/dashboard_page.dart';
import '../inventaris/views/inventory_page.dart';
import '../scanner/views/scanner_page.dart';
import 'package:carekicks/features/auth/views/suspended_shop_page.dart';

class AdminMainPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;
  final int initialTab;

  const AdminMainPage({
    super.key,
    required this.token,
    required this.user,
    this.initialTab = 0,
  });

  @override
  State<AdminMainPage> createState() => _AdminMainPageState();
}

class _AdminMainPageState extends State<AdminMainPage> with WidgetsBindingObserver {
  late int _currentIndex;
  Timer? _suspendCheckTimer;

  bool get _isShopAdmin => widget.user['jenis_role'] == 'shops_admin';
  bool get _showInventory => _isShopAdmin;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
    WidgetsBinding.instance.addObserver(this);

    // Check once after first frame renders
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkSuspense();
    });

    // Poll every 15 seconds for real-time suspension detection
    _suspendCheckTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _checkSuspense();
    });
  }

  @override
  void dispose() {
    _suspendCheckTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSuspense();
    }
  }

  Future<void> _checkSuspense() async {
    try {
      final response = await ApiService.getShopProfile(token: widget.token);
      if (response == null || response['success'] != true) return;

      final shopData = response['data'];
      if (shopData == null) return;

      final status = shopData['status_verifikasi']?.toString().toLowerCase();
      if ((status == 'suspended' || status == 'appealed') && mounted) {
        _suspendCheckTimer?.cancel(); // Stop polling once suspended
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => SuspendedShopPage(
              shop: Map<String, dynamic>.from(shopData),
            ),
          ),
          (route) => false,
        );
      }
    } catch (e) {
      debugPrint('Suspend check error: $e');
    }
  }

  void _onTabTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      DashboardPage(token: widget.token, user: widget.user),
      AntreanScreen(token: widget.token, user: widget.user),
      ScannerPage(token: widget.token, user: widget.user),
      if (_showInventory) InventoryPage(token: widget.token, user: widget.user),
    ];

    if (_currentIndex >= pages.length) {
      _currentIndex = pages.length - 1;
    }

    return CustomScaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
        showInventory: _showInventory,
      ),
    );
  }
}
