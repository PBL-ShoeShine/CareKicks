import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/metode_pembayaran_service.dart';


class MetodePembayaranController extends ChangeNotifier {
  bool isLoading = false;
  String errorMessage = '';

  List<Map<String, dynamic>> bankAccounts = [];
  List<Map<String, dynamic>> qrisList = [];

  Future<void> fetchPaymentMethods(String token) async {
    isLoading = true;
    notifyListeners();

    final result = await MetodePembayaranService.fetchPaymentMethods(token);

    if (result['success'] == true) {
      final List<dynamic> rawData = result['data'] ?? [];
      bankAccounts.clear();
      qrisList.clear();

      for (var item in rawData) {
        if (item['tipe_pembayaran'] == 'BANK_TRANSFER') {
          bankAccounts.add(Map<String, dynamic>.from(item));
        } else if (item['tipe_pembayaran'] == 'QRIS') {
          qrisList.add(Map<String, dynamic>.from(item));
        }
      }
    } else {
      errorMessage = result['message'] ?? 'Gagal memuat data';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<bool> addPaymentMethod({
    required String token,
    required String tipePembayaran,
    required String namaBank,
    required String noRek,
    required String atasNama,
    bool isDefault = false,
  }) async {
    isLoading = true;
    notifyListeners();

    final result = await MetodePembayaranService.addPaymentMethod(
      token: token,
      tipePembayaran: tipePembayaran,
      namaBank: namaBank,
      noRek: noRek,
      atasNama: atasNama,
      isDefault: isDefault,
    );

    if (result['success'] == true) {
      await fetchPaymentMethods(token);
      return true;
    } else {
      errorMessage = result['message'] ?? 'Gagal menambah data';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Fungsi baru: Tambah QRIS sekaligus Upload Gambar
  Future<bool> addQrisWithImage({
    required String token,
    required String namaToko,
    required String mid,
    File? imageFile,
  }) async {
    isLoading = true;
    notifyListeners();

    // 1. Simpan data teksnya dulu
    final result = await MetodePembayaranService.addPaymentMethod(
      token: token,
      tipePembayaran: 'QRIS',
      namaBank: 'QRIS',
      noRek: mid,
      atasNama: namaToko,
      isDefault: false,
    );

    if (result['success'] == true) {
      // 2. Jika berhasil dan ada gambar, langsung upload gambarnya
      if (imageFile != null && result['data'] != null) {
        int newId = result['data']['id_account'];
        await MetodePembayaranService.uploadQrisImage(
          token: token,
          idAccount: newId,
          imageFile: imageFile,
        );
      }
      await fetchPaymentMethods(token);
      return true;
    } else {
      errorMessage = result['message'] ?? 'Gagal menyimpan data QRIS';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> toggleStatus({
    required String token,
    required int idAccount,
    required bool isActive,
  }) async {
    _updateLocalStatus(idAccount, isActive);

    final result = await MetodePembayaranService.toggleStatus(
      token: token,
      idAccount: idAccount,
      isActive: isActive,
    );

    if (result['success'] != true) {
      errorMessage = result['message'] ?? 'Gagal mengubah status';
      _updateLocalStatus(idAccount, !isActive);
      return false;
    }
    return true;
  }

  void _updateLocalStatus(int idAccount, bool isActive) {
    for (var i = 0; i < bankAccounts.length; i++) {
      if (bankAccounts[i]['id_account'] == idAccount) {
        bankAccounts[i]['is_active'] = isActive;
      }
    }
    for (var i = 0; i < qrisList.length; i++) {
      if (qrisList[i]['id_account'] == idAccount) {
        qrisList[i]['is_active'] = isActive;
      }
    }
    notifyListeners();
  }

  Future<bool> deletePaymentMethod(String token, int idAccount) async {
    final ok = await MetodePembayaranService.deletePaymentMethod(
      token,
      idAccount,
    );
    if (ok) {
      await fetchPaymentMethods(token);
    } else {
      errorMessage = 'Gagal menghapus metode pembayaran';
      notifyListeners();
    }
    return ok;
  }

  Future<bool> uploadQrisImage(
    String token,
    int idAccount,
    ImageSource source,
  ) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 85);

    if (image == null) return false;

    isLoading = true;
    notifyListeners();

    final result = await MetodePembayaranService.uploadQrisImage(
      token: token,
      idAccount: idAccount,
      imageFile: File(image.path),
    );

    if (result['success'] == true) {
      await fetchPaymentMethods(token);
      return true;
    } else {
      errorMessage = result['message'] ?? 'Gagal mengunggah QRIS';
      isLoading = false;
      notifyListeners();
      return false;
    }
  }
}
