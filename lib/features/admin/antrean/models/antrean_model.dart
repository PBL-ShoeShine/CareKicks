class DetailOrder {
  final int idDetailOrders;
  final String merk;
  final String jenisSepatu;
  final String warna;
  final String? fotoSebelum;
  final String? fotoSesudah;
  final int idServices;
  final double totalHarga;

  DetailOrder({
    required this.idDetailOrders,
    required this.merk,
    required this.jenisSepatu,
    required this.warna,
    this.fotoSebelum,
    this.fotoSesudah,
    required this.idServices,
    required this.totalHarga,
  });

  factory DetailOrder.fromJson(Map<String, dynamic> json) {
    return DetailOrder(
      idDetailOrders: json['id_detail_orders'],
      merk: json['merk'] ?? '',
      jenisSepatu: json['jenis_sepatu'] ?? '',
      warna: json['warna'] ?? '',
      fotoSebelum: json['foto_sebelum'],
      fotoSesudah: json['foto_sesudah'],
      idServices: json['id_services'] ?? 0,
      totalHarga: (json['total_harga'] ?? 0).toDouble(),
    );
  }
}

class AntreanModel {
  final int idOrders;
  final String kodeOrder;
  final String statusOrder;
  final String tglOrder;
  final List<DetailOrder> detailOrders;

  AntreanModel({
    required this.idOrders,
    required this.kodeOrder,
    required this.statusOrder,
    required this.tglOrder,
    required this.detailOrders,
  });

  factory AntreanModel.fromJson(Map<String, dynamic> json) {
    final details = (json['detail_orders'] as List<dynamic>? ?? [])
        .map((d) => DetailOrder.fromJson(d))
        .toList();
    return AntreanModel(
      idOrders: json['id_orders'],
      kodeOrder: json['kode_order'] ?? '',
      statusOrder: json['status_order'] ?? '',
      tglOrder: json['tgl_order'] ?? '',
      detailOrders: details,
    );
  }

  DetailOrder? get detail => detailOrders.isNotEmpty ? detailOrders.first : null;
}