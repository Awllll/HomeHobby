import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../service/auth_service.dart';
import '../model/user_model.dart';
import 'pelanggan/beranda_pelanggan.dart';

class AppColors {
  static const deepRed = Color(0xFF832D25);
  static const pink = Color(0xFFEA6993);
  static const lightPink = Color(0xFFF8CAE4);
  static const sage = Color(0xFFCFDD9D);
  static const forest = Color(0xFF447A5F);
  static const bg = Color(0xFFFDF6F9);

  static const pinkShadow = Color(0x26EA6993);
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _namaController = TextEditingController();
  final _emailController = TextEditingController();
  final _teleponController = TextEditingController();
  final _passwordController = TextEditingController();
  final _konfirmasiPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureKonfirmasi = true;

  Future<void> _register() async {
    if (_namaController.text.isEmpty ||
        _emailController.text.isEmpty ||
        _teleponController.text.isEmpty ||
        _passwordController.text.isEmpty ||
        _konfirmasiPasswordController.text.isEmpty) {
      _showSnackbar('Semua field harus diisi!', isError: true);
      return;
    }

    if (_teleponController.text.trim().length < 9) {
      _showSnackbar('Nomor telepon tidak valid!', isError: true);
      return;
    }

    if (_passwordController.text.length < 6) {
      _showSnackbar('Password minimal 6 karakter!', isError: true);
      return;
    }

    if (_passwordController.text != _konfirmasiPasswordController.text) {
      _showSnackbar('Password dan konfirmasi password tidak sama!', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    UserModel? user = await _authService.register(
      _namaController.text.trim(),
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _teleponController.text.trim(),
    );

    if (user == null) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showSnackbar('Registrasi gagal! Email mungkin sudah digunakan.', isError: true);
      return;
    }

    await _authService.logout();

    if (!mounted) return;
    setState(() => _isLoading = false);

    _showDialogSukses();
  }

  void _showDialogSukses() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                color: AppColors.sage,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, color: AppColors.forest, size: 44),
            ),
            const SizedBox(height: 16),
            const Text(
              'Registrasi Berhasil!',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.deepRed),
            ),
            const SizedBox(height: 8),
            Text(
              'Akunmu sukses di buat, login dulu yah sebelum belanja ;).',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade500),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.deepRed,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Login Sekarang',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _loginWithGoogle() async {
    setState(() => _isLoading = true);

    UserModel? user = await _authService.loginWithGoogle();

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (user == null) {
      _showSnackbar('Login Google gagal, coba lagi!', isError: true);
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const BerandaPelanggan()),
    );
  }

  void _showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? const Color(0xFFB71C1C) : AppColors.forest,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    _namaController.dispose();
    _emailController.dispose();
    _teleponController.dispose();
    _passwordController.dispose();
    _konfirmasiPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 32),

              //Header
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.pinkShadow,
                            blurRadius: 16,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ClipOval(
                        child: Image.asset(
                          'assets/images/logo_homehobby.jpg',
                          fit: BoxFit.cover,
                          alignment: const Alignment(0, 0.8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Buat Akun Baru',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.deepRed,
                        letterSpacing: 0.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Daftar dan mulai pesan sekarang!',
                      style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              //Nama
              _fieldLabel('Nama Lengkap'),
              const SizedBox(height: 8),
              _buildField(
                controller: _namaController,
                hint: 'Masukkan nama lengkap',
                icon: Icons.person_outline_rounded,
              ),

              const SizedBox(height: 16),

              //Email
              _fieldLabel('Email'),
              const SizedBox(height: 8),
              _buildField(
                controller: _emailController,
                hint: 'Masukkan email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              //Nomor Telepon
              _fieldLabel('Nomor Telepon'),
              const SizedBox(height: 8),
              _buildField(
                controller: _teleponController,
                hint: 'Contoh: 081234567890',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(14),
                ],
              ),

              const SizedBox(height: 16),

              //Password
              _fieldLabel('Password'),
              const SizedBox(height: 8),
              _buildField(
                controller: _passwordController,
                hint: 'Minimal 6 karakter',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),

              const SizedBox(height: 16),

              //Konfirmasi Password
              _fieldLabel('Konfirmasi Password'),
              const SizedBox(height: 8),
              _buildField(
                controller: _konfirmasiPasswordController,
                hint: 'Ulangi password',
                icon: Icons.lock_outline_rounded,
                obscureText: _obscureKonfirmasi,
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscureKonfirmasi
                        ? Icons.visibility_off_rounded
                        : Icons.visibility_rounded,
                    color: Colors.grey.shade500,
                    size: 20,
                  ),
                  onPressed: () =>
                      setState(() => _obscureKonfirmasi = !_obscureKonfirmasi),
                ),
              ),

              const SizedBox(height: 28),

              //Tombol Daftar
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.deepRed,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 22, height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Text(
                          'Daftar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 18),

              //Garis pembatas
              Row(
                children: [
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('atau', style: TextStyle(color: Colors.grey.shade500)),
                  ),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),

              const SizedBox(height: 18),

              //Tombol Google
              SizedBox(
                width: double.infinity,
                height: 52,
                child: OutlinedButton.icon(
                  onPressed: _isLoading ? null : _loginWithGoogle,
                  icon: const Icon(Icons.g_mobiledata_rounded, color: AppColors.pink, size: 28),
                  label: const Text(
                    'Daftar dengan Google',
                    style: TextStyle(
                      fontSize: 15,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.lightPink, width: 1.4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              //Sudah punya akun
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Sudah punya akun? ', style: TextStyle(color: Colors.grey.shade500)),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Masuk di sini',
                      style: TextStyle(color: AppColors.deepRed, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) => Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF1A1A1A)),
      );

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffixIcon,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      inputFormatters: inputFormatters,
      style: const TextStyle(fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
        prefixIcon: Icon(icon, color: AppColors.deepRed, size: 20),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightPink),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.lightPink),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.deepRed, width: 1.5),
        ),
      ),
    );
  }
}