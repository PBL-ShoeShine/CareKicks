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

  /// Hitung ongkir berdasarkan jarak:
  /// - Gratis jika jarak <= 2 KM
  /// - 5000 per KM jika jarak > 2 KM
  static int calculateOngkir(double distanceKm) {
    if (distanceKm <= 2.0) return 0;
    
    // Perhitungan biaya dilakukan ketika lebih dari 2km
    // Tiap 1 km itu 5 rb.
    // Kita bulatkan ke atas atau gunakan desimal? 
    // Biasanya distance * 5000.
    return (distanceKm * 5000).round();
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
