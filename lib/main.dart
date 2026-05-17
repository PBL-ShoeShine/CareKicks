import 'package:carekicks/features/auth/screens/splash_screen.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

void main() {
  // Pakai yang ini karena ada pengecekan binding-nya (lebih aman)
  WidgetsFlutterBinding.ensureInitialized();
  // Panggil class CareKicksApp karena tema dan konfigurasinya ada di situ
  runApp(const CareKicksApp());
}

// HAPUS atau comment baris yang di bawah ini:
// void main() => runApp(const CareKicksApp());

class CareKicksApp extends StatelessWidget {
  const CareKicksApp({super.key});

  @override
  Widget build(BuildContext context) {
    final base = ThemeData(useMaterial3: true);
    return MaterialApp(
      title: 'Care Kicks',
      debugShowCheckedModeBanner: false,
      theme: base.copyWith(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1FB6C1)),
        textTheme: GoogleFonts.interTextTheme(base.textTheme),
        scaffoldBackgroundColor: const Color(0xFFF7F8FA),
      ),
      home: SplashScreen(),
    );
  }
}
