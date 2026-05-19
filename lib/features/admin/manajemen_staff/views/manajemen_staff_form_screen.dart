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

  List<StaffRole> _selectedRoles = [StaffRole.WASHER];
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
      _selectedRoles = List.from(s.roles);
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

  void _toggleRole(StaffRole role) {
    setState(() {
      if (_selectedRoles.contains(role)) {
        if (_selectedRoles.length > 1) {
          _selectedRoles.remove(role);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Karyawan minimal harus memiliki 1 peran (role)'),
            ),
          );
        }
      } else {
        _selectedRoles.add(role);
      }
    });
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
          // ID Toko tidak perlu di-update karena sudah otomatis
          'role': _selectedRoles.map((e) => e.name).toList(),
          'status': _selectedStatus.name.toUpperCase(),
        });
      } else {
        await _controller.createStaff(
          nama: _namaController.text.trim(),
          email: _emailController.text.trim(),
          noHp: _noHpController.text.trim(),
          roles: _selectedRoles,
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
              if (!_isEditMode) ...[
                // Garis abu-abu di atas dihilangkan karena sekarang pakai AppBar normal
                const SizedBox(height: 32),
              ] else
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
                        DropdownMenuItem(
                          value: StaffStatus.aktif,
                          child: Text('Aktif'),
                        ),
                        DropdownMenuItem(
                          value: StaffStatus.cuti,
                          child: Text('Cuti'),
                        ),
                        DropdownMenuItem(
                          value: StaffStatus.sedang_tugas,
                          child: Text('Sedang Tugas'),
                        ),
                        DropdownMenuItem(
                          value: StaffStatus.non_aktif,
                          child: Text('Non Aktif / Resign'),
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
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Email wajib diisi';
                  if (!v.contains('@')) return 'Format email tidak valid';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              _label('No. HP'),
              _buildField(
                controller: _noHpController,
                hint: '08xxxxxxxxxx',
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'No HP wajib diisi'
                    : null,
              ),
              const SizedBox(height: 20),

              // Form input ID Toko sudah dihapus dari sini
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
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Kata sandi wajib diisi'
                      : null,
                ),
                const SizedBox(height: 24),
              ],

              _label('Pilih Role Staf (Bisa Pilih Lebih Dari Satu)'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _RoleButton(
                      role: StaffRole.WASHER,
                      isSelected: _selectedRoles.contains(StaffRole.WASHER),
                      onTap: () => _toggleRole(StaffRole.WASHER),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _RoleButton(
                      role: StaffRole.COURIER,
                      isSelected: _selectedRoles.contains(StaffRole.COURIER),
                      onTap: () => _toggleRole(StaffRole.COURIER),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 36),

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
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _isEditMode
                                  ? 'Simpan Perubahan'
                                  : 'Buat Akun Staf',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Icon(
                              _isEditMode
                                  ? Icons.save
                                  : Icons.person_add_outlined,
                              color: Colors.white,
                              size: 18,
                            ),
                          ],
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Hapus Karyawan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.delete_outline, size: 18),
                      ],
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
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      validator: validator,
      style: const TextStyle(fontSize: 14, color: Color(0xFF1A1A2E)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Colors.grey, fontSize: 14),
        filled: true,
        fillColor: const Color(0xFFF7F8FA),
        suffixIcon: suffixIcon,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
    );
  }
}

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
          color: isSelected
              ? _color.withOpacity(0.08)
              : const Color(0xFFF7F8FA),
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
