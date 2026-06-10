import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../services/tambah_alamat_service.dart';

class TambahAlamatController extends ChangeNotifier {
  // ── Controllers teks ──────────────────────────────────────────────────────
  final streetCtrl = TextEditingController();
  final detailCtrl = TextEditingController();
  final recipientCtrl = TextEditingController();
  // FIX: init langsung '+62-' agar tampil sebelum field diklik
  final phoneCtrl = TextEditingController(text: '+62-');
  final MapController mapCtrl = MapController();

  // ── State wilayah ─────────────────────────────────────────────────────────
  Wilayah? provinsi;
  Wilayah? kabupaten;
  Wilayah? kecamatan;
  Wilayah? kelurahan;

  // ── State peta & geocoding ────────────────────────────────────────────────
  LatLng pinLocation = const LatLng(-7.0051, 110.4381);
  String resolvedAddress = '';
  bool mapReady = false;
  bool isLoadingLoc = false;
  bool isGeocoding = false;
  bool _streetAutoFilled = false;

  // ── State form ────────────────────────────────────────────────────────────
  String? selectedLabel;
  bool isDefault = false;
  bool isSaving = false;

  Timer? _geocodeDebounce;
  bool _disposed = false;

  // ── Inisialisasi dari data existing (mode edit) ───────────────────────────
  void initFromExisting(Map<String, dynamic> e) {
    recipientCtrl.text = e['recipient_name'] ?? '';
    phoneCtrl.text = _formatPhone(e['phone_number'] ?? '');
    selectedLabel = e['address_label'];
    isDefault = e['is_default'] ?? false;

    final parts = (e['full_address'] ?? '').split('\n');
    streetCtrl.text = parts.isNotEmpty ? parts[0] : '';
    detailCtrl.text = parts.length > 1 ? parts.sublist(1).join('\n') : '';
    _streetAutoFilled = streetCtrl.text.isNotEmpty;

    final lat = double.tryParse(e['latitude']?.toString() ?? '');
    final lng = double.tryParse(e['longitude']?.toString() ?? '');

    if (lat != null && lng != null) {
      pinLocation = LatLng(lat, lng);
      resolvedAddress = e['full_address'] ?? '';
    }

    notifyListeners();
  }

  // Dipanggil oleh View setelah inisialisasi edit selesai
  Future<void> syncWilayahFromCoordinates() async {
    if (pinLocation.latitude == -7.0051 && pinLocation.longitude == 110.4381) {
      return; // Jika koordinat default, lewati
    }
    await _doReverseGeocode(pinLocation, clearStreet: false);
  }

  // ── GPS ───────────────────────────────────────────────────────────────────
  Future<void> useCurrentLocation() async {
    _set(() => isLoadingLoc = true);
    final ll = await GpsService.getCurrentLocation();
    if (ll != null) _movePinAndGeocode(ll, clearStreet: true);
    _set(() => isLoadingLoc = false);
  }

  // ── Saat peta digeser selesai ─────────────────────────────────────────────
  void onMapMoveEnd(LatLng center) {
    pinLocation = center;
    _geocodeDebounce?.cancel();
    _geocodeDebounce = Timer(
      const Duration(milliseconds: 700),
      () => _doReverseGeocode(center, clearStreet: true),
    );
  }

  // ── Setelah user memilih dari hasil search ────────────────────────────────
  void applySearchResult(Map<String, dynamic> item) {
    final result = GeocodingService.parseSearchItem(item);
    if (result == null) return;
    _movePinAndGeocode(result.latLng, preloaded: result);
  }

  // ── Gerak peta + reverse geocode ─────────────────────────────────────────
  void _movePinAndGeocode(
    LatLng ll, {
    bool clearStreet = false,
    GeoResult? preloaded,
  }) {
    pinLocation = ll;
    if (mapReady) mapCtrl.move(ll, 17);
    if (clearStreet) {
      streetCtrl.clear();
      _streetAutoFilled = false;
    }
    if (preloaded != null) {
      _applyGeoResult(preloaded);
    } else {
      _doReverseGeocode(ll, clearStreet: clearStreet);
    }
  }

  Future<void> _doReverseGeocode(LatLng ll, {bool clearStreet = false}) async {
    _set(() => isGeocoding = true);
    final result = await GeocodingService.reverseGeocode(ll);
    if (!_disposed && result != null) {
      _applyGeoResult(result, clearStreet: clearStreet);
    }
    _set(() => isGeocoding = false);
  }

  void _applyGeoResult(GeoResult result, {bool clearStreet = false}) {
    resolvedAddress = result.displayName;

    if (result.road.isNotEmpty && !_streetAutoFilled) {
      streetCtrl.text = result.road;
    }

    _syncWilayahFromGeo(result);
    notifyListeners();
  }

  Future<void> _syncWilayahFromGeo(GeoResult geo) async {
    if (geo.province.isEmpty) return;

    final provList = await WilayahService.getProvinsi();
    final matchProv = _findBestMatch(provList, geo.province);
    if (matchProv == null || _disposed) return;

    final kabList = await WilayahService.getKabupaten(matchProv.id);
    final matchKab = _findBestMatch(kabList, geo.city);

    Wilayah? matchKec;
    if (matchKab != null) {
      final kecList = await WilayahService.getKecamatan(matchKab.id);
      matchKec = _findBestMatch(kecList, geo.district);
    }

    Wilayah? matchKel;
    if (matchKec != null) {
      final kelList = await WilayahService.getKelurahan(matchKec.id);
      matchKel = _findBestMatch(kelList, geo.suburb);
    }

    if (!_disposed) {
      _set(() {
        provinsi = matchProv;
        kabupaten = matchKab;
        kecamatan = matchKec;
        kelurahan = matchKel;
      });
    }
  }

  Wilayah? _findBestMatch(List<Wilayah> list, String query) {
    if (query.isEmpty || list.isEmpty) return null;
    final q = query.toLowerCase();
    for (final w in list) {
      if (w.nama.toLowerCase() == q) return w;
    }
    for (final w in list) {
      if (w.nama.toLowerCase().contains(q) ||
          q.contains(w.nama.toLowerCase())) {
        return w;
      }
    }
    return null;
  }

  // ── Getters ───────────────────────────────────────────────────────────────
  String get wilayahText {
    if (provinsi == null) return '';
    return [
      if (kelurahan != null) kelurahan!.nama,
      if (kecamatan != null) kecamatan!.nama,
      if (kabupaten != null) kabupaten!.nama,
      provinsi!.nama,
    ].join(', ');
  }

  bool get isPhoneValid {
    final digits = phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length >= 10 && digits.length <= 14;
  }

  String get rawPhone {
    final digits = phoneCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('62')) return '0${digits.substring(2)}';
    if (digits.isEmpty) return '';
    return '0$digits';
  }

  String get fullAddressForSave => [
    streetCtrl.text.trim(),
    if (detailCtrl.text.trim().isNotEmpty) detailCtrl.text.trim(),
    if (wilayahText.isNotEmpty) wilayahText,
    if (resolvedAddress.isNotEmpty) resolvedAddress,
  ].join('\n');

  void markStreetManual() => _streetAutoFilled = true;

  void _set(VoidCallback fn) {
    fn();
    if (!_disposed) notifyListeners();
  }

  String _formatPhone(String raw) {
    if (raw.isEmpty) return '+62-';
    String digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.startsWith('62')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = digits.substring(1);
    if (digits.length > 12) digits = digits.substring(0, 12);
    final buf = StringBuffer('+62');
    for (int i = 0; i < digits.length; i++) {
      if (i % 4 == 0) buf.write('-');
      buf.write(digits[i]);
    }
    return buf.toString();
  }

  @override
  void dispose() {
    _disposed = true;
    _geocodeDebounce?.cancel();
    streetCtrl.dispose();
    detailCtrl.dispose();
    recipientCtrl.dispose();
    phoneCtrl.dispose();
    super.dispose();
  }
}
