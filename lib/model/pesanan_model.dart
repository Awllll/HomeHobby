class PesananModel {
  final String id;
  final String pelangganId;
  final String pelangganNama;
  final String pelangganEmail;
  final String pelangganAlamat; 
  final String produkId;
  final String produkNama;
  final String produkGambar;
  final String kategori;
  final int harga;
  final int jumlah;
  final int totalHarga;
  final String catatan;
  final String status;
  final DateTime createdAt;

  static const List<String> statusList = [
    'pending',
    'diproses',
    'dikirim',
    'selesai',
    'dibatalkan',
  ];

  PesananModel({
    required this.id,
    required this.pelangganId,
    required this.pelangganNama,
    required this.pelangganEmail,
    required this.pelangganAlamat,
    required this.produkId,
    required this.produkNama,
    required this.produkGambar,
    required this.kategori,
    required this.harga,
    required this.jumlah,
    required this.totalHarga,
    required this.catatan,
    required this.status,
    required this.createdAt,
  });

  factory PesananModel.fromMap(Map<String, dynamic> map, String id) {
    return PesananModel(
      id: id,
      pelangganId: map['pelangganId'] ?? '',
      pelangganNama: map['pelangganNama'] ?? '',
      pelangganEmail: map['pelangganEmail'] ?? '',
      pelangganAlamat: map['pelangganAlamat'] ?? '',
      produkId: map['produkId'] ?? '',
      produkNama: map['produkNama'] ?? '',
      produkGambar: map['produkGambar'] ?? '',
      kategori: map['kategori'] ?? '',
      harga: map['harga'] ?? 0,
      jumlah: map['jumlah'] ?? 0,
      totalHarga: map['totalHarga'] ?? 0,
      catatan: map['catatan'] ?? '',
      status: map['status'] ?? 'pending',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'pelangganId': pelangganId,
      'pelangganNama': pelangganNama,
      'pelangganEmail': pelangganEmail,
      'pelangganAlamat': pelangganAlamat,
      'produkId': produkId,
      'produkNama': produkNama,
      'produkGambar': produkGambar,
      'kategori': kategori,
      'harga': harga,
      'jumlah': jumlah,
      'totalHarga': totalHarga,
      'catatan': catatan,
      'status': status,
      'createdAt': createdAt,
    };
  }
}