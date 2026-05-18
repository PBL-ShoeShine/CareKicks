import 'package:flutter/material.dart';
import 'core/navigation/app_navigator.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/views/splash_screen.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'CareKicks',
      theme: AppTheme.lightTheme,
      home: const SplashScreen(),
    );
  }
}
