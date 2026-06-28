import 'dart:io';
import 'package:flutter/material.dart';
import '../services/cart_service.dart';

class CartController extends ChangeNotifier {
  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _cartData = [];
  final Set<int> _selectedItemIds = {};

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<dynamic> get cartData => _cartData;
  Set<int> get selectedItemIds => _selectedItemIds;

  void toggleSelection(int idCartItem) {
    if (_selectedItemIds.contains(idCartItem)) {
      _selectedItemIds.remove(idCartItem);
    } else {
      _selectedItemIds.add(idCartItem);
    }
    notifyListeners();
  }

  bool isSelected(int idCartItem) => _selectedItemIds.contains(idCartItem);

  void toggleShop(int idCart) {
    final shop = _cartData.firstWhere(
      (s) => s['id_cart'] == idCart,
      orElse: () => null,
    );
    if (shop == null) return;

    final items = shop['items'] as List<dynamic>? ?? [];
    final itemIds = items.map<int>((i) => i['id_cart_item'] as int).toSet();
    final allSelected = itemIds.every(_selectedItemIds.contains);

    if (allSelected) {
      _selectedItemIds.removeAll(itemIds);
    } else {
      _selectedItemIds.addAll(itemIds);
    }
    notifyListeners();
  }

  bool isShopSelected(int idCart) {
    final shop = _cartData.firstWhere(
      (s) => s['id_cart'] == idCart,
      orElse: () => null,
    );
    if (shop == null) return false;

    final items = shop['items'] as List<dynamic>? ?? [];
    if (items.isEmpty) return false;
    return items.every((i) => _selectedItemIds.contains(i['id_cart_item']));
  }

  List<Map<String, dynamic>> get selectedItems {
    final selected = <Map<String, dynamic>>[];
    for (final shop in _cartData) {
      final items = shop['items'] as List<dynamic>? ?? [];
      for (final item in items) {
        if (_selectedItemIds.contains(item['id_cart_item'])) {
          selected.add(Map<String, dynamic>.from(item as Map));
        }
      }
    }
    return selected;
  }

  int get totalSelectedPrice {
    return selectedItems.fold(0, (sum, item) {
      return sum + (int.tryParse(item['harga_layanan']?.toString() ?? '0') ?? 0);
    });
  }

  bool get allSelectedSameShop {
    if (selectedItems.isEmpty) return false;
    final cartIds = <int>{};
    for (final shop in _cartData) {
      final items = shop['items'] as List<dynamic>? ?? [];
      final hasSelected = items.any(
        (item) => _selectedItemIds.contains(item['id_cart_item']),
      );
      if (hasSelected) {
        cartIds.add(shop['id_cart'] as int);
      }
    }
    return cartIds.length == 1;
  }

  void clearSelection() {
    _selectedItemIds.clear();
    notifyListeners();
  }

  Future<void> fetchCart({required String token}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await CartService.getCart(token: token);
      
      if (result != null && result['success'] == true) {
        _cartData = result['data'] ?? [];
      } else {
        _errorMessage = result?['message'] ?? 'Gagal memuat keranjang';
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart({
    required String token,
    required String idShops,
    required String idServices,
    required String hargaLayanan,
    String? catatan,
    required String merk,
    required String jenisSepatu,
    required String warna,
    required List<File> fotoSebelumList,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await CartService.addToCart(
        token: token,
        idShops: idShops,
        idServices: idServices,
        hargaLayanan: hargaLayanan,
        catatan: catatan,
        merk: merk,
        jenisSepatu: jenisSepatu,
        warna: warna,
        fotoSebelumList: fotoSebelumList,
      );
      
      if (result != null && result['success'] == true) {
        await fetchCart(token: token);
        return true;
      } else {
        _errorMessage = result?['message'] ?? 'Gagal menambahkan ke keranjang';
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

  Future<bool> updateItem({
    required String token,
    required int idCartItem,
    String? catatan,
    String? merk,
    String? jenisSepatu,
    String? warna,
    String? fotoIndices,
    List<File>? fotoSebelumList,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await CartService.updateItem(
        token: token,
        idCartItem: idCartItem,
        catatan: catatan,
        merk: merk,
        jenisSepatu: jenisSepatu,
        warna: warna,
        fotoIndices: fotoIndices,
        fotoSebelumList: fotoSebelumList,
      );

      if (result != null && result['success'] == true) {
        await fetchCart(token: token);
        return true;
      } else {
        _errorMessage = result?['message'] ?? 'Gagal memperbarui item';
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

  Future<Map<String, dynamic>?> createOrderFromCart({
    required String token,
    required String namaPemilik,
    required String noHp,
    required String alamat,
    double? latOrder,
    double? longOrder,
    int? totalOngkir,
    String? metodePengambilan,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final selectedIds = selectedItems.map((item) => item['id_cart_item'] as int).toList();
      final result = await CartService.createOrderFromCart(
        token: token,
        selectedIds: selectedIds,
        namaPemilik: namaPemilik,
        noHp: noHp,
        alamat: alamat,
        latOrder: latOrder,
        longOrder: longOrder,
        totalOngkir: totalOngkir,
        metodePengambilan: metodePengambilan,
      );

      if (result != null && result['success'] == true) {
        await fetchCart(token: token);
        return result;
      } else {
        _errorMessage = result?['message'] ?? 'Gagal membuat pesanan';
        return null;
      }
    } catch (e) {
      _errorMessage = 'Terjadi kesalahan: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteItem({
    required String token,
    required int idCartItem,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await CartService.deleteItem(
        token: token,
        idCartItem: idCartItem,
      );
      
      if (result != null && result['success'] == true) {
        _selectedItemIds.remove(idCartItem);
        await fetchCart(token: token);
        return true;
      } else {
        _errorMessage = result?['message'] ?? 'Gagal menghapus item';
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
}
