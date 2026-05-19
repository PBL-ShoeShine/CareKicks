import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/inventory_model.dart';

class InventoryItemTile extends StatelessWidget {
  final InventoryItem item;
  final String token;
  final VoidCallback onUpdate;

  const InventoryItemTile({
    super.key,
    required this.item,
    required this.token,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    final bool isLowStock = item.stokSaatIni <= item.stokMinimum;
    final double progress = item.stokMinimum > 0 
        ? (item.stokSaatIni / item.stokMinimum).clamp(0.0, 1.0) 
        : 1.0;

    return Column(
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: item.fotoInven != null && item.fotoInven!.isNotEmpty
                          ? Image.network(item.fotoInven!, width: 24, height: 24, errorBuilder: (c, e, s) => _buildIcon())
                          : _buildIcon(),
                    ),
                  ),
                  const SizedBox(width: 16),
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
                            color: const Color(0xFF34495E),
                          ),
                        ),
                        Text(
                          'Kategori: ${item.kategori ?? "-"}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: const Color(0xFF43474C),
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
                if (isLowStock)
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFDAD6),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Text(
                          'HAMPIR\nHABIS',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: const Color(0xFFBA1A1A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${item.stokSaatIni.toInt()}\n${item.satuan ?? ""}',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF34495E),
                        ),
                      ),
                    ],
                  )
                else
                  Text(
                    '${item.stokSaatIni.toInt()}${item.satuan ?? ""}',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF34495E),
                    ),
                  ),
                Text(
                  'Minimum: ${item.stokMinimum.toInt()} ${item.satuan ?? ""}',
                  textAlign: TextAlign.right,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF43474C),
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: const Color(0xFFE1E3E3),
            valueColor: AlwaysStoppedAnimation<Color>(
              isLowStock ? const Color(0xFFBA1A1A) : const Color(0xFFD1E5F3),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon() {
    IconData iconData = Icons.inventory_2_outlined;
    if (item.kategori?.toLowerCase().contains('cairan') ?? false) {
      iconData = Icons.opacity;
    } else if (item.kategori?.toLowerCase().contains('alat') ?? false) {
      iconData = Icons.brush;
    }
    return Icon(iconData, color: const Color(0xFF34495E), size: 20);
  }
}
