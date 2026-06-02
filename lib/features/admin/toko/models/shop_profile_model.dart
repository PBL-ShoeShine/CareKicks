class ShopProfileModel {
  final int? idShops;
  final String? nmToko;
  final String? deskToko;
  final String? alamatToko;
  final double? latToko;
  final double? longToko;
  final String? fotoToko;
  final String? spesialisasi;
  final DateTime? tglBerdiri;
  final String? emailToko;
  final String? waToko;

  ShopProfileModel({
    this.idShops,
    this.nmToko,
    this.deskToko,
    this.alamatToko,
    this.latToko,
    this.longToko,
    this.fotoToko,
    this.spesialisasi,
    this.tglBerdiri,
    this.emailToko,
    this.waToko,
  });

  factory ShopProfileModel.fromJson(Map<String, dynamic> json) {
    DateTime? parsedDate;
    final rawDate = json['tgl_berdiri'];
    if (rawDate is String && rawDate.isNotEmpty) {
      parsedDate = DateTime.tryParse(rawDate);
    }

    return ShopProfileModel(
      idShops: json['id_shops'],
      nmToko: json['nm_toko'],
      deskToko: json['desk_toko'],
      alamatToko: json['alamat_toko'],
      latToko: (json['lat_toko'] as num?)?.toDouble(),
      longToko: (json['long_toko'] as num?)?.toDouble(),
      fotoToko: json['foto_toko'],
      spesialisasi: json['spesialisasi'],
      tglBerdiri: parsedDate,
      emailToko: json['email_toko'],
      waToko: json['wa_toko'],
    );
  }

  ShopProfileModel copyWith({
    int? idShops,
    String? nmToko,
    String? deskToko,
    String? alamatToko,
    double? latToko,
    double? longToko,
    String? fotoToko,
    String? spesialisasi,
    DateTime? tglBerdiri,
    String? emailToko,
    String? waToko,
  }) {
    return ShopProfileModel(
      idShops: idShops ?? this.idShops,
      nmToko: nmToko ?? this.nmToko,
      deskToko: deskToko ?? this.deskToko,
      alamatToko: alamatToko ?? this.alamatToko,
      latToko: latToko ?? this.latToko,
      longToko: longToko ?? this.longToko,
      fotoToko: fotoToko ?? this.fotoToko,
      spesialisasi: spesialisasi ?? this.spesialisasi,
      tglBerdiri: tglBerdiri ?? this.tglBerdiri,
      emailToko: emailToko ?? this.emailToko,
      waToko: waToko ?? this.waToko,
    );
  }

  String? get tglBerdiriFormatted {
    if (tglBerdiri == null) return null;
    return _formatDate(tglBerdiri!);
  }

  static String _formatDate(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
