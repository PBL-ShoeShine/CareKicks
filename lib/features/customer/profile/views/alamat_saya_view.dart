import 'package:flutter/material.dart';
import 'package:carekicks/core/constants/app_colors.dart';
import '../controllers/customer_profile_controller.dart';
import 'tambah_alamat_view.dart';

class AlamatSayaView extends StatefulWidget {
  final String token;
  final CustomerProfileController profileController;

  const AlamatSayaView({
    super.key,
    required this.token,
    required this.profileController,
  });

  @override
  State<AlamatSayaView> createState() => _AlamatSayaViewState();
}

class _AlamatSayaViewState extends State<AlamatSayaView> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAlamat();
  }

  Future<void> _loadAlamat() async {
    setState(() => _isLoading = true);
    await widget.profileController.fetchAlamat(widget.token);
    if (mounted) setState(() => _isLoading = false);
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? AppColors.errorRed : AppColors.successGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _bukaFormAlamat({Map<String, dynamic>? existing}) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => TambahAlamatView(
          token: widget.token,
          profileController: widget.profileController,
          existing: existing,
        ),
      ),
    );
    if (result == true && mounted) await _loadAlamat();
  }

  void _confirmDelete(int idAddress) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
        contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        title: Row(
          children: const [
            Icon(Icons.delete_outline, color: AppColors.errorRed, size: 22),
            SizedBox(width: 8),
            Text(
              'Hapus Alamat',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
            ),
          ],
        ),
        content: const Text(
          'Apakah Anda yakin ingin menghapus alamat ini?\nTindakan ini tidak dapat dibatalkan.',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: Colors.grey.shade300),
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: const Text(
                    'Batal',
                    style: TextStyle(
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.errorRed,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    final ok = await widget.profileController.deleteAlamat(
                      token: widget.token,
                      idAddress: idAddress,
                    );
                    _showSnack(
                      ok ? 'Alamat berhasil dihapus' : 'Gagal menghapus alamat',
                      isError: !ok,
                    );
                    if (mounted) setState(() {});
                  },
                  child: const Text(
                    'Hapus',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final alamatList = widget.profileController.alamatList;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppBar(
        title: const Text(
          'Alamat Saya',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            )
          : alamatList.isEmpty
          ? _buildEmpty()
          : Column(
              children: [
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    itemCount: alamatList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (_, i) => _buildCard(alamatList[i]),
                  ),
                ),
                // ✅ FIX: Padding bawah dinaikkan agar tidak tertimpa navbar HP
                Container(
                  color: Colors.white,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    12,
                    16,
                    bottomPad + 24, // Diberi bantalan ekstra ke atas
                  ),
                  child: OutlinedButton(
                    onPressed: () => _bukaFormAlamat(),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.primaryBlue,
                        width: 1.5,
                      ),
                      minimumSize: const Size(double.infinity, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(
                          Icons.add_location_alt_outlined,
                          color: AppColors.primaryBlue,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Tambah Alamat Baru',
                          style: TextStyle(
                            color: AppColors.primaryBlue,
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  // ── Empty State ────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Column(
      children: [
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.location_off_outlined,
                  size: 64,
                  color: Colors.grey.shade300,
                ),
                const SizedBox(height: 16),
                Text(
                  'Belum ada alamat tersimpan',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 15),
                ),
              ],
            ),
          ),
        ),
        // ✅ FIX: Padding bawah dinaikkan untuk empty state juga
        Container(
          color: Colors.white,
          padding: EdgeInsets.fromLTRB(16, 12, 16, bottomPad + 24),
          child: OutlinedButton(
            onPressed: () => _bukaFormAlamat(),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primaryBlue, width: 1.5),
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.add_location_alt_outlined,
                  color: AppColors.primaryBlue,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Tambah Alamat Baru',
                  style: TextStyle(
                    color: AppColors.primaryBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Card Alamat ────────────────────────────────────────────────────────
  Widget _buildCard(Map<String, dynamic> a) {
    final isDefault = a['is_default'] == true;
    final fullAddress = a['full_address']?.toString() ?? '';
    final phone = a['phone_number']?.toString() ?? '';
    final label = a['address_label']?.toString() ?? '';

    final lines = fullAddress
        .split('\n')
        .where((l) => l.trim().isNotEmpty)
        .toList();
    final streetLine = lines.isNotEmpty ? lines.first : '';
    final detailLines = lines.length > 1 ? lines.sublist(1).join(', ') : '';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: isDefault
            ? Border.all(color: AppColors.primaryBlue, width: 1.5)
            : Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    children: [
                      Text(
                        a['recipient_name'] ?? '-',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      if (phone.isNotEmpty) ...[
                        Text(
                          '|',
                          style: TextStyle(
                            color: Colors.grey.shade300,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          phone,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (isDefault)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primaryBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppColors.primaryBlue,
                        width: 1,
                      ),
                    ),
                    child: const Text(
                      'Utama',
                      style: TextStyle(
                        color: AppColors.primaryBlue,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 6),

            if (streetLine.isNotEmpty)
              Text(
                streetLine,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                ),
              ),

            if (detailLines.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  detailLines.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey.shade500,
                    height: 1.4,
                    letterSpacing: 0.2,
                  ),
                ),
              ),

            if (label.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(
                    label,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                  ),
                ),
              ),

            const SizedBox(height: 8),
            Divider(color: Colors.grey.shade100, height: 1),
            const SizedBox(height: 4),

            Row(
              children: [
                if (!isDefault)
                  GestureDetector(
                    onTap: () async {
                      final ok = await widget.profileController
                          .setDefaultAlamat(
                            token: widget.token,
                            idAddress: a['id_address'],
                          );
                      _showSnack(
                        ok
                            ? 'Alamat utama berhasil diubah'
                            : 'Gagal mengubah alamat utama',
                        isError: !ok,
                      );
                      if (mounted) setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: AppColors.primaryBlue.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Jadikan Utama',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                const Spacer(),
                InkWell(
                  onTap: () => _bukaFormAlamat(existing: a),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.edit_outlined,
                          size: 15,
                          color: AppColors.primaryBlue,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Ubah',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () => _confirmDelete(a['id_address']),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 6,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.delete_outline,
                          size: 15,
                          color: AppColors.errorRed,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Hapus',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.errorRed,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
