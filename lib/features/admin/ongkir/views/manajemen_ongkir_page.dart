import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_scaffold.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../controllers/ongkir_controller.dart';

class ManajemenOngkirPage extends StatefulWidget {
  final String token;

  const ManajemenOngkirPage({super.key, required this.token});

  @override
  State<ManajemenOngkirPage> createState() => _ManajemenOngkirPageState();
}

class _ManajemenOngkirPageState extends State<ManajemenOngkirPage> {
  late OngkirController _controller;

  final _jarakGratisCtrl = TextEditingController();
  final _tarifPerKmCtrl = TextEditingController();
  final _jarakMaksimalCtrl = TextEditingController();
  final _tarifLuarRadiusCtrl = TextEditingController();

  // ✅ formatter titik ribuan
  String _formatRupiah(int amount) {
    String result = amount.toString();
    String formatted = '';
    int count = 0;
    for (int i = result.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) formatted = '.$formatted';
      formatted = result[i] + formatted;
      count++;
    }
    return formatted;
  }

  @override
  void initState() {
    super.initState();
    _controller = OngkirController();
    _loadData();
  }

  Future<void> _loadData() async {
    await _controller.fetchOngkirSetting(widget.token);
    if (mounted) {
      _fillControllers();
    }
  }

  void _fillControllers() {
    _jarakGratisCtrl.text = _controller.jarakGratisKm.toString();
    _jarakMaksimalCtrl.text = _controller.jarakMaksimalKm.toString();
    // ✅ FIX: format titik ribuan untuk field tarif
    _tarifPerKmCtrl.text = _formatRupiah(_controller.tarifPerKm.toInt());
    _tarifLuarRadiusCtrl.text = _formatRupiah(
      _controller.tarifPerKmLuarRadius.toInt(),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _jarakGratisCtrl.dispose();
    _tarifPerKmCtrl.dispose();
    _jarakMaksimalCtrl.dispose();
    _tarifLuarRadiusCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    // ✅ FIX: hapus titik sebelum parse
    _controller.jarakGratisKm =
        double.tryParse(
          _jarakGratisCtrl.text.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0;
    _controller.tarifPerKm =
        double.tryParse(
          _tarifPerKmCtrl.text.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0;
    _controller.jarakMaksimalKm =
        double.tryParse(
          _jarakMaksimalCtrl.text.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0;
    _controller.tarifPerKmLuarRadius =
        double.tryParse(
          _tarifLuarRadiusCtrl.text.replaceAll('.', '').replaceAll(',', '.'),
        ) ??
        0;

    final success = await _controller.saveOngkirSetting(widget.token);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (_controller.successMessage ?? 'Berhasil disimpan')
              : (_controller.errorMessage ?? 'Gagal menyimpan'),
        ),
        backgroundColor: success ? AppColors.successGreen : AppColors.errorRed,
      ),
    );
  }

  Widget _buildField({
    required String label,
    required String suffix,
    required TextEditingController controller,
    required String helperText,
    bool isRupiah = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          // ✅ FIX: formatter titik ribuan untuk field rupiah
          inputFormatters: isRupiah
              ? [_ThousandSeparatorFormatter()]
              : [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(
            suffixText: suffix,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          helperText,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      appBar: const CustomAppBar(
        title: 'Manajemen Ongkir',
        showBackButton: true,
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, _) {
          if (_controller.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildField(
                  label: 'Jarak Gratis Ongkir',
                  suffix: 'km',
                  controller: _jarakGratisCtrl,
                  helperText:
                      'Pelanggan tidak dikenakan ongkir jika di bawah angka ini.',
                ),
                _buildField(
                  label: 'Tarif per KM',
                  suffix: 'Rp / km',
                  controller: _tarifPerKmCtrl,
                  helperText: 'Tarif setelah melewati jarak gratis.',
                  isRupiah: true, // ✅
                ),
                _buildField(
                  label: 'Jarak Maksimal Layanan',
                  suffix: 'km',
                  controller: _jarakMaksimalCtrl,
                  helperText: 'Batas radius normal layanan.',
                ),
                _buildField(
                  label: 'Tarif per KM di Luar Radius',
                  suffix: 'Rp / km',
                  controller: _tarifLuarRadiusCtrl,
                  helperText: 'Tarif tambahan untuk luar radius maksimal.',
                  isRupiah: true, // ✅
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _controller.isSaving ? null : _handleSave,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _controller.isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Simpan Pengaturan',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ✅ Custom formatter titik ribuan
class _ThousandSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.isEmpty) return newValue;

    // Hapus semua titik dulu
    final digits = newValue.text.replaceAll('.', '');

    // Hanya boleh angka
    if (!RegExp(r'^\d+$').hasMatch(digits)) return oldValue;

    // Format dengan titik ribuan
    String formatted = '';
    int count = 0;
    for (int i = digits.length - 1; i >= 0; i--) {
      if (count > 0 && count % 3 == 0) formatted = '.$formatted';
      formatted = digits[i] + formatted;
      count++;
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
