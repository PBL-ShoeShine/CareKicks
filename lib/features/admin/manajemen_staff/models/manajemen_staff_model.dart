import 'package:flutter/material.dart';

enum StaffStatus { aktif, cuti } // ✅ FIX: hapus sedang_tugas & non_aktif

class ManajemenStaffModel {
  final String id;
  final String nama;
  final String email;
  final String noHp;
  final String idShops;
  final StaffStatus status;

  ManajemenStaffModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.noHp,
    required this.idShops,
    required this.status,
  });

  factory ManajemenStaffModel.fromJson(Map<String, dynamic> json) {
    final profile = json['staff_profile'] ?? json;

    return ManajemenStaffModel(
      id: (json['id_staff_profile'] ?? json['id'] ?? '').toString(),
      nama: profile['nama'] ?? '',
      email: profile['email'] ?? '',
      noHp: profile['no_hp'] ?? '',
      idShops: (profile['id_shops'] ?? '').toString(),
      status: _parseStatus(profile['status']),
    );
  }

  static StaffStatus _parseStatus(String? s) {
    if (s == null) return StaffStatus.aktif;
    switch (s.toUpperCase()) {
      case 'CUTI':
        return StaffStatus.cuti;
      default:
        return StaffStatus.aktif; // ✅ semua selain CUTI → aktif
    }
  }

  String get statusLabel {
    switch (status) {
      case StaffStatus.aktif:
        return 'AKTIF';
      case StaffStatus.cuti:
        return 'CUTI';
    }
  }

  Color get statusColor {
    switch (status) {
      case StaffStatus.aktif:
        return const Color(0xFF2ECC71);
      case StaffStatus.cuti:
        return const Color(0xFF95A5A6);
    }
  }
}