import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import '../../model/produk_model.dart';
import '../../model/pesanan_model.dart';
import '../../service/firestore_service.dart';

class AppColors {
  static const deepRed = Color(0xFF832D25);
  static const pink = Color(0xFFEA6993);
  static const lightPink = Color(0xFFF8CAE4);
  static const sage = Color(0xFFCFDD9D);
  static const forest = Color(0xFF447A5F);
  static const bg = Color(0xFFFDF6F9);
}

class DetailProduk extends StatefulWidget {
  final ProdukModel produk;
  const DetailProduk({super.key, required this.produk});

  @override
  State<DetailProduk> createState() => _DetailProdukState();
}

class _DetailProdukState extends State<DetailProduk> {
  final _catatanController = TextEditingController();
  final _alamatController = TextEditingController();
  final _firestoreService = FirestoreService();
  int _jumlah = 1;
  bool _isLoading = false;

  String _formatHarga(int harga) =>
      'Rp ${harga.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  Widget _buildGambar({
    required String base64String,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    try {
      if (base64String.isEmpty) return _imgPlaceholder(width, height);
      return Image.memory(
        base64Decode(base64String),
        width: width, height: height, fit: fit,
        errorBuilder: (_, __, ___) => _imgPlaceholder(width, height),
      );
    } catch (_) {
      return _imgPlaceholder(width, height);
    }
  }

  Widget _imgPlaceholder(double? w, double? h) => Container(
        width: w, height: h,
        color: AppColors.lightPink,
        child: const Icon(Icons.image_outlined, size: 64, color: AppColors.pink),
      );

  void _showSnack(String message, {bool isError = true}) {
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

  Future<void> _pesan() async {
    if (_alamatController.text.isEmpty) {
      _showSnack('Alamat pengiriman harus diisi!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      final pesanan = PesananModel(
        id: '',
        pelangganId: user.uid,
        pelangganNama: doc['nama'] ?? '',
        pelangganEmail: user.email ?? '',
        pelangganAlamat: _alamatController.text.trim(),
        produkId: widget.produk.id,
        produkNama: widget.produk.nama,
        produkGambar: widget.produk.gambarBase64,
        kategori: widget.produk.kategori,
        harga: widget.produk.harga,
        jumlah: _jumlah,
        totalHarga: widget.produk.harga * _jumlah,
        catatan: _catatanController.text.trim(),
        status: 'pending',
        createdAt: DateTime.now(),
      );

      await _firestoreService.tambahPesanan(pesanan);
      if (!mounted) return;
      setState(() => _isLoading = false);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(
                  color: AppColors.sage,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.forest, size: 44),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pesanan Berhasil!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.deepRed),
              ),
              const SizedBox(height: 8),
              Text(
                'Pesanan kamu sedang diproses oleh admin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepRed,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Oke', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnack(
        e.toString().contains('Stok tidak mencukupi')
            ? 'Stok tidak mencukupi!'
            : 'Gagal memesan, coba lagi!',
      );
    }
  }

  @override
  void dispose() {
    _catatanController.dispose();
    _alamatController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final produk = widget.produk;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: AppColors.deepRed,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Detail Produk',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: double.infinity,
              height: 280,
              child: _buildGambar(
                base64String: produk.gambarBase64,
                width: double.infinity,
                height: 280,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  //Badge Kategori
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.lightPink,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      produk.kategori,
                      style: const TextStyle(
                          color: AppColors.deepRed, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 10),

                  //Nama & Harga
                  Text(
                    produk.nama,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _formatHarga(produk.harga),
                        style: const TextStyle(
                            fontSize: 20, color: AppColors.forest, fontWeight: FontWeight.bold),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: produk.stok > 0 ? AppColors.sage : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          produk.stok > 0 ? 'Stok: ${produk.stok}' : 'Stok Habis',
                          style: TextStyle(
                            color: produk.stok > 0 ? AppColors.forest : const Color(0xFFB71C1C),
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),

                  Divider(height: 28, color: AppColors.lightPink),

                  //Deskripsi
                  const Text(
                    'Deskripsi',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.deepRed),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    produk.deskripsi,
                    style: TextStyle(color: Colors.grey.shade600, height: 1.5),
                  ),

                  Divider(height: 28, color: AppColors.lightPink),

                  //Jumlah
                  const Text(
                    'Jumlah',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.deepRed),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.lightPink,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (_jumlah > 1) setState(() => _jumlah--);
                          },
                          icon: const Icon(Icons.remove_rounded),
                          color: AppColors.deepRed,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          border: Border.all(color: AppColors.deepRed),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '$_jumlah',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                      Container(
                        decoration: const BoxDecoration(
                          color: AppColors.lightPink,
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          onPressed: () {
                            if (_jumlah < produk.stok) {
                              setState(() => _jumlah++);
                            } else {
                              _showSnack('Jumlah melebihi stok!');
                            }
                          },
                          icon: const Icon(Icons.add_rounded),
                          color: AppColors.deepRed,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Total: ${_formatHarga(produk.harga * _jumlah)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.forest),
                      ),
                    ],
                  ),

                  Divider(height: 28, color: AppColors.lightPink),

                  //Alamat Pengiriman
                  const Text(
                    'Alamat Pengiriman',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.deepRed),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _alamatController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Masukkan alamat lengkap pengiriman...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(bottom: 40),
                        child: Icon(Icons.location_on_outlined, color: AppColors.deepRed),
                      ),
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
                  ),

                  Divider(height: 28, color: AppColors.lightPink),

                  //Catatan
                  const Text(
                    'Catatan (opsional)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.deepRed),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _catatanController,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Contoh: ukuran A3, warna dominan biru...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
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
                  ),

                  const SizedBox(height: 28),

                  //Tombol Pesan
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading || produk.stok == 0 ? null : _pesan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: produk.stok == 0 ? Colors.grey : AppColors.deepRed,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              produk.stok == 0 ? 'Stok Habis' : 'Pesan Sekarang',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}