class InventoryItem {
  final int idInventory;
  final int idShops;
  final String namaItem;
  final String? kategori;
  final double stokSaatIni;
  final double stokMaksimum;
  final double stokMinimum;
  final String? satuan;
  final String? fotoInven;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  InventoryItem({
    required this.idInventory,
    required this.idShops,
    required this.namaItem,
    this.kategori,
    required this.stokSaatIni,
    required this.stokMaksimum,
    required this.stokMinimum,
    this.satuan,
    this.fotoInven,
    this.createdAt,
    this.updatedAt,
  });

  static String? _resolveFotoUrl(String? path) {
    if (path == null || path.isEmpty) return null;
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return 'https://xedmzxaytjnfcnhnxumj.supabase.co/storage/v1/object/public/services/$path';
  }

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    return InventoryItem(
      idInventory: json['id_inventory'],
      idShops: json['id_shops'],
      namaItem: json['nama_item'],
      kategori: json['kategori'],
      stokSaatIni: (json['stok_saat_ini'] as num).toDouble(),
      stokMaksimum: (json['stok_maksimum'] as num).toDouble(),
      stokMinimum: (json['stok_minimum'] as num).toDouble(),
      satuan: json['satuan'],
      fotoInven: _resolveFotoUrl(json['foto_inven']),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id_inventory': idInventory,
      'id_shops': idShops,
      'nama_item': namaItem,
      'kategori': kategori,
      'stok_saat_ini': stokSaatIni,
      'stok_maksimum': stokMaksimum,
      'stok_minimum': stokMinimum,
      'satuan': satuan,
      'foto_inven': fotoInven,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class InventorySummary {
  final int totalJenis;
  final int butuhRestock;

  InventorySummary({
    required this.totalJenis,
    required this.butuhRestock,
  });

  factory InventorySummary.fromJson(Map<String, dynamic> json) {
    return InventorySummary(
      totalJenis: json['total_jenis'],
      butuhRestock: json['butuh_restock'],
    );
  }
}
