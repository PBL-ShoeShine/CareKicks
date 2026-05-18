import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/widgets/custom_appbar.dart';
import '../../../../core/widgets/custom_scaffold.dart';
import '../controllers/inventory_controller.dart';
import 'inventory_list_page.dart';
import 'add_item_page.dart';
import '../widgets/inventory_summary_card.dart';
import '../widgets/inventory_item_tile.dart';

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
      backgroundColor: const Color(0xFFF8F9F9),

      body: ListenableBuilder(
        listenable: _controller,
        builder: (context, child) {
          if (_controller.isLoading && _controller.items.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

          return RefreshIndicator(
            onRefresh: () async {
              await _controller.fetchInventory(widget.token);
              await _controller.fetchSummary(widget.token);
            },
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ATELIER INVENTORY',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: const Color(0xFF4E616D),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manajemen Stok &\nInventaris Bahan',
                    style: GoogleFonts.manrope(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: const Color(0xFF34495E),
                    ),
                  ),
                  const SizedBox(height: 48),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F4),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Daftar Bahan\nBaku',
                              style: GoogleFonts.manrope(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF34495E),
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
                                );
                              },
                              child: Text(
                                'Lihat Semua',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  color: const Color(0xFF1980FF),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Pantau ketersediaan\nperlengkapan\npembersihan Anda.',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: const Color(0xFF43474C),
                          ),
                        ),
                        const SizedBox(height: 32),
                        ..._controller.items
                            .take(4)
                            .map(
                              (item) => Padding(
                                padding: const EdgeInsets.only(bottom: 32),
                                child: InventoryItemTile(
                                  item: item,
                                  token: widget.token,
                                  onUpdate: () {
                                    _controller.fetchInventory(widget.token);
                                    _controller.fetchSummary(widget.token);
                                  },
                                ),
                              ),
                            ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  InventorySummaryCard(summary: _controller.summary),
                  const SizedBox(height: 100), // Space for bottom fab or nav
                ],
              ),
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
        backgroundColor: const Color(0xFF34495E),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
