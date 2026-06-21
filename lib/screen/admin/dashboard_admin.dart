import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../screen/login_screen.dart';
import 'kelola_produk.dart';
import 'kelola_pesanan.dart';

class AppColors {
  static const deepRed = Color(0xFF832D25);
  static const pink = Color(0xFFEA6993);
  static const lightPink = Color(0xFFF8CAE4);
  static const sage = Color(0xFFCFDD9D);
  static const forest = Color(0xFF447A5F);
  static const bg = Color(0xFFFDF6F9);

  static const pinkShadow = Color(0x59EA6993);
  static const whiteSurface = Color(0x26FFFFFF);
  static const deepRedShadow = Color(0x14832D25);
  static const forestShadow = Color(0x12447A5F);
  static const pinkShadowLight = Color(0x12EA6993);
}

class DashboardAdmin extends StatefulWidget {
  const DashboardAdmin({super.key});

  @override
  State<DashboardAdmin> createState() => _DashboardAdminState();
}

class _DashboardAdminState extends State<DashboardAdmin> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<int> _streamJumlah(String collection) => _firestore
      .collection(collection)
      .snapshots()
      .map((s) => s.docs.length);

  Stream<int> _streamPesananStatus(String status) => _firestore
      .collection('pesanan')
      .where('status', isEqualTo: status)
      .snapshots()
      .map((s) => s.docs.length);

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
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.deepRed,
        elevation: 0,
        title: const Text(
          'Dashboard Admin',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.white),
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
            //Hero Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.deepRed, AppColors.pink],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: AppColors.pinkShadow,
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Welcome Back,',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Minchy Cantik 🫰',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 6),
                        Text(
                          'Semangat kerjanya!!!',
                          style: TextStyle(color: Colors.white60, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: const BoxDecoration(
                      color: AppColors.whiteSurface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.admin_panel_settings_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            _sectionLabel('Ringkasan'),
            const SizedBox(height: 12),

            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    label: 'Total Produk',
                    stream: _streamJumlah('produk'),
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.deepRed,
                    accent: AppColors.lightPink,
                    shadow: AppColors.deepRedShadow,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    label: 'Total Pesanan',
                    stream: _streamJumlah('pesanan'),
                    icon: Icons.shopping_bag_rounded,
                    color: AppColors.forest,
                    accent: AppColors.sage,
                    shadow: AppColors.forestShadow,
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
                    icon: Icons.fiber_new_rounded,
                    color: AppColors.pink,
                    accent: AppColors.lightPink,
                    shadow: AppColors.pinkShadowLight,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    label: 'Selesai',
                    stream: _streamPesananStatus('selesai'),
                    icon: Icons.check_circle_rounded,
                    color: AppColors.forest,
                    accent: AppColors.sage,
                    shadow: AppColors.forestShadow,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            _sectionLabel('Menu'),
            const SizedBox(height: 12),

            _buildMenuCard(
              icon: Icons.inventory_2_rounded,
              title: 'Kelola Produk',
              subtitle: 'Tambah, edit, dan hapus produk',
              color: AppColors.deepRed,
              accent: AppColors.lightPink,
              shadow: AppColors.deepRedShadow,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KelolaProduk()),
              ),
            ),
            const SizedBox(height: 12),
            _buildMenuCard(
              icon: Icons.shopping_bag_rounded,
              title: 'Kelola Pesanan',
              subtitle: 'Lihat dan update status pesanan',
              color: AppColors.forest,
              accent: AppColors.sage,
              shadow: AppColors.forestShadow,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const KelolaPesanan()),
              ),
            ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.deepRed,
          letterSpacing: 0.2,
        ),
      );

  Widget _buildStatCard({
    required String label,
    required Stream<int> stream,
    required IconData icon,
    required Color color,
    required Color accent,
    required Color shadow,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: shadow, blurRadius: 10, offset: const Offset(0, 4))],
        border: Border.all(color: accent, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 10),
          StreamBuilder<int>(
            stream: stream,
            builder: (context, snapshot) => Text(
              '${snapshot.data ?? 0}',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color accent,
    required Color shadow,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accent, width: 1.2),
            boxShadow: [BoxShadow(color: shadow, blurRadius: 10, offset: const Offset(0, 4))],
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(14)),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                    ),
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                child: Icon(Icons.arrow_forward_ios_rounded, size: 13, color: color),
              ),
            ],
          ),
        ),
      ),
    );
  }
}