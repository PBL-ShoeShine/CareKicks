import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/widgets/custom_scaffold.dart';
import '../controllers/manajemen_staff_controller.dart';
import '../models/manajemen_staff_model.dart';

class ManajemenStaffFormScreen extends StatefulWidget {
  final String token;
  final ManajemenStaffModel? existingStaff;
  const ManajemenStaffFormScreen({
    super.key,
    required this.token,
    this.existingStaff,
  });

  @override
  State<ManajemenStaffFormScreen> createState() =>
      _ManajemenStaffFormScreenState();
}

class _ManajemenStaffFormScreenState extends State<ManajemenStaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late ManajemenStaffController _controller;

  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _noHpController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  StaffStatus _selectedStatus = StaffStatus.aktif;

  bool get _isEditMode => widget.existingStaff != null;

  @override
  void initState() {
    super.initState();
    _controller = ManajemenStaffController(token: widget.token);
    if (_isEditMode) {
      final s = widget.existingStaff!;
      _namaController.text = s.nama;
      _emailController.text = s.email;
      _noHpController.text = s.noHp;
      _selectedStatus = s.status;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isEditMode) {
        await _controller.updateStaff(widget.existingStaff!.id, {
          'nama': _namaController.text.trim(),
          'email': _emailController.text.trim(),
          'no_hp': _noHpController.text.trim(),
          'status': _selectedStatus.name.toUpperCase(),
        });
      } else {
        await _controller.createStaff(
          nama: _namaController.text.trim(),
          email: _emailController.text.trim(),
          noHp: _noHpController.text.trim(),
          password: _passwordController.text.trim(),
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _isEditMode
                  ? 'Data staff berhasil diperbarui'
                  : 'Akun staff berhasil dibuat',
            ),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
      }
    }
  }

  Future<void> _deleteStaff() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Staff'),
        content: Text('Yakin ingin menghapus ${widget.existingStaff!.nama}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() => _isLoading = true);
      try {
        await _controller.deleteStaff(widget.existingStaff!.id);
        if (mounted) {
          Navigator.pop(context, true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff berhasil dihapus')),
          );
        }
      } catch (e) {
        setState(() => _isLoading = false);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: Colors.white,
      appBar: CustomAppBar(
        title: _isEditMode ? 'Edit Karyawan' : 'Daftarkan Staf Baru',
        showBackButton: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              if (_isEditMode) ...[
                _label('Status Karyawan'),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF7F8FA),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFE0E0E0)),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<StaffStatus>(
                      value: _selectedStatus,
                      isExpanded: true,
                      items: const [
                        // ✅ FIX: hanya Aktif dan Cuti
                        DropdownMenuItem(
                          value: StaffStatus.aktif,
                          child: Text('Aktif'),
                        ),
                        DropdownMenuItem(
                          value: StaffStatus.cuti,
                          child: Text('Cuti'),
                        ),
                      ],
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedStatus = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
              _label('Nama Lengkap'),
              _buildField(
                controller: _namaController,
                hint: 'Contoh: Budi Santoso',
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 20),
              _label('Email'),
              _buildField(
                controller: _emailController,
                hint: 'budi@shoecare.pro',
                keyboardType: TextInputType.emailAddress,
                validator: (v) => (v == null || !v.contains('@'))
                    ? 'Format email tidak valid'
                    : null,
              ),
              const SizedBox(height: 20),
              _label('No. HP'),
              _buildField(
                controller: _noHpController,
                hint: '0812....',
                keyboardType: TextInputType.phone,
                maxLength: 13,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'No HP wajib diisi'
                    : null,
              ),
              const SizedBox(height: 20),
              if (!_isEditMode) ...[
                _label('Kata Sandi'),
                _buildField(
                  controller: _passwordController,
                  hint: 'Masukkan kata sandi',
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                      color: Colors.grey,
                    ),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Kata sandi wajib diisi'
                      : null,
                ),
                const SizedBox(height: 36),
              ],
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A1A2E),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          _isEditMode ? 'Simpan Perubahan' : 'Buat Akun Staf',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              if (_isEditMode) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: OutlinedButton(
                    onPressed: _isLoading ? null : _deleteStaff,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                    ),
                    child: const Text(
                      'Hapus Karyawan',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Color(0xFF1A1A2E),
      ),
    ),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      maxLength: maxLength,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
      ),
    );
  }
}
