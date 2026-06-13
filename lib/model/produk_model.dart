class ProdukModel {
  final String id;
  final String nama;
  final String kategori;
  final String deskripsi;
  final int harga;
  final int stok; 
  final String gambarBase64;
  final DateTime createdAt;

  static const List<String> kategoriList = [
    'Stiker',
    'Poster',
    'Hand Banner',
    'Pin',
    'Gantungan Kunci',
    'Standee',
  ];

  ProdukModel({
    required this.id,
    required this.nama,
    required this.kategori,
    required this.deskripsi,
    required this.harga,
    required this.stok,
    required this.gambarBase64,
    required this.createdAt,
  });

  factory ProdukModel.fromMap(Map<String, dynamic> map, String id) {
    return ProdukModel(
      id: id,
      nama: map['nama'] ?? '',
      kategori: map['kategori'] ?? '',
      deskripsi: map['deskripsi'] ?? '',
      harga: map['harga'] ?? 0,
      stok: map['stok'] ?? 0,
      gambarBase64: map['gambarBase64'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'kategori': kategori,
      'deskripsi': deskripsi,
      'harga': harga,
      'stok': stok,
      'gambarBase64': gambarBase64,
      'createdAt': createdAt,
    };
  }
}