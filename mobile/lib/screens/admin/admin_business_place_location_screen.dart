import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../theme/app_colors.dart';

const _placeLocation = LatLng(41.311081, 69.240562);

/// MIKKA Business mobil "Manzil tafsilotlari" ekrani — joyning xarita
/// belgisini ko'rish/surish va manzilni saqlash uchun sof UI. Xarita
/// belgisi va koordinatalar lokal holatda saqlanadi — hech qanday
/// backend/servis chaqiruvi yo'q.
class AdminBusinessPlaceLocationScreen extends StatefulWidget {
  const AdminBusinessPlaceLocationScreen({super.key});

  @override
  State<AdminBusinessPlaceLocationScreen> createState() =>
      _AdminBusinessPlaceLocationScreenState();
}

class _AdminBusinessPlaceLocationScreenState
    extends State<AdminBusinessPlaceLocationScreen> {
  final _searchController = TextEditingController();
  LatLng _marker = _placeLocation;
  bool _movingMarker = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _saveLocation() {
    setState(() => _movingMarker = false);
    _showMessage('Manzil saqlandi');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 20, 8),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.fieldBorder(context)),
                      ),
                      child: Icon(Icons.arrow_back, size: 18, color: AppColors.darkText(context)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Manzil tafsilotlari',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText(context),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 220,
              child: Stack(
                children: [
                  GoogleMap(
                    initialCameraPosition: CameraPosition(target: _marker, zoom: 16),
                    markers: {
                      Marker(markerId: const MarkerId('place'), position: _marker),
                    },
                    onTap: _movingMarker
                        ? (position) => setState(() => _marker = position)
                        : null,
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    top: 12,
                    child: Material(
                      elevation: 2,
                      borderRadius: BorderRadius.circular(14),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(color: AppColors.darkText(context)),
                        decoration: InputDecoration(
                          hintText: 'Yangi manzil qidirish...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: AppColors.surface(context),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        onSubmitted: (_) => _showMessage('Manzil qidirish tez orada qo\'shiladi'),
                      ),
                    ),
                  ),
                  if (_movingMarker)
                    Positioned(
                      left: 16,
                      right: 16,
                      bottom: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: AppColors.darkText(context).withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Belgini ko\'chirish uchun xaritaga bosing',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Manzil tafsilotlari',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkText(context),
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3F9142).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.verified, size: 13, color: Color(0xFF3F9142)),
                              SizedBox(width: 4),
                              Text(
                                'Tasdiqlangan',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: Color(0xFF3F9142),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Biznesingiz manzilini boshqaring',
                      style: TextStyle(fontSize: 13, color: AppColors.mutedText(context)),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.fieldBorder(context)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.storefront_outlined,
                                    color: AppColors.orange, size: 20),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Coffee Lab',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkText(context),
                                    ),
                                  ),
                                  Text(
                                    'Kafe va qovurdoqxona',
                                    style: TextStyle(
                                        fontSize: 12, color: AppColors.mutedText(context)),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 24),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.location_on_outlined,
                                  size: 18, color: AppColors.orange),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  '124-uy, Dizayn ko\'chasi\nMarkaziy tuman, Toshkent',
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.darkText(context),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'XARITA ANIQLIGI',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                        color: AppColors.mutedText(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _CoordinateCard(
                            label: 'Kenglik',
                            value: '${_marker.latitude.toStringAsFixed(4)}° N',
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _CoordinateCard(
                            label: 'Uzunlik',
                            value: '${_marker.longitude.toStringAsFixed(4)}° E',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: () => setState(() => _movingMarker = !_movingMarker),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkText(context),
                          side: BorderSide(
                            color: _movingMarker
                                ? AppColors.adminGradientMid
                                : AppColors.fieldBorder(context),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        icon: const Icon(Icons.control_camera_outlined, size: 18),
                        label: Text(_movingMarker ? 'Belgi ko\'chirilmoqda...' : 'Belgini ko\'chirish'),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.adminBrandGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: _saveLocation,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text(
                            'Manzilni saqlash',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CoordinateCard extends StatelessWidget {
  const _CoordinateCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.cream(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText(context),
            ),
          ),
        ],
      ),
    );
  }
}
