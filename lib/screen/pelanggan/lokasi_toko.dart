import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';

class AppColors {
  static const deepRed = Color(0xFF832D25);
  static const pink = Color(0xFFEA6993);
  static const lightPink = Color(0xFFF8CAE4);
  static const sage = Color(0xFFCFDD9D);
  static const forest = Color(0xFF447A5F);
  static const bg = Color(0xFFFDF6F9);

  static const shadow = Color(0x1A000000);
}

class LokasiToko extends StatefulWidget {
  const LokasiToko({super.key});

  @override
  State<LokasiToko> createState() => _LokasiTokoState();
}

class _LokasiTokoState extends State<LokasiToko> {
  final MapController _mapController = MapController();
  Position? _posisiUser;
  bool _isLoading = true;

  static const LatLng _lokasiToko = LatLng(-8.162921888586801, 113.71181489497145);
  static const String _namaToko = 'HomeHobby';
  static const String _alamatToko = 'Jember, Jawa Timur';

  @override
  void initState() {
    super.initState();
    _getLokasiUser();
  }

  Future<void> _getLokasiUser() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      if (!mounted) return;
      setState(() {
        _posisiUser = position;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _hitungJarak() {
    if (_posisiUser == null) return 'Lokasi tidak diketahui';

    double jarakMeter = Geolocator.distanceBetween(
      _posisiUser!.latitude,
      _posisiUser!.longitude,
      _lokasiToko.latitude,
      _lokasiToko.longitude,
    );

    if (jarakMeter < 1000) {
      return '${jarakMeter.toStringAsFixed(0)} m dari lokasimu';
    } else {
      double jarakKm = jarakMeter / 1000;
      return '${jarakKm.toStringAsFixed(1)} km dari lokasimu';
    }
  }

  Future<void> _bukaNavigasi() async {
    final Uri urlMaps = Uri.parse(
      'https://www.google.com/maps/dir/?api=1'
      '&destination=${_lokasiToko.latitude},${_lokasiToko.longitude}'
      '&travelmode=driving',
    );

    try {
      final berhasil = await launchUrl(urlMaps, mode: LaunchMode.externalApplication);
      if (!berhasil) throw Exception('launchUrl returned false');
    } catch (_) {
      try {
        final urlGeo = Uri.parse(
          'geo:${_lokasiToko.latitude},${_lokasiToko.longitude}'
          '?q=${_lokasiToko.latitude},${_lokasiToko.longitude}(HomeHobby)',
        );
        final berhasilGeo = await launchUrl(urlGeo, mode: LaunchMode.externalApplication);
        if (!berhasilGeo) throw Exception('geo: launch failed');
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Tidak bisa membuka Google Maps. Pastikan aplikasi Maps sudah terinstall.'),
            backgroundColor: const Color(0xFFB71C1C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.deepRed,
        elevation: 0,
        title: const Text(
          'Lokasi Toko',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: const MapOptions(
              initialCenter: _lokasiToko,
              initialZoom: 15,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.homehobby.app',
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _lokasiToko,
                    width: 60,
                    height: 60,
                    child: GestureDetector(
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('📍 HomeHobby - Jember'),
                            backgroundColor: AppColors.deepRed,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                        );
                      },
                      child: const Column(
                        children: [
                          Icon(Icons.location_pin, color: AppColors.deepRed, size: 40),
                          Text(
                            'Toko',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.deepRed,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (_posisiUser != null)
                    Marker(
                      point: LatLng(_posisiUser!.latitude, _posisiUser!.longitude),
                      width: 60,
                      height: 60,
                      child: const Column(
                        children: [
                          Icon(Icons.location_pin, color: AppColors.forest, size: 40),
                          Text(
                            'Kamu',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppColors.forest,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),

          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(color: AppColors.deepRed),
            ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, -4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  //Info Toko
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.lightPink,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.store_rounded, color: AppColors.deepRed, size: 24),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              _namaToko,
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.deepRed),
                            ),
                            Text(
                              _alamatToko,
                              style: TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  //Jarak
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.directions_walk_rounded, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(_hitungJarak(), style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  //Jam Operasional
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.bg,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.access_time_rounded, size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Text(
                          'Senin - Sabtu: 08.00 - 17.00 WIB',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  //Tombol Navigasi
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: _bukaNavigasi,
                      icon: const Icon(Icons.navigation_rounded, color: Colors.white),
                      label: const Text(
                        'Buka di Google Maps',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.deepRed,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}