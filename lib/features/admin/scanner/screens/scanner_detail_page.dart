import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_scaffold.dart';

const _brand = Color(0xFF1FB6C1);

class ScannerDetailPage extends StatelessWidget {
  // Variabel untuk menangkap data lemparan dari halaman scanner
  final Map<String, dynamic> dataOrder;

  const ScannerDetailPage({super.key, required this.dataOrder});

  @override
  Widget build(BuildContext context) {
    // Membongkar data dari Supabase agar mudah dipanggil di UI
    final customerName = dataOrder['customers']?['nama'] ?? 'Tidak diketahui';
    final customerAddress = dataOrder['customers']?['alamat'] ?? '-';
    final orderCode = dataOrder['kode_order'] ?? '-';
    final status = dataOrder['status_order'] ?? 'pending';
    final orderDate = dataOrder['tgl_order'] ?? '-';

    // Karena detail_orders adalah array/list, kita sediakan default list kosong
    final details = dataOrder['detail_orders'] as List? ?? [];

    return CustomScaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // KARTU INFO PELANGGAN
            _buildInfoCard(
              title: 'Informasi Pelanggan',
              icon: Icons.person_outline,
              children: [
                _buildRow('Kode Order', orderCode, isBold: true),
                _buildRow('Tanggal', orderDate),
                const Divider(height: 24),
                _buildRow('Nama', customerName),
                _buildRow('Alamat', customerAddress),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _brand.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Status: $status',
                    style: const TextStyle(
                      color: _brand,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Text(
              'Item Sepatu & Treatment',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            // KARTU LIST SEPATU & LAYANAN (Bisa lebih dari 1 sepatu)
            ...details.map((sepatu) {
              final merk = sepatu['merk'] ?? '-';
              final jenis = sepatu['jenis_sepatu'] ?? '-';
              final warna = sepatu['warna'] ?? '-';
              final layanan = sepatu['services']?['nama_layanan'] ?? '-';

              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.shopping_bag_outlined, color: _brand),
                        const SizedBox(width: 8),
                        Text(
                          merk,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    _buildRow('Jenis', jenis),
                    _buildRow('Warna', warna),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Treatment:',
                            style: TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            layanan,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // Fungsi bantuan untuk membuat baris teks agar rapi
  Widget _buildRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey, fontSize: 14)),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _brand, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }
}
