import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:mime/mime.dart';
import 'package:flutter/foundation.dart';
import '../../../../core/network/api_service.dart';

class InventoryService {
  static const String _inventoryUrl = '${ApiService.baseUrl}/admin/inventaris';

  static Future<Map<String, dynamic>> getInventory({
    required String token,
    String? search,
    String? category,
  }) async {
    try {
      final queryParams = {
        if (search != null && search.isNotEmpty) 'search': search,
        if (category != null && category.isNotEmpty) 'category': category,
      };

      final uri = Uri.parse(
        _inventoryUrl,
      ).replace(queryParameters: queryParams);

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error in InventoryService.getInventory: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> getSummary({
    required String token,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$_inventoryUrl/summary'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error in InventoryService.getSummary: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> createItem({
    required String token,
    required String namaItem,
    String? kategori,
    double? stokSaatIni,
    double? stokMaksimum,
    double? stokMinimum,
    String? satuan,
    File? fotoInven,
  }) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse(_inventoryUrl));
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      request.fields['nama_item'] = namaItem;
      if (kategori != null) request.fields['kategori'] = kategori;
      if (stokSaatIni != null)
        request.fields['stok_saat_ini'] = stokSaatIni.toString();
      if (stokMaksimum != null)
        request.fields['stok_maksimum'] = stokMaksimum.toString();
      if (stokMinimum != null)
        request.fields['stok_minimum'] = stokMinimum.toString();
      if (satuan != null) request.fields['satuan'] = satuan;

      if (fotoInven != null) {
        final mimeType = lookupMimeType(fotoInven.path) ?? 'image/jpeg';
        final mimeSplit = mimeType.split('/');

        request.files.add(
          await http.MultipartFile.fromPath(
            'foto_inven',
            fotoInven.path,
            contentType: MediaType(mimeSplit[0], mimeSplit[1]),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
          'InventoryService.createItem failed: ${response.statusCode}',
        );
        debugPrint('Response body: ${response.body}');
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'body': response.body,
        };
      }
    } catch (e) {
      debugPrint('Error in InventoryService.createItem: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> updateItem({
    required String token,
    required int id,
    String? namaItem,
    String? kategori,
    double? stokSaatIni,
    double? stokMaksimum,
    double? stokMinimum,
    String? satuan,
    File? fotoInven,
  }) async {
    try {
      var request = http.MultipartRequest(
        'PATCH',
        Uri.parse('$_inventoryUrl/$id'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.headers['Accept'] = 'application/json';

      if (namaItem != null) request.fields['nama_item'] = namaItem;
      if (kategori != null) request.fields['kategori'] = kategori;
      if (stokSaatIni != null)
        request.fields['stok_saat_ini'] = stokSaatIni.toString();
      if (stokMaksimum != null)
        request.fields['stok_maksimum'] = stokMaksimum.toString();
      if (stokMinimum != null)
        request.fields['stok_minimum'] = stokMinimum.toString();
      if (satuan != null) request.fields['satuan'] = satuan;

      if (fotoInven != null) {
        final mimeType = lookupMimeType(fotoInven.path) ?? 'image/jpeg';
        final mimeSplit = mimeType.split('/');

        request.files.add(
          await http.MultipartFile.fromPath(
            'foto_inven',
            fotoInven.path,
            contentType: MediaType(mimeSplit[0], mimeSplit[1]),
          ),
        );
      }

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        debugPrint(
          'InventoryService.updateItem failed: ${response.statusCode}',
        );
        debugPrint('Response body: ${response.body}');
        return {
          'success': false,
          'message': 'Server error: ${response.statusCode}',
          'body': response.body,
        };
      }
    } catch (e) {
      debugPrint('Error in InventoryService.updateItem: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> addStock({
    required String token,
    required int id,
    required double amount,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_inventoryUrl/$id/add-stock'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'amount': amount}),
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error in InventoryService.addStock: $e');
      return {'success': false, 'message': e.toString()};
    }
  }

  static Future<Map<String, dynamic>> deleteItem({
    required String token,
    required int id,
  }) async {
    try {
      final response = await http.delete(
        Uri.parse('$_inventoryUrl/$id'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      return jsonDecode(response.body);
    } catch (e) {
      debugPrint('Error in InventoryService.deleteItem: $e');
      return {'success': false, 'message': e.toString()};
    }
  }
}
