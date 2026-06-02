import 'package:flutter/material.dart';

enum StaffRole { WASHER, COURIER }

enum StaffStatus { aktif, sedang_tugas, cuti, non_aktif }

class ManajemenStaffModel {
  final String id;
  final String nama;
  final String email;
  final String noHp;
  final String idShops;
  final List<StaffRole> roles; // Diubah menjadi List untuk multi-role
  final StaffStatus status;

  ManajemenStaffModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.noHp,
    required this.idShops,
    required this.roles,
    required this.status,
  });

  factory ManajemenStaffModel.fromJson(Map<String, dynamic> json) {
    final profile = json['staff_profile'] ?? json;

    // Parsing Role dari Text[] (Array) Supabase
    List<StaffRole> parsedRoles = [];
    if (profile['role'] != null && profile['role'] is List) {
      for (var r in profile['role']) {
        if (r.toString().toUpperCase() == 'COURIER') {
          parsedRoles.add(StaffRole.COURIER);
        } else {
          parsedRoles.add(StaffRole.WASHER);
        }
      }
    } else if (profile['role'] is String) {
      // Fallback jika masih string biasa
      parsedRoles = [
        profile['role'].toString().toUpperCase() == 'COURIER'
            ? StaffRole.COURIER
            : StaffRole.WASHER,
      ];
    }

    // Pastikan minimal ada 1 role jika kosong
    if (parsedRoles.isEmpty) parsedRoles = [StaffRole.WASHER];

    return ManajemenStaffModel(
      id: (json['id_staff_profile'] ?? json['id'] ?? '').toString(),
      nama: profile['nama'] ?? '',
      email: profile['email'] ?? '',
      noHp: profile['no_hp'] ?? '',
      idShops: (profile['id_shops'] ?? '').toString(),
      roles: parsedRoles.toSet().toList(), // toSet agar tidak ada duplikat
      status: _parseStatus(profile['status']),
    );
  }

  static StaffStatus _parseStatus(String? s) {
    if (s == null) return StaffStatus.aktif;
    switch (s.toUpperCase()) {
      case 'SEDANG TUGAS':
      case 'SEDANG_TUGAS':
        return StaffStatus.sedang_tugas;
      case 'CUTI':
        return StaffStatus.cuti;
      case 'NON AKTIF':
      case 'NON_AKTIF':
        return StaffStatus.non_aktif;
      default:
        return StaffStatus.aktif;
    }
  }

  String get statusLabel {
    switch (status) {
      case StaffStatus.aktif:
        return 'AKTIF';
      case StaffStatus.sedang_tugas:
        return 'SEDANG TUGAS';
      case StaffStatus.cuti:
        return 'CUTI';
      case StaffStatus.non_aktif:
        return 'NON AKTIF';
    }
  }

  Color get statusColor {
    switch (status) {
      case StaffStatus.aktif:
        return const Color(0xFF2ECC71);
      case StaffStatus.sedang_tugas:
        return const Color(0xFFFF9F43);
      case StaffStatus.cuti:
        return const Color(0xFF95A5A6);
      case StaffStatus.non_aktif:
        return const Color(0xFFE74C3C);
    }
  }
}
