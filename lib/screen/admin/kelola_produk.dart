import 'package:flutter/material.dart';
import 'dart:convert';
import '../../model/produk_model.dart';
import '../../service/firestore_service.dart';
import 'tambah_produk.dart';

class AppColors {
  static const deepRed = Color(0xFF832D25);
  static const pink = Color(0xFFEA6993);
  static const lightPink = Color(0xFFF8CAE4);
  static const sage = Color(0xFFCFDD9D);
  static const forest = Color(0xFF447A5F);
  static const bg = Color(0xFFFDF6F9);

  static const pinkShadow = Color(0x12EA6993);
}

class KelolaProduk extends StatefulWidget {
  const KelolaProduk({super.key});

  @override
  State<KelolaProduk> createState() => _KelolaProdukState();
}

class _KelolaProdukState extends State<KelolaProduk> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedKategori = 'Semua';

  final List<String> _filterKategori = ['Semua', ...ProdukModel.kategoriList];

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
        child: const Icon(Icons.image_outlined, color: AppColors.pink),
      );

  Future<void> _hapusProduk(ProdukModel produk) async {
    bool? konfirmasi = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: const [
            Icon(Icons.warning_rounded, color: AppColors.deepRed),
            SizedBox(width: 8),
            Text(
              'Hapus Produk',
              style: TextStyle(
                color: AppColors.deepRed,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        content: Text(
          'Yakin ingin menghapus "${produk.nama}"?\nTindakan ini tidak dapat dibatalkan.',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
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
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (konfirmasi == true) {
      await _firestoreService.hapusProduk(produk.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Produk berhasil dihapus!'),
          backgroundColor: const Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.deepRed,
        elevation: 0,
        title: const Text(
          'Kelola Produk',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const TambahProduk()),
        ),
        backgroundColor: AppColors.forest,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text(
          'Tambah Produk',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        elevation: 4,
      ),
      body: Column(
        children: [
          //Filter Chips
          Container(
            height: 54,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _filterKategori.length,
              itemBuilder: (context, index) {
                final kategori = _filterKategori[index];
                final isSelected = kategori == _selectedKategori;
                return GestureDetector(
                  onTap: () => setState(() => _selectedKategori = kategori),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.deepRed : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? AppColors.deepRed : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      kategori,
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade600,
                        fontSize: 12,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          //Product List
          Expanded(
            child: StreamBuilder<List<ProdukModel>>(
              stream: _selectedKategori == 'Semua'
                  ? _firestoreService.streamProduk()
                  : _firestoreService.streamProdukByKategori(_selectedKategori),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.deepRed),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80, height: 80,
                          decoration: const BoxDecoration(
                            color: AppColors.lightPink,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.inventory_2_outlined,
                              size: 38, color: AppColors.pink),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada produk',
                          style: TextStyle(
                            color: AppColors.deepRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Tambahkan produk pertama Anda',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                final list = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _buildProdukCard(list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProdukCard(ProdukModel produk) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        border: Border.fromBorderSide(BorderSide(color: AppColors.lightPink, width: 1)),
        boxShadow: [BoxShadow(color: AppColors.pinkShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          //Gambar
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(16),
              bottomLeft: Radius.circular(16),
            ),
            child: _buildGambar(
                base64String: produk.gambarBase64, width: 94, height: 94),
          ),

          //Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: const BoxDecoration(
                      color: AppColors.lightPink,
                      borderRadius: BorderRadius.all(Radius.circular(8)),
                    ),
                    child: Text(
                      produk.kategori,
                      style: const TextStyle(
                        fontSize: 10,
                        color: AppColors.deepRed,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    produk.nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Color(0xFF1A1A1A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Rp ${produk.harga.toString().replaceAllMapped(
                      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                      (m) => '${m[1]}.',
                    )}',
                    style: const TextStyle(
                      color: AppColors.forest,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          //Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Column(
              children: [
                Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.lightPink,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.edit_rounded, color: AppColors.deepRed, size: 17),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => TambahProduk(produk: produk)),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: 36, height: 36,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFFEBEE),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    icon: const Icon(Icons.delete_rounded, color: Color(0xFFB71C1C), size: 17),
                    onPressed: () => _hapusProduk(produk),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}