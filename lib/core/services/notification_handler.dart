import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import '../navigation/app_navigator.dart';

class NotificationHandler {
  static Future<void> initialize() async {
    // Meminta izin untuk iOS/Android
    FirebaseMessaging messaging = FirebaseMessaging.instance;
    await messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Foreground listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('Menerima notifikasi di foreground: ${message.notification?.title}');
      
      if (message.notification != null) {
        _showForegroundAlert(message);
      }
    });

    // Background/Terminated listener (saat notifikasi di-klik)
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Notifikasi di-klik: ${message.notification?.title}');
    });
  }

  static void _showForegroundAlert(RemoteMessage message) {
    final context = appNavigatorKey.currentContext;
    if (context != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                message.notification?.title ?? 'Notifikasi Baru',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              Text(message.notification?.body ?? ''),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'LIHAT',
            onPressed: () {
              // Bisa tambahkan navigasi ke riwayat pesanan jika perlu
            },
          ),
        ),
      );
    }
  }
}

// Background message handler (harus di luar class dan static)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  debugPrint("Handling a background message: ${message.messageId}");
}
