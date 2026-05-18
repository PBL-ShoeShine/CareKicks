import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/views/login_page.dart';
import '../navigation/app_navigator.dart';

class StoredAuthSession {
  final String token;
  final Map<String, dynamic> user;
  final int loginTime;

  const StoredAuthSession({
    required this.token,
    required this.user,
    required this.loginTime,
  });
}

class AuthSessionManager {
  static const String tokenKey = 'auth_token';
  static const String userKey = 'auth_user';
  static const String loginTimeKey = 'auth_login_time';
  static const Duration maxSessionAge = Duration(days: 7);

  static bool _isRedirecting = false;

  static Future<void> save({
    required String token,
    required Map<String, dynamic> user,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(tokenKey, token);
    await prefs.setString(userKey, jsonEncode(user));
    await prefs.setInt(loginTimeKey, DateTime.now().millisecondsSinceEpoch);
  }

  static Future<StoredAuthSession?> getValidSession() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString(tokenKey);
    final userJson = prefs.getString(userKey);
    final loginTime = prefs.getInt(loginTimeKey);

    if (token == null ||
        token.isEmpty ||
        userJson == null ||
        userJson.isEmpty ||
        loginTime == null) {
      return null;
    }

    final loggedInAt = DateTime.fromMillisecondsSinceEpoch(loginTime);
    if (DateTime.now().difference(loggedInAt) > maxSessionAge) {
      await clear();
      return null;
    }

    try {
      final decodedUser = jsonDecode(userJson);
      if (decodedUser is! Map) {
        await clear();
        return null;
      }

      return StoredAuthSession(
        token: token,
        user: Map<String, dynamic>.from(decodedUser),
        loginTime: loginTime,
      );
    } catch (_) {
      await clear();
      return null;
    }
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(tokenKey);
    await prefs.remove(userKey);
    await prefs.remove(loginTimeKey);
  }

  static bool isTokenExpiredResponse(Map<String, dynamic> response) {
    final errorCode = response['error_code']?.toString().toUpperCase();
    final message = response['message']?.toString().toLowerCase() ?? '';

    return errorCode == 'TOKEN_EXPIRED' || message.contains('token expired');
  }

  static Future<void> handleExpiredResponse(
    Map<String, dynamic> response,
  ) async {
    if (!isTokenExpiredResponse(response) || _isRedirecting) return;

    _isRedirecting = true;
    final navigator = appNavigatorKey.currentState;
    final context = appNavigatorKey.currentContext;
    final scaffoldMessenger = context == null
        ? null
        : ScaffoldMessenger.maybeOf(context);

    await clear();

    if (navigator != null && scaffoldMessenger != null) {
      scaffoldMessenger
        ..clearSnackBars()
        ..showSnackBar(
          const SnackBar(
            content: Text('Session telah habis, silakan login kembali'),
          ),
        );

      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
    }

    Future<void>.delayed(const Duration(seconds: 1), () {
      _isRedirecting = false;
    });
  }
}
