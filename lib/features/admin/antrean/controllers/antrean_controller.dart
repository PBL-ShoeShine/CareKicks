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

  bool get _isStaff => _role == 'courier' || _role == 'washer' || _role == 'staff';

  String get _baseEndpoint => '${ApiService.baseUrl}/admin/antrean';

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $_token',
  };

  // ─── Fetch Antrean ───────────────────────────────────────────────────────

  Future<void> fetchAntrean(String tab, String metodeOrder) async {
    _isLoading = true;
    _errorMessage = null;
    _antreanList = [];
    notifyListeners();

    try {
      // Gunakan endpoint konfirmasi_pesanan jika di tab pesanan_masuk, pembayaran, atau pesanan_baru
      String endpoint = _baseEndpoint;
      if (!_isStaff && (tab == 'pesanan_masuk' || tab == 'pembayaran' || tab == 'pesanan_baru')) {
        endpoint = '${ApiService.baseUrl}/admin/konfirmasi_pesanan';
      }

      final uri = Uri.parse('$endpoint?tab=$tab&metode_order=$metodeOrder');
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

  // ─── Konfirmasi Actions ──────────────────────────────────────────────────

  Future<Map<String, dynamic>> processPayment({
    required int idOrders,
    required String action,
    String? reason,
  }) async {
    try {
      final response = await ApiService.confirmPayment(
        token: _token!,
        idOrders: idOrders,
        action: action,
        reason: reason,
      );
      return response ?? {'success': false, 'message': 'Gagal menghubungi server'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> processOrder({
    required int idOrders,
    required String action,
    String? reason,
  }) async {
    try {
      final response = await ApiService.confirmOrder(
        token: _token!,
        idOrders: idOrders,
        action: action,
        reason: reason,
      );
      return response ?? {'success': false, 'message': 'Gagal menghubungi server'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // ─── Update Status ───────────────────────────────────────────────────────

  Future<bool> updateStatus(
    int idOrder,
    String status, {
    String? keterangan,
  }) async {
    try {
      final uri = Uri.parse('$_baseEndpoint/$idOrder/status');
      final body = <String, dynamic>{'status': status};
      if (keterangan != null && keterangan.trim().isNotEmpty) {
        body['keterangan'] = keterangan.trim();
      }

      final response = await http.patch(
        uri,
        headers: _headers,
        body: jsonEncode(body),
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
