import 'package:flutter/material.dart';

import 'core/navigation/app_navigator.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/views/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const CareKicksApp());
}

class CareKicksApp extends StatelessWidget {
  const CareKicksApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      title: 'Care Kicks',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}

class MyApp extends CareKicksApp {
  const MyApp({super.key});
}
