import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';


class NotifikasiPage extends StatelessWidget {
  const NotifikasiPage({super.key});

  String formatTanggal(Timestamp? timestamp) {
    if (timestamp == null) return '';

    final date = timestamp.toDate();

    const namaBulan = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${date.day} ${namaBulan[date.month - 1]} ${date.year} • '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }


  @override
  Widget build(BuildContext context) {

    final uid =
        FirebaseAuth.instance.currentUser!.uid;


    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
      ),


      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('notifikasi')
            .where(
              'userId',
              isEqualTo: uid,
            )
            .orderBy(
              'createdAt',
              descending: true,
            )
            .snapshots(),

        builder: (context, snapshot) {

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'ERROR: ${snapshot.error}',
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }


          final data = snapshot.data!.docs;


          if (data.isEmpty) {
            return const Center(
              child: Text('Belum ada notifikasi'),
            );
          }


          return ListView.builder(
            itemCount: data.length,
            itemBuilder: (context, index) {

              final item =
                  data[index].data()
                  as Map<String, dynamic>;

              return ListTile(
                leading: const Icon(
                  Icons.notifications,
                ),
                title: Text(
                  item['judul'] ?? '',
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    Text(
                      item['pesan'] ?? '',
                    ),

                    const SizedBox(height: 5),

                    Text(
                      formatTanggal(item['createdAt']),
                      style: const TextStyle(
                        fontSize: 11,
                        color: Colors.grey,
                      ),
                    ),

                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}