import 'package:flutter/material.dart';
import '../services/detail_layanan_service.dart';

class DetailLayananController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _serviceData;
  List<dynamic> _reviews = [];
  bool _isLoadingReviews = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get serviceData => _serviceData;
  List<dynamic> get reviews => _reviews;
  bool get isLoadingReviews => _isLoadingReviews;

  Future<void> fetchDetail({required String token, required int serviceId}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await DetailLayananService.getDetailLayanan(
        token: token,
        serviceId: serviceId,
      );

      if (result['success']) {
        _serviceData = result['data'];
        
        // Setelah dapat detail, ambil review spesifik untuk layanan ini
        _fetchReviews(serviceId);
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengambil detail layanan';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchReviews(int serviceId) async {
    _isLoadingReviews = true;
    notifyListeners();

    try {
      final result = await DetailLayananService.getReviews(serviceId: serviceId);
      if (result['success']) {
        _reviews = result['data'] ?? [];
      }
    } catch (e) {
      debugPrint('Error fetching reviews: $e');
    }

    _isLoadingReviews = false;
    notifyListeners();
  }
}
