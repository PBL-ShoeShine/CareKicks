import 'package:carekicks/features/admin/antrean/views/antrean_screen.dart';
import 'package:flutter/material.dart';
import '../../../core/widgets/custom_scaffold.dart';
import '../../../core/widgets/custom_bottom_nav_bar.dart';
import '../dashboard/views/dashboard_page.dart';
import '../tracking/views/tracking_page.dart';
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
