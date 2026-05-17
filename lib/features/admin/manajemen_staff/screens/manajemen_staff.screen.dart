import 'package:flutter/material.dart';
import '../controller/manajemen_staff.controller.dart';
import '../models/manajemen_staff.model.dart';
import 'manajemen_staff_form.screen.dart';

class ManajemenStaffScreen extends StatefulWidget {
  final String token;
  const ManajemenStaffScreen({super.key, required this.token});

  @override
  State<ManajemenStaffScreen> createState() => _ManajemenStaffScreenState();
}

class _ManajemenStaffScreenState extends State<ManajemenStaffScreen> {
  late ManajemenStaffController _controller;
  final TextEditingController _searchController = TextEditingController();

  List<ManajemenStaffModel> _allStaff = [];
  List<ManajemenStaffModel> _filteredStaff = [];
  bool _isLoading = true;
  String? _errorMessage;

  // State untuk filter
  List<StaffRole> _activeFilterRoles = [];

  @override
  void initState() {
    super.initState();
    _controller = ManajemenStaffController(token: widget.token);
    _loadStaff();
    _searchController.addListener(_applySearchAndFilter);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadStaff() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final staff = await _controller.getAllStaff();
      setState(() {
        _allStaff = staff;
        _applySearchAndFilter(); // Terapkan filter saat data masuk
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applySearchAndFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStaff = _allStaff.where((s) {
        // 1. Pencarian berdasarkan nama, email ATAU role
        final matchSearch =
            s.nama.toLowerCase().contains(query) ||
            s.email.toLowerCase().contains(query) ||
            s.roles.any((r) => r.name.toLowerCase().contains(query));

        // 2. Pencarian berdasarkan filter role (Bottom Sheet)
        final matchFilter =
            _activeFilterRoles.isEmpty ||
            s.roles.any((r) => _activeFilterRoles.contains(r));

        return matchSearch && matchFilter;
      }).toList();
    });
  }

  void _showFilterBottomSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Berdasarkan Role',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  CheckboxListTile(
                    title: const Text('Washer'),
                    value: _activeFilterRoles.contains(StaffRole.WASHER),
                    activeColor: const Color(0xFF1A1A2E),
                    onChanged: (bool? value) {
                      setModalState(() {
                        if (value == true) {
                          _activeFilterRoles.add(StaffRole.WASHER);
                        } else {
                          _activeFilterRoles.remove(StaffRole.WASHER);
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: const Text('Courier'),
                    value: _activeFilterRoles.contains(StaffRole.COURIER),
                    activeColor: const Color(0xFF1A1A2E),
                    onChanged: (bool? value) {
                      setModalState(() {
                        if (value == true) {
                          _activeFilterRoles.add(StaffRole.COURIER);
                        } else {
                          _activeFilterRoles.remove(StaffRole.COURIER);
                        }
                      });
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A1A2E),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () {
                        _applySearchAndFilter();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Terapkan Filter',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _goToForm({ManajemenStaffModel? staff}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ManajemenStaffFormScreen(token: widget.token, existingStaff: staff),
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
                        hintText: 'Cari staf atau role...',
                        hintStyle: TextStyle(color: Colors.grey, fontSize: 14),
                        prefixIcon: Icon(
                          Icons.search,
                          color: Colors.grey,
                          size: 20,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  onTap: _showFilterBottomSheet,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _activeFilterRoles.isNotEmpty
                          ? const Color(0xFF1A1A2E)
                          : const Color(0xFFF0F0F0),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.tune,
                      color: _activeFilterRoles.isNotEmpty
                          ? Colors.white
                          : Colors.grey,
                      size: 20,
                    ),
                  ),
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
                        Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.red),
                        ),
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
                          onTap: () => _goToForm(
                            staff: _filteredStaff[index],
                          ), // Klik langsung ke form edit
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
  final VoidCallback onTap;

  const _StaffCard({required this.staff, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap, // Opsi 2: Klik masuk ke halaman edit
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
            ),
          ],
        ),
        child: Row(
          children: [
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
                        child: Text(
                          staff.nama,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                            color: Color(0xFF1A1A2E),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
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
                  Text(
                    staff.email,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  const SizedBox(height: 8),

                  // Menampilkan Multi-Role di Card
                  Wrap(
                    spacing: 6,
                    children: staff.roles.map((role) {
                      bool isWasher = role == StaffRole.WASHER;
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isWasher
                              ? const Color(0xFFEEF2FF)
                              : const Color(0xFFE8F8F2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          role.name,
                          style: TextStyle(
                            color: isWasher
                                ? const Color(0xFF5C6BC0)
                                : const Color(0xFF27AE60),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(
              Icons.chevron_right,
              color: Colors.grey,
            ), // Indikator bisa diklik
          ],
        ),
      ),
    );
  }
}
