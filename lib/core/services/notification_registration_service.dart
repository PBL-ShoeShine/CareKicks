import 'dart:convert';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../network/api_service.dart';

class NotificationRegistrationService {
  static Future<void> registerForUser({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS || Platform.isMacOS)) {
      return;
    }

    if (user['jenis_role'] != 'customer') return;

    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp();
      }

      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission();

      final fcmToken = await messaging.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      await _sendTokenToBackend(token: token, fcmToken: fcmToken);

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        _sendTokenToBackend(token: token, fcmToken: newToken);
      });
    } catch (e) {
      debugPrint('Gagal register notifikasi: $e');
    }
  }

  static Future<void> _sendTokenToBackend({
    required String token,
    required String fcmToken,
  }) async {
    try {
      await http.post(
        Uri.parse('${ApiService.baseUrl}/customer/notifications/fcm-token'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'fcm_token': fcmToken,
          'platform': Platform.operatingSystem,
        }),
      );
    } catch (e) {
      debugPrint('Gagal kirim FCM token ke backend: $e');
    }
  }
}
