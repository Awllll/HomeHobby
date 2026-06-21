import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class AppColors {
  static const deepRed = Color(0xFF832D25);
  static const pink = Color(0xFFEA6993);
  static const lightPink = Color(0xFFF8CAE4);
  static const sage = Color(0xFFCFDD9D);
  static const forest = Color(0xFF447A5F);
  static const bg = Color(0xFFFDF6F9);

  static const whiteCircle = Color(0x33FFFFFF);
  static const shadow      = Color(0x0D000000);
}

class ChatbotScreen extends StatefulWidget {
  const ChatbotScreen({super.key});

  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final List<Map<String, dynamic>> _messages = [];
  bool _sudahSapa = false;

  // Isi konten tiap menu
  final Map<String, String> _kontenMenu = {
    'Informasi Produk':
        'Produk - produk HomeHobby:\n\n'
        '• Stiker\n'
        '• Poster\n'
        '• Hand Banner\n'
        '• Pin\n'
        '• Gantungan Kunci\n'
        '• Standee\n\n'
        'Semua produk bisa dicustom sesuai desain kamu!',
    'Cara Pemesanan':
        'Cara Pemesanan:\n\n'
        '1. Buka menu Katalog\n'
        '2. Pilih produk yang diinginkan\n'
        '3. Tentukan jumlah pesanan\n'
        '4. Tambahkan catatan desain\n'
        '5. Tap tombol "Pesan Sekarang"\n'
        '6. Tunggu konfirmasi dari admin',
    'Cara Pembayaran':
        'Cara Pembayaran:\n\n'
        '1. Setelah pesanan dikonfirmasi admin\n'
        '2. Transfer ke rekening berikut:\n'
        '   • BCA: 1234567890 a/n HomeHobby\n'
        '   • GoPay: 08123456789\n'
        '3. Kirim bukti transfer ke admin\n'
        '4. Pesanan akan diproses setelah\n'
        '   pembayaran terverifikasi',
    'Hubungi Admin': '',
  };

  @override
  void initState() {
    super.initState();
    _sapaPengguna();
  }

  void _sapaPengguna() {
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'tipe': 'bot',
          'pesan':
              'Halow! Welcome di HomeHobby 👋!!\n\nSilakan pilih informasi yang kamu butuhkan:',
        });
        _sudahSapa = true;
      });
    });
  }

  Future<void> _pilihMenu(String menu) async {
    setState(() {
      _messages.add({'tipe': 'user', 'pesan': menu});
    });

    // Kalau pilih Hubungi Admin → redirect WhatsApp
    if (menu == 'Hubungi Admin') {
      Future.delayed(const Duration(milliseconds: 600), () {
        if (!mounted) return;
        setState(() {
          _messages.add({
            'tipe': 'bot',
            'pesan': 'Menghubungkan kamu ke admin via WhatsApp... 📱',
          });
        });
      });

      await Future.delayed(const Duration(milliseconds: 1200));
      if (!mounted) return;
      _bukaWhatsApp();
      return;
    }

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      setState(() {
        _messages.add({
          'tipe': 'bot',
          'pesan': _kontenMenu[menu] ?? 'Maaf, informasi tidak tersedia.',
        });
        _messages.add({
          'tipe': 'bot',
          'pesan': 'Ada yang ingin ditanyakan lagi?',
          'showMenu': true,
        });
      });
    });
  }

  Future<void> _bukaWhatsApp() async {
    const noWhatsApp = '6285336488329';
    const pesanAwal =
        'Halo Minchy, saya ingin bertanya tentang pesanan saya...';

    final Uri url = Uri.parse(
      'https://wa.me/$noWhatsApp?text=${Uri.encodeComponent(pesanAwal)}',
    );

    try {
      final berhasil = await launchUrl(url, mode: LaunchMode.externalApplication);
      if (!berhasil) throw Exception('launchUrl returned false');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Tidak bisa membuka WhatsApp. Pastikan WhatsApp sudah terinstall.'),
          backgroundColor: const Color(0xFFB71C1C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.deepRed,
        elevation: 0,
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: const BoxDecoration(
                color: AppColors.whiteCircle,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.smart_toy_outlined,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'HomeHobby Bot',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isBot = msg['tipe'] == 'bot';
                final showMenu = msg['showMenu'] == true;

                return Column(
                  crossAxisAlignment:
                      isBot ? CrossAxisAlignment.start : CrossAxisAlignment.end,
                  children: [
                    //Bubble Chat
                    Row(
                      mainAxisAlignment:
                          isBot ? MainAxisAlignment.start : MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isBot) ...[
                          Container(
                            width: 32, height: 32,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [AppColors.deepRed, AppColors.pink],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.smart_toy_outlined,
                              color: Colors.white,
                              size: 16,
                            ),
                          ),
                          const SizedBox(width: 8),
                        ],
                        Flexible(
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: isBot ? Colors.white : AppColors.deepRed,
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isBot ? 0 : 16),
                                bottomRight: Radius.circular(isBot ? 16 : 0),
                              ),
                              border: isBot
                                  ? Border.all(color: AppColors.lightPink, width: 1)
                                  : null,
                              boxShadow: const [
                                BoxShadow(
                                  color: AppColors.shadow,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Text(
                              msg['pesan'],
                              style: TextStyle(
                                color: isBot ? Colors.black87 : Colors.white,
                                fontSize: 13,
                                height: 1.5,
                              ),
                            ),
                          ),
                        ),
                        if (!isBot) const SizedBox(width: 8),
                      ],
                    ),

                    //Tombol Menu
                    if (showMenu || (isBot && index == 0 && _sudahSapa)) ...[
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: _kontenMenu.keys.map((menu) {
                          return GestureDetector(
                            onTap: () => _pilihMenu(menu),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.lightPink,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.deepRed, width: 1),
                              ),
                              child: Text(
                                menu,
                                style: const TextStyle(
                                  color: AppColors.deepRed,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 8),
                    ],

                    const SizedBox(height: 8),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}