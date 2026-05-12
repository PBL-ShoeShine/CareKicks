import 'package:flutter/material.dart';
import '../controller/manajemen_staff.controller.dart';
import '../models/manajemen_staff.model.dart';

class ManajemenStaffFormScreen extends StatefulWidget {
  final ManajemenStaffModel? existingStaff;
  const ManajemenStaffFormScreen({super.key, this.existingStaff});

  @override
  State<ManajemenStaffFormScreen> createState() =>
      _ManajemenStaffFormScreenState();
}

class _ManajemenStaffFormScreenState extends State<ManajemenStaffFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final ManajemenStaffController _controller = ManajemenStaffController();

  final _namaController    = TextEditingController();
  final _emailController   = TextEditingController();
  final _noHpController    = TextEditingController();
  final _idShopsController = TextEditingController();

  bool _isLoading = false;
  StaffRole _selectedRole = StaffRole.WASHER;

  bool get _isEditMode => widget.existingStaff != null;

  @override
  void initState() {
    super.initState();
    if (_isEditMode) {
      final s = widget.existingStaff!;
      _namaController.text    = s.nama;
      _emailController.text   = s.email;
      _noHpController.text    = s.noHp;
      _idShopsController.text = s.idShops;
      _selectedRole           = s.role;
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _noHpController.dispose();
    _idShopsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      if (_isEditMode) {
        await _controller.updateStaff(widget.existingStaff!.id, {
          'nama':     _namaController.text.trim(),
          'email':    _emailController.text.trim(),
          'no_hp':    _noHpController.text.trim(),
          'id_shops': int.tryParse(_idShopsController.text.trim()),
          'role':     _selectedRole.name,
        });
      } else {
        await _controller.createStaff(
          nama:    _namaController.text.trim(),
          email:   _emailController.text.trim(),
          noHp:    _noHpController.text.trim(),
          idShops: _idShopsController.text.trim(),
          role:    _selectedRole,
        );
      }

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_isEditMode
              ? 'Data staff berhasil diperbarui'
              : 'Akun staff berhasil dibuat'),
          ),
        );
      }
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _isEditMode
        ? AppBar(
            backgroundColor: Colors.white,
            elevation: 0,
            leading: const BackButton(color: Color(0xFF1A1A2E)),
            title: const Text('Edit Karyawan',
              style: TextStyle(
                color: Color(0xFF1A1A2E),
                fontWeight: FontWeight.w600,
              )),
          )
        : null,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (mode tambah)
                if (!_isEditMode) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Center(
                    child: Text('Daftarkan Staf Baru',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1A1A2E),
                      )),
                  ),
                  const SizedBox(height: 6),
                  const Center(
                    child: Text(
                      'Lengkapi data untuk akses sistem manajemen.',
                      style: TextStyle(color: Colors.grey, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 32),
                ] else
                  const SizedBox(height: 16),

                // Nama
                _label('Nama Lengkap'),
                _buildField(
                  controller: _namaController,
                  hint: 'Contoh: Budi Santoso',
                  validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama wajib diisi' : null,
                ),
                const SizedBox(height: 20),

                // Email
                _label('Email'),
                _buildField(
                  controller: _emailController,
                  hint: 'budi@shoecare.pro',
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                    if (!v.contains('@')) return 'Format email tidak valid';
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // No HP
                _label('No. HP'),
                _buildField(
                  controller: _noHpController,
                  hint: '08xxxxxxxxxx',
                  keyboardType: TextInputType.phone,
                  validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'No HP wajib diisi' : null,
                ),
                const SizedBox(height: 20),

                // ID Shops
                _label('ID Toko'),
                _buildField(
                  controller: _idShopsController,
                  hint: 'Contoh: 1',
                  keyboardType: TextInputType.number,
                  validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'ID Toko wajib diisi' : null,
                ),
                const SizedBox(height: 24),

                // Role
                _label('Pilih Role Staf'),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _RoleButton(
                        role: StaffRole.WASHER,
                        isSelected: _selectedRole == StaffRole.WASHER,
                        onTap: () => setState(() => _selectedRole = StaffRole.WASHER),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _RoleButton(
                        role: StaffRole.COURIER,
                        isSelected: _selectedRole == StaffRole.COURIER,
                        onTap: () => setState(() => _selectedRole = StaffRole.COURIER),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 36),

                // Tombol submit
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
                      elevation: 0,
                    ),
                    child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isEditMode ? 'Simpan Perubahan' : 'Buat Akun Staf',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.person_add_outlined,
                              color: Colors.white, size: 18),
                          ],
                        ),
                  ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: Color(0xFF1A1A2E),
      )),
  );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF1A1A2E), width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}

// ─── Role Button ───────────────────────────────────────────────────────────────

class _RoleButton extends StatelessWidget {
  final StaffRole role;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleButton({
    required this.role,
    required this.isSelected,
    required this.onTap,
  });

  Color get _color => role == StaffRole.WASHER
    ? const Color(0xFF5C6BC0)
    : const Color(0xFF27AE60);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: isSelected ? _color.withOpacity(0.08) : const Color(0xFFF7F8FA),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? _color : const Color(0xFFE0E0E0),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              role == StaffRole.WASHER
                ? Icons.local_laundry_service_outlined
                : Icons.local_shipping_outlined,
              color: isSelected ? _color : Colors.grey,
              size: 28,
            ),
            const SizedBox(height: 8),
            Text(
              role.name,
              style: TextStyle(
                color: isSelected ? _color : Colors.grey,
                fontWeight: FontWeight.w700,
                fontSize: 13,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}