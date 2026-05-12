import 'package:flutter/material.dart';
import '../controller/manajemen_staff.controller.dart';
import '../models/manajemen_staff.model.dart';
import 'manajemen_staff_form.screen.dart';

class ManajemenStaffScreen extends StatefulWidget {
  const ManajemenStaffScreen({super.key});

  @override
  State<ManajemenStaffScreen> createState() => _ManajemenStaffScreenState();
}

class _ManajemenStaffScreenState extends State<ManajemenStaffScreen> {
  final ManajemenStaffController _controller = ManajemenStaffController();
  final TextEditingController _searchController = TextEditingController();

  List<ManajemenStaffModel> _allStaff = [];
  List<ManajemenStaffModel> _filteredStaff = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadStaff();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final staff = await _controller.getAllStaff();
      setState(() {
        _allStaff = staff;
        _filteredStaff = staff;
        _isLoading = false;
      });
    } catch (e) {
      setState(() { _errorMessage = e.toString(); _isLoading = false; });
    }
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStaff = _allStaff.where((s) =>
        s.nama.toLowerCase().contains(query) ||
        s.email.toLowerCase().contains(query)
      ).toList();
    });
  }

  Future<void> _deleteStaff(ManajemenStaffModel staff) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Staff'),
        content: Text('Yakin ingin menghapus ${staff.nama}?'),
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
      try {
        await _controller.deleteStaff(staff.id);
        _loadStaff();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Staff berhasil dihapus')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e')),
          );
        }
      }
    }
  }

  void _goToForm({ManajemenStaffModel? staff}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ManajemenStaffFormScreen(existingStaff: staff),
      ),
    );
    if (result == true) _loadStaff();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: const BackButton(color: Color(0xFF1A1A2E)),
        title: const Text(
          'Manajemen Karyawan',
          style: TextStyle(
            color: Color(0xFF1A1A2E),
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
      ),
      body: Column(
        children: [
          // Search bar
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        hintText: 'Cari staf...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Colors.grey, size: 20),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.tune, color: Colors.grey, size: 20),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _errorMessage != null
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(_errorMessage!,
                          style: const TextStyle(color: Colors.red)),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _loadStaff,
                          child: const Text('Coba Lagi'),
                        ),
                      ],
                    ),
                  )
                : _filteredStaff.isEmpty
                  ? const Center(child: Text('Tidak ada data staff'))
                  : RefreshIndicator(
                      onRefresh: _loadStaff,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredStaff.length,
                        itemBuilder: (context, index) {
                          return _StaffCard(
                            staff: _filteredStaff[index],
                            onEdit: () => _goToForm(staff: _filteredStaff[index]),
                            onDelete: () => _deleteStaff(_filteredStaff[index]),
                          );
                        },
                      ),
                    ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _goToForm(),
        backgroundColor: const Color(0xFF1A1A2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

// ─── Staff Card ────────────────────────────────────────────────────────────────

class _StaffCard extends StatelessWidget {
  final ManajemenStaffModel staff;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _StaffCard({
    required this.staff,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: () {
        showModalBottomSheet(
          context: context,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit Staff'),
                onTap: () { Navigator.pop(context); onEdit(); },
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Hapus Staff',
                  style: TextStyle(color: Colors.red)),
                onTap: () { Navigator.pop(context); onDelete(); },
              ),
            ],
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: const Color(0xFFEEF2FF),
              child: Text(
                staff.nama.isNotEmpty ? staff.nama[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Color(0xFF1A1A2E),
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(staff.nama,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF1A1A2E),
                          )),
                      ),
                      // Status badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: staff.statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          staff.statusLabel,
                          style: TextStyle(
                            color: staff.statusColor,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(staff.email,
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  const SizedBox(height: 8),

                  // Role chip
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: staff.role == StaffRole.WASHER
                        ? const Color(0xFFEEF2FF)
                        : const Color(0xFFE8F8F2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      staff.role.name,
                      style: TextStyle(
                        color: staff.role == StaffRole.WASHER
                          ? const Color(0xFF5C6BC0)
                          : const Color(0xFF27AE60),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}