import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

// ── MODEL ──────────────────────────────────────────────────────────────────

class Wilayah {
  final String id;
  final String nama;
  const Wilayah({required this.id, required this.nama});
}

/// Hasil reverse/forward geocode yang dipakai untuk sinkronisasi
class GeoResult {
  final LatLng latLng;
  final String displayName;
  final String road;       // nama jalan dari OSM
  final String province;   // provinsi dari OSM (untuk matching)
  final String city;       // kabupaten/kota dari OSM
  final String district;   // kecamatan dari OSM
  final String suburb;     // kelurahan/desa dari OSM

  const GeoResult({
    required this.latLng,
    required this.displayName,
    this.road = '',
    this.province = '',
    this.city = '',
    this.district = '',
    this.suburb = '',
  });
}

// ── WILAYAH SERVICE ────────────────────────────────────────────────────────

class WilayahService {
  static const _base = 'https://ibnux.github.io/data-indonesia';

  static Future<List<Wilayah>> getProvinsi() => _fetch('$_base/provinsi.json');
  static Future<List<Wilayah>> getKabupaten(String idProv) =>
      _fetch('$_base/kabupaten/$idProv.json');
  static Future<List<Wilayah>> getKecamatan(String idKab) =>
      _fetch('$_base/kecamatan/$idKab.json');
  static Future<List<Wilayah>> getKelurahan(String idKec) =>
      _fetch('$_base/kelurahan/$idKec.json');

  static Future<List<Wilayah>> _fetch(String url) async {
    try {
      final res = await http
          .get(Uri.parse(url), headers: {'Accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        final List raw =
            decoded is List ? decoded : (decoded['data'] as List? ?? []);
        return raw
            .map((e) => Wilayah(
                  id: e['id']?.toString() ?? '',
                  nama: _titleCase(e['nama']?.toString() ?? ''),
                ))
            .where((w) => w.id.isNotEmpty && w.nama.isNotEmpty)
            .toList();
      }
    } catch (e) {
      debugPrint('WilayahService error: $e');
    }
    return [];
  }

  static String _titleCase(String s) => s
      .toLowerCase()
      .split(' ')
      .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

// ── GEOCODING SERVICE ──────────────────────────────────────────────────────

class GeocodingService {
  static const _userAgent = 'CareKicksApp/1.0';

  /// Search by teks → list kandidat (forward geocoding)
  static Future<List<Map<String, dynamic>>> search(String query) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/search'
        '?q=${Uri.encodeComponent(query)}'
        '&format=json&addressdetails=1&limit=10&countrycodes=id',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('GeocodingService.search error: $e');
    }
    return [];
  }

  /// Koordinat → detail alamat (reverse geocoding)
  static Future<GeoResult?> reverseGeocode(LatLng ll) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?lat=${ll.latitude}&lon=${ll.longitude}'
        '&format=json&zoom=18&addressdetails=1',
      );
      final res = await http
          .get(uri, headers: {'User-Agent': _userAgent})
          .timeout(const Duration(seconds: 10));
      if (res.statusCode == 200) {
        return _parseGeoResult(ll, jsonDecode(res.body));
      }
    } catch (e) {
      debugPrint('GeocodingService.reverseGeocode error: $e');
    }
    return null;
  }

  /// Parse satu item Nominatim (dari search atau reverse) → GeoResult
  static GeoResult? parseSearchItem(Map<String, dynamic> item) {
    final lat = double.tryParse(item['lat']?.toString() ?? '');
    final lon = double.tryParse(item['lon']?.toString() ?? '');
    if (lat == null || lon == null) return null;
    return _parseGeoResult(LatLng(lat, lon), item);
  }

  static GeoResult _parseGeoResult(
      LatLng ll, Map<String, dynamic> data) {
    final addr =
        (data['address'] as Map?)?.cast<String, dynamic>() ?? {};
    final road = addr['road'] ??
        addr['pedestrian'] ??
        addr['suburb'] ??
        addr['village'] ??
        '';
    final houseNo = addr['house_number'] ?? '';
    final roadWithNo = houseNo.isNotEmpty ? '$road No. $houseNo' : road;

    return GeoResult(
      latLng: ll,
      displayName: data['display_name']?.toString() ?? '',
      road: roadWithNo,
      province: _normalize(addr['state']?.toString() ?? ''),
      city: _normalize(
        (addr['city'] ?? addr['county'] ?? addr['regency'] ?? '')
            .toString(),
      ),
      district: _normalize(
        (addr['city_district'] ?? addr['suburb'] ?? addr['town'] ?? '')
            .toString(),
      ),
      suburb: _normalize(
        (addr['quarter'] ?? addr['neighbourhood'] ?? addr['village'] ?? '')
            .toString(),
      ),
    );
  }

  /// Normalize: hapus prefix "Kota/Kabupaten/Kecamatan" untuk matching
  static String _normalize(String s) {
    return s
        .toLowerCase()
        .replaceAll('kabupaten ', '')
        .replaceAll('kota ', '')
        .replaceAll('kecamatan ', '')
        .replaceAll('kelurahan ', '')
        .replaceAll('desa ', '')
        .trim();
  }
}

// ── GPS SERVICE ─────────────────────────────────────────────────────────────

class GpsService {
  static Future<LatLng?> getCurrentLocation() async {
    try {
      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever) return null;

      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      return LatLng(pos.latitude, pos.longitude);
    } catch (e) {
      debugPrint('GpsService error: $e');
      return null;
    }
  }
}