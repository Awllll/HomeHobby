import 'package:flutter/material.dart';
import 'dart:convert';
import '../../model/pesanan_model.dart';
import '../../service/firestore_service.dart';

class AppColors {
  static const deepRed = Color(0xFF832D25);
  static const pink = Color(0xFFEA6993);
  static const lightPink = Color(0xFFF8CAE4);
  static const sage = Color(0xFFCFDD9D);
  static const forest = Color(0xFF447A5F);
  static const bg = Color(0xFFFDF6F9);

  static const pinkBorder = Color(0x1AEA6993);
  static const pinkShadow = Color(0x12EA6993);
  static const greyDivider = Color(0xFFE0E0E0);
}

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
      '${date.month.toString().padLeft(2, '0')}/${date.year}  '
      '${date.hour.toString().padLeft(2, '0')}:'
      '${date.minute.toString().padLeft(2, '0')}';

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

  Future<void> _updateStatus(String statusBaru) async {
    try {
      await _firestoreService.updateStatusPesanan(
        widget.pesanan.id, statusBaru,
        widget.pesanan.produkNama, widget.pesanan.pelangganId,
        produkId: widget.pesanan.produkId,
        jumlah: widget.pesanan.jumlah,
      );
      setState(() => _statusSaatIni = statusBaru);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Status diubah ke "$statusBaru"'),
        backgroundColor: AppColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Error: $e'),
        backgroundColor: const Color(0xFFB71C1C),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
    }
  }

  Future<void> _showUbahStatus() async {
    if (_statusSaatIni == 'dibatalkan' || _statusSaatIni == 'selesai') {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_statusSaatIni == 'dibatalkan'
            ? 'Pesanan yang dibatalkan tidak bisa diubah!'
            : 'Pesanan yang sudah selesai tidak bisa diubah!'),
        backgroundColor: AppColors.pink,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ));
      return;
    }

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
              'Ubah Status Pesanan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.deepRed,
              ),
            ),
            const SizedBox(height: 16),
            ...PesananModel.statusList.map((status) {
              final isSelected = status == _statusSaatIni;
              bool show = true;
              if (_statusSaatIni == 'pending' &&
                  (status == 'selesai' || status == 'dikirim')) show = false;
              if (_statusSaatIni == 'diproses' && status == 'pending') show = false;
              if (_statusSaatIni == 'dikirim' &&
                  (status == 'pending' || status == 'diproses')) show = false;
              if (!show) return const SizedBox.shrink();

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: isSelected ? _accentStatus(status) : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? _warnaStatus(status) : Colors.grey.shade200,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: ListTile(
                  onTap: () {
                    Navigator.pop(context);
                    if (status != _statusSaatIni) _updateStatus(status);
                  },
                  leading: Container(
                    width: 10, height: 10,
                    decoration: BoxDecoration(
                      color: _warnaStatus(status),
                      shape: BoxShape.circle,
                    ),
                  ),
                  title: Text(
                    status[0].toUpperCase() + status.substring(1),
                    style: TextStyle(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? _warnaStatus(status) : Colors.black87,
                    ),
                  ),
                  trailing: isSelected
                      ? Icon(Icons.check_circle_rounded, color: _warnaStatus(status))
                      : null,
                ),
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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.deepRed,
        elevation: 0,
        title: const Text(
          'Detail Pesanan',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            //Status
            _buildSection(
              title: 'Status Pesanan',
              titleIcon: Icons.info_outline_rounded,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _accentStatus(_statusSaatIni),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: BoxDecoration(
                            color: _warnaStatus(_statusSaatIni),
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _statusSaatIni[0].toUpperCase() + _statusSaatIni.substring(1),
                          style: TextStyle(
                            color: _warnaStatus(_statusSaatIni),
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _statusSaatIni == 'dibatalkan' || _statusSaatIni == 'selesai'
                        ? null
                        : _showUbahStatus,
                    icon: const Icon(Icons.edit_rounded, size: 15),
                    label: Text(
                      _statusSaatIni == 'dibatalkan'
                          ? 'Dibatalkan'
                          : _statusSaatIni == 'selesai'
                              ? 'Selesai'
                              : 'Ubah Status',
                      style: const TextStyle(fontSize: 13),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _statusSaatIni == 'dibatalkan'
                          ? const Color(0xFFB71C1C)
                          : _statusSaatIni == 'selesai'
                              ? AppColors.forest
                              : AppColors.deepRed,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            //Info Produk
            _buildSection(
              title: 'Info Produk',
              titleIcon: Icons.inventory_2_rounded,
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: _buildGambar(
                        base64String: pesanan.produkGambar, width: 76, height: 76),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pesanan.produkNama,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1A1A1A)),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.lightPink,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            pesanan.kategori,
                            style: const TextStyle(
                                color: AppColors.deepRed, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _formatHarga(pesanan.harga),
                          style: const TextStyle(
                              color: AppColors.forest, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            //Info Pesanan
            _buildSection(
              title: 'Info Pesanan',
              titleIcon: Icons.receipt_long_rounded,
              child: Column(
                children: [
                  _buildInfoRow('ID Pesanan', '#${pesanan.id.substring(0, 8).toUpperCase()}'),
                  _buildInfoRow('Jumlah', '${pesanan.jumlah} pcs'),
                  _buildInfoRow('Harga Satuan', _formatHarga(pesanan.harga)),
                  _buildInfoRowBold('Total', _formatHarga(pesanan.totalHarga)),
                  _buildInfoRow('Tanggal', _formatTanggal(pesanan.createdAt)),
                  if (pesanan.catatan.isNotEmpty)
                    _buildInfoRow('Catatan', pesanan.catatan),
                ],
              ),
            ),
            const SizedBox(height: 12),

            //Info Pelanggan
            _buildSection(
              title: 'Info Pelanggan',
              titleIcon: Icons.person_rounded,
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
    required IconData titleIcon,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.all(Radius.circular(16)),
        boxShadow: [BoxShadow(color: AppColors.pinkShadow, blurRadius: 10, offset: Offset(0, 4))],
        border: Border.fromBorderSide(BorderSide(color: AppColors.lightPink, width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.circle, size: 8, color: AppColors.deepRed),
              const SizedBox(width: 6),
              Icon(titleIcon, size: 16, color: AppColors.deepRed),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.deepRed),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.lightPink),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade500, fontSize: 13)),
          const SizedBox(width: 12),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(fontSize: 13, color: Color(0xFF1A1A1A))),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRowBold(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(value,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.forest)),
        ],
      ),
    );
  }
}