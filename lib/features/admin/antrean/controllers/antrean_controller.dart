import 'dart:convert';
import 'package:carekicks/core/network/api_service.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/antrean_model.dart';

class AntreanController extends ChangeNotifier {
  List<AntreanModel> _antreanList = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _token;
  String? _role;

  List<AntreanModel> get antreanList => _antreanList;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─── Setters ─────────────────────────────────────────────────────────────

  void setToken(String token) => _token = token;

  void setRole(String role) => _role = role;

  // ─── Helpers ─────────────────────────────────────────────────────────────

  bool get _isStaff => _role == 'courier' || _role == 'washer';

  String get _baseEndpoint =>
      _isStaff ? '${ApiService.baseUrl}/staff/antrean'
               : '${ApiService.baseUrl}/admin/antrean';

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token',
      };

  // ─── Fetch Antrean ───────────────────────────────────────────────────────

  Future<void> fetchAntrean(String status) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final uri = Uri.parse('$_baseEndpoint?status=$status');
      final response = await http.get(uri, headers: _headers);

      debugPrint('=== FETCH ANTREAN ===');
      debugPrint('ROLE   : $_role');
      debugPrint('URL    : $uri');
      debugPrint('STATUS : ${response.statusCode}');
      debugPrint('BODY   : ${response.body}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final List data = json['data'] ?? [];
        _antreanList = data.map((e) => AntreanModel.fromJson(e)).toList();
      } else {
        _errorMessage = 'Gagal mengambil data antrean';
      }
    } catch (e) {
      debugPrint('ERROR fetchAntrean: $e');
      _errorMessage = 'Tidak dapat terhubung ke server';
    }

    _isLoading = false;
    notifyListeners();
  }

  // ─── Update Status ───────────────────────────────────────────────────────

  Future<bool> updateStatus(int idOrder, String status) async {
    try {
      final uri = Uri.parse('$_baseEndpoint/$idOrder/status');
      final response = await http.patch(
        uri,
        headers: _headers,
        body: jsonEncode({'status': status}),
      );

      debugPrint('=== UPDATE STATUS ===');
      debugPrint('URL    : $uri');
      debugPrint('STATUS : ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('ERROR updateStatus: $e');
      return false;
    }
  }
}