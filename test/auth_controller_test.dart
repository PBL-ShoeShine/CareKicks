import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:carekicks/features/auth/controllers/auth_controller.dart';
import 'package:carekicks/core/auth/session_manager.dart';

void main() {
  group('AuthController - Suspended Shop Tests', () {
    late AuthController authController;

    setUp(() {
      authController = AuthController();
    });

    tearDown(() {
      authController.dispose();
    });

    test('checkLoginStatus returns false and sets suspendedShop if status_verifikasi is suspended', () async {
      final userMap = {
        'id_user': 123,
        'email': 'shop_owner@mail.com',
        'jenis_role': 'shops_admin',
        'shop': {
          'id_shops': 456,
          'nm_toko': 'Suspended Shoe Care',
          'status_verifikasi': 'suspended',
          'alasan_penangguhan': 'Melanggar aturan platform.'
        }
      };

      SharedPreferences.setMockInitialValues({
        AuthSessionManager.tokenKey: 'mock-jwt-token',
        AuthSessionManager.userKey: jsonEncode(userMap),
        AuthSessionManager.loginTimeKey: DateTime.now().millisecondsSinceEpoch,
      });

      final result = await authController.checkLoginStatus();

      expect(result, isFalse);
      expect(authController.token, equals('mock-jwt-token'));
      expect(authController.suspendedShop, isNotNull);
      expect(authController.suspendedShop?['nm_toko'], equals('Suspended Shoe Care'));
      expect(authController.suspendedShop?['status_verifikasi'], equals('suspended'));
      expect(authController.errorMessage, equals('Toko Anda ditangguhkan'));
    });

    test('checkLoginStatus returns true and clear suspendedShop if status_verifikasi is approved', () async {
      final userMap = {
        'id_user': 123,
        'email': 'shop_owner@mail.com',
        'jenis_role': 'shops_admin',
        'shop': {
          'id_shops': 456,
          'nm_toko': 'Approved Shoe Care',
          'status_verifikasi': 'approved',
        }
      };

      SharedPreferences.setMockInitialValues({
        AuthSessionManager.tokenKey: 'mock-jwt-token',
        AuthSessionManager.userKey: jsonEncode(userMap),
        AuthSessionManager.loginTimeKey: DateTime.now().millisecondsSinceEpoch,
      });

      final result = await authController.checkLoginStatus();

      expect(result, isTrue);
      expect(authController.token, equals('mock-jwt-token'));
      expect(authController.suspendedShop, isNull);
      expect(authController.errorMessage, isNull);
    });
    test('checkLoginStatus returns false and sets suspendedShop if staff role associated shop status_verifikasi is suspended', () async {
      final userMap = {
        'id_user': 124,
        'email': 'staff_member@mail.com',
        'jenis_role': 'staff',
        'shop': {
          'id_shops': 456,
          'nm_toko': 'Suspended Shoe Care',
          'status_verifikasi': 'suspended',
          'alasan_penangguhan': 'Melanggar aturan platform.'
        }
      };

      SharedPreferences.setMockInitialValues({
        AuthSessionManager.tokenKey: 'mock-jwt-token',
        AuthSessionManager.userKey: jsonEncode(userMap),
        AuthSessionManager.loginTimeKey: DateTime.now().millisecondsSinceEpoch,
      });

      final result = await authController.checkLoginStatus();

      expect(result, isFalse);
      expect(authController.suspendedShop, isNotNull);
      expect(authController.suspendedShop?['status_verifikasi'], equals('suspended'));
      expect(authController.errorMessage, equals('Toko Anda ditangguhkan'));
    });
  });
}
