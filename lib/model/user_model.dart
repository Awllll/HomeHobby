class UserModel {
  final String uid;
  final String nama;
  final String email;
  final String role;

  UserModel({
    required this.uid,
    required this.nama,
    required this.email,
    required this.role,
  });

  // Ambil data dari Firestore → jadi object UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      nama: map['nama'] ?? '',
      email: map['email'] ?? '',
      role: map['role'] ?? 'pelanggan',
    );
  }

  // Ubah object UserModel → jadi Map untuk disimpan ke Firestore
  Map<String, dynamic> toMap() {
    return {
      'nama': nama,
      'email': email,
      'role': role,
    };
  }
}