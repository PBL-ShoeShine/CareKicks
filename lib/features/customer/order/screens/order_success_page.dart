import 'package:flutter/material.dart';
import '../../../../../core/constants/app_colors.dart';
import '../../../customer/riwayat/views/riwayat_page.dart';
import '../../../customer/detail_order/views/detail_order_page.dart';

class OrderSuccessPage extends StatelessWidget {
  final String token;
  final String orderId;
  final String kodeOrder;
  final int totalHarga;

  const OrderSuccessPage({
    super.key,
    required this.token,
    required this.orderId,
    required this.kodeOrder,
    required this.totalHarga,
  });

  String _formatCurrency(int value) {
    final formatted = value.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+$)'),
      (match) => '${match[1]}.',
    );
    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Ikon sukses
                  Container(
                    width: 110,
                    height: 110,
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_circle_rounded,
                      size: 72,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(height: 28),

                  // Judul
                  const Text(
                    'Pesanan Berhasil Dibuat!',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1A1A2E),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 10),

                  // Kode pesanan
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '#$kodeOrder',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Kartu info alur
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Langkah Selanjutnya',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                        const SizedBox(height: 14),
                        _buildStep(
                          icon: Icons.hourglass_top_rounded,
                          color: AppColors.primaryBlue,
                          title: 'Menunggu Konfirmasi Admin',
                          subtitle: 'Admin toko sedang memproses pesananmu',
                          isActive: true,
                        ),
                        _buildDivider(),
                        _buildStep(
                          icon: Icons.payment_rounded,
                          color: Colors.orange.shade600,
                          title: 'Lakukan Pembayaran',
                          subtitle:
                              'Setelah dikonfirmasi, kamu akan mendapat info pembayaran',
                          isActive: false,
                        ),
                        _buildDivider(),
                        _buildStep(
                          icon: Icons.local_shipping_rounded,
                          color: Colors.green.shade600,
                          title: 'Sepatu Dijemput & Dicuci',
                          subtitle:
                              'Kurir akan menjemput sepatumu setelah pembayaran terverifikasi',
                          isActive: false,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Total harga info
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Tagihan',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        Text(
                          _formatCurrency(totalHarga),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Tombol aksi
              Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => DetailOrderPage(
                              token: token,
                              orderId: orderId,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Lihat Detail Pesanan',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton(
                      onPressed: () {
                        // Kembali ke home (popUntil first route)
                        Navigator.of(context).popUntil(
                          (route) => route.isFirst,
                        );
                        // Lalu push riwayat (tab index 1 pada CustomerMainPage)
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => RiwayatPage(token: token),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primaryBlue,
                        side: const BorderSide(color: AppColors.primaryBlue),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Lihat Semua Pesanan',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required bool isActive,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: color.withOpacity(isActive ? 0.15 : 0.07),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isActive ? color : color.withOpacity(0.4),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? const Color(0xFF1A1A2E)
                      : const Color(0xFF94A3B8),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isActive
                      ? const Color(0xFF64748B)
                      : const Color(0xFFCBD5E1),
                ),
              ),
            ],
          ),
        ),
        if (isActive)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: AppColors.primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Sekarang',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryBlue,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDivider() {
    return Padding(
      padding: const EdgeInsets.only(left: 18, top: 6, bottom: 6),
      child: Container(
        width: 1,
        height: 20,
        color: const Color(0xFFE2E8F0),
      ),
    );
  }
}
