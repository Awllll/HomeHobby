import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';

import '../../model/produk_model.dart';
import '../../service/firestore_service.dart';

class TambahProduk extends StatefulWidget {
  final ProdukModel? produk;
  const TambahProduk({super.key, this.produk});

  @override
  State<TambahProduk> createState() => _TambahProdukState();
}

class _TambahProdukState extends State<TambahProduk> {
  final _namaController = TextEditingController();
  final _hargaController = TextEditingController();
  final _deskripsiController = TextEditingController();
  final _stokController = TextEditingController();
  final _firestoreService = FirestoreService();
  final _imagePicker = ImagePicker();

  String _selectedKategori = ProdukModel.kategoriList.first;

  Uint8List? _gambarBytes;
  String _gambarBase64Lama = '';

  bool _isLoading = false;
  bool get _isEdit => widget.produk != null;

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _namaController.text = widget.produk!.nama;
      _hargaController.text = widget.produk!.harga.toString();
      _deskripsiController.text = widget.produk!.deskripsi;
      _stokController.text = widget.produk!.stok.toString();
      _selectedKategori = widget.produk!.kategori;
      _gambarBase64Lama = widget.produk!.gambarBase64;
    }
  }

  Future<void> _pilihGambar() async {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Pilih Gambar',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 16),

            ListTile(
              leading: const Icon(Icons.camera_alt_outlined,
                  color: Color(0xFF6C63FF)),
              title: const Text('Kamera'),
              onTap: () async {
                Navigator.pop(context);
                await _ambilGambar(ImageSource.camera);
              },
            ),

            ListTile(
              leading: const Icon(Icons.photo_library_outlined,
                  color: Color(0xFF6C63FF)),
              title: const Text('Galeri'),
              onTap: () async {
                Navigator.pop(context);
                await _ambilGambar(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _ambilGambar(ImageSource source) async {
    final XFile? picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 70,
    );

    if (picked != null) {
      final bytes = await picked.readAsBytes();

      setState(() {
        _gambarBytes = bytes;
      });
    }
  }

  Future<void> _simpan() async {
    if (_namaController.text.isEmpty ||
        _hargaController.text.isEmpty ||
        _deskripsiController.text.isEmpty ||
        _stokController.text.isEmpty) {
      _showSnackbar('Semua field harus diisi!');
      return;
    }

    if (!_isEdit && _gambarBytes == null) {
      _showSnackbar('Pilih gambar produk terlebih dahulu!');
      return;
    }

    setState(() => _isLoading = true);

    try {
      String gambarBase64 = _gambarBase64Lama;

      if (_gambarBytes != null) {
        gambarBase64 = base64Encode(_gambarBytes!);
      }

      if (_isEdit) {
        await _firestoreService.editProduk(widget.produk!.id, {
          'nama': _namaController.text.trim(),
          'kategori': _selectedKategori,
          'deskripsi': _deskripsiController.text.trim(),
          'harga': int.parse(_hargaController.text.trim()),
          'stok': int.parse(_stokController.text.trim()),
          'gambarBase64': gambarBase64,
        });

        _showSnackbar('Produk berhasil diupdate!');
      } else {
        ProdukModel produkBaru = ProdukModel(
          id: '',
          nama: _namaController.text.trim(),
          kategori: _selectedKategori,
          deskripsi: _deskripsiController.text.trim(),
          harga: int.parse(_hargaController.text.trim()),
          stok: int.parse(_stokController.text.trim()),
          gambarBase64: gambarBase64,
          createdAt: DateTime.now(),
        );

        await _firestoreService.tambahProduk(produkBaru);
        _showSnackbar('Produk berhasil ditambahkan!');
      }

      Navigator.pop(context);
    } catch (e) {
        print("ERROR SIMPAN: $e");
        _showSnackbar('Error: $e');
    }

    setState(() => _isLoading = false);
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF6C63FF),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _hargaController.dispose();
    _deskripsiController.dispose();
    _stokController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        title: Text(
          _isEdit ? 'Edit Produk' : 'Tambah Produk',
          style: const TextStyle(
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

            // IMAGE UPLOAD
            GestureDetector(
              onTap: _pilihGambar,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF6C63FF).withOpacity(0.3),
                  ),
                ),
                child: _gambarBytes != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.memory(
                          _gambarBytes!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                        ),
                      )
                    : _gambarBase64Lama.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              base64Decode(_gambarBase64Lama),
                              fit: BoxFit.cover,
                              width: double.infinity,
                            ),
                          )
                        : _buildUploadPlaceholder(),
              ),
            ),

            const SizedBox(height: 16),

            _buildLabel('Nama Produk'),
            _buildTextField(
              controller: _namaController,
              hint: 'Masukkan nama produk',
              icon: Icons.label_outline,
            ),

            const SizedBox(height: 16),

            _buildLabel('Kategori'),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedKategori,
                  isExpanded: true,
                  items: ProdukModel.kategoriList.map((kategori) {
                    return DropdownMenuItem(
                      value: kategori,
                      child: Text(kategori),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedKategori = value!);
                  },
                ),
              ),
            ),

            const SizedBox(height: 16),

            _buildLabel('Harga'),
            _buildTextField(
              controller: _hargaController,
              hint: 'Masukkan harga',
              icon: Icons.attach_money,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            _buildLabel('Stok'),
            const SizedBox(height: 8),
            _buildTextField(
              controller: _stokController,
              hint: 'Masukkan jumlah stok',
              icon: Icons.inventory_outlined,
              keyboardType: TextInputType.number,
            ),

            const SizedBox(height: 16),

            _buildLabel('Deskripsi'),
            TextField(
              controller: _deskripsiController,
              maxLines: 4,
              decoration: InputDecoration(
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(_isEdit ? 'Update' : 'Simpan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUploadPlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: const [
        Icon(Icons.add_a_photo, size: 40, color: Colors.grey),
        SizedBox(height: 8),
        Text('Tap untuk pilih gambar'),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}