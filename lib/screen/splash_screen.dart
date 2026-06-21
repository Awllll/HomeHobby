import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_screen.dart';
import 'admin/dashboard_admin.dart';
import 'pelanggan/beranda_pelanggan.dart';

class AppColors {
  static const deepRed = Color(0xFF832D25);
  static const pink = Color(0xFFEA6993);
  static const lightPink = Color(0xFFF8CAE4);
  static const sage = Color(0xFFCFDD9D);
  static const forest = Color(0xFF447A5F);

  static const whiteSoft = Color(0xB3FFFFFF);
  static const shadow = Color(0x33000000);
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _cekLogin();
  }

  Future<void> _cekLogin() async {
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      // Belum login → ke halaman login
      _navigateTo(const LoginScreen());
    } else {
      // Sudah login → cek role
      DocumentSnapshot doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!mounted) return;

      String role = doc['role'] ?? 'pelanggan';

      if (role == 'admin') {
        _navigateTo(const DashboardAdmin());
      } else {
        _navigateTo(const BerandaPelanggan());
      }
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.deepRed, AppColors.pink],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              //Logo
              Container(
                width: 130,
                height: 130,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 20,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: Image.asset(
                    'assets/images/logo_homehobby.jpg',
                    fit: BoxFit.cover,
                    alignment: const Alignment(0, 1),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'HomeHobby',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Platform Merchandise Custom Ter-Favv',
                style: TextStyle(
                  color: AppColors.whiteSoft,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 44),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: AppColors.sage,
                  strokeWidth: 3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}