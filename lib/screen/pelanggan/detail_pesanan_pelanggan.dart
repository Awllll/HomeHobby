import 'package:flutter/material.dart';
import 'dart:convert';
import '../../model/pesanan_model.dart';

class DetailPesananPelanggan extends StatelessWidget {
  final PesananModel pesanan;
  const DetailPesananPelanggan({super.key, required this.pesanan});

  // ignore: unused_element
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

  @override
  Widget build(BuildContext context) {
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
            // Status Pesanan
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

                  // Progress Status
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatusStep('Pending',
                          Icons.access_time, 'pending', pesanan.status),
                      _buildGaris(pesanan.status, 'pending'),
                      _buildStatusStep('Diproses',
                          Icons.settings_outlined, 'diproses', pesanan.status),
                      _buildGaris(pesanan.status, 'diproses'),
                      _buildStatusStep('Dikirim',
                          Icons.local_shipping_outlined, 'dikirim', pesanan.status),
                      _buildGaris(pesanan.status, 'dikirim'),
                      _buildStatusStep('Selesai',
                          Icons.check_circle_outline, 'selesai', pesanan.status),
                    ],
                  ),

                  if (pesanan.status == 'dibatalkan') ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.cancel_outlined,
                              color: Colors.red, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'Pesanan Dibatalkan',
                            style: TextStyle(
                              color: Colors.red,
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

            // Info Produk
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

            // Info Pesanan
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

            // Alamat Pengiriman
            _buildSection(
              title: 'Alamat Pengiriman',
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: Color(0xFF6C63FF), size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pesanan.pelangganAlamat.isNotEmpty
                          ? pesanan.pelangganAlamat
                          : '-',
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

  Widget _buildStatusStep(
    String label,
    IconData icon,
    String step,
    String statusSaatIni,
  ) {
    final statusOrder = [
      'pending', 'diproses', 'dikirim', 'selesai'
    ];
    final stepIndex = statusOrder.indexOf(step);
    final currentIndex = statusOrder.indexOf(statusSaatIni);
    final isActive = currentIndex >= stepIndex;
    final isCancelled = statusSaatIni == 'dibatalkan';

    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: isCancelled
                ? Colors.grey.shade200
                : isActive
                    ? const Color(0xFF6C63FF)
                    : Colors.grey.shade200,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isCancelled
                ? Colors.grey
                : isActive
                    ? Colors.white
                    : Colors.grey,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isCancelled
                ? Colors.grey
                : isActive
                    ? const Color(0xFF6C63FF)
                    : Colors.grey,
            fontWeight: isActive && !isCancelled
                ? FontWeight.bold
                : FontWeight.normal,
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
        color: isCancelled
            ? Colors.grey.shade300
            : isActive
                ? const Color(0xFF6C63FF)
                : Colors.grey.shade300,
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