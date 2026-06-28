import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/auth/session_manager.dart';
import '../services/auth_service.dart';
import '../../../core/network/api_service.dart';

class AuthController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  Map<String, dynamic>? _user;
  Map<String, dynamic>? _suspendedShop;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;
  Map<String, dynamic>? get suspendedShop => _suspendedShop;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthService.login(email, password);

      if (result['success']) {
        _token = result['token'];
        _user = Map<String, dynamic>.from(result['user'] ?? {});
        _suspendedShop = null;
        final role = _user?['jenis_role'];
        if (role == 'customer' || role == 'shops_admin' || role == 'staff') {
          await saveSession();
        }
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        if (result['code'] == 'SHOP_SUSPENDED') {
          _token = result['token'];
          _user = Map<String, dynamic>.from(result['user'] ?? {});
          _suspendedShop = Map<String, dynamic>.from(result['data'] ?? {});
          await saveSession();
          _isLoading = false;
          _errorMessage = 'Toko Anda ditangguhkan';
          notifyListeners();
          return false;
        }
        _errorMessage = result['message'] ?? 'Login gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    required String nama,
    required String noHp,
    required String email,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthService.register(
        nama: nama,
        noHp: noHp,
        email: email,
        password: password,
      );

      if (result['success']) {
        if (result['message'] == 'OTP_SENT') {
          _isLoading = false;
          notifyListeners();
          return true; // Sukses memicu kirim OTP ke email
        }
        return false;
      } else {
        _errorMessage = result['message'] ?? 'Register gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // --- FUNGSI BARU UNTUK VERIFIKASI OTP PENDAFTARAN ---
  Future<bool> verifyRegisterOtp(String email, String otpCode) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthService.verifyRegisterOtp(email, otpCode);
      if (result['success']) {
        _token = result['token'];
        _user = Map<String, dynamic>.from(result['user'] ?? {});
        await saveSession(); // Simpan sesi login resmi setelah OTP sukses
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = result['message'] ?? 'Verifikasi OTP gagal';
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(AuthSessionManager.tokenKey);
    final savedUserStr = prefs.getString(AuthSessionManager.userKey);

    // PERBAIKAN: Mengubah savedStr menjadi savedUserStr agar sesuai deklarasi
    if (savedToken != null && savedToken.isNotEmpty && savedUserStr != null) {
      _token = savedToken;
      _user = jsonDecode(savedUserStr);
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> resendRegisterOtp(String email) async {
    _isLoading = true;
    notifyListeners();
    final result = await AuthService.resendRegisterOtp(email);
    if (result['success'] == false) {
      _errorMessage = result['message'];
    }
    _isLoading = false;
    notifyListeners();
    return result['success'] ?? false;
  }

  Future<bool> checkSuspendedStatus() async {
    final token = _token;
    if (token == null || token.isEmpty) return false;

    try {
      final response = await ApiService.getProfile(token: token, role: 'admin');
      if (response == null) return false;

      final shopData =
          response['data']?['shopAdmin']?['shops'] ??
          response['data']?['staff']?['staff_profile']?['shops'];

      if (shopData != null) {
        final status = shopData['status_verifikasi']?.toString().toLowerCase();
        if (status == 'suspended') {
          _suspendedShop = Map<String, dynamic>.from(shopData);
          _errorMessage = 'Toko Anda ditangguhkan';
          notifyListeners();
          return false;
        }
      }

      _suspendedShop = null;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (_) {
      await logout();
      return false;
    }
  }

  void updateField(String key, dynamic value) {
    if (_user != null) {
      _user = Map<String, dynamic>.from(_user!);
      _user![key] = value;
      saveSession();
      notifyListeners();
    }
  }

  Future<void> saveSession() async {
    final token = _token;
    final user = _user;

    if (token == null || token.isEmpty || user == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AuthSessionManager.tokenKey, token);
    await prefs.setString(AuthSessionManager.userKey, jsonEncode(user));
    await prefs.setInt(
      AuthSessionManager.loginTimeKey,
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(AuthSessionManager.tokenKey);
    await prefs.remove(AuthSessionManager.userKey);
    await prefs.remove(AuthSessionManager.loginTimeKey);
  }

  Future<void> logout() async {
    await clearSession();
    _token = null;
    _user = null;
    _suspendedShop = null;
    _errorMessage = null;
    notifyListeners();
  }
}
