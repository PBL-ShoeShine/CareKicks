import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../history/views/history_page.dart';
import '../../input_off/views/input_off_page.dart';
import 'package:carekicks/features/admin/profile/views/profile_page.dart';
import '../controllers/dashboard_controller.dart';
import 'package:carekicks/features/admin/ulasan/views/ulasan_admin_page.dart';

class DashboardPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const DashboardPage({super.key, required this.token, required this.user});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  late DashboardController _dashboardController;

  @override
  void initState() {
    super.initState();
    _dashboardController = DashboardController();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _dashboardController.fetchDashboard(widget.token);
      }
    });
  }

  @override
  void dispose() {
    _dashboardController.dispose();
    super.dispose();
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return 'Rp 0';
    try {
      final parsedValue = int.tryParse(value.toString()) ?? 0;
      final formatter = parsedValue.toString().replaceAllMapped(
        RegExp(r'(\d)(?=(\d{3})+$)'),
        (match) => '${match[1]}.',
      );
      return 'Rp $formatter';
    } catch (_) {
      return 'Rp 0';
    }
  }

  String? _firstString(List<dynamic> values) {
    for (final value in values) {
      if (value == null) continue;
      final text = value.toString().trim();
      if (text.isNotEmpty) return text;
    }
    return null;
  }

  dynamic _userShopValue(String key) {
    try {
      final shop = widget.user['shop'];
      if (shop is Map) return shop[key];
    } catch (_) {}
    return null;
  }

  String get _shopName {
    return _firstString([
          _dashboardController.shopName,
          _userShopValue('nama_toko'),
          _userShopValue('nm_toko'),
          widget.user['nama_toko'],
          widget.user['nm_toko'],
        ]) ??
        'Toko Sepatu';
  }

  String get _userName {
    return _firstString([
          widget.user['nama'],
          widget.user['name'],
          widget.user['nama_user'],
          widget.user['nama_lengkap'],
          widget.user['email'],
        ]) ??
        'User';
  }

  String get _roleLabel {
    final rawRole = _firstString([
      widget.user['role_label'],
      widget.user['nama_role'],
      widget.user['jenis_role'],
      widget.user['role'],
    ]);

    if (rawRole == null || rawRole.isEmpty) return 'Admin Staff';

    switch (rawRole.toLowerCase()) {
      case 'shops_admin':
        return 'Owner Toko';
      case 'staff':
        return 'Staff Toko';
      case 'customer':
        return 'Customer';
      default:
        try {
          return rawRole
              .replaceAll('_', ' ')
              .split(' ')
              .where((word) => word.isNotEmpty)
              .map((word) => word[0].toUpperCase() + word.substring(1))
              .join(' ');
        } catch (_) {
          return rawRole;
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F8FA),
      body: ListenableBuilder(
        listenable: _dashboardController,
        builder: (context, child) {
          if (_dashboardController.isLoading &&
              _dashboardController.dashboardData == null) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          final shopName = _shopName;
          final userName = _userName;
          final roleLabel = _roleLabel;

          final int pesananAktifVal =
              int.tryParse(
                _dashboardController.pesananAktif?.toString() ?? '0',
              ) ??
              0;
          final int antreanCuciVal =
              int.tryParse(
                _dashboardController.antreanCuci?.toString() ?? '0',
              ) ??
              0;
          final int deepCleaningVal =
              int.tryParse(
                _dashboardController.deepCleaning?.toString() ?? '0',
              ) ??
              0;

          return RefreshIndicator(
            onRefresh: () async =>
                _dashboardController.fetchDashboard(widget.token),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.zero,
              children: [
                // PREMIUM WAVE HEADER
                Stack(
                  children: [
                    ClipPath(
                      clipper: _HeaderClipper(),
                      child: Container(
                        height: 210,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              AppColors.primaryBlue,
                              AppColors.primaryBlue.withOpacity(0.85),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => ProfilePage(
                                            token: widget.token,
                                            user: widget.user,
                                          ),
                                        ),
                                      );
                                    },
                                    child: Row(
                                      children: [
                                        Container(
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: CircleAvatar(
                                            radius: 22,
                                            backgroundColor: Colors.white
                                                .withOpacity(0.2),
                                            child: const Icon(
                                              Icons.store,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                shopName,
                                                style: const TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: Colors.white,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                roleLabel,
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.white
                                                      .withOpacity(0.8),
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  height: 40,
                                  width: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.15),
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.notifications_none_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                    onPressed: () {},
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 28),
                            Text(
                              'Halo, $userName 👋',
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                                letterSpacing: -0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Kualitas adalah prioritas. Berikut ringkasan hari ini.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // CONTENT SECTION
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildGridStatCard(
                              title: 'Pesanan Aktif',
                              count: pesananAktifVal,
                              subtitle: '+2 hari ini',
                              icon: Icons.assignment_rounded,
                              gradientColors: [
                                Colors.blue.shade400,
                                Colors.blue.shade600,
                              ],
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: _buildGridStatCard(
                              title: 'Antrean Cuci',
                              count: antreanCuciVal,
                              subtitle: '$deepCleaningVal Deep Cleaning',
                              icon: Icons.water_drop_rounded,
                              gradientColors: [
                                Colors.teal.shade400,
                                Colors.teal.shade600,
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // SALDO TOKO CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.015),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.account_balance_wallet_rounded,
                                        size: 16,
                                        color: Colors.grey.shade400,
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'SALDO TOKO',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.grey.shade400,
                                          letterSpacing: 0.5,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    _formatCurrency(
                                      _dashboardController.saldoToko,
                                    ),
                                    style: const TextStyle(
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2C3E50),
                                      letterSpacing: -0.5,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.primaryBlue.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.account_balance_wallet_outlined,
                                size: 20,
                                color: AppColors.primaryBlue,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 16),

                      _buildUlasanCard(context),
                      const SizedBox(height: 16),

                      // INPUT MANUAL OFFLINE BANNER
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFE6F0FA), Color(0xFFDBEAFE)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFBFDBFE).withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Registrasi Pesanan Offline',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E3A8A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Daftarkan pelanggan walk-in / offline langsung ke sistem.',
                              style: TextStyle(
                                fontSize: 12,
                                color: Color(0xFF1E40AF),
                              ),
                            ),
                            const SizedBox(height: 14),
                            SizedBox(
                              width: double.infinity,
                              height: 44,
                              child: ElevatedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          InputOffPage(token: widget.token),
                                    ),
                                  );
                                },
                                icon: const Icon(
                                  Icons.add_circle_outline_rounded,
                                  size: 18,
                                ),
                                label: const Text(
                                  'Buat Pesanan Walk-In',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDark,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 26),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Aktivitas Terkini',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF334155),
                              letterSpacing: -0.3,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      HistoryPage(token: widget.token),
                                ),
                              );
                            },
                            child: const Row(
                              children: [
                                Text(
                                  'Lihat Semua',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primaryBlue,
                                  ),
                                ),
                                SizedBox(width: 2),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.primaryBlue,
                                  size: 16,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (_dashboardController.aktivitasTerkini != null &&
                          _dashboardController.aktivitasTerkini is List)
                        ...(_dashboardController.aktivitasTerkini as List)
                            .take(5)
                            .map((activity) {
                              if (activity is! Map)
                                return const SizedBox.shrink();
                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.015),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryBlue
                                            .withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.inventory_2_outlined,
                                        size: 20,
                                        color: AppColors.primaryBlue,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            activity['nama_sepatu'] ?? 'Sepatu',
                                            style: const TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF334155),
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Text(
                                            activity['layanan'] ?? 'Layanan',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey.shade500,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: _getStatusColor(
                                          activity['status_order'],
                                        ).withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        activity['status_order']
                                                ?.toString()
                                                .toUpperCase() ??
                                            'PENDING',
                                        style: TextStyle(
                                          fontSize: 9,
                                          fontWeight: FontWeight.bold,
                                          color: _getStatusColor(
                                            activity['status_order'],
                                          ),
                                          letterSpacing: 0.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            })
                            .toList(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildGridStatCard({
    required String title,
    required int count,
    required String subtitle,
    required IconData icon,
    required List<Color> gradientColors,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title.toUpperCase(),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: Colors.grey.shade400,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: gradientColors[0].withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 14, color: gradientColors[1]),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            count.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF2C3E50),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey.shade400,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildUlasanCard(BuildContext context) {
    final int? myShopId = int.tryParse(
      widget.user['id_shops']?.toString() ??
          widget.user['shop']?['id_shops']?.toString() ??
          '',
    );

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.015),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    UlasanAdminPage(token: widget.token, idShops: myShopId),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.star_rounded,
                    size: 24,
                    color: Colors.amber,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ulasan Pelanggan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2C3E50),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Lihat rating dan masukan dari pembeli',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded, color: Colors.grey),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Color _getStatusColor(String? status) {
  switch (status?.toLowerCase()) {
    case 'pending':
      return Colors.orange.shade700;
    case 'diproses':
    case 'dicuci':
      return Colors.blue.shade700;
    case 'selesai':
    case 'siap_ambil':
      return Colors.green.shade700;
    default:
      return Colors.grey.shade700;
  }
}

class _HeaderClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    Path path = Path();
    path.lineTo(0, size.height - 40);
    path.quadraticBezierTo(
      size.width / 2,
      size.height,
      size.width,
      size.height - 40,
    );
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
