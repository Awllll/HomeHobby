import 'package:flutter/material.dart';
import 'dart:convert';
import '../../model/pesanan_model.dart';
import '../../service/firestore_service.dart';
import 'detail_pesanan_admin.dart';

class AppColors {
  static const deepRed = Color(0xFF832D25);
  static const pink = Color(0xFFEA6993);
  static const lightPink = Color(0xFFF8CAE4);
  static const sage = Color(0xFFCFDD9D);
  static const forest = Color(0xFF447A5F);
  static const bg = Color(0xFFFDF6F9);

  static const pinkShadow = Color(0x12EA6993);
  static const lightPinkFaded  = Color(0x66F8CAE4);
}

class KelolaPesanan extends StatefulWidget {
  const KelolaPesanan({super.key});

  @override
  State<KelolaPesanan> createState() => _KelolaPesananState();
}

class _KelolaPesananState extends State<KelolaPesanan> {
  final FirestoreService _firestoreService = FirestoreService();
  String _selectedStatus = 'Semua';

  final List<String> _filterStatus = [
    'Semua', 'pending', 'diproses', 'dikirim', 'selesai', 'dibatalkan',
  ];

  Color _warnaStatus(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFE8A020);
      case 'diproses': return AppColors.pink;
      case 'dikirim': return AppColors.deepRed;
      case 'selesai': return AppColors.forest;
      case 'dibatalkan': return const Color(0xFFB71C1C);
      default: return Colors.grey;
    }
  }

  Color _accentStatus(String status) {
    switch (status) {
      case 'pending': return const Color(0xFFFFF3D6);
      case 'diproses': return AppColors.lightPink;
      case 'dikirim': return AppColors.lightPink;
      case 'selesai': return AppColors.sage;
      case 'dibatalkan': return const Color(0xFFFFEBEE);
      default: return const Color(0xFFF5F5F5);
    }
  }

  String _formatHarga(int harga) =>
      'Rp ${harga.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

  String _formatTanggal(DateTime date) =>
      '${date.day.toString().padLeft(2, '0')}/'
      '${date.month.toString().padLeft(2, '0')}/${date.year}';

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.deepRed,
        elevation: 0,
        title: const Text(
          'Kelola Pesanan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
              itemCount: _filterStatus.length,
              itemBuilder: (context, index) {
                final status = _filterStatus[index];
                final isSelected = status == _selectedStatus;
                final chipColor =
                    status == 'Semua' ? AppColors.deepRed : _warnaStatus(status);
                return GestureDetector(
                  onTap: () => setState(() => _selectedStatus = status),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: isSelected ? chipColor : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected ? chipColor : Colors.grey.shade300,
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      status == 'Semua'
                          ? 'Semua'
                          : status[0].toUpperCase() + status.substring(1),
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

          //List
          Expanded(
            child: StreamBuilder<List<PesananModel>>(
              stream: _selectedStatus == 'Semua'
                  ? _firestoreService.streamSemuaPesanan()
                  : _firestoreService.streamPesananByStatus(_selectedStatus),
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
                          child: const Icon(Icons.shopping_bag_outlined,
                              size: 38, color: AppColors.pink),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Belum ada pesanan',
                          style: TextStyle(
                            color: AppColors.deepRed,
                            fontWeight: FontWeight.w600,
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Pesanan akan muncul di sini',
                          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                final list = snapshot.data!;
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (_, i) => _buildPesananCard(list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPesananCard(PesananModel pesanan) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailPesananAdmin(pesanan: pesanan)),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          border: Border.fromBorderSide(BorderSide(color: AppColors.lightPink, width: 1)),
          boxShadow: [BoxShadow(color: AppColors.pinkShadow, blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          children: [
            //Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: const BoxDecoration(
                color: AppColors.lightPinkFaded,
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.receipt_rounded, size: 14, color: AppColors.deepRed),
                      const SizedBox(width: 6),
                      Text(
                        '#${pesanan.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.deepRed,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _accentStatus(pesanan.status),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6, height: 6,
                          decoration: BoxDecoration(
                            color: _warnaStatus(pesanan.status),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          pesanan.status[0].toUpperCase() + pesanan.status.substring(1),
                          style: TextStyle(
                            color: _warnaStatus(pesanan.status),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            //Body
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildGambar(
                        base64String: pesanan.produkGambar, width: 64, height: 64),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pesanan.produkNama,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${pesanan.jumlah} pcs × ${_formatHarga(pesanan.harga)}',
                          style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatHarga(pesanan.totalHarga),
                          style: const TextStyle(
                            color: AppColors.forest,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, color: AppColors.pink, size: 22),
                ],
              ),
            ),

            //Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: const BoxDecoration(
                color: Color(0xFFFAFAFA),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                border: Border(top: BorderSide(color: AppColors.lightPink, width: 1)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.person_outline_rounded,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(pesanan.pelangganNama,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                  Row(
                    children: [
                      Icon(Icons.calendar_today_rounded,
                          size: 13, color: Colors.grey.shade400),
                      const SizedBox(width: 4),
                      Text(_formatTanggal(pesanan.createdAt),
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}