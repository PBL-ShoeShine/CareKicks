import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/inventory_model.dart';

class InventorySummaryCard extends StatelessWidget {
  final InventorySummary? summary;

  const InventorySummaryCard({super.key, this.summary});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF34495E),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(32),
      child: Stack(
        children: [
          Positioned(
            right: -40,
            bottom: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ringkasan Stok',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Produk',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFA2B8D1),
                    ),
                  ),
                  Text(
                    '${summary?.totalJenis ?? 0} Jenis',
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Butuh Restock',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFFA2B8D1),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFDAD6),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      '${summary?.butuhRestock ?? 0} Item',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF93000A),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(height: 1, color: Colors.white.withOpacity(0.1)),
              const SizedBox(height: 24),
              // SizedBox(
              //   width: double.infinity,
              //   child: ElevatedButton(
              //     onPressed: () {},
              //     style: ElevatedButton.styleFrom(
              //       backgroundColor: const Color(0xFFD1E5F3),
              //       foregroundColor: const Color(0xFF374954),
              //       shape: RoundedRectangleBorder(
              //         borderRadius: BorderRadius.circular(16),
              //       ),
              //       padding: const EdgeInsets.symmetric(vertical: 12),
              //       elevation: 0,
              //     ),
              //     child: Text(
              //       'Laporan Inventaris',
              //       style: GoogleFonts.inter(
              //         fontSize: 14,
              //         fontWeight: FontWeight.w600,
              //       ),
              //     ),
              //   ),
              // ),
            ],
          ),
        ],
      ),
    );
  }
}
