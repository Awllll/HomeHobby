class UserModel {
  final String uid;
  final String nama;
  final String email;
  final String role;
  final String noTelepon;
  final String fotoProfil;

  UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.role,
    this.noTelepon = '',
    this.fotoProfil = '',
  });

  // Ambil data dari Firestore → jadi object UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'pelanggan',
      noTelepon: map['noTelepon'] ?? '',
      fotoProfil: map['fotoProfil'] ?? '',
    );
  }

  // Ubah object UserModel → jadi Map untuk disimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'email': email,
      'role': role,
      'noTelepon': noTelepon,
      'fotoProfil': fotoProfil,
    };
  }
}