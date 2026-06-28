import 'dart:math' as math;

class LocationUtils {
  /// Hitung jarak antara dua titik koordinat (Haversine Formula) dalam KM
  static double calculateDistanceKm(
    double lat1,
    double lon1,
    double lat2,
    double lon2,
  ) {
    const earthRadiusKm = 6371.0;

    final dLat = _degToRad(lat2 - lat1);
    final dLon = _degToRad(lon2 - lon1);

    final rLat1 = _degToRad(lat1);
    final rLat2 = _degToRad(lat2);

    final a = (math.sin(dLat / 2) * math.sin(dLat / 2)) +
              (math.cos(rLat1) * math.cos(rLat2) *
               math.sin(dLon / 2) * math.sin(dLon / 2));

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  static double _degToRad(double deg) => deg * (math.pi / 180.0);

  /// Hitung ongkir berdasarkan jarak & tarif milik toko (dinamis per toko).
  ///
  /// Skema:
  /// - 0 .. jarakGratisKm               -> gratis (Rp 0)
  /// - jarakGratisKm .. jarakMaksimalKm -> (jarak - jarakGratisKm) * tarifPerKm
  /// - > jarakMaksimalKm                -> ongkir di batas radius normal
  ///                                        + (jarak - jarakMaksimalKm) * tarifPerKmLuarRadius
  ///
  /// Parameter default disamakan dengan rumus lama (gratis 2km, lalu Rp5.000/km)
  /// supaya pemanggilan lama yang belum diupdate tetap berjalan sama seperti sebelumnya.
  static int calculateOngkir(
    double distanceKm, {
    double jarakGratisKm = 2.0,
    double tarifPerKm = 5000,
    double? jarakMaksimalKm,
    double? tarifPerKmLuarRadius,
  }) {
    // Fallback: kalau jarakMaksimalKm tidak diisi, anggap tidak ada batas radius
    // (semua jarak dihitung pakai tarifPerKm biasa, sama seperti rumus lama)
    final maksimal = jarakMaksimalKm ?? double.infinity;
    final tarifLuar = tarifPerKmLuarRadius ?? tarifPerKm;

    if (distanceKm <= jarakGratisKm) {
      return 0;
    }

    if (distanceKm <= maksimal) {
      return ((distanceKm - jarakGratisKm) * tarifPerKm).round();
    }

    // Melebihi radius maksimal toko
    final ongkirDalamRadius = (maksimal - jarakGratisKm) * tarifPerKm;
    final ongkirLuarRadius = (distanceKm - maksimal) * tarifLuar;
    return (ongkirDalamRadius + ongkirLuarRadius).round();
  }

  /// Deduplicate and clean up repeating parts of an address
  static String cleanAddress(String? address) {
    if (address == null || address.trim().isEmpty) return '';

    // Split by newlines, trim, and remove empty lines
    final List<String> lines = address
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final List<String> cleanLines = [];

    for (final line in lines) {
      bool isSubset = false;
      for (final other in lines) {
        if (identical(line, other)) continue;
        if (other.toLowerCase().contains(line.toLowerCase())) {
          if (other.toLowerCase() == line.toLowerCase()) {
            if (lines.indexOf(line) > lines.indexOf(other)) {
              isSubset = true;
              break;
            }
          } else {
            isSubset = true;
            break;
          }
        }
      }

      if (!isSubset) {
        bool alreadyAdded = false;
        for (int i = 0; i < cleanLines.length; i++) {
          final existing = cleanLines[i];
          if (existing.toLowerCase().contains(line.toLowerCase())) {
            alreadyAdded = true;
            break;
          }
          if (line.toLowerCase().contains(existing.toLowerCase())) {
            cleanLines[i] = line;
            alreadyAdded = true;
            break;
          }
        }
        if (!alreadyAdded) {
          cleanLines.add(line);
        }
      }
    }

    return cleanLines.join('\n');
  }
}