import 'package:flutter/material.dart';
import '../services/shop_profile_service.dart';

class ShopProfileController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _shopData;
  List<dynamic> _services = [];
  List<dynamic> _recentReviews = [];

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  Map<String, dynamic>? get shopData => _shopData;
  List<dynamic> get services => _services;
  List<dynamic> get recentReviews => _recentReviews;

  Future<void> fetchShopProfile({
    required String token,
    required int idShops,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = await ShopProfileService.getShopProfile(
      token: token,
      idShops: idShops,
    );

    if (result['success'] == true) {
      final data = result['data'];
      _shopData = data['shop'];
      _services = data['services'] ?? [];
      _recentReviews = data['recent_reviews'] ?? [];
    } else {
      _errorMessage = result['message'] ?? 'Gagal memuat profil toko';
    }

    _isLoading = false;
    notifyListeners();
  }
}
