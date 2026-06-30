import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_sizes.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/widgets/custom_scaffold.dart';
import '../../../../core/widgets/custom_search_field.dart';
import '../controllers/manajemen_staff_controller.dart';
import '../models/manajemen_staff_model.dart';
import 'manajemen_staff_form_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _controller = ManajemenStaffController(token: widget.token);
    _loadStaff();
    _searchController.addListener(_applySearch);
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
        _applySearch();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applySearch() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredStaff = _allStaff.where((s) {
        return s.nama.toLowerCase().contains(query) ||
            s.email.toLowerCase().contains(query);
      }).toList();
    });
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
    return CustomScaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: const CustomAppBar(
        title: 'Manajemen Karyawan',
        showBackButton: true,
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primary,
            padding: const EdgeInsets.fromLTRB(
              AppSizes.paddingMd,
              0,
              AppSizes.paddingMd,
              AppSizes.paddingMd,
            ),
            child: CustomSearchField(
              controller: _searchController,
              hintText: 'Cari staf...',
              onClear: () {
                _searchController.clear();
                _applySearch();
              },
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                ? Center(
                    child: Text(
                      _errorMessage!,
                      style: const TextStyle(color: Colors.red),
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
                          onTap: () => _goToForm(staff: _filteredStaff[index]),
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

// ─── Staff Card (Tanpa Status) ───────────────────────────────────────────────
class _StaffCard extends StatelessWidget {
  final ManajemenStaffModel staff;
  final VoidCallback onTap;

  const _StaffCard({required this.staff, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
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
                  Text(
                    staff.nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                      color: Color(0xFF1A1A2E),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    staff.email,
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}
