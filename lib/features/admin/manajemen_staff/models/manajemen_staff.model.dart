import 'package:flutter/material.dart';

enum StaffRole { WASHER, COURIER }
enum StaffStatus { aktif, sedang_tugas, cuti, non_aktif }

class ManajemenStaffModel {
  final String id;
  final String nama;
  final String email;
  final String noHp;
  final String idShops;
  final StaffRole role;
  final StaffStatus status;

  ManajemenStaffModel({
    required this.id,
    required this.nama,
    required this.email,
    required this.noHp,
    required this.idShops,
    required this.role,
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
      role: profile['role'] == 'COURIER' ? StaffRole.COURIER : StaffRole.WASHER,
      status: _parseStatus(profile['status']),
    );
  }

  static StaffStatus _parseStatus(String? s) {
    switch (s) {
      case 'sedang_tugas': return StaffStatus.sedang_tugas;
      case 'cuti':         return StaffStatus.cuti;
      case 'non_aktif':    return StaffStatus.non_aktif;
      default:             return StaffStatus.aktif;
    }
  }

  String get statusLabel {
    switch (status) {
      case StaffStatus.aktif:        return 'AKTIF';
      case StaffStatus.sedang_tugas: return 'SEDANG TUGAS';
      case StaffStatus.cuti:         return 'CUTI';
      case StaffStatus.non_aktif:    return 'NON AKTIF';
    }
  }

  Color get statusColor {
    switch (status) {
      case StaffStatus.aktif:        return const Color(0xFF2ECC71);
      case StaffStatus.sedang_tugas: return const Color(0xFFFF9F43);
      case StaffStatus.cuti:         return const Color(0xFF95A5A6);
      case StaffStatus.non_aktif:    return const Color(0xFFE74C3C);
    }
  }
}