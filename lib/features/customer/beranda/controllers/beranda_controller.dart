import 'package:flutter/material.dart';
import '../services/beranda_service.dart';

class BerandaController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _services = [];
  Map<String, dynamic>? _pagination;

  // Filters
  String _searchQuery = '';
  double? _minPrice;
  double? _maxPrice;
  String? _selectedSpesialisasi;
  double? _minRating;
  String _sortBy = 'harga';
  String _sortOrder = 'asc';
  int _page = 1;
  int _limit = 10;

  bool _isSortActive = false;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get services => _services;
  Map<String, dynamic>? get pagination => _pagination;

  // Filter Getters
  String get searchQuery => _searchQuery;
  double? get minPrice => _minPrice;
  double? get maxPrice => _maxPrice;
  String? get selectedSpesialisasi => _selectedSpesialisasi;
  double? get minRating => _minRating;
  String get sortBy => _sortBy;
  String get sortOrder => _sortOrder;
  bool get isSortActive => _isSortActive;

  void setSearch(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setPriceRange(double? min, double? max) {
    _minPrice = min;
    _maxPrice = max;
    notifyListeners();
  }

  void setSpesialisasi(String? spesialisasi) {
    _selectedSpesialisasi = spesialisasi;
    notifyListeners();
  }

  void setMinRating(double? rating) {
    _minRating = rating;
    notifyListeners();
  }

  void setSorting(String sortBy, String sortOrder) {
    _sortBy = sortBy;
    _sortOrder = sortOrder;
    _isSortActive = true;
    notifyListeners();
  }

  Future<void> fetchBeranda(String token, {bool isRefresh = false}) async {
    if (isRefresh) {
      _page = 1;
      _services = [];
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await BerandaService.getBeranda(
        token: token,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        spesialisasi: _selectedSpesialisasi,
        minRating: _minRating,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
        page: _page,
        limit: _limit,
      );

      if (result['success']) {
        if (isRefresh) {
          _services = result['data'] ?? [];
        } else {
          _services.addAll(result['data'] ?? []);
        }
        _pagination = result['pagination'];
      } else {
        _errorMessage = result['message'] ?? 'Gagal mengambil data beranda';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    }

    _isLoading = false;
    notifyListeners();
  }
}
