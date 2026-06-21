import 'package:carekicks/features/admin/antrean/views/antrean_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/custom_scaffold.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../dashboard/views/dashboard_page.dart';
import '../inventaris/views/inventory_page.dart';
import '../scanner/views/scanner_page.dart';

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

class _AdminMainPageState extends State<AdminMainPage> {
  late int _currentIndex;

  bool get _isShopAdmin => widget.user['jenis_role'] == 'shops_admin';
  bool get _showInventory => _isShopAdmin;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTab;
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
