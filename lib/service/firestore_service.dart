import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io';
import 'dart:convert';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../model/produk_model.dart';
import '../model/pesanan_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<String> gambarKeBase64(File file) async {
    if (kIsWeb) {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    }

    final compressed = await FlutterImageCompress.compressWithFile(
      file.absolute.path,
      quality: 60,
      minWidth: 800,
      minHeight: 800,
    );

    if (compressed == null) {
      final bytes = await file.readAsBytes();
      return base64Encode(bytes);
    }

    return base64Encode(compressed);
  }

  //PRODUK
  Stream<List<ProdukModel>> streamProduk() {
    return _firestore
        .collection('produk')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => ProdukModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<ProdukModel>> streamProdukByKategori(String kategori) {
    return _firestore
        .collection('produk')
        .where('kategori', isEqualTo: kategori)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => ProdukModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<ProdukModel>> streamProdukPopuler() {
    return _firestore.collection('produk').snapshots().asyncMap((produkSnap) async {
      final produkList = produkSnap.docs
          .map((doc) => ProdukModel.fromMap(doc.data(), doc.id))
          .toList();

      final pesananSnap = await _firestore.collection('pesanan').get();

      final Map<String, int> totalTerjual = {};
      for (final doc in pesananSnap.docs) {
        final data = doc.data();
        final produkId = data['produkId'] as String?;
        final jumlah = (data['jumlah'] as num?)?.toInt() ?? 0;
        if (produkId == null) continue;
        totalTerjual[produkId] = (totalTerjual[produkId] ?? 0) + jumlah;
      }

      produkList.sort((a, b) {
        final terjualA = totalTerjual[a.id] ?? 0;
        final terjualB = totalTerjual[b.id] ?? 0;
        if (terjualB != terjualA) return terjualB.compareTo(terjualA);
        return b.createdAt.compareTo(a.createdAt);
      });

      return produkList;
    });
  }

  Future<void> tambahProduk(ProdukModel produk) async {
    await _firestore.collection('produk').add(produk.toMap());
  }

  Future<void> editProduk(String id, Map<String, dynamic> data) async {
    await _firestore.collection('produk').doc(id).update(data);
  }

  Future<void> hapusProduk(String id) async {
    await _firestore.collection('produk').doc(id).delete();
  }

  // Kurangi stok saat pesanan masuk
  Future<void> kurangiStok(String produkId, int jumlah) async {
    await _firestore.collection('produk').doc(produkId).update({
      'stok': FieldValue.increment(-jumlah),
    });
  }

  // Tambah stok kembali saat pesanan dibatalkan
  Future<void> tambahStok(String produkId, int jumlah) async {
    await _firestore.collection('produk').doc(produkId).update({
      'stok': FieldValue.increment(jumlah),
    });
  }

  //PESANAN
  Stream<List<PesananModel>> streamSemuaPesanan() {
    return _firestore
        .collection('pesanan')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => PesananModel.fromMap(doc.data(), doc.id))
            .toList());
  }

  Stream<List<PesananModel>> streamPesananByStatus(String status) {
    return _firestore
        .collection('pesanan')
        .where('status', isEqualTo: status)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => PesananModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  Stream<List<PesananModel>> streamPesananPelanggan(String pelangganId) {
    return _firestore
        .collection('pesanan')
        .where('pelangganId', isEqualTo: pelangganId)
        .snapshots()
        .map((snap) {
          final list = snap.docs
              .map((doc) => PesananModel.fromMap(doc.data(), doc.id))
              .toList();
          list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
          return list;
        });
  }

  // Tambah pesanan + kurangi stok otomatis
  Future<void> tambahPesanan(PesananModel pesanan) async {
    // Cek stok dulu
    DocumentSnapshot produkDoc = await _firestore
        .collection('produk')
        .doc(pesanan.produkId)
        .get();

    int stokSaatIni = produkDoc['stok'] ?? 0;

    if (stokSaatIni < pesanan.jumlah) {
      throw Exception('Stok tidak mencukupi!');
    }

    // Simpan pesanan
    await _firestore.collection('pesanan').add(pesanan.toMap());

    // Kurangi stok otomatis
    await kurangiStok(pesanan.produkId, pesanan.jumlah);
  }

  // Update status pesanan + handle stok + notifikasi
  Future<void> updateStatusPesanan(
    String pesananId,
    String status,
    String namaProduk,
    String pelangganId, {
    String? produkId,
    int? jumlah,
  }) async {
    final doc =
        await _firestore.collection('pesanan').doc(pesananId).get();

    final statusLama = doc['status'];

    if (statusLama != 'dibatalkan' &&
        status == 'dibatalkan' &&
        produkId != null &&
        jumlah != null) {
      await tambahStok(produkId, jumlah);
    }

    await _firestore.collection('pesanan').doc(pesananId).update({
      'status': status,
    });

    await _firestore.collection('notifikasi').add({
      'userId': pelangganId,
      'judul': 'Status Pesanan',
      'pesan':
          'Pesanan $namaProduk sekarang $status',
      'dibaca': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}