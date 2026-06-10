import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:carekicks/core/constants/app_colors.dart';
import '../controllers/metode_pembayaran_controller.dart';

// ─── FORMATTER: SPASI TIAP 4 DIGIT ──────────────────────────────────────────
class _CardNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final text = newValue.text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      final next = i + 1;
      if (next % 4 == 0 && next != text.length) buffer.write(' ');
    }
    final formatted = buffer.toString();
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}

// ─── WIDGET LOGO BANK ────────────────────────────────────────────────────────
// Sumber: https://raw.githubusercontent.com/hafidznoor/idn-finlogos/main/icons/[slug].svg
// Format SVG — pakai flutter_svg package
class _BankLogo extends StatelessWidget {
  final String? slug; // nama file tanpa .svg, contoh: 'bca', 'mandiri'
  final String name; // untuk fallback inisial
  final double size;

  const _BankLogo({required this.name, this.slug, this.size = 40});

  static const _base =
      'https://raw.githubusercontent.com/hafidznoor/idn-finlogos/main/icons';

  String? get _url {
    if (slug == null || slug!.isEmpty) return null;
    return '$_base/$slug.svg';
  }

  @override
  Widget build(BuildContext context) {
    final url = _url;
    if (url == null) return _fallback();

    return SvgPicture.network(
      url,
      width: size,
      height: size,
      fit: BoxFit.contain,
      placeholderBuilder: (_) => _shimmer(),
    );
  }

  Widget _shimmer() => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
    ),
  );

  Widget _fallback() => Container(
    width: size,
    height: size,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: AppColors.primaryBlue.withOpacity(0.08),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      name.isNotEmpty ? name[0].toUpperCase() : '?',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        color: AppColors.primaryBlue,
        fontSize: 16,
      ),
    ),
  );
}

// ─── MAIN VIEW ───────────────────────────────────────────────────────────────
class MetodePembayaranView extends StatefulWidget {
  final String token;
  const MetodePembayaranView({super.key, required this.token});

  @override
  State<MetodePembayaranView> createState() => _MetodePembayaranViewState();
}

class _MetodePembayaranViewState extends State<MetodePembayaranView> {
  final MetodePembayaranController _controller = MetodePembayaranController();
  bool isBankSelected = true;

  // ─── DATABASE BANK & E-WALLET ─────────────────────────────────────────────
  // slug = nama file di idn-finlogos (tanpa .svg)
  // null = tidak ada logo di repo, pakai fallback inisial
  static const List<Map<String, String?>> daftarBankLengkap = [
    // ===== BANK =====
    {'name': 'BCA', 'slug': 'bca', 'type': 'Bank'},
    {'name': 'Mandiri', 'slug': 'mandiri', 'type': 'Bank'},
    {'name': 'BNI', 'slug': 'bni', 'type': 'Bank'},
    {'name': 'BRI', 'slug': 'bri', 'type': 'Bank'},
    {'name': 'BSI', 'slug': 'bsi', 'type': 'Bank'},
    {'name': 'BTN', 'slug': 'btn', 'type': 'Bank'},
    {'name': 'CIMB Niaga', 'slug': 'cimb-niaga', 'type': 'Bank'},
    {'name': 'Permata Bank', 'slug': 'permata', 'type': 'Bank'},
    {'name': 'Danamon', 'slug': 'danamon', 'type': 'Bank'},
    {'name': 'Bank Mega', 'slug': 'mega', 'type': 'Bank'},
    {'name': 'Maybank', 'slug': 'maybank', 'type': 'Bank'},
    {'name': 'OCBC NISP', 'slug': 'ocbc-nisp', 'type': 'Bank'},
    {'name': 'Panin Bank', 'slug': null, 'type': 'Bank'},
    {'name': 'Bukopin', 'slug': null, 'type': 'Bank'},
    {'name': 'Sinarmas', 'slug': 'sinarmas', 'type': 'Bank'},
    {'name': 'Muamalat', 'slug': null, 'type': 'Bank'},
    {'name': 'Jenius', 'slug': 'jenius', 'type': 'Bank'},
    {'name': 'Bank Jago', 'slug': 'jago', 'type': 'Bank'},
    {'name': 'SeaBank', 'slug': 'seabank', 'type': 'Bank'},
    {'name': 'Allo Bank', 'slug': 'allo', 'type': 'Bank'},
    {'name': 'Bank Neo Commerce', 'slug': 'bnc', 'type': 'Bank'},
    {'name': 'Bank DKI', 'slug': 'bank-dki', 'type': 'Bank'},
    {'name': 'Bank Jateng', 'slug': null, 'type': 'Bank'},
    {'name': 'Bank Jatim', 'slug': null, 'type': 'Bank'},
    {'name': 'HSBC Indonesia', 'slug': 'hsbc', 'type': 'Bank'},
    {'name': 'Citibank', 'slug': 'citibank', 'type': 'Bank'},
    {'name': 'Commonwealth', 'slug': 'commonwealth', 'type': 'Bank'},
    {
      'name': 'Standard Chartered',
      'slug': 'standard-chartered',
      'type': 'Bank',
    },

    // ===== E-WALLET =====
    {'name': 'GoPay', 'slug': 'gopay', 'type': 'E-Wallet'},
    {'name': 'OVO', 'slug': null, 'type': 'E-Wallet'},
    {'name': 'DANA', 'slug': 'dana', 'type': 'E-Wallet'},
    {'name': 'ShopeePay', 'slug': 'shopee-pay', 'type': 'E-Wallet'},
    {'name': 'LinkAja', 'slug': 'linkaja', 'type': 'E-Wallet'},
    {'name': 'Doku', 'slug': 'doku', 'type': 'E-Wallet'},
    {'name': 'Sakuku', 'slug': null, 'type': 'E-Wallet'},
    {'name': 'Akulaku', 'slug': 'akulaku', 'type': 'E-Wallet'},
  ];

  static const _popularNames = [
    'BCA',
    'Mandiri',
    'BNI',
    'BRI',
    'GoPay',
    'DANA',
    'ShopeePay',
  ];

  @override
  void initState() {
    super.initState();
    _controller.fetchPaymentMethods(widget.token);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
      ),
    );
  }

  String _formatAccountNumber(String text) {
    text = text.replaceAll(' ', '');
    final buffer = StringBuffer();
    for (int i = 0; i < text.length; i++) {
      buffer.write(text[i]);
      if ((i + 1) % 4 == 0 && i != text.length - 1) buffer.write(' ');
    }
    return buffer.toString();
  }

  // Cari slug dari nama bank yang tersimpan di DB
  String? _getSlug(String namaBankFull) {
    try {
      final match = daftarBankLengkap.firstWhere((e) {
        final eName = e['name']!.toLowerCase();
        final qName = namaBankFull.toLowerCase();
        return eName == qName || qName.contains(eName) || eName.contains(qName);
      });
      return match['slug'];
    } catch (_) {
      return null;
    }
  }

  // ─── HIGHLIGHT TEKS PENCARIAN ─────────────────────────────────────────────
  Widget _highlightText(String text, String query) {
    if (query.isEmpty) {
      return Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      );
    }
    final lower = text.toLowerCase();
    final q = query.toLowerCase().trim();
    final idx = lower.indexOf(q);
    if (idx < 0) {
      return Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
      );
    }
    return RichText(
      text: TextSpan(
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 15,
          color: Colors.black87,
        ),
        children: [
          if (idx > 0) TextSpan(text: text.substring(0, idx)),
          TextSpan(
            text: text.substring(idx, idx + q.length),
            style: TextStyle(
              color: AppColors.primaryBlue,
              backgroundColor: AppColors.primaryBlue.withOpacity(0.12),
            ),
          ),
          if (idx + q.length < text.length)
            TextSpan(text: text.substring(idx + q.length)),
        ],
      ),
    );
  }

  // ─── BOTTOM SHEET: PILIH BANK ─────────────────────────────────────────────
  Future<Map<String, String?>?> _showBankSearchSheet() async {
    return showModalBottomSheet<Map<String, String?>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        String searchQuery = '';
        String activeFilter = 'Semua';
        final searchCtrl = TextEditingController();
        Timer? debounce;

        return StatefulBuilder(
          builder: (context, setStateSheet) {
            final filtered = daftarBankLengkap.where((bank) {
              final matchFilter =
                  activeFilter == 'Semua' || bank['type'] == activeFilter;
              final q = searchQuery.toLowerCase().trim();
              final matchSearch =
                  q.isEmpty || bank['name']!.toLowerCase().contains(q);
              return matchFilter && matchSearch;
            }).toList()..sort((a, b) => a['name']!.compareTo(b['name']!));

            final banks = filtered.where((b) => b['type'] == 'Bank').toList();
            final wallets = filtered
                .where((b) => b['type'] == 'E-Wallet')
                .toList();
            final popular = daftarBankLengkap
                .where((b) => _popularNames.contains(b['name']))
                .toList();

            return SafeArea(
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.92,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Pilih Bank / E-Wallet',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Search bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: searchCtrl,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(
                            Icons.search,
                            color: Colors.grey,
                          ),
                          suffixIcon: searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    searchCtrl.clear();
                                    setStateSheet(() => searchQuery = '');
                                  },
                                )
                              : null,
                          hintText: 'Cari nama bank atau e-wallet...',
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 0,
                          ),
                        ),
                        onChanged: (value) {
                          debounce?.cancel();
                          debounce = Timer(
                            const Duration(milliseconds: 250),
                            () => setStateSheet(() => searchQuery = value),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Filter chips
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: ['Semua', 'Bank', 'E-Wallet'].map((f) {
                          final active = activeFilter == f;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: ChoiceChip(
                              label: Text(f),
                              selected: active,
                              onSelected: (_) {
                                HapticFeedback.selectionClick();
                                setStateSheet(() => activeFilter = f);
                              },
                              selectedColor: AppColors.primaryBlue.withOpacity(
                                0.1,
                              ),
                              backgroundColor: Colors.white,
                              labelStyle: TextStyle(
                                color: active
                                    ? AppColors.primaryBlue
                                    : Colors.grey.shade600,
                                fontWeight: active
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                              side: BorderSide(
                                color: active
                                    ? AppColors.primaryBlue
                                    : Colors.grey.shade300,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    Divider(color: Colors.grey.shade100, thickness: 1),

                    Expanded(
                      child: filtered.isEmpty
                          ? _buildSearchEmpty(searchQuery)
                          : ListView(
                              padding: const EdgeInsets.only(bottom: 24),
                              children: [
                                // Popular shortcuts
                                if (searchQuery.isEmpty &&
                                    activeFilter == 'Semua') ...[
                                  _sectionHeader('POPULER'),
                                  SizedBox(
                                    height: 96,
                                    child: ListView.separated(
                                      scrollDirection: Axis.horizontal,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 20,
                                      ),
                                      itemCount: popular.length,
                                      separatorBuilder: (_, __) =>
                                          const SizedBox(width: 12),
                                      itemBuilder: (_, i) {
                                        final b = popular[i];
                                        return GestureDetector(
                                          onTap: () {
                                            HapticFeedback.selectionClick();
                                            Navigator.pop(context, b);
                                          },
                                          child: Column(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Container(
                                                width: 56,
                                                height: 56,
                                                padding: const EdgeInsets.all(
                                                  8,
                                                ),
                                                decoration: BoxDecoration(
                                                  color: Colors.white,
                                                  borderRadius:
                                                      BorderRadius.circular(16),
                                                  border: Border.all(
                                                    color: Colors.grey.shade200,
                                                  ),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: Colors.black
                                                          .withOpacity(0.05),
                                                      blurRadius: 6,
                                                    ),
                                                  ],
                                                ),
                                                child: _BankLogo(
                                                  name: b['name']!,
                                                  slug: b['slug'],
                                                  size: 40,
                                                ),
                                              ),
                                              const SizedBox(height: 6),
                                              Text(
                                                b['name']!,
                                                style: const TextStyle(
                                                  fontSize: 11,
                                                ),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Divider(color: Colors.grey.shade100),
                                ],

                                if (banks.isNotEmpty &&
                                    activeFilter != 'E-Wallet')
                                  _sectionHeader('BANK'),
                                ...banks.map(
                                  (b) => _bankListTile(b, searchQuery),
                                ),

                                if (wallets.isNotEmpty &&
                                    activeFilter != 'Bank') ...[
                                  if (banks.isNotEmpty)
                                    const SizedBox(height: 8),
                                  _sectionHeader('E-WALLET'),
                                ],
                                ...wallets.map(
                                  (b) => _bankListTile(b, searchQuery),
                                ),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sectionHeader(String label) => Padding(
    padding: const EdgeInsets.fromLTRB(24, 12, 24, 6),
    child: Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade500,
        letterSpacing: 1.2,
      ),
    ),
  );

  Widget _bankListTile(Map<String, String?> bank, [String highlight = '']) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        width: 48,
        height: 48,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: _BankLogo(name: bank['name']!, slug: bank['slug'], size: 36),
      ),
      title: _highlightText(bank['name']!, highlight),
      subtitle: bank['type'] == 'E-Wallet'
          ? Text(
              'E-Wallet',
              style: TextStyle(fontSize: 11, color: Colors.purple.shade300),
            )
          : null,
      trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
      onTap: () {
        HapticFeedback.selectionClick();
        Navigator.pop(context, bank);
      },
    );
  }

  Widget _buildSearchEmpty(String query) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
        const SizedBox(height: 12),
        Text(
          query.isEmpty ? 'Tidak ada data' : '"$query" tidak ditemukan',
          style: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Coba kata kunci lain',
          style: TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    ),
  );

  // ─── DIALOG TAMBAH BANK ──────────────────────────────────────────────────
  void _showAddBankDialog() {
    Map<String, String?>? selectedBank;
    final noRekCtrl = TextEditingController();
    final atasNamaCtrl = TextEditingController();
    bool isDefault = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tambah Rekening Bank',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Pilih bank
                  GestureDetector(
                    onTap: () async {
                      final bank = await _showBankSearchSheet();
                      if (bank != null) {
                        setStateSheet(() => selectedBank = bank);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade300),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          if (selectedBank != null) ...[
                            SizedBox(
                              width: 28,
                              height: 28,
                              child: _BankLogo(
                                name: selectedBank!['name']!,
                                slug: selectedBank!['slug'],
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Expanded(
                            child: Text(
                              selectedBank != null
                                  ? selectedBank!['name']!
                                  : 'Pilih Bank / E-Wallet',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: selectedBank != null
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: selectedBank != null
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ),
                          const Icon(
                            Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // No rekening
                  TextField(
                    controller: noRekCtrl,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      _CardNumberFormatter(),
                      LengthLimitingTextInputFormatter(25),
                    ],
                    decoration: InputDecoration(
                      labelText: 'Nomor Rekening / No HP',
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Atas nama
                  TextField(
                    controller: atasNamaCtrl,
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Atas Nama',
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  CheckboxListTile(
                    title: const Text(
                      'Jadikan Rekening Default',
                      style: TextStyle(fontSize: 14),
                    ),
                    value: isDefault,
                    activeColor: AppColors.primaryBlue,
                    onChanged: (val) =>
                        setStateSheet(() => isDefault = val ?? false),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.primaryBlue.withOpacity(0.4),
                      ),
                      onPressed: () async {
                        if (selectedBank == null ||
                            noRekCtrl.text.isEmpty ||
                            atasNamaCtrl.text.isEmpty) {
                          _showSnack('Semua kolom wajib diisi', isError: true);
                          return;
                        }
                        Navigator.pop(context);
                        final ok = await _controller.addPaymentMethod(
                          token: widget.token,
                          tipePembayaran: 'BANK_TRANSFER',
                          namaBank: selectedBank!['name']!,
                          noRek: noRekCtrl.text.trim(),
                          atasNama: atasNamaCtrl.text.trim(),
                          isDefault: isDefault,
                        );
                        if (ok) {
                          _showSnack('Rekening berhasil ditambahkan');
                        } else {
                          _showSnack(_controller.errorMessage, isError: true);
                        }
                      },
                      child: const Text(
                        'Simpan Rekening',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── DIALOG TAMBAH QRIS ──────────────────────────────────────────────────
  void _showAddQrisDialog() {
    final namaTokoCtrl = TextEditingController();
    final midCtrl = TextEditingController();
    File? selectedImage;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setStateSheet) => SafeArea(
          child: Padding(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'Tambah QRIS Mitra',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  // Upload foto QRIS
                  GestureDetector(
                    onTap: () async {
                      final picker = ImagePicker();
                      final pickedFile = await picker.pickImage(
                        source: ImageSource.gallery,
                      );
                      if (pickedFile != null) {
                        setStateSheet(
                          () => selectedImage = File(pickedFile.path),
                        );
                      }
                    },
                    child: Container(
                      height: 180,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.5),
                          width: 1.5,
                        ),
                        image: selectedImage != null
                            ? DecorationImage(
                                image: FileImage(selectedImage!),
                                fit: BoxFit.contain,
                              )
                            : null,
                      ),
                      child: selectedImage == null
                          ? Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.qr_code_scanner_rounded,
                                  size: 48,
                                  color: AppColors.primaryBlue.withOpacity(0.8),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Tap untuk upload foto QRIS',
                                  style: TextStyle(
                                    color: AppColors.primaryBlue,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            )
                          : null,
                    ),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: namaTokoCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nama Toko di QRIS (Wajib)',
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: midCtrl,
                    decoration: InputDecoration(
                      labelText: 'Nomor NMID (Wajib)',
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primaryBlue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 4,
                        shadowColor: AppColors.primaryBlue.withOpacity(0.4),
                      ),
                      onPressed: () async {
                        if (namaTokoCtrl.text.isEmpty || midCtrl.text.isEmpty) {
                          _showSnack(
                            'Nama Toko dan NMID wajib diisi',
                            isError: true,
                          );
                          return;
                        }
                        if (selectedImage == null) {
                          _showSnack('Harap upload foto QRIS', isError: true);
                          return;
                        }
                        Navigator.pop(context);
                        final ok = await _controller.addQrisWithImage(
                          token: widget.token,
                          namaToko: namaTokoCtrl.text.trim(),
                          mid: midCtrl.text.trim(),
                          imageFile: selectedImage,
                        );
                        if (ok) {
                          _showSnack('QRIS berhasil disimpan');
                        } else {
                          _showSnack(_controller.errorMessage, isError: true);
                        }
                      },
                      child: const Text(
                        'Simpan Data QRIS',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─── OPTIONS SHEET ────────────────────────────────────────────────────────
  void _showOptions(int idAccount, bool isQris) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            if (isQris)
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.image,
                    color: AppColors.primaryBlue,
                    size: 20,
                  ),
                ),
                title: const Text(
                  'Ganti Gambar QRIS',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  final ok = await _controller.uploadQrisImage(
                    widget.token,
                    idAccount,
                    ImageSource.gallery,
                  );
                  if (ok) {
                    _showSnack('Gambar QRIS berhasil diganti');
                  } else {
                    _showSnack(_controller.errorMessage, isError: true);
                  }
                },
              ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.errorRed.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: AppColors.errorRed,
                  size: 20,
                ),
              ),
              title: const Text(
                'Hapus Metode Pembayaran',
                style: TextStyle(
                  color: AppColors.errorRed,
                  fontWeight: FontWeight.w600,
                ),
              ),
              onTap: () async {
                Navigator.pop(context);
                final ok = await _controller.deletePaymentMethod(
                  widget.token,
                  idAccount,
                );
                if (ok) _showSnack('Berhasil dihapus');
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ─── MAIN BUILD ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Metode Pembayaran',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading &&
              _controller.bankAccounts.isEmpty &&
              _controller.qrisList.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          return Column(
            children: [
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Container(
                  height: 54,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _buildTab(
                        active: isBankSelected,
                        icon: Icons.account_balance,
                        label: 'Transfer Bank',
                        onTap: () => setState(() => isBankSelected = true),
                      ),
                      _buildTab(
                        active: !isBankSelected,
                        icon: Icons.qr_code_scanner,
                        label: 'QRIS Mitra',
                        onTap: () => setState(() => isBankSelected = false),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: isBankSelected
                      ? _buildBankTransferSection()
                      : _buildQrisSection(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTab({
    required bool active,
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Container(
          margin: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: active ? AppColors.primaryBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
            boxShadow: active
                ? [
                    BoxShadow(
                      color: AppColors.primaryBlue.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: active ? Colors.white : Colors.grey.shade500,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: active ? Colors.white : Colors.grey.shade600,
                  fontWeight: active ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBankTransferSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'DAFTAR REKENING',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_controller.bankAccounts.isEmpty)
          _buildEmptyState(
            'Belum ada rekening bank',
            Icons.account_balance_wallet_outlined,
          ),
        ..._controller.bankAccounts.map((b) => _buildBankCard(b)),
        const SizedBox(height: 16),
        _buildDashedButton(
          icon: Icons.add_card_rounded,
          label: 'Tambah Rekening Bank',
          onTap: _showAddBankDialog,
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildBankCard(Map<String, dynamic> bank) {
    final bool isDefault = bank['is_default'] ?? false;
    final bool isActive = bank['is_active'] ?? false;
    final String namaBankFull = bank['nama_bank'] ?? 'BANK';
    final String? slug = _getSlug(namaBankFull);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: isDefault
            ? Border.all(
                color: AppColors.primaryBlue.withOpacity(0.5),
                width: 1.5,
              )
            : null,
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
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(
                width: 60,
                height: 44,
                child: _BankLogo(name: namaBankFull, slug: slug, size: 44),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => _showOptions(bank['id_account'], false),
                child: const Icon(Icons.more_vert, color: Colors.grey),
              ),
            ],
          ),
          if (isDefault) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'DEFAULT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primaryBlue,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      namaBankFull,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatAccountNumber(bank['no_rek'] ?? ''),
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade800,
                        letterSpacing: 1.5,
                        fontFamily: 'Courier',
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'a.n. ${bank['atas_nama']}',
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              CupertinoSwitch(
                value: isActive,
                activeColor: AppColors.primaryBlue,
                onChanged: (val) => _controller.toggleStatus(
                  token: widget.token,
                  idAccount: bank['id_account'],
                  isActive: val,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQrisSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4),
          child: Text(
            'QRIS MITRA TOKO',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_controller.qrisList.isEmpty)
          _buildEmptyState(
            'Belum ada data QRIS',
            Icons.qr_code_scanner_rounded,
          ),
        ..._controller.qrisList.map((q) => _buildQrisCard(q)),
        const SizedBox(height: 16),
        _buildDashedButton(
          icon: Icons.add_photo_alternate_outlined,
          label: 'Tambah QRIS Baru',
          onTap: _showAddQrisDialog,
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildQrisCard(Map<String, dynamic> qris) {
    final bool isActive = qris['is_active'] ?? false;
    final String pathQris = qris['path_qris'] ?? '';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
              image: pathQris.isNotEmpty
                  ? DecorationImage(
                      image: NetworkImage(pathQris),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: pathQris.isEmpty
                ? const Center(
                    child: Icon(
                      Icons.qr_code_2,
                      color: Colors.black87,
                      size: 40,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  qris['atas_nama'] ?? 'QRIS Toko',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'NMID: ${qris['no_rek']}',
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                if (isActive)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.successGreen.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'AKTIF',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: AppColors.successGreen,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          Column(
            children: [
              GestureDetector(
                onTap: () => _showOptions(qris['id_account'], true),
                child: const Icon(Icons.more_vert, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              CupertinoSwitch(
                value: isActive,
                activeColor: AppColors.primaryBlue,
                onChanged: (val) => _controller.toggleStatus(
                  token: widget.token,
                  idAccount: qris['id_account'],
                  isActive: val,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, IconData icon) => Container(
    width: double.infinity,
    padding: const EdgeInsets.symmetric(vertical: 40),
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: Colors.grey.shade200),
    ),
    child: Column(
      children: [
        Icon(icon, size: 48, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
      ],
    ),
  );

  Widget _buildDashedButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 18),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColors.primaryBlue.withOpacity(0.5),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.primaryBlue, size: 22),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
        ],
      ),
    ),
  );
}
