import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screen/login_screen.dart';
import 'kelola_produk.dart';
import 'kelola_pesanan.dart';

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Ambil jumlah data dari Firestore
  Stream<int> _streamJumlah(String collection) {
    return _firestore
        .collection(collection)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  // Ambil jumlah pesanan berdasarkan status
  Stream<int> _streamPesananStatus(String status) {
    return _firestore
        .collection('pesanan')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        title: const Text(
          'Dashboard Admin',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
            tooltip: 'Logout',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Sapaan Admin
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6C63FF), Color(0xFF9C8FFF)],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selamat Datang, Admin! 👋',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Kelola produk dan pesanan HomeHobby',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Statistik
            const Text(
              'Ringkasan',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Card Statistik
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Total Produk',
                    stream: _streamJumlah('produk'),
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF6C63FF),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    label: 'Total Pesanan',
                    stream: _streamJumlah('pesanan'),
                    icon: Icons.shopping_cart_outlined,
                    color: const Color(0xFFFF6584),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Pesanan Baru',
                    stream: _streamPesananStatus('pending'),
                    icon: Icons.new_releases_outlined,
                    color: const Color(0xFFFFB347),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    label: 'Selesai',
                    stream: _streamPesananStatus('selesai'),
                    icon: Icons.check_circle_outline,
                    color: const Color(0xFF43D19E),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Menu Admin
            const Text(
              'Menu',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),

            // Kelola Produk
            _buildMenuCard(
              icon: Icons.inventory_2_outlined,
              title: 'Kelola Produk',
              subtitle: 'Tambah, edit, dan hapus produk',
              color: const Color(0xFF6C63FF),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KelolaProduk()),
              ),
            ),

            const SizedBox(height: 12),

            // Kelola Pesanan
            _buildMenuCard(
              icon: Icons.shopping_cart_outlined,
              title: 'Kelola Pesanan',
              subtitle: 'Lihat dan update status pesanan',
              color: const Color(0xFFFF6584),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KelolaPesanan()),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget Card Statistik
  Widget _buildStatCard({
    required String label,
    required Stream<int> stream,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snapshot) {
              return Text(
                '${snapshot.data ?? 0}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              );
            },
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  // Widget Card Menu
  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}