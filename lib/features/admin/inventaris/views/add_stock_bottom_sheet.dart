import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/inventory_controller.dart';
import '../models/inventory_model.dart';

class AddStockBottomSheet extends StatefulWidget {
  final InventoryItem item;
  final String token;

  const AddStockBottomSheet({
    super.key,
    required this.item,
    required this.token,
  });

  @override
  State<AddStockBottomSheet> createState() => _AddStockBottomSheetState();
}

class _AddStockBottomSheetState extends State<AddStockBottomSheet> {
  final TextEditingController _amountController = TextEditingController(
    text: '0',
  );
  late InventoryController _controller;

  @override
  void initState() {
    super.initState();
    _controller = InventoryController();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tambah Stok Bahan',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0D2137),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          image:
                              widget.item.fotoInven != null &&
                                  widget.item.fotoInven!.isNotEmpty
                              ? DecorationImage(
                                  image: NetworkImage(widget.item.fotoInven!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child:
                            widget.item.fotoInven == null ||
                                widget.item.fotoInven!.isEmpty
                            ? const Icon(
                                Icons.inventory_2_outlined,
                                color: Color(0xFF5D5F5F),
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BAHAN BAKU',
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.55,
                                color: const Color(0xFF5D5F5F),
                              ),
                            ),
                            Text(
                              widget.item.namaItem,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF000C2E),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Jumlah Tambahan',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.blue,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.blue,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: TextField(
                    controller: _amountController,
                    keyboardType: TextInputType.number,
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: InputDecoration(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 18,
                        vertical: 14,
                      ),
                      border: InputBorder.none,
                      suffixIcon: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              widget.item.satuan ?? 'unit',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF5D5F5F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                // const SizedBox(height: 20),
                // Text(
                //   'Pemasok',
                //   style: GoogleFonts.inter(
                //     fontSize: 14,
                //     fontWeight: FontWeight.w600,
                //     color: Colors.blue,
                //   ),
                // ),
                // const SizedBox(height: 8),
                // Container(
                //   padding: const EdgeInsets.symmetric(
                //     horizontal: 16,
                //     vertical: 14,
                //   ),
                //   decoration: BoxDecoration(
                //     color: Colors.blue,
                //     borderRadius: BorderRadius.circular(12),
                //   ),
                //   child: Row(
                //     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                //     children: [
                //       Text(
                //         'Pilih Pemasok',
                //         style: GoogleFonts.inter(
                //           fontSize: 16,
                //           color: const Color(0xFF000C2E),
                //         ),
                //       ),
                //       const Icon(
                //         Icons.keyboard_arrow_down,
                //         color: Color(0xFF000C2E),
                //       ),
                //     ],
                //   ),
                // ),
                const SizedBox(height: 32),
                ListenableBuilder(
                  listenable: _controller,
                  builder: (context, child) {
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _controller.isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF000C2E),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 0,
                        ),
                        child: _controller.isLoading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : Text(
                                'Konfirmasi Stok',
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _submit() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus lebih dari 0')),
      );
      return;
    }

    final success = await _controller.addStock(
      token: widget.token,
      id: widget.item.idInventory,
      amount: amount,
    );

    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Stok berhasil ditambahkan')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_controller.errorMessage ?? 'Gagal menambah stok'),
        ),
      );
    }
  }
}
