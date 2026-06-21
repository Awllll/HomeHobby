import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';
import '../../service/auth_service.dart';
import '../../service/firestore_service.dart';
import '../login_screen.dart';

class AppColors {
  static const deepRed = Color(0xFF832D25);
  static const pink = Color(0xFFEA6993);
  static const lightPink = Color(0xFFF8CAE4);
  static const sage = Color(0xFFCFDD9D);
  static const forest = Color(0xFF447A5F);
  static const bg = Color(0xFFFDF6F9);

  static const pinkShadow = Color(0x12EA6993);
}

class ProfilPelanggan extends StatefulWidget {
  const ProfilPelanggan({super.key});

  @override
  State<ProfilPelanggan> createState() => _ProfilPelangganState();
}

class _ProfilPelangganState extends State<ProfilPelanggan> {
  final _authService = AuthService();
  final _firestoreService = FirestoreService();
  final _picker = ImagePicker();
  final _namaController = TextEditingController();
  final _teleponController = TextEditingController();

  bool _isEditing = false;
  bool _isLoading = false;
  bool _isUploadingFoto = false;
  Map<String, dynamic> _userData = {};

  @override
  void initState() {
    super.initState();
    _loadProfil();
  }

  Future<void> _loadProfil() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      setState(() {
        _userData = doc.data() ?? {};
        _namaController.text = _userData['nama'] ?? '';
        _teleponController.text = _userData['noTelepon'] ?? '';
      });
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFB71C1C) : AppColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  //Upload Foto Profil
  Future<void> _pilihFotoProfil(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (file == null) return;

    setState(() => _isUploadingFoto = true);

    try {
      final base64String =
          await _firestoreService.gambarKeBase64(File(file.path));

      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'fotoProfil': base64String});

      if (!mounted) return;
      setState(() {
        _userData['fotoProfil'] = base64String;
      });
      _showSnack('Fotonya sudah di updatee!');
    } catch (e) {
      _showSnack('Gagal mengunggah foto: $e', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingFoto = false);
    }
  }

  Future<void> _showPilihSumberGambar() async {
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Pilih Sumber Foto',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.deepRed),
            ),
            const SizedBox(height: 16),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _pilihFotoProfil(ImageSource.camera);
              },
              leading: Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: AppColors.lightPink, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.deepRed),
              ),
              title: const Text('Ambil dari Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _pilihFotoProfil(ImageSource.gallery);
              },
              leading: Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: AppColors.lightPink, shape: BoxShape.circle),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.deepRed),
              ),
              title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simpanProfil() async {
    if (_namaController.text.isEmpty) {
      _showSnack('Nama tidak boleh kosong!', isError: true);
      return;
    }
    if (_teleponController.text.trim().length < 9) {
      _showSnack('Nomor telepon tidak valid!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({
        'nama': _namaController.text.trim(),
        'noTelepon': _teleponController.text.trim(),
      });

      if (!mounted) return;
      setState(() {
        _userData['nama'] = _namaController.text.trim();
        _userData['noTelepon'] = _teleponController.text.trim();
        _isEditing = false;
        _isLoading = false;
      });

      _showSnack('Profil berhasil diupdate!');
    }
  }

  Future<void> _logout() async {
    bool? konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.logout_rounded, color: AppColors.deepRed),
            SizedBox(width: 8),
            Text('Logout', style: TextStyle(color: AppColors.deepRed, fontWeight: FontWeight.bold)),
          ],
        ),
        content: Text(
          'Yakin nih mau keluar?',
          style: TextStyle(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Batal', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFB71C1C),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      await _authService.logout();
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  void dispose() {
    _namaController.dispose();
    _teleponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final fotoProfil = _userData['fotoProfil'] as String? ?? '';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.deepRed,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: const Text(
          'Profil',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.close_rounded : Icons.edit_outlined,
              color: Colors.white,
            ),
            onPressed: () {
              setState(() {
                _isEditing = !_isEditing;
                if (!_isEditing) {
                  _namaController.text = _userData['nama'] ?? '';
                  _teleponController.text = _userData['noTelepon'] ?? '';
                }
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            //Avatar + Upload Foto
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(18)),
                border: Border.fromBorderSide(BorderSide(color: AppColors.lightPink, width: 1)),
                boxShadow: [BoxShadow(color: AppColors.pinkShadow, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                children: [
                  GestureDetector(
                    onTap: (_isEditing && !_isUploadingFoto) ? _showPilihSumberGambar : null,
                    child: Stack(
                      children: [
                        Container(
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [AppColors.deepRed, AppColors.pink],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          padding: const EdgeInsets.all(3),
                          child: CircleAvatar(
                            radius: 45,
                            backgroundColor: Colors.white,
                            backgroundImage: fotoProfil.isNotEmpty
                                ? MemoryImage(base64Decode(fotoProfil))
                                : (user?.photoURL != null
                                    ? NetworkImage(user!.photoURL!)
                                    : null) as ImageProvider?,
                            child: fotoProfil.isEmpty && user?.photoURL == null
                                ? Text(
                                    (_userData['nama'] ?? 'P').toString().substring(0, 1).toUpperCase(),
                                    style: const TextStyle(
                                      fontSize: 34,
                                      color: AppColors.deepRed,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  )
                                : null,
                          ),
                        ),
                        // Overlay loading saat upload
                        if (_isUploadingFoto)
                          Positioned.fill(
                            child: Container(
                              decoration: const BoxDecoration(
                                color: Color(0x99000000), // black @ 60%
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: SizedBox(
                                  width: 22, height: 22,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        if (_isEditing)
                          Positioned(
                            right: 0,
                            bottom: 0,
                            child: Container(
                              width: 28, height: 28,
                              decoration: const BoxDecoration(
                                color: AppColors.deepRed,
                                shape: BoxShape.circle,
                                border: Border.fromBorderSide(BorderSide(color: Colors.white, width: 2)),
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 14),
                            ),
                          ),
                      ],
                    ),
                  ),
                  if (_isEditing) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Klik untuk mengubah foto',
                      style: TextStyle(color: Colors.grey.shade400, fontSize: 11),
                    ),
                  ],
                  const SizedBox(height: 14),
                  Text(
                    _userData['nama'] ?? 'Pelanggan',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            //Form Edit
            if (_isEditing) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.all(Radius.circular(16)),
                  border: Border.fromBorderSide(BorderSide(color: AppColors.lightPink, width: 1)),
                  boxShadow: [BoxShadow(color: AppColors.pinkShadow, blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Edit Profil',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.deepRed),
                    ),
                    const SizedBox(height: 16),

                    const Text(
                      'Nama Lengkap',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _namaController,
                      hint: 'Masukkan nama lengkap',
                      icon: Icons.person_outline_rounded,
                    ),

                    const SizedBox(height: 14),

                    const Text(
                      'Nomor Telepon',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: Color(0xFF1A1A1A)),
                    ),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _teleponController,
                      hint: 'Contoh: 081234567890',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(14),
                      ],
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _simpanProfil,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.deepRed,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                              )
                            : const Text('Simpan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            //Info Akun
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(16)),
                border: Border.fromBorderSide(BorderSide(color: AppColors.lightPink, width: 1)),
                boxShadow: [BoxShadow(color: AppColors.pinkShadow, blurRadius: 10, offset: Offset(0, 4))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Info Akun',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.deepRed),
                  ),
                  const Divider(height: 20, color: AppColors.lightPink),
                  _buildInfoRow(
                    icon: Icons.person_outline_rounded,
                    label: 'Nama',
                    value: _userData['nama'] ?? '-',
                  ),
                  const SizedBox(height: 14),
                  _buildInfoRow(
                    icon: Icons.email_outlined,
                    label: 'Email',
                    value: user?.email ?? '-',
                  ),
                  const SizedBox(height: 14),
                  _buildInfoRow(
                    icon: Icons.phone_outlined,
                    label: 'Nomor Telepon',
                    value: (_userData['noTelepon'] as String?)?.isNotEmpty == true
                        ? _userData['noTelepon']
                        : 'Belum diisi',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            //Tombol Logout
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                label: const Text(
                  'Logout',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFB71C1C),
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.deepRed),
        filled: true,
        fillColor: AppColors.bg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightPink),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightPink),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.deepRed, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Container(
          width: 36, height: 36,
          decoration: const BoxDecoration(
            color: AppColors.lightPink,
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 18, color: AppColors.deepRed),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 11)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A1A))),
            ],
          ),
        ),
      ],
    );
  }
}