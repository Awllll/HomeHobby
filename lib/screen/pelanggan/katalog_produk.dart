import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';
import 'dart:convert';
import 'dart:async';
import '../../model/produk_model.dart';
import '../../service/firestore_service.dart';
import 'detail_produk.dart';
import 'notifikasi.dart';
import 'katalog_kategori.dart';

class AppColors {
  static const deepRed = Color(0xFF832D25);
  static const pink = Color(0xFFEA6993);
  static const lightPink = Color(0xFFF8CAE4);
  static const sage = Color(0xFFCFDD9D);
  static const forest = Color(0xFF447A5F);
  static const bg = Color(0xFFFDF6F9);

  static const whiteCircle = Color(0x33FFFFFF);
  static const pinkShadow  = Color(0x12EA6993);
  static const deepRedDot  = Color(0x4D832D25);
}

// Banner promo
class _BannerPromo {
  final String judul;
  final String subjudul;
  final List<Color> gradient;
  const _BannerPromo({
    required this.judul,
    required this.subjudul,
    required this.gradient,
  });
}

const List<_BannerPromo> _daftarBanner = [
  _BannerPromo(
    judul: 'Promo Merchandise!',
    subjudul: 'Diskon hingga 20% untuk pemesanan custom',
    gradient: [AppColors.deepRed, AppColors.pink],
  ),
  _BannerPromo(
    judul: 'Gratis Desain',
    subjudul: 'Konsultasi desain gratis untuk pesanan ≥ 50 pcs',
    gradient: [AppColors.forest, AppColors.sage],
  ),
  _BannerPromo(
    judul: 'Produk Baru!',
    subjudul: 'Cek koleksi Standee terbaru kami',
    gradient: [AppColors.pink, AppColors.lightPink],
  ),
];

Map<String, IconData> _ikonKategori = {
  'Stiker': MdiIcons.sticker,
  'Poster': Icons.photo_size_select_actual_outlined,
  'Hand Banner': Icons.flag_outlined,
  'Pin': Icons.workspace_premium_outlined,
  'Gantungan Kunci': MdiIcons.keyChainVariant,
  'Standee': Icons.directions_walk_rounded,
};

class _BannerCarousel extends StatefulWidget {
  const _BannerCarousel();

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final PageController _bannerController = PageController();
  int _bannerIndex = 0;
  Timer? _bannerTimer;

  @override
  void initState() {
    super.initState();
    _mulaiAutoSlideBanner();
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    super.dispose();
  }

  void _mulaiAutoSlideBanner() {
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_bannerIndex + 1) % _daftarBanner.length;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Column(
        children: [
          SizedBox(
            height: 160,
            child: PageView.builder(
              controller: _bannerController,
              itemCount: _daftarBanner.length,
              onPageChanged: (index) => setState(() => _bannerIndex = index),
              itemBuilder: (context, index) {
                final banner = _daftarBanner[index];
                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: banner.gradient,
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        banner.judul.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        banner.subjudul,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          // Dot indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_daftarBanner.length, (index) {
              final isActive = index == _bannerIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: isActive ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: isActive ? AppColors.deepRed : AppColors.deepRedDot,
                  borderRadius: BorderRadius.circular(3),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class KatalogProduk extends StatefulWidget {
  const KatalogProduk({super.key});

  @override
  State<KatalogProduk> createState() => _KatalogProdukState();
}

class _KatalogProdukState extends State<KatalogProduk> {
  final FirestoreService _firestoreService = FirestoreService();
  final TextEditingController _searchController = TextEditingController();

  String _namaPelanggan = '';
  String _searchQuery = '';
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _getNamaPelanggan();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _getNamaPelanggan() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!mounted) return;
      setState(() {
        _namaPelanggan = doc['nama'] ?? 'Pelanggan';
      });
    }
  }

  // Hitung jumlah notifikasi yang belum dibaca (dibaca == false)
  Stream<int> _streamJumlahNotifBelumDibaca() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(0);
    return FirebaseFirestore.instance
        .collection('notifikasi')
        .where('userId', isEqualTo: uid)
        .where('dibaca', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  String _formatHarga(int harga) =>
      'Rp ${harga.toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (m) => '${m[1]}.',
      )}';

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
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            //Header: sapaan + notifikasi
            SliverToBoxAdapter(child: _buildHeader()),

            //Search Bar
            SliverToBoxAdapter(child: _buildSearchBar()),

            //Banner Promo Carousel
            const SliverToBoxAdapter(child: _BannerCarousel()),

            //Grid Kategori
            SliverToBoxAdapter(child: _buildKategoriGrid()),

            //Judul "Produk Popular"
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16, 8, 16, 8),
                child: Text(
                  'Produk Popular',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.deepRed,
                  ),
                ),
              ),
            ),

            //Grid Produk
            _buildProdukGridSliver(),
          ],
        ),
      ),
    );
  }

  //Header
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.deepRed, AppColors.pink],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Helloww, $_namaPelanggan! 👋',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                const Text(
                  'Mau pesan merchandise lucu apa hari ini?',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Ikon search 
          GestureDetector(
            onTap: () {
              setState(() => _isSearchActive = !_isSearchActive);
              if (!_isSearchActive) {
                _searchController.clear();
                _searchQuery = '';
              }
            },
            child: Container(
              width: 42, height: 42,
              decoration: const BoxDecoration(
                color: AppColors.whiteCircle,
                borderRadius: BorderRadius.all(Radius.circular(12)),
              ),
              child: Icon(
                _isSearchActive ? Icons.close_rounded : Icons.search_rounded,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotifikasiPage()),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: const BoxDecoration(
                    color: AppColors.whiteCircle,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: const Icon(Icons.notifications_outlined, color: Colors.white),
                ),
                // Badge jumlah notifikasi yang belum dibaca
                StreamBuilder<int>(
                  stream: _streamJumlahNotifBelumDibaca(),
                  builder: (context, snapshot) {
                    final jumlah = snapshot.data ?? 0;
                    if (jumlah == 0) return const SizedBox.shrink();
                    return Positioned(
                      top: -4,
                      right: -4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                        constraints: const BoxConstraints(minWidth: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFB71C1C),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        child: Text(
                          jumlah > 9 ? '9+' : '$jumlah',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  //Search Bar
  Widget _buildSearchBar() {
    if (!_isSearchActive) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.lightPink, width: 1),
            ),
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (value) => setState(() => _searchQuery = value.trim().toLowerCase()),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Cari produk atau kategori...',
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.deepRed),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.close_rounded, color: Colors.grey.shade400, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty) _buildSearchSuggestions(),
        ],
      ),
    );
  }

  // Daftar suggestion hasil pencarian
  Widget _buildSearchSuggestions() {
    return StreamBuilder<List<ProdukModel>>(
      stream: _firestoreService.streamProduk(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(child: CircularProgressIndicator(color: AppColors.deepRed)),
          );
        }

        final semuaProduk = snapshot.data ?? [];
        final hasil = semuaProduk.where((p) {
          final cocokNama = p.nama.toLowerCase().contains(_searchQuery);
          final cocokKategori = p.kategori.toLowerCase().contains(_searchQuery);
          return cocokNama || cocokKategori;
        }).toList();

        if (hasil.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Tidak ada hasil untuk "$_searchQuery"',
                style: TextStyle(color: Colors.grey.shade400, fontSize: 13),
              ),
            ),
          );
        }

        return Container(
          margin: const EdgeInsets.only(top: 10),
          constraints: const BoxConstraints(maxHeight: 320),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: hasil.length,
            separatorBuilder: (_, __) => Divider(height: 1, color: Colors.grey.shade100),
            itemBuilder: (context, index) {
              final produk = hasil[index];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () {
                  setState(() => _isSearchActive = false);
                  _searchController.clear();
                  _searchQuery = '';
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => DetailProduk(produk: produk)),
                  );
                },
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildGambar(base64String: produk.gambarBase64, width: 44, height: 44),
                ),
                title: Text(
                  produk.nama,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${produk.kategori} • ${_formatHarga(produk.harga)}',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                ),
              );
            },
          ),
        );
      },
    );
  }

  //Grid Kategori Bundar
  Widget _buildKategoriGrid() {
    final kategoriList = ProdukModel.kategoriList;
    final barisAtas = kategoriList.sublist(0, 3);
    final barisBawah = kategoriList.sublist(3, 6);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: Column(
        children: [
          Row(
            children: barisAtas.map((k) => _kategoriItem(k)).toList(),
          ),
          const SizedBox(height: 18),
          Row(
            children: barisBawah.map((k) => _kategoriItem(k)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _kategoriItem(String kategori) {
    final ikon = _ikonKategori[kategori] ?? Icons.category_rounded;
    return Expanded(
      child: GestureDetector(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => KatalogKategori(kategori: kategori, ikon: ikon),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.lightPink,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(ikon, color: AppColors.deepRed, size: 34),
            ),
            const SizedBox(height: 8),
            Text(
              kategori,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1A1A1A),
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Grid Produk (Sliver)
  Widget _buildProdukGridSliver() {
    return StreamBuilder<List<ProdukModel>>(
      stream: _firestoreService.streamProdukPopuler(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: CircularProgressIndicator(color: AppColors.deepRed),
            ),
          );
        }

        final produkList = snapshot.data ?? [];

        if (produkList.isEmpty) {
          return const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.lightPink,
                    child: Icon(Icons.inventory_2_outlined, size: 38, color: AppColors.pink),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Maaf ya, produknya masih dalam maintenance :(',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.deepRed,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildProdukCard(produkList[index]),
              childCount: produkList.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildProdukCard(ProdukModel produk) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => DetailProduk(produk: produk)),
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(14)),
          border: Border.fromBorderSide(BorderSide(color: AppColors.lightPink, width: 1)),
          boxShadow: [BoxShadow(color: AppColors.pinkShadow, blurRadius: 8, offset: Offset(0, 3))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  topRight: Radius.circular(14),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: _buildGambar(base64String: produk.gambarBase64),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.lightPink,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      produk.kategori,
                      style: const TextStyle(
                          fontSize: 9, color: AppColors.deepRed, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    produk.nama,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _formatHarga(produk.harga),
                    style: const TextStyle(
                        color: AppColors.forest, fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}