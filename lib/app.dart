import 'package:flutter/material.dart';
import 'features/auth/screens/splash_screen.dart';
import 'core/constants/app_colors.dart';
import '../features/admin/antrean/screens/antrean_screen.dart'; // tambah ini

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CareKicks',
      theme: ThemeData(
        scaffoldBackgroundColor: AppColors.primaryDark,
        primaryColor: AppColors.primaryBlue,
        fontFamily: 'Poppins',
      ),
      // GANTI home-nya sementara untuk testing:
      home: AntreanScreen(token: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpZCI6Miwicm9sZSI6InNob3BzX2FkbWluIiwiaWF0IjoxNzc4NDIwNjA0LCJleHAiOjE3NzkwMjU0MDR9.4y9cykPKhvbk1z2REyeP4OfryuPBQ7WY4i-DQejxXBM'),
    );
  }
}