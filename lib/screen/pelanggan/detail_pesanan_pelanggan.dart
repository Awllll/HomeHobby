import 'package:flutter/material.dart';
import 'dart:convert';
import '../../model/pesanan_model.dart';

class AppColors {
  static const deepRed = Color(0xFF832D25);
  static const pink = Color(0xFFEA6993);
  static const lightPink = Color(0xFFF8CAE4);
  static const sage = Color(0xFFCFDD9D);
  static const forest = Color(0xFF447A5F);
  static const bg = Color(0xFFFDF6F9);

  static const redBg      = Color(0x1AB71C1C);
  static const pinkShadow = Color(0x12EA6993);
}

class DetailPesananPelanggan extends StatelessWidget {
  final PesananModel pesanan;
  const DetailPesananPelanggan({super.key, required this.pesanan});

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

  @override
  Widget build(BuildContext context) {
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
            //Status Pesanan
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.lightPink, width: 1),
                boxShadow: const [
                  BoxShadow(color: AppColors.pinkShadow, blurRadius: 10, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: AppColors.deepRed),
                      SizedBox(width: 6),
                      Text(
                        'Status Pesanan',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.deepRed,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Progress Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusStep('Pending', Icons.access_time_rounded, 'pending', pesanan.status),
                      _buildGaris(pesanan.status, 'pending'),
                      _buildStatusStep('Diproses', Icons.settings_outlined, 'diproses', pesanan.status),
                      _buildGaris(pesanan.status, 'diproses'),
                      _buildStatusStep('Dikirim', Icons.local_shipping_outlined, 'dikirim', pesanan.status),
                      _buildGaris(pesanan.status, 'dikirim'),
                      _buildStatusStep('Selesai', Icons.check_circle_outline_rounded, 'selesai', pesanan.status),
                    ],
                  ),

                  if (pesanan.status == 'dibatalkan') ...[
                    const SizedBox(height: 14),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.redBg,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.cancel_outlined, color: Color(0xFFB71C1C), size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Pesanan Dibatalkan',
                            style: TextStyle(
                              color: Color(0xFFB71C1C),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                    child: _buildGambar(base64String: pesanan.produkGambar, width: 70, height: 70),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pesanan.produkNama,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
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

            //Alamat Pengiriman
            _buildSection(
              title: 'Alamat Pengiriman',
              titleIcon: Icons.location_on_rounded,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined, color: AppColors.deepRed, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pesanan.pelangganAlamat.isNotEmpty ? pesanan.pelangganAlamat : '-',
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusStep(String label, IconData icon, String step, String statusSaatIni) {
    final statusOrder = ['pending', 'diproses', 'dikirim', 'selesai'];
    final stepIndex = statusOrder.indexOf(step);
    final currentIndex = statusOrder.indexOf(statusSaatIni);
    final isActive = currentIndex >= stepIndex;
    final isCancelled = statusSaatIni == 'dibatalkan';

    return Column(
      children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isCancelled
                ? Colors.grey.shade200
                : isActive ? AppColors.deepRed : AppColors.lightPink,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isCancelled
                ? Colors.grey
                : isActive ? Colors.white : AppColors.pink,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isCancelled ? Colors.grey : isActive ? AppColors.deepRed : Colors.grey,
            fontWeight: isActive && !isCancelled ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildGaris(String statusSaatIni, String step) {
    final statusOrder = ['pending', 'diproses', 'dikirim', 'selesai'];
    final stepIndex = statusOrder.indexOf(step);
    final currentIndex = statusOrder.indexOf(statusSaatIni);
    final isActive = currentIndex > stepIndex;
    final isCancelled = statusSaatIni == 'dibatalkan';

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        color: isCancelled
            ? Colors.grey.shade300
            : isActive ? AppColors.deepRed : Colors.grey.shade300,
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
        border: Border.fromBorderSide(BorderSide(color: AppColors.lightPink, width: 1)),
        boxShadow: [BoxShadow(color: AppColors.pinkShadow, blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(titleIcon, size: 16, color: AppColors.deepRed),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.deepRed),
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
              style: TextStyle(color: Colors.grey.shade500, fontSize: 13, fontWeight: FontWeight.w600)),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.forest)),
        ],
      ),
    );
  }
}