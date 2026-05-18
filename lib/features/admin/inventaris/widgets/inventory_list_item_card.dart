import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/inventory_model.dart';

class InventoryListItemCard extends StatelessWidget {
  final InventoryItem item;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const InventoryListItemCard({
    super.key,
    required this.item,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLowStock = item.stokSaatIni <= item.stokMinimum;
    final bool isVeryLowStock = item.stokSaatIni <= (item.stokMinimum / 2);
    final double progress = item.stokMaksimum > 0 
        ? (item.stokSaatIni / item.stokMaksimum).clamp(0.0, 1.0) 
        : 0.0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFC5C6D1)),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: isLowStock ? const Color(0xFFFFDAD6).withOpacity(0.2) : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: item.fotoInven != null && item.fotoInven!.isNotEmpty
                              ? Image.network(item.fotoInven!, width: 18, height: 20, errorBuilder: (c, e, s) => _buildIcon())
                              : _buildIcon(),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.namaItem,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF191C1E),
                              ),
                            ),
                            Text(
                              item.kategori ?? "-",
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.inter(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.5,
                                color: const Color(0xFF5D5F5F),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${item.stokSaatIni.toInt()}${item.satuan ?? ""} / ${item.stokMaksimum.toInt()}${item.satuan ?? ""}',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isLowStock ? const Color(0xFFBA1A1A) : const Color(0xFF000C2E),
                      ),
                    ),
                    if (onDelete != null)
                      GestureDetector(
                        onTap: onDelete,
                        child: const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        ),
                      ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: Colors.blue,
                valueColor: AlwaysStoppedAnimation<Color>(
                  isLowStock ? const Color(0xFFBA1A1A) : Colors.blue.shade400,
                ),
              ),
            ),
            if (isVeryLowStock)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    const Icon(Icons.warning_amber_rounded, color: Color(0xFFBA1A1A), size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Stok sangat rendah',
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                        color: const Color(0xFFBA1A1A),
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

  Widget _buildIcon() {
    IconData iconData = Icons.inventory_2_outlined;
    if (item.kategori?.toLowerCase().contains('fluid') ?? false) {
      iconData = Icons.opacity;
    } else if (item.kategori?.toLowerCase().contains('wax') ?? false) {
      iconData = Icons.brush;
    } else if (item.kategori?.toLowerCase().contains('accessories') ?? false) {
      iconData = Icons.style;
    }
    return Icon(iconData, color: const Color(0xFF191C1E), size: 18);
  }
}
