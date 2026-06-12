import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
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

  // 🔥 DESAIN HEADER BARU ALA UI REFERENSI 🔥
  Widget _buildBeranda() {
    // Ambil data user untuk ditampilkan di header
    final userName = widget.user['nama'] ?? 'Customer';
    final avatarUrl = widget.user['path_gambar'];
    final isValidAvatar = avatarUrl != null && avatarUrl.toString().startsWith('http');

    return SafeArea(
      child: Container(
        color: Colors.white, // Latar belakang putih bersih
        child: Column(
          children: [
            // ─── 1. BARIS PROFIL & NOTIFIKASI ───
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  // Foto Profil
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primaryBlue.withOpacity(0.1),
                    backgroundImage: isValidAvatar ? NetworkImage(avatarUrl) : null,
                    child: !isValidAvatar
                        ? const Icon(Icons.person, color: AppColors.primaryBlue)
                        : null,
                  ),
                  const SizedBox(width: 12),
                  // Teks Selamat Datang
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Welcome Back',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                userName,
                                style: const TextStyle(
                                  color: Colors.black87,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Text('📌', style: TextStyle(fontSize: 14)), // Emoji sesuai gambar
                          ],
                        ),
                      ],
                    ),
                  ),
                  // Ikon Keranjang/Notifikasi dengan titik merah
                  Stack(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.grey.shade200, width: 1.5),
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined, // Ikon tas belanja
                          color: Colors.black87,
                          size: 20,
                        ),
                      ),
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppColors.errorRed,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ─── 2. BARIS PENCARIAN & FILTER ───
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  // Search Bar
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.grey.shade200, width: 1.5),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.search, color: Colors.grey.shade500, size: 20),
                          const SizedBox(width: 10),
                          Text(
                            "What's on your list?",
                            style: TextStyle(
                              color: Colors.grey.shade400,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Tombol Filter
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade200, width: 1.5),
                    ),
                    child: const Icon(
                      Icons.tune_rounded, // Ikon filter slider
                      color: AppColors.primaryBlue, // Warna biru agar stand out
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),

            // ─── 3. KONTEN BERANDA BAWAH (SISA HALAMAN) ───
            const Expanded(
              child: Center(
                child: Text('Beranda / Coming Soon'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildBeranda(),
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