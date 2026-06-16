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
}
