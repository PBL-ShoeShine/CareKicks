import 'package:carekicks/core/widgets/custom_scaffold.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/custom_appbar.dart';

class OrdersPage extends StatelessWidget {
  final String token;
  final Map<String, dynamic> user;

  const OrdersPage({super.key, required this.token, required this.user});

  @override
  Widget build(BuildContext context) {
    return CustomScaffold(
      backgroundColor: const Color(0xFFF7F8FA),
      appBar: const CustomAppBar(title: 'Antrean Pesanan'),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              'Menu Antrean belum tersedia',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey.shade600,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Fitur ini sedang dalam tahap pengembangan.',
              style: TextStyle(color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
     
