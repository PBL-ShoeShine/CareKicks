import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/antrean_model.dart';

class AntreanController extends ChangeNotifier {
  // Ganti dengan IP komputer kamu:
  // Emulator Android  → 10.0.2.2
  // HP fisik (WiFi)   → IP lokal komputer, misal 192.168.1.5
  static const String _baseUrl = 'http://192.168.110.217:3000/api/v1';

  List<AntreanModel> _antreanList = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;

  List<AntreanModel> get antreanList => _antreanList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  void setToken(String token) {
    _token = token;
  }

  Future<void> fetchAntrean(String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/admin/antrean?status=$status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        _antreanList = data.map((e) => AntreanModel.fromJson(e)).toList();
      } else {
        _errorMessage = 'Gagal mengambil data antrean';
      }
    } catch (e) {
      _errorMessage = 'Tidak dapat terhubung ke server';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> updateStatus(int idOrder, String status) async {
    try {
      final response = await http.patch(
        Uri.parse('$_baseUrl/admin/antrean/$idOrder/status'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'status': status}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}