import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:carekicks/features/edit_profile/views/edit_profile_view.dart';
import 'package:carekicks/features/admin/pemindai/pemindai_view.dart';
import 'app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CareKicksApp());
}

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
      home: const EditProfileView(),
    );
  }
}
