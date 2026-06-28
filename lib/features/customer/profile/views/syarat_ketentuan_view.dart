import 'package:flutter/material.dart';
import 'package:carekicks/core/constants/app_colors.dart';

class SyaratKetentuanView extends StatelessWidget {
  const SyaratKetentuanView({super.key});

  // Base Style untuk mengatur standar font agar seragam dan rapi
  static const TextStyle _baseStyle = TextStyle(
    fontSize: 14,
    height: 1.6,
    color: Color(0xFF333333),
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

        // Mengatur jarak antara panah back dan judul agar tidak terlalu jauh
        leadingWidth: 42,
        titleSpacing: 0,

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
        padding: const EdgeInsets.all(24.0),
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
              'Mitra Cuci atau Penyedia Jasa adalah Pengguna terdaftar, baik perorangan maupun badan usaha, yang menawarkan dan menyediakan layanan perawatan sepatu kepada Pelanggan melalui aplikasi ShoeShine.',
            ),
            _buildBulletPoint(
              'Layanan adalah segala jenis jasa perawatan, pencucian, pembersihan, pewarnaan, atau perbaikan sepatu yang disediakan oleh Mitra Cuci.',
            ),
            _buildBulletPoint(
              'Transaksi adalah kesepakatan pemesanan dan pembayaran Layanan antara Pelanggan dan Mitra Cuci yang diproses atau dicatat melalui sistem ShoeShine.',
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
              'Segala bentuk komunikasi mengenai detail layanan, perubahan instruksi, keluhan, dan kesepakatan tambahan sebaiknya dilakukan melalui fitur komunikasi resmi yang tersedia di dalam aplikasi ShoeShine, apabila fitur tersebut tersedia, agar dapat menjadi bukti komunikasi antara Pelanggan dan Mitra Cuci.',
            ]),

            _buildSectionTitle('D. Pengiriman dan Logistik Sepatu'),
            _buildNumberedList([
              'Proses penyerahan dan pengembalian sepatu dapat dilakukan melalui opsi kurir internal ShoeShine, kurir pihak ketiga yang terintegrasi dalam sistem, atau diantar langsung oleh Pelanggan, tergantung fitur dan metode pengiriman yang tersedia pada saat transaksi.',
              'Pelanggan wajib mengemas atau menyerahkan sepatu dengan aman dan rapi sebelum diberikan kepada kurir atau Mitra Cuci untuk mengurangi risiko kerusakan fisik selama perjalanan.',
              'Risiko kehilangan atau kerusakan barang selama proses pengiriman oleh kurir pihak ketiga tunduk pada peraturan dan ketentuan ganti rugi dari penyedia jasa logistik yang bersangkutan.',
            ]),

            _buildSectionTitle(
              'E. Kebijakan Kondisi Barang, Kerusakan, dan Ganti Rugi',
            ),
            _buildNumberedList([
              'Dokumentasi Wajib: Mitra Cuci wajib mengambil dokumentasi berupa foto atau video yang jelas mengenai kondisi sepatu saat pertama kali diterima dari kurir atau Pelanggan sebelum proses pengerjaan dimulai.',
              'Kerusakan Bawaan: Mitra Cuci dan ShoeShine dibebaskan dari tanggung jawab atas kerusakan sepatu yang diakibatkan oleh kondisi bawaan material sepatu yang sudah rapuh, getas, cacat tersembunyi, atau dampak penuaan alami produk yang terjadi selama atau setelah proses pembersihan.',
              'Kelalaian Pengerjaan: Apabila terbukti terjadi kerusakan atau kehilangan komponen sepatu akibat kelalaian Mitra Cuci, seperti warna luntur akibat penggunaan bahan kimia yang tidak sesuai, sol meleleh, atau kain robek saat pengerjaan, maka tanggung jawab penyelesaian berada pada Mitra Cuci yang bersangkutan.',
              'Batasan Nilai Ganti Rugi: Apabila terdapat kesepakatan ganti rugi antara Pelanggan dan Mitra Cuci, nilai dan bentuk kompensasi diselesaikan secara langsung oleh para pihak. ShoeShine tidak bertanggung jawab atas nilai ganti rugi yang disepakati di luar sistem atau di luar ketentuan yang tersedia pada aplikasi.',
            ]),

            _buildSectionTitle('F. Harga dan Pembayaran'),
            _buildNumberedList([
              'Tarif atau harga Layanan yang tertera pada aplikasi ditentukan oleh masing-masing Mitra Cuci sesuai dengan jenis perawatan yang dipilih.',
              'Metode pembayaran utama yang berlaku untuk setiap pesanan adalah transfer bank langsung ke rekening milik Mitra Cuci yang bersangkutan, kecuali apabila di kemudian hari ShoeShine menyediakan metode pembayaran lain di dalam aplikasi.',
              'Pelanggan wajib memastikan nama bank, nomor rekening tujuan, dan nominal transfer sudah sesuai dengan tagihan sebelum melakukan pembayaran. Pelanggan juga diwajibkan untuk mengunggah bukti transfer yang sah ke dalam sistem ShoeShine apabila fitur unggah bukti pembayaran tersedia.',
              'Pelepasan Tanggung Jawab: Karena dana pembayaran ditransfer langsung kepada Mitra Cuci tanpa melalui rekening penampung atau rekening bersama milik ShoeShine, maka ShoeShine dibebaskan dari tuntutan ganti rugi yang timbul akibat kesalahan transfer, kesalahan nominal pembayaran, penipuan, atau kegagalan penyediaan jasa oleh Mitra Cuci.',
            ]),

            _buildSectionTitle('G. Penanganan Kendala Layanan'),
            _buildNumberedList([
              'Apabila hasil pengerjaan tidak sesuai dengan kesepakatan atau terdapat kendala pada sepatu yang diterima kembali, Pelanggan dapat menghubungi Mitra Cuci secara langsung melalui fitur komunikasi yang tersedia di aplikasi atau melalui kontak yang disepakati oleh para pihak.',
              'Pelanggan disarankan untuk menyimpan bukti pendukung berupa foto, video, bukti pembayaran, riwayat pemesanan, dan riwayat komunikasi dengan Mitra Cuci untuk mempermudah proses penyelesaian kendala.',
              'Untuk saat ini, ShoeShine belum menyediakan fitur komplain, pusat resolusi, atau sistem mediasi resmi di dalam aplikasi. Oleh karena itu, penyelesaian kendala, pengembalian dana, perbaikan ulang, atau kompensasi lainnya dilakukan secara langsung antara Pelanggan dan Mitra Cuci.',
              'ShoeShine tidak memiliki kewenangan untuk menarik dana dari rekening Mitra Cuci, membatalkan transfer yang telah dilakukan, atau memaksa Mitra Cuci memberikan pengembalian dana di luar mekanisme yang tersedia pada aplikasi.',
            ]),

            _buildSectionTitle('H. Pembatasan Tanggung Jawab'),
            _buildParagraph(
              'ShoeShine bertindak sebagai platform perantara berbasis Consumer-to-Consumer (C2C) yang menghubungkan Pelanggan dengan penyedia jasa pihak ketiga, yaitu Mitra Cuci. ShoeShine tidak memiliki, mengelola, atau mengoperasikan gerai cuci sepatu secara langsung, sehingga kualitas teknis hasil pengerjaan, ketepatan waktu pengerjaan, dan kepatuhan Mitra Cuci terhadap kesepakatan layanan merupakan tanggung jawab Mitra Cuci yang bersangkutan.',
            ),
            const SizedBox(height: 12),
            _buildParagraph(
              'Sepanjang diperbolehkan oleh hukum yang berlaku, ShoeShine tidak bertanggung jawab atas kerugian langsung maupun tidak langsung yang timbul dari tindakan, kelalaian, wanprestasi, atau pelanggaran yang dilakukan oleh Pelanggan, Mitra Cuci, kurir pihak ketiga, maupun pihak lain di luar kendali ShoeShine.',
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
          color: Colors.black,
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
        final int idx = entry.key + 1;
        final String text = entry.value;

        // Mendeteksi bagian mana yang harus ditebalkan, yaitu teks sebelum titik dua.
        final int colonIndex = text.indexOf(':');
        final bool hasBoldIntro = colonIndex != -1 && colonIndex < 35;

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
                              text: text.substring(0, colonIndex + 1),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            TextSpan(text: text.substring(colonIndex + 1)),
                          ],
                        ),
                        textAlign: TextAlign.justify,
                        style: _baseStyle,
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
