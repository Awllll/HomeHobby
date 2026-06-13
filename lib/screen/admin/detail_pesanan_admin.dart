import 'package:flutter/material.dart';
import 'dart:convert';
import '../../model/pesanan_model.dart';
import '../../service/firestore_service.dart';

class DetailPesananAdmin extends StatefulWidget {
  final PesananModel pesanan;
  const DetailPesananAdmin({super.key, required this.pesanan});

  @override
  State<DetailPesananAdmin> createState() => _DetailPesananAdminState();
}

class _DetailPesananAdminState extends State<DetailPesananAdmin> {
  final FirestoreService _firestoreService = FirestoreService();
  late String _statusSaatIni;

  @override
  void initState() {
    super.initState();
    _statusSaatIni = widget.pesanan.status;
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

  String _formatHarga(int harga) {
    return 'Rp ${harga.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    )}';
  }

  String _formatTanggal(DateTime date) {
    return '${date.day}/${date.month}/${date.year} '
        '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
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

  Future<void> _updateStatus(String statusBaru) async {
    try {
      await _firestoreService.updateStatusPesanan(
        widget.pesanan.id,
        statusBaru,
        widget.pesanan.produkNama,
        widget.pesanan.pelangganId,
        produkId: widget.pesanan.produkId,
        jumlah: widget.pesanan.jumlah,
      );

      setState(() => _statusSaatIni = statusBaru);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Status diubah ke "$statusBaru"'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      print('ERROR UPDATE STATUS: $e');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _showUbahStatus() async {
    if (_statusSaatIni == 'dibatalkan') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan yang dibatalkan tidak bisa diubah!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_statusSaatIni == 'selesai') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pesanan yang sudah selesai tidak bisa diubah!'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ubah Status Pesanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...PesananModel.statusList.map((status) {
              final isSelected = status == _statusSaatIni;

              bool shouldShow = true;
              if (_statusSaatIni == 'pending' &&
                  (status == 'selesai' || status == 'dikirim')) {
                shouldShow = false;
              }
              if (_statusSaatIni == 'diproses' &&
                  status == 'pending') {
                shouldShow = false;
              }
              if (_statusSaatIni == 'dikirim' &&
                  (status == 'pending' || status == 'diproses')) {
                shouldShow = false;
              }

              if (!shouldShow) return const SizedBox.shrink();

              return ListTile(
                onTap: () {
                  Navigator.pop(context);
                  if (status != _statusSaatIni) _updateStatus(status);
                },
                leading: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: _warnaStatus(status),
                    shape: BoxShape.circle,
                  ),
                ),
                title: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    fontWeight: isSelected
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: isSelected
                        ? const Color(0xFF6C63FF)
                        : Colors.black,
                  ),
                ),
                trailing: isSelected
                    ? const Icon(Icons.check,
                        color: Color(0xFF6C63FF))
                    : null,
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pesanan = widget.pesanan;
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Status Pesanan',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _warnaStatus(_statusSaatIni)
                              .withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _statusSaatIni[0].toUpperCase() +
                              _statusSaatIni.substring(1),
                          style: TextStyle(
                            color: _warnaStatus(_statusSaatIni),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _statusSaatIni == 'dibatalkan' ||
                                _statusSaatIni == 'selesai'
                            ? null  
                            : _showUbahStatus,
                        icon: const Icon(Icons.edit, size: 16),
                        label: Text(
                          _statusSaatIni == 'dibatalkan'
                              ? 'Dibatalkan'
                              : _statusSaatIni == 'selesai'
                                  ? 'Selesai'
                                  : 'Ubah Status',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _statusSaatIni == 'dibatalkan'
                              ? Colors.red
                              : _statusSaatIni == 'selesai'
                                  ? Colors.green
                                  : const Color(0xFF6C63FF),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSection(
              title: 'Info Produk',
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildGambar(
                      base64String: pesanan.produkGambar,
                      width: 70,
                      height: 70,
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
                            fontSize: 15,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          pesanan.kategori,
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _formatHarga(pesanan.harga),
                          style: const TextStyle(
                            color: Color(0xFF6C63FF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSection(
              title: 'Info Pesanan',
              child: Column(
                children: [
                  _buildInfoRow('ID Pesanan',
                      '#${pesanan.id.substring(0, 8).toUpperCase()}'),
                  _buildInfoRow('Jumlah', '${pesanan.jumlah} pcs'),
                  _buildInfoRow(
                      'Harga Satuan', _formatHarga(pesanan.harga)),
                  _buildInfoRow(
                      'Total', _formatHarga(pesanan.totalHarga),
                      isBold: true),
                  _buildInfoRow(
                      'Tanggal', _formatTanggal(pesanan.createdAt)),
                  if (pesanan.catatan.isNotEmpty)
                    _buildInfoRow('Catatan', pesanan.catatan),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _buildSection(
              title: 'Info Pelanggan',
              child: Column(
                children: [
                  _buildInfoRow('Nama', pesanan.pelangganNama),
                  _buildInfoRow('Email', pesanan.pelangganEmail),
                   _buildInfoRow('Alamat', pesanan.pelangganAlamat), 
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const Divider(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value,
      {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight:
                  isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
              color:
                  isBold ? const Color(0xFF6C63FF) : Colors.black,
            ),
          ),
        ],
      ),
    );
  }
}