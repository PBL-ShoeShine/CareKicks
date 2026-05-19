import 'dart:io';
import 'package:flutter/material.dart';
import '../models/inventory_model.dart';
import '../services/inventory_service.dart';

class InventoryController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<InventoryItem> _items = [];
  InventorySummary? _summary;

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<InventoryItem> get items => _items;
  InventorySummary? get summary => _summary;

  Future<void> fetchInventory(String token, {String? search, String? category}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await InventoryService.getInventory(
        token: token,
        search: search,
        category: category,
      );

      if (response['success'] == true) {
        final List<dynamic> data = response['data'];
        _items = data.map((item) => InventoryItem.fromJson(item)).toList();
      } else {
        _errorMessage = response['message'] ?? 'Gagal mengambil data inventaris';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchSummary(String token) async {
    try {
      final response = await InventoryService.getSummary(token: token);

      if (response['success'] == true) {
        _summary = InventorySummary.fromJson(response['data']);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching summary: $e');
    }
  }

  Future<bool> createItem({
    required String token,
    required String namaItem,
    String? kategori,
    double? stokSaatIni,
    double? stokMaksimum,
    double? stokMinimum,
    String? satuan,
    File? fotoInven,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await InventoryService.createItem(
        token: token,
        namaItem: namaItem,
        kategori: kategori,
        stokSaatIni: stokSaatIni,
        stokMaksimum: stokMaksimum,
        stokMinimum: stokMinimum,
        satuan: satuan,
        fotoInven: fotoInven,
      );

      if (response['success'] == true) {
        await fetchInventory(token);
        await fetchSummary(token);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Gagal menambah item';
        if (response['body'] != null) {
          debugPrint('Server Error Body: ${response['body']}');
        }
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addStock({
    required String token,
    required int id,
    required double amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await InventoryService.addStock(
        token: token,
        id: id,
        amount: amount,
      );

      if (response['success'] == true) {
        await fetchInventory(token);
        await fetchSummary(token);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Gagal menambah stok';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> reduceStock({
    required String token,
    required int id,
    required double amount,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await InventoryService.reduceStock(
        token: token,
        id: id,
        amount: amount,
      );

      if (response['success'] == true) {
        await fetchInventory(token);
        await fetchSummary(token);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Gagal mengurangi stok';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteItem(String token, int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await InventoryService.deleteItem(token: token, id: id);

      if (response['success'] == true) {
        await fetchInventory(token);
        await fetchSummary(token);
        return true;
      } else {
        _errorMessage = response['message'] ?? 'Gagal menghapus item';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
