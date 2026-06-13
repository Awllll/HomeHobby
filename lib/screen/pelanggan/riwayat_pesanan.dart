import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';
import 'detail_pesanan_pelanggan.dart';
import '../../model/pesanan_model.dart';
import '../../service/firestore_service.dart';

class RiwayatPesanan extends StatefulWidget {
  const RiwayatPesanan({super.key});

  @override
  State<RiwayatPesanan> createState() => _RiwayatPesananState();
}

class _RiwayatPesananState extends State<RiwayatPesanan> {
  final FirestoreService _firestoreService = FirestoreService();
  final String _pelangganId =
      FirebaseAuth.instance.currentUser?.uid ?? '';

  String _formatHarga(int harga) {
    return 'Rp ${harga.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  String _formatTanggal(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  Color _warnaStatus(String status) {
    switch (status) {
      case 'pending': return Colors.orange;
      case 'diproses': return Colors.blue;
      case 'dikirim': return Colors.purple;
      case 'selesai': return Colors.green;
      case 'dibatalkan': return Colors.red;
      default: return Colors.grey;
    }
  }

  IconData _ikonStatus(String status) {
    switch (status) {
      case 'pending': return Icons.access_time;
      case 'diproses': return Icons.settings_outlined;
      case 'dikirim': return Icons.local_shipping_outlined;
      case 'selesai': return Icons.check_circle_outline;
      case 'dibatalkan': return Icons.cancel_outlined;
      default: return Icons.help_outline;
    }
  }

  Widget _buildGambar({
    required String base64String,
    double? width,
    double? height,
    BoxFit fit = BoxFit.cover,
  }) {
    try {
      if (base64String.isEmpty) {
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_outlined, color: Colors.grey),
        );
      }
      return Image.memory(
        base64Decode(base64String),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (_, __, ___) => Container(
          width: width,
          height: height,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_outlined, color: Colors.grey),
        ),
      );
    } catch (e) {
      return Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_outlined, color: Colors.grey),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        automaticallyImplyLeading: false,
        title: const Text(
          'Riwayat Pesanan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: StreamBuilder<List<PesananModel>>(
        stream: _firestoreService.streamPesananPelanggan(_pelangganId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada pesanan',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Yuk mulai pesan merchandise!',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            );
          }
          final pesananList = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pesananList.length,
            itemBuilder: (context, index) {
              return _buildPesananCard(pesananList[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildPesananCard(PesananModel pesanan) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => DetailPesananPelanggan(pesanan: pesanan),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: _warnaStatus(pesanan.status).withOpacity(0.05),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '#${pesanan.id.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                Row(
                  children: [
                    Icon(
                      _ikonStatus(pesanan.status),
                      size: 14,
                      color: _warnaStatus(pesanan.status),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      pesanan.status[0].toUpperCase() +
                          pesanan.status.substring(1),
                      style: TextStyle(
                        color: _warnaStatus(pesanan.status),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildGambar(
                    base64String: pesanan.produkGambar,
                    width: 65,
                    height: 65,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pesanan.produkNama,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${pesanan.jumlah} pcs × ${_formatHarga(pesanan.harga)}',
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatHarga(pesanan.totalHarga),
                        style: const TextStyle(
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 12, color: Colors.grey.shade400),
                const SizedBox(width: 4),
                Text(
                  _formatTanggal(pesanan.createdAt),
                  style: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 12,
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