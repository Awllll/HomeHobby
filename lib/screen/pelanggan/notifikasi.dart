import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class AppColors {
  static const deepRed = Color(0xFF832D25);
  static const pink = Color(0xFFEA6993);
  static const lightPink = Color(0xFFF8CAE4);
  static const sage = Color(0xFFCFDD9D);
  static const forest = Color(0xFF447A5F);
  static const bg = Color(0xFFFDF6F9);

  static const pinkShadow = Color(0x12EA6993);
  static const pinkTint   = Color(0x0DEA6993);
}

class NotifikasiPage extends StatelessWidget {
  const NotifikasiPage({super.key});

  String _formatTanggal(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();

    const namaBulan = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
    ];

    return '${date.day} ${namaBulan[date.month - 1]} ${date.year} • '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  // Tandai satu notifikasi sebagai sudah dibaca saat di-tap
  Future<void> _tandaiSudahDibaca(String docId) async {
    await FirebaseFirestore.instance
        .collection('notifikasi')
        .doc(docId)
        .update({'dibaca': true});
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.deepRed,
        elevation: 0,
        title: const Text(
          'Notifikasi',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifikasi')
            .where('userId', isEqualTo: uid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('ERROR: ${snapshot.error}'));
          }

          if (!snapshot.hasData || snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: AppColors.deepRed),
            );
          }

          final data = snapshot.data!.docs;

          if (data.isEmpty) {
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
                    child: const Icon(Icons.notifications_none_rounded, size: 38, color: AppColors.pink),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Belum ada notifikasi',
                    style: TextStyle(color: AppColors.deepRed, fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.length,
            itemBuilder: (context, index) {
              final doc = data[index];
              final item = doc.data() as Map<String, dynamic>;
              final bool sudahDibaca = item['dibaca'] == true;

              return GestureDetector(
                onTap: () {
                  if (!sudahDibaca) _tandaiSudahDibaca(doc.id);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: sudahDibaca ? Colors.white : AppColors.pinkTint,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: sudahDibaca ? AppColors.lightPink : AppColors.pink,
                      width: sudahDibaca ? 1 : 1.4,
                    ),
                    boxShadow: const [
                      BoxShadow(color: AppColors.pinkShadow, blurRadius: 8, offset: Offset(0, 3)),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            width: 40, height: 40,
                            decoration: const BoxDecoration(
                              color: AppColors.lightPink,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.notifications_rounded, color: AppColors.deepRed, size: 20),
                          ),
                          // Titik merah kecil untuk notifikasi belum dibaca
                          if (!sudahDibaca)
                            Positioned(
                              top: -2,
                              right: -2,
                              child: Container(
                                width: 11, height: 11,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFB71C1C),
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.white, width: 1.5),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['judul'] ?? '',
                              style: TextStyle(
                                fontWeight: sudahDibaca ? FontWeight.w600 : FontWeight.bold,
                                fontSize: 14,
                                color: const Color(0xFF1A1A1A),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              item['pesan'] ?? '',
                              style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _formatTanggal(item['createdAt']),
                              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}