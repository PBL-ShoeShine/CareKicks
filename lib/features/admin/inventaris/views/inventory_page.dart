import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/widgets/custom_scaffold.dart';
import '../controllers/inventory_controller.dart';
import '../models/inventory_model.dart';
import 'inventory_list_page.dart';
import 'add_item_page.dart';

class InventoryPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const InventoryPage({super.key, required this.token, required this.user});

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  late InventoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InventoryController();
    _controller.fetchInventory(widget.token);
    _controller.fetchSummary(widget.token);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: const CustomAppBar(title: 'Inventaris'),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoading && _controller.items.isEmpty) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.primaryBlue),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _controller.fetchInventory(widget.token);
              await _controller.fetchSummary(widget.token);
            },
            color: AppColors.primaryBlue,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Summary Card
                _buildSummaryCard(),
                const SizedBox(height: 20),
                // Section Header
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Daftar Bahan Baku',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => InventoryListPage(
                              token: widget.token,
                              user: widget.user,
                            ),
                          ),
                        ).then((_) {
                          _controller.fetchInventory(widget.token);
                          _controller.fetchSummary(widget.token);
                        });
                      },
                      child: const Text(
                        'Lihat Semua',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.primaryBlue,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Items List
                if (_controller.items.isEmpty)
                  _buildEmptyState()
                else
                  ..._controller.items
                      .take(5)
                      .map((item) => _buildItemCard(item)),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddItemPage(token: widget.token),
            ),
          ).then((_) {
            _controller.fetchInventory(widget.token);
            _controller.fetchSummary(widget.token);
          });
        },
        backgroundColor: AppColors.primaryDark,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final summary = _controller.summary;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryBlue,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ringkasan Stok',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.inventory_2_outlined,
                  label: 'Total Produk',
                  value: '${summary?.totalJenis ?? 0}',
                  color: AppColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryItem(
                  icon: Icons.warning_amber_rounded,
                  label: 'Butuh Restock',
                  value: '${summary?.butuhRestock ?? 0}',
                  color: AppColors.errorRed,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(InventoryItem item) {
    final bool isLowStock = item.stokSaatIni <= item.stokMinimum;
    final double progress = item.stokMinimum > 0
        ? (item.stokSaatIni / (item.stokMinimum * 2)).clamp(0.0, 1.0)
        : 1.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: isLowStock
                        ? AppColors.errorRed.withOpacity(0.1)
                        : AppColors.primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: item.fotoInven != null && item.fotoInven!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              item.fotoInven!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Icon(
                                _getIconForCategory(item.kategori),
                                color: isLowStock
                                    ? AppColors.errorRed
                                    : AppColors.primaryBlue,
                                size: 22,
                              ),
                            ),
                          )
                        : Icon(
                            _getIconForCategory(item.kategori),
                            color: isLowStock
                                ? AppColors.errorRed
                                : AppColors.primaryBlue,
                            size: 22,
                          ),
                  ),
                ),
                const SizedBox(width: 12),
                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.namaItem,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.kategori ?? '-',
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                // Stock Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isLowStock)
                          Container(
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.errorRed.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'LOW',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: AppColors.errorRed,
                              ),
                            ),
                          ),
                        Text(
                          '${item.stokSaatIni.toInt()} ${item.satuan ?? ""}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: isLowStock
                                ? AppColors.errorRed
                                : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Min: ${item.stokMinimum.toInt()} ${item.satuan ?? ""}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                backgroundColor: AppColors.border,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isLowStock ? AppColors.errorRed : AppColors.successGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 48),
        child: Column(
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              'Belum ada bahan baku',
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Tambahkan bahan baku pertama Anda',
              style: TextStyle(color: Colors.grey[400], fontSize: 13),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForCategory(String? kategori) {
    if (kategori == null) return Icons.inventory_2_outlined;
    final lower = kategori.toLowerCase();
    if (lower.contains('cairan') || lower.contains('kimia')) {
      return Icons.opacity;
    } else if (lower.contains('alat') || lower.contains('brush')) {
      return Icons.brush;
    } else if (lower.contains('kain') || lower.contains('lap')) {
      return Icons.dry_cleaning;
    }
    return Icons.inventory_2_outlined;
  }
}
