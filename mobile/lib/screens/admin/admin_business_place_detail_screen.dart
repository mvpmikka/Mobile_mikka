import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'admin_business_place_location_screen.dart';
import 'widgets/admin_section_topbar.dart';

/// MIKKA Business mobil "Joy" profil ekrani — Figma dizayni asosidagi sof
/// UI. Barcha ma'lumotlar (statistika, tavsif, reyting) lokal namunaviy
/// qiymatlar — hech qanday backend/servis chaqiruvi yo'q.
class AdminBusinessPlaceDetailScreen extends StatelessWidget {
  const AdminBusinessPlaceDetailScreen({super.key});

  void _showSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$feature tez orada qo\'shiladi')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSectionTopBar(
                title: 'Joy',
                onNotification: () => _showSoon(context, 'Bildirishnomalar'),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _HeroHeader(onShowSoon: (feature) => _showSoon(context, feature)),
                      const SizedBox(height: 16),
                      Row(
                        children: const [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.visibility_outlined,
                              value: '12.4k',
                              label: 'Ko\'rishlar (30k)',
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.directions_walk,
                              value: '3,204',
                              label: 'Tashriflar',
                            ),
                          ),
                          SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.bookmark_border,
                              value: '842',
                              label: 'Saqlanganlar',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _InfoCard(
                        onTapMap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const AdminBusinessPlaceLocationScreen(),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _PublicPreviewCard(),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.onShowSoon});

  final ValueChanged<String> onShowSoon;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 140,
            width: double.infinity,
            decoration: const BoxDecoration(gradient: AppColors.adminBrandGradient),
            child: const Center(
              child: Icon(Icons.local_cafe_outlined, size: 48, color: Colors.white),
            ),
          ),
          Container(
            color: AppColors.surface(context),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF8A5A3B),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.surface(context), width: 3),
                      ),
                      child: const Center(
                        child: Text(
                          'CL',
                          style: TextStyle(
                              color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Coffee Lab',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.darkText(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.star, size: 14, color: Color(0xFFE9A23C)),
                              const SizedBox(width: 3),
                              Text(
                                '4.8 (124 sharh)',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.mutedText(context)),
                              ),
                              const SizedBox(width: 6),
                              Text('•', style: TextStyle(color: AppColors.mutedText(context))),
                              const SizedBox(width: 6),
                              Text(
                                'Kafe va qovurdoqxona',
                                style: TextStyle(
                                    fontSize: 12, color: AppColors.mutedText(context)),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => onShowSoon('Ommaviy profil'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.darkText(context),
                          side: BorderSide(color: AppColors.fieldBorder(context)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: const Text('Ommaviy profilni ko\'rish'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.adminBrandGradient,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: ElevatedButton.icon(
                          onPressed: () => onShowSoon('Joyni tahrirlash'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.transparent,
                            shadowColor: Colors.transparent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Tahrirlash'),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.orange),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: AppColors.mutedText(context)),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.onTapMap});

  final VoidCallback onTapMap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.info_outline, size: 18, color: Color(0xFF5D4038)),
              const SizedBox(width: 8),
              Text(
                'Umumiy ma\'lumot',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppColors.darkText(context),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Text(
            'TAVSIF',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: AppColors.mutedText(context),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Dizayn tumanining markazida joylashgan hunarmandchilik kofe '
            'qovurdoqxonasi. Biz bir manbali donlarni etik tarzda sotib olamiz '
            've joyida qovuramiz.',
            style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.darkText(context)),
          ),
          const SizedBox(height: 16),
          _InfoRow(icon: Icons.location_on_outlined, title: 'Manzil', value: '124-uy, Dizayn ko\'chasi, Markaziy tuman'),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.schedule_outlined, title: 'Ish vaqti', value: 'Dush-Juma: 7:00 - 19:00\nShan-Yak: 8:00 - 18:00'),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.call_outlined, title: 'Telefon', value: '+998 (90) 123-45-67'),
          const SizedBox(height: 12),
          _InfoRow(icon: Icons.language_outlined, title: 'Veb-sayt', value: 'coffeelab.example.com', valueColor: AppColors.adminGradientMid),
          const SizedBox(height: 16),
          InkWell(
            onTap: onTapMap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              height: 110,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.cream(context),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.fieldBorder(context)),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.map_outlined, size: 24, color: AppColors.mutedText(context)),
                    const SizedBox(height: 6),
                    Text(
                      'Manzilni xaritada ko\'rish/tahrirlash',
                      style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.title,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String title;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: AppColors.orange),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? AppColors.darkText(context),
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _PublicPreviewCard extends StatelessWidget {
  const _PublicPreviewCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
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
              const Icon(Icons.phone_iphone, size: 18, color: Color(0xFF5D4038)),
              const SizedBox(width: 8),
              Text(
                'OMMAVIY KO\'RINISH',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.mutedText(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: AppColors.cream(context),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.fieldBorder(context)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                Container(
                  height: 90,
                  decoration: const BoxDecoration(gradient: AppColors.adminBrandGradient),
                  child: const Center(
                    child: Icon(Icons.coffee_outlined, size: 32, color: Colors.white),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Coffee Lab',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.darkText(context),
                        ),
                      ),
                      Text(
                        'Kafe • 0.2 mil masofada',
                        style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                      ),
                      const SizedBox(height: 10),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: AppColors.adminBrandGradient,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: null,
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                            ),
                            child: const Text(
                              'Oldindan buyurtma berish',
                              style: TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
