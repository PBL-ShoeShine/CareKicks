import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controller/inventory_controller.dart';
import '../models/inventory_model.dart';
import 'widgets/inventory_list_item_card.dart';
import 'add_stock_bottom_sheet.dart';
import 'add_item_page.dart';

class InventoryListPage extends StatefulWidget {
  final String token;
  final Map<String, dynamic> user;

  const InventoryListPage({super.key, required this.token, required this.user});

  @override
  State<InventoryListPage> createState() => _InventoryListPageState();
}

class _InventoryListPageState extends State<InventoryListPage> {
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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: Colors.black.withOpacity(0.05),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF001F5B)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Stok & Inventaris Bahan',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: const Color(0xFF001F5B),
            letterSpacing: -0.45,
          ),
        ),
      ),
      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              16,
              80,
              16,
              100,
            ), // Spacing for header overlay
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Status Card
                    Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: const Color(0xFF001F5B),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ),
                        ],
                      ),
                      padding: const EdgeInsets.all(24),
                      child: Stack(
                        children: [
                          Positioned(
                            right: -48,
                            bottom: -48,
                            child: Container(
                              width: 192,
                              height: 192,
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Kondisi Saat Ini',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withOpacity(0.8),
                                  letterSpacing: 0.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Status Gudang: ${_controller.summary?.butuhRestock ?? 0} Item Menipis',
                                style: GoogleFonts.inter(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Icon(
                                    Icons.info_outline,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'Segera lakukan pemesanan ulang untuk bahan kimia pembersih.',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Daftar Bahan',
                            style: GoogleFonts.inter(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF000C2E),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        // ElevatedButton.icon(
                        //   onPressed: () {
                        //     // Show a picker or search to add stock
                        //   },
                        //   icon: const Icon(Icons.add, size: 16),
                        //   label: const Text('Tambah Stok'),
                        //   style: ElevatedButton.styleFrom(
                        //     backgroundColor: const Color(0xFF000C2E),
                        //     foregroundColor: Colors.white,
                        //     shape: RoundedRectangleBorder(
                        //       borderRadius: BorderRadius.circular(8),
                        //     ),
                        //     padding: const EdgeInsets.symmetric(
                        //       horizontal: 16,
                        //       vertical: 8,
                        //     ),
                        //     elevation: 0,
                        //   ),
                        // ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_controller.isLoading && _controller.items.isEmpty)
                      const Center(child: CircularProgressIndicator())
                    else
                      ..._controller.items.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: InventoryListItemCard(
                            item: item,
                            onTap: () {
                              _showAddStockBottomSheet(context, item);
                            },
                            onDelete: () {
                              _showDeleteConfirmation(context, item);
                            },
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: Container(
        margin: const EdgeInsets.only(bottom: 20, right: 10),
        child: FloatingActionButton(
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
          backgroundColor: const Color(0xFF001F5B),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add, color: Colors.white),
        ),
      ),
    );
  }

  void _showAddStockBottomSheet(BuildContext context, InventoryItem item) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) =>
          AddStockBottomSheet(item: item, token: widget.token),
    ).then((_) {
      _controller.fetchInventory(widget.token);
      _controller.fetchSummary(widget.token);
    });
  }

  void _showDeleteConfirmation(BuildContext context, InventoryItem item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Hapus Bahan',
          style: GoogleFonts.inter(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Apakah Anda yakin ingin menghapus ${item.namaItem} dari daftar bahan?',
          style: GoogleFonts.inter(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: GoogleFonts.inter(color: Colors.black)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              final success = await _controller.deleteItem(
                widget.token,
                item.idInventory,
              );
              if (mounted) {
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${item.namaItem} berhasil dihapus'),
                      backgroundColor: Colors.green,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        _controller.errorMessage ?? 'Gagal menghapus bahan',
                      ),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: Text(
              'Hapus',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
