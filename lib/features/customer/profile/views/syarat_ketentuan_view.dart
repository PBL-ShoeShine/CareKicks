import 'package:flutter/material.dart';
import 'package:carekicks/core/constants/app_colors.dart';

class SyaratKetentuanView extends StatelessWidget {
  const SyaratKetentuanView({super.key});

  // Base Style untuk mengatur standar font agar seragam dan rapi
  static const TextStyle _baseStyle = TextStyle(
    fontSize: 14, // Diperbesar sedikit agar nyaman dibaca
    height: 1.6, // Jarak antar baris lebih lega
    color: Color(0xFF333333), // Warna hitam/abu gelap pekat yang konsisten
    fontWeight: FontWeight.w400,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Syarat & Ketentuan | ShoeShine',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade200, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(
          24.0,
        ), // Padding dinaikkan agar tidak terlalu mepet
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Syarat dan Ketentuan Penggunaan ShoeShine',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryDark,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),
            _buildParagraph(
              'Syarat dan ketentuan yang ditetapkan di bawah ini merupakan perjanjian antara Pengguna ("Anda") dengan ShoeShine ("Kami") yang mengatur hak, kewajiban, dan tanggung jawab Pengguna terhadap penggunaan layanan, fitur, dan/atau jasa yang diakses melalui aplikasi ShoeShine ("Situs/Aplikasi").',
            ),
            const SizedBox(height: 12),
            _buildParagraph(
              'Dengan mendaftar dan/atau menggunakan Situs/Aplikasi, maka Pengguna dianggap telah membaca, mengerti, memahami, dan menyetujui semua isi dalam Syarat dan Ketentuan ini. Jika Pengguna tidak menyetujui salah satu, sebagian, atau seluruh isi Syarat dan Ketentuan, maka Pengguna tidak diperkenankan mengakses dan/atau menggunakan Situs/Aplikasi.',
            ),

            _buildSectionTitle('A. Definisi'),
            _buildBulletPoint(
              'ShoeShine adalah platform marketplace digital yang menghubungkan Pelanggan dengan Mitra Cuci Sepatu untuk bertransaksi jasa perawatan, pencucian, dan perbaikan sepatu.',
            ),
            _buildBulletPoint(
              'Pengguna adalah pihak yang menggunakan layanan ShoeShine, termasuk namun tidak terbatas pada Pelanggan dan Mitra Cuci.',
            ),
            _buildBulletPoint(
              'Pelanggan adalah Pengguna terdaftar yang melakukan pemesanan jasa cuci, perawatan, pewarnaan ulang (repaint), atau perbaikan sepatu melalui aplikasi ShoeShine.',
            ),
            _buildBulletPoint(
              'Mitra Cuci (Penyedia Jasa) adalah Pengguna terdaftar (baik perorangan maupun badan usaha) yang menawarkan dan menyediakan layanan perawatan sepatu kepada Pelanggan melalui aplikasi ShoeShine.',
            ),
            _buildBulletPoint(
              'Layanan adalah segala jenis jasa perawatan, pencucian, pembersihan, pewarnaan, atau perbaikan sepatu yang disediakan oleh Mitra Cuci.',
            ),
            _buildBulletPoint(
              'Transaksi adalah kesepakatan pemesanan dan pembayaran Layanan antara Pelanggan dan Mitra Cuci yang diproses melalui sistem ShoeShine.',
            ),

            _buildSectionTitle('B. Akun, Password, dan Keamanan'),
            _buildNumberedList([
              'Pengguna dengan ini menyatakan bahwa Pengguna adalah individu yang cakap secara hukum untuk membuat perjanjian yang mengikat.',
              'ShoeShine tidak memungut biaya pendaftaran akun kepada Pengguna.',
              'Pengguna bertanggung jawab secara pribadi untuk menjaga kerahasiaan akun, password, dan kode OTP (One Time Password) untuk semua aktivitas yang terjadi dalam akun Pengguna.',
              'ShoeShine tidak akan pernah meminta password maupun kode OTP milik akun Pengguna untuk alasan apa pun. Pengguna diimbau untuk tidak memberikan data tersebut kepada pihak mana pun.',
            ]),

            _buildSectionTitle('C. Pemesanan dan Transaksi Layanan'),
            _buildNumberedList([
              'Pelanggan wajib memberikan informasi, foto, dan deskripsi yang jujur, jelas, serta akurat mengenai kondisi awal sepatu sebelum melakukan pemesanan.',
              'Mitra Cuci berhak menolak pesanan apabila kondisi sepatu dinilai terlalu rusak, tidak sesuai dengan deskripsi yang diberikan Pelanggan, atau di luar kapasitas keahlian Mitra Cuci.',
              'Segala bentuk komunikasi mengenai detail layanan, perubahan instruksi, keluhan, dan kesepakatan tambahan wajib dilakukan melalui fitur Chat resmi yang tersedia di dalam aplikasi ShoeShine sebagai bukti transaksi yang sah.',
            ]),

            _buildSectionTitle('D. Pengiriman dan Logistik Sepatu'),
            _buildNumberedList([
              'Proses penyerahan dan pengembalian sepatu dapat dilakukan melalui opsi kurir internal ShoeShine, kurir pihak ketiga yang terintegrasi dalam sistem, atau diantar langsung oleh Pelanggan (tergantung fitur yang diaktifkan).',
              'Pelanggan wajib mengemas (packing) sepatu dengan aman dan rapi sebelum diserahkan kepada kurir atau Mitra Cuci untuk menghindari kerusakan fisik selama perjalanan.',
              'Risiko kehilangan atau kerusakan komoditas selama proses pengiriman oleh kurir pihak ketiga tunduk pada peraturan dan ketentuan ganti rugi dari penyedia jasa logistik yang bersangkutan.',
            ]),

            _buildSectionTitle(
              'E. Kebijakan Kondisi Barang, Kerusakan, dan Ganti Rugi',
            ),
            _buildNumberedList([
              'Dokumentasi Wajib: Mitra Cuci wajib mengambil dokumentasi berupa foto atau video yang jelas mengenai kondisi sepatu saat pertama kali diterima dari kurir/Pelanggan, dan mengunggahnya ke sistem ShoeShine sebelum proses pengerjaan dimulai.',
              'Kerusakan Bawaan: Mitra Cuci dan ShoeShine dibebaskan dari tanggung jawab atas kerusakan sepatu yang diakibatkan oleh kondisi bawaan material sepatu yang sudah rapuk, getas, cacat tersembunyi, atau dampak penuaan alami produk yang terjadi selama atau setelah proses pembersihan.',
              'Kelalaian Pengerjaan: Apabila terbukti terjadi kerusakan atau kehilangan komponen sepatu akibat murni kelalaian Mitra Cuci (seperti warna luntur akibat salah bahan kimia, sol meleleh, atau kain robek saat pengerjaan), maka Mitra Cuci wajib memberikan kompensasi ganti rugi kepada Pelanggan.',
              'Batasan Nilai Ganti Rugi: Kecuali jika Pelanggan memilih fitur proteksi/asuransi tambahan di awal transaksi, batas maksimal nilai ganti rugi yang wajib dibayarkan oleh Mitra Cuci atas kerusakan atau kehilangan sepatu adalah maksimal sebesar 10x (sepuluh kali) dari total biaya jasa pencucian yang dipesan, dan bukan berdasarkan harga beli awal sepatu tersebut.',
            ]),

            _buildSectionTitle('F. Harga dan Pembayaran'),
            _buildNumberedList([
              'Tarif atau harga Layanan yang tertera pada aplikasi ditentukan sepenuhnya oleh masing-masing Mitra Cuci sesuai dengan jenis perawatan yang dipilih.',
              'Metode pembayaran utama yang berlaku untuk setiap pesanan adalah Transfer Bank langsung ke rekening milik Mitra Cuci yang bersangkutan.',
              'Pelanggan wajib memastikan nama bank, nomor rekening tujuan, dan nominal transfer sudah sesuai dengan tagihan sebelum melakukan pembayaran. Pelanggan juga diwajibkan untuk mengunggah bukti transfer yang sah ke dalam sistem ShoeShine untuk proses verifikasi oleh Mitra Cuci.',
              'Pelepasan Tanggung Jawab: Karena dana pembayaran ditransfer langsung kepada Mitra Cuci (tanpa melalui rekening penampung/bersama milik ShoeShine), maka ShoeShine dibebaskan dari segala tuntutan ganti rugi apabila terjadi penipuan, kesalahan transfer nominal, atau kegagalan penyediaan jasa oleh Mitra Cuci.',
            ]),

            _buildSectionTitle('G. Sistem Resolusi Kendala (Komplain)'),
            _buildNumberedList([
              'Apabila hasil pengerjaan tidak sesuai dengan kesepakatan atau terdapat kendala fisik pada sepatu yang diterima kembali, Pelanggan dapat mengajukan komplain melalui fitur "Pusat Resolusi" ShoeShine dalam jangka waktu maksimal 2x24 jam sejak pesanan dinyatakan selesai.',
              'Penyelesaian Dana: Mengingat dana pembayaran telah diterima langsung oleh Mitra Cuci sejak awal transaksi, maka segala bentuk kesepakatan pengembalian dana (refund) atau kompensasi ganti rugi harus diselesaikan dan ditransfer secara langsung antara Mitra Cuci kepada Pelanggan.',
              'ShoeShine hanya memfasilitasi ruang mediasi dan pencatatan riwayat komplain, namun tidak memiliki wewenang atau akses sistem untuk menarik maupun mengembalikan dana dari rekening Mitra Cuci.',
            ]),

            _buildSectionTitle('H. Pembatasan Tanggung Jawab'),
            _buildParagraph(
              'ShoeShine bertindak murni sebagai platform perantara berbasis Consumer-to-Consumer (C2C) yang menghubungkan Pelanggan dengan penyedia jasa pihak ketiga (Mitra Cuci). ShoeShine tidak memiliki, mengelola, atau mengoperasikan gerai cuci sepatu secara langsung, sehingga kualitas teknis hasil pengerjaan, ketepatan waktu pengerjaan oleh Mitra Cuci, dan kepatuhan Mitra Cuci terhadap kesepakatan pengerjaan merupakan tanggung jawab penuh dari Mitra Cuci yang bersangkutan.',
            ),

            const SizedBox(height: 50),
          ],
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(text, textAlign: TextAlign.justify, style: _baseStyle);
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 28, bottom: 12),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black, // Warna judul tetap hitam pekat
        ),
      ),
    );
  }

  Widget _buildBulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              height: 1.6,
              color: Color(0xFF333333),
            ),
          ),
          Expanded(
            child: Text(text, textAlign: TextAlign.justify, style: _baseStyle),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberedList(List<String> items) {
    return Column(
      children: items.asMap().entries.map((entry) {
        int idx = entry.key + 1;
        String text = entry.value;

        // Mendeteksi bagian mana yang harus ditebalkan (sebelum titik dua ':')
        int colonIndex = text.indexOf(':');
        bool hasBoldIntro = colonIndex != -1 && colonIndex < 35;

        return Padding(
          padding: const EdgeInsets.only(bottom: 12.0, left: 4.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$idx. ', style: _baseStyle),
              Expanded(
                child: hasBoldIntro
                    ? Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: '${text.substring(0, colonIndex + 1)} ',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ), // Bold khusus untuk awalan
                            ),
                            TextSpan(text: text.substring(colonIndex + 1)),
                          ],
                        ),
                        textAlign: TextAlign.justify,
                        style:
                            _baseStyle, // Style utamanya 100% sama dengan text biasa
                      )
                    : Text(
                        text,
                        textAlign: TextAlign.justify,
                        style: _baseStyle,
                      ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
