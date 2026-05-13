import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  Map<String, dynamic>? _user;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await AuthService.login(email, password);

      if (result['success']) {
        _token = result['token'];
        _user = result['user'];
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
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
        _token = result['token'];
        _user = result['user'];
        _isLoading = false;
        notifyListeners();
        return true;
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

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void logout() {
    _token = null;
    _user = null;
    _errorMessage = null;
    notifyListeners();
  }
}

