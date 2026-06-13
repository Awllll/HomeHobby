import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

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
        '🛍️ *Produk yang tersedia di HomeHobby:*\n\n'
        '• Stiker\n'
        '• Poster\n'
        '• Hand Banner\n'
        '• Pin\n'
        '• Gantungan Kunci\n'
        '• Standee\n\n'
        'Semua produk bisa dicustom sesuai desain kamu!',
    'Cara Pemesanan':
        '📋 *Cara Pemesanan:*\n\n'
        '1. Buka menu Katalog\n'
        '2. Pilih produk yang diinginkan\n'
        '3. Tentukan jumlah pesanan\n'
        '4. Tambahkan catatan desain\n'
        '5. Tap tombol "Pesan Sekarang"\n'
        '6. Tunggu konfirmasi dari admin',
    'Cara Pembayaran':
        '💳 *Cara Pembayaran:*\n\n'
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
      setState(() {
        _messages.add({
          'tipe': 'bot',
          'pesan':
              'Halo! Selamat datang di HomeHobby 👋\n\nSilakan pilih informasi yang kamu butuhkan:',
        });
        _sudahSapa = true;
      });
    });
  }

  Future<void> _pilihMenu(String menu) async {
    // Tambah pesan user
    setState(() {
      _messages.add({
        'tipe': 'user',
        'pesan': menu,
      });
    });

    // Kalau pilih Hubungi Admin → redirect WhatsApp
    if (menu == 'Hubungi Admin') {
      Future.delayed(const Duration(milliseconds: 600), () {
        setState(() {
          _messages.add({
            'tipe': 'bot',
            'pesan': 'Menghubungkan kamu ke admin via WhatsApp... 📱',
          });
        });
      });

      // Buka WhatsApp setelah delay sebentar
      await Future.delayed(const Duration(milliseconds: 1200));
      _bukaWhatsApp();
      return;
    }

    // Menu lain tetap seperti biasa
    Future.delayed(const Duration(milliseconds: 600), () {
      setState(() {
        _messages.add({
          'tipe': 'bot',
          'pesan': _kontenMenu[menu] ?? 'Maaf, informasi tidak tersedia.',
        });
        _messages.add({
          'tipe': 'bot',
          'pesan': 'Ada yang ingin kamu tanyakan lagi?',
          'showMenu': true,
        });
      });
    });
  }

  Future<void> _bukaWhatsApp() async {
    const noWhatsApp = '6282333963533';
    const pesanAwal = 'Halo Admin HomeHobby, saya ingin bertanya tentang pesanan saya.';

    final Uri url = Uri.parse(
      'https://wa.me/$noWhatsApp?text=${Uri.encodeComponent(pesanAwal)}',
    );

    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak bisa membuka WhatsApp'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF6C63FF),
        automaticallyImplyLeading: false,
        title: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
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
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Daftar Pesan
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isBot = msg['tipe'] == 'bot';
                final showMenu = msg['showMenu'] == true;

                return Column(
                  crossAxisAlignment: isBot
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.end,
                  children: [
                    // Bubble Chat
                    Row(
                      mainAxisAlignment: isBot
                          ? MainAxisAlignment.start
                          : MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        if (isBot) ...[
                          CircleAvatar(
                            radius: 16,
                            backgroundColor: const Color(0xFF6C63FF),
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
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isBot
                                  ? Colors.white
                                  : const Color(0xFF6C63FF),
                              borderRadius: BorderRadius.only(
                                topLeft: const Radius.circular(16),
                                topRight: const Radius.circular(16),
                                bottomLeft: Radius.circular(isBot ? 0 : 16),
                                bottomRight: Radius.circular(isBot ? 16 : 0),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
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

                    // Tombol Menu
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
                                horizontal: 14,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: const Color(0xFF6C63FF),
                                ),
                              ),
                              child: Text(
                                menu,
                                style: const TextStyle(
                                  color: Color(0xFF6C63FF),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
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