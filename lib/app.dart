import 'package:flutter/material.dart';
import 'features/auth/screens/splash_screen.dart';
import 'core/constants/app_colors.dart';
// tambah ini

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
      home: const SplashScreen(),
    );
  }
}
