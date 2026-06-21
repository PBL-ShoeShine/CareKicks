import 'dart:io';
import '../../../../core/network/api_service.dart';

class CartService {
  static Future<Map<String, dynamic>?> getCart({required String token}) async {
    return await ApiService.getCustomerCart(token: token);
  }

  static Future<Map<String, dynamic>?> addToCart({
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
    return await ApiService.addToCart(
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
  }

  static Future<Map<String, dynamic>?> updateItem({
    required String token,
    required int idCartItem,
    String? catatan,
    String? merk,
    String? jenisSepatu,
    String? warna,
    String? fotoIndices,
    List<File>? fotoSebelumList,
  }) async {
    return await ApiService.updateCartItem(
      token: token,
      idCartItem: idCartItem,
      catatan: catatan,
      merk: merk,
      jenisSepatu: jenisSepatu,
      warna: warna,
      fotoIndices: fotoIndices,
      fotoSebelumList: fotoSebelumList,
    );
  }

  static Future<Map<String, dynamic>?> createOrderFromCart({
    required String token,
    required List<int> selectedIds,
    required String namaPemilik,
    required String noHp,
    required String alamat,
    double? latOrder,
    double? longOrder,
    int? totalOngkir,
    String? metodePengambilan,
  }) async {
    return await ApiService.createOrderFromCart(
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
  }

  static Future<Map<String, dynamic>?> deleteItem({
    required String token,
    required int idCartItem,
  }) async {
    return await ApiService.deleteCartItem(
      token: token,
      idCartItem: idCartItem,
    );
  }
}
