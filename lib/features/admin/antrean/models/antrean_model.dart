class DetailOrder {
  final int idDetailOrders;
  final String merk;
  final String jenisSepatu;
  final String warna;
  final String? fotoSebelum;
  final String? fotoSesudah;
  final int idServices;
  final double totalHarga;
  final String? namaLayanan;

  DetailOrder({
    required this.idDetailOrders,
    required this.merk,
    required this.jenisSepatu,
    required this.warna,
    this.fotoSebelum,
    this.fotoSesudah,
    required this.idServices,
    required this.totalHarga,
    this.namaLayanan,
  });

  factory DetailOrder.fromJson(Map<String, dynamic> json) {
    // Handle nested services object from Supabase or dummy data
    int serviceId = json['id_services'] ?? 0;
    String? serviceName;
    
    if (json['services'] != null) {
      serviceId = json['services']['id_services'] ?? serviceId;
      serviceName = json['services']['nama_layanan'];
    }

    return DetailOrder(
      idDetailOrders: json['id_detail_orders'],
      merk: json['merk'] ?? '',
      jenisSepatu: json['jenis_sepatu'] ?? '',
      warna: json['warna'] ?? '',
      fotoSebelum: json['foto_sebelum'],
      fotoSesudah: json['foto_sesudah'],
      idServices: serviceId,
      totalHarga: (json['total_harga'] ?? 0).toDouble(),
      namaLayanan: serviceName,
    );
  }
}

class CustomerInfo {
  final int? idUser;
  final String nama;
  final String nomorHp;

  CustomerInfo({this.idUser, required this.nama, required this.nomorHp});

  factory CustomerInfo.fromJson(Map<String, dynamic> json) {
    return CustomerInfo(
      idUser: json['id_user'],
      nama: json['nama'] ?? '-',
      nomorHp: json['nomor_hp'] ?? '-',
    );
  }
}

class AntreanModel {
  final int idOrders;
  final String kodeOrder;
  final String statusOrder;
  final String statusPembayaran;
  final String? uploadBktByr;
  final String? alasanTolakPembayaran;
  final String? alasanPembatalan;
  final String tglOrder;
  final String? qrImage;
  final String? linkQr;
  final List<DetailOrder> detailOrders;
  final CustomerInfo? customer;

  AntreanModel({
    required this.idOrders,
    required this.kodeOrder,
    required this.statusOrder,
    required this.statusPembayaran,
    this.uploadBktByr,
    this.alasanTolakPembayaran,
    this.alasanPembatalan,
    required this.tglOrder,
    this.qrImage,
    this.linkQr,
    required this.detailOrders,
    this.customer,
  });

  factory AntreanModel.fromJson(Map<String, dynamic> json) {
    final details = (json['detail_orders'] as List<dynamic>? ?? [])
        .map((d) => DetailOrder.fromJson(d))
        .toList();
    
    CustomerInfo? cust;
    if (json['customers'] != null) {
      cust = CustomerInfo.fromJson(json['customers']);
    }

    return AntreanModel(
      idOrders: json['id_orders'],
      kodeOrder: json['kode_order'] ?? '',
      statusOrder: json['status_order'] ?? '',
      statusPembayaran: json['status_pembayaran'] ?? '',
      uploadBktByr: json['upload_bkt_byr']?.toString(),
      alasanTolakPembayaran: json['alasan_tolak_pembayaran']?.toString(),
      alasanPembatalan: json['alasan_pembatalan']?.toString(),
      tglOrder: json['tgl_order'] ?? '',
      qrImage: json['qr_image']?.toString(),
      linkQr: json['link_qr']?.toString(),
      detailOrders: details,
      customer: cust,
    );
  }

  DetailOrder? get detail => detailOrders.isNotEmpty ? detailOrders.first : null;
}
