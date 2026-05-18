import 'package:carekicks/features/admin/antrean/screens/antrean_screen.dart';
import 'package:flutter/material.dart';
import '../../core/widgets/custom_scaffold.dart';
import '../../core/widgets/custom_bottom_nav_bar.dart';
import 'dashboard/screens/dashboard_page.dart';
import 'tracking/screens/tracking_page.dart';
import 'inventaris/screens/inventory_page.dart';
import 'scanner/screens/scanner_page.dart';

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
    // List of pages to be displayed in the IndexedStack
    // This ensures state is preserved across tab switches
    final List<Widget> pages = [
      DashboardPage(token: widget.token, user: widget.user),
      AntreanScreen(token: widget.token, user: widget.user),
      ScannerPage(token: widget.token, user: widget.user),
      InventoryPage(token: widget.token, user: widget.user),
      TrackingPage(token: widget.token, user: widget.user),
    ];

    return CustomScaffold(
      body: IndexedStack(index: _currentIndex, children: pages),
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: _onTabTapped,
      ),
    );
  }
}
