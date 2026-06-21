import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../../model/produk_model.dart';
import '../../service/firestore_service.dart';

class AppColors {
  static const deepRed = Color(0xFF832D25);
  static const pink = Color(0xFFEA6993);
  static const lightPink = Color(0xFFF8CAE4);
  static const sage = Color(0xFFCFDD9D);
  static const forest = Color(0xFF447A5F);
  static const bg = Color(0xFFFDF6F9);

  static const pinkShadow = Color(0x12EA6993);
}

class TambahProduk extends StatefulWidget {
  final ProdukModel? produk; // null = tambah baru, non-null = edit
  const TambahProduk({super.key, this.produk});

  @override
  State<TambahProduk> createState() => _TambahProdukState();
}

class _TambahProdukState extends State<TambahProduk> {
  final _formKey = GlobalKey<FormState>();
  final FirestoreService _firestoreService = FirestoreService();
  final ImagePicker _picker = ImagePicker();

  late TextEditingController _namaCtrl;
  late TextEditingController _hargaCtrl;
  late TextEditingController _deskripsiCtrl;
  late TextEditingController _stokCtrl;

  String _selectedKategori = ProdukModel.kategoriList.first;
  String _gambarBase64 = '';
  bool _isLoading = false;

  bool get _isEdit => widget.produk != null;

  @override
  void initState() {
    super.initState();
    final p = widget.produk;
    _namaCtrl = TextEditingController(text: p?.nama ?? '');
    _hargaCtrl = TextEditingController(text: p != null ? p.harga.toString() : '');
    _deskripsiCtrl = TextEditingController(text: p?.deskripsi ?? '');
    _stokCtrl = TextEditingController(text: p != null ? p.stok.toString() : '');
    _selectedKategori = p?.kategori ?? ProdukModel.kategoriList.first;
    _gambarBase64 = p?.gambarBase64 ?? '';
  }

  @override
  void dispose() {
    _namaCtrl.dispose();
    _hargaCtrl.dispose();
    _deskripsiCtrl.dispose();
    _stokCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? file = await _picker.pickImage(
      source: source,
      imageQuality: 90,
    );
    if (file == null) return;

    setState(() => _isLoading = true);
    try {
      final base64String =
          await _firestoreService.gambarKeBase64(File(file.path));
      if (!mounted) return;
      setState(() => _gambarBase64 = base64String);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memproses gambar: $e'),
          backgroundColor: const Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _showPilihSumberGambar() async {
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
              'Pilih Sumber Gambar',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.deepRed),
            ),
            const SizedBox(height: 16),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
              leading: Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: AppColors.lightPink, shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt_rounded, color: AppColors.deepRed),
              ),
              title: const Text('Ambil dari Kamera', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            ListTile(
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
              leading: Container(
                width: 40, height: 40,
                decoration: const BoxDecoration(color: AppColors.lightPink, shape: BoxShape.circle),
                child: const Icon(Icons.photo_library_rounded, color: AppColors.deepRed),
              ),
              title: const Text('Pilih dari Galeri', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _simpan() async {
    if (!_formKey.currentState!.validate()) return;
    if (_gambarBase64.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Pilih gambar produk terlebih dahulu'),
          backgroundColor: AppColors.pink,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final namaBaru = _namaCtrl.text.trim();
      final hargaBaru = int.parse(_hargaCtrl.text.replaceAll('.', ''));
      final deskripsiBaru = _deskripsiCtrl.text.trim();
      final stokBaru = int.parse(_stokCtrl.text);

      if (_isEdit) {
        await _firestoreService.editProduk(widget.produk!.id, {
          'nama': namaBaru,
          'harga': hargaBaru,
          'deskripsi': deskripsiBaru,
          'kategori': _selectedKategori,
          'gambarBase64': _gambarBase64,
          'stok': stokBaru,
        });
      } else {
        final produkBaru = ProdukModel(
          id: '',
          nama: namaBaru,
          harga: hargaBaru,
          deskripsi: deskripsiBaru,
          kategori: _selectedKategori,
          gambarBase64: _gambarBase64,
          stok: stokBaru,
          createdAt: DateTime.now(),
        );
        await _firestoreService.tambahProduk(produkBaru);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Produk berhasil diperbarui!' : 'Produk berhasil ditambahkan!'),
          backgroundColor: AppColors.forest,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: const Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.deepRed,
        elevation: 0,
        title: Text(
          _isEdit ? 'Edit Produk' : 'Tambah Produk',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              //Gambar
              _sectionLabel('Foto Produk'),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: _showPilihSumberGambar,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _gambarBase64.isEmpty
                          ? AppColors.lightPink
                          : AppColors.forest,
                      width: 1.5,
                    ),
                    boxShadow: const [
                      BoxShadow(
                        color: AppColors.pinkShadow,
                        blurRadius: 8,
                        offset: Offset(0, 3),
                      ),
                    ],
                  ),
                  child: _gambarBase64.isEmpty
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(Icons.add_photo_alternate_rounded,
                                size: 48, color: AppColors.pink),
                            SizedBox(height: 8),
                            Text(
                              'Ketuk untuk memilih foto',
                              style: TextStyle(
                                color: AppColors.pink,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Format: JPG, PNG (maks. 800×800)',
                              style: TextStyle(color: Colors.grey, fontSize: 11),
                            ),
                          ],
                        )
                      : Stack(
                          fit: StackFit.expand,
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: Image.memory(
                                base64Decode(_gambarBase64),
                                fit: BoxFit.cover,
                              ),
                            ),
                            Positioned(
                              top: 8, right: 8,
                              child: GestureDetector(
                                onTap: _showPilihSumberGambar,
                                child: Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: const BoxDecoration(
                                    color: AppColors.deepRed,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(Icons.edit_rounded,
                                      color: Colors.white, size: 16),
                                ),
                              ),
                            ),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 20),

              //Info Produk
              _sectionLabel('Informasi Produk'),
              const SizedBox(height: 10),

              _buildCard(
                child: Column(
                  children: [
                    _buildTextField(
                      controller: _namaCtrl,
                      label: 'Nama Produk',
                      hint: 'Masukkan nama produk',
                      icon: Icons.inventory_2_rounded,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Nama tidak boleh kosong' : null,
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _hargaCtrl,
                      label: 'Harga (Rp)',
                      hint: 'Contoh: 50000',
                      icon: Icons.payments_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Harga tidak boleh kosong';
                        if (int.tryParse(v) == null) return 'Masukkan angka yang valid';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    _buildTextField(
                      controller: _stokCtrl,
                      label: 'Stok',
                      hint: 'Jumlah stok tersedia',
                      icon: Icons.warehouse_rounded,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Stok tidak boleh kosong';
                        if (int.tryParse(v) == null) return 'Masukkan angka yang valid';
                        return null;
                      },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              //Kategori
              _sectionLabel('Kategori'),
              const SizedBox(height: 10),

              _buildCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.category_rounded,
                            size: 18, color: AppColors.deepRed),
                        const SizedBox(width: 8),
                        Text(
                          'Pilih Kategori',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: ProdukModel.kategoriList.map((k) {
                        final isSelected = k == _selectedKategori;
                        return GestureDetector(
                          onTap: () => setState(() => _selectedKategori = k),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? AppColors.deepRed
                                  : AppColors.lightPink,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? AppColors.deepRed
                                    : AppColors.pink,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              k,
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppColors.deepRed,
                                fontSize: 12,
                                fontWeight: isSelected
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              //Deskripsi
              _sectionLabel('Deskripsi'),
              const SizedBox(height: 10),

              _buildCard(
                child: _buildTextField(
                  controller: _deskripsiCtrl,
                  label: 'Deskripsi Produk',
                  hint: 'Jelaskan produk Anda...',
                  icon: Icons.description_rounded,
                  maxLines: 4,
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Deskripsi tidak boleh kosong' : null,
                ),
              ),

              const SizedBox(height: 28),

              //Tombol Simpan
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: _isLoading ? null : _simpan,
                  icon: _isLoading
                      ? const SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2),
                        )
                      : Icon(
                          _isEdit ? Icons.save_rounded : Icons.add_rounded,
                          color: Colors.white,
                        ),
                  label: Text(
                    _isLoading
                        ? 'Menyimpan...'
                        : (_isEdit ? 'Simpan Perubahan' : 'Tambah Produk'),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.forest,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: AppColors.deepRed,
          letterSpacing: 0.2,
        ),
      );

  Widget _buildCard({required Widget child}) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.all(Radius.circular(16)),
          border: Border.fromBorderSide(
              BorderSide(color: AppColors.lightPink, width: 1)),
          boxShadow: [
            BoxShadow(
              color: AppColors.pinkShadow,
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: child,
      );

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      validator: validator,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: AppColors.deepRed, size: 20),
        labelStyle: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        filled: true,
        fillColor: AppColors.bg,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightPink),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.lightPink),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.deepRed, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB71C1C)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFB71C1C), width: 1.5),
        ),
      ),
    );
  }
}