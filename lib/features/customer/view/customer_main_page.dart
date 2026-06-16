import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../customer/beranda/views/beranda_page.dart';
import '../../customer/riwayat/views/riwayat_page.dart';
import '../../customer/profile/views/customer_profile_page.dart';


class CustomerMainPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const CustomerMainPage({super.key, required this.token, required this.user});

  @override
  State createState() => _CustomerMainPageState();
}

class _CustomerMainPageState extends State<CustomerMainPage> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    super.dispose();
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
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
          items: const [
            BottomNavigationBarItem(
              icon: Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Icon(Icons.home_rounded),
              ),
              label: 'Home', // Mengikuti gaya referensi (Home, Orders, Favorites, Profile)
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