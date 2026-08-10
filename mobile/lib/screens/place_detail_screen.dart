import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/place.dart';
import '../providers/place_provider.dart';
import '../theme/app_colors.dart';
import '../theme/place_category_icon.dart';
import 'check_in_screen.dart';

class PlaceDetailScreen extends ConsumerStatefulWidget {
  const PlaceDetailScreen({super.key, required this.place});

  final Place place;

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  bool _saved = false;

  @override
  Widget build(BuildContext context) {
    final place = widget.place;
    final detailAsync = ref.watch(placeDetailProvider(place.id));
    final ratingAsync = ref.watch(placeRatingProvider(place.id));

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 240,
                color: AppColors.orange.withValues(alpha: 0.12),
                alignment: Alignment.center,
                child: Icon(
                  placeCategoryIcon(place.category.name),
                  color: AppColors.orange,
                  size: 64,
                ),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _CircleIconButton(
                        icon: Icons.arrow_back,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      Row(
                        children: [
                          _CircleIconButton(
                            icon: _saved
                                ? Icons.favorite
                                : Icons.favorite_border,
                            onTap: () => setState(() => _saved = !_saved),
                          ),
                          const SizedBox(width: 10),
                          _CircleIconButton(
                            icon: Icons.ios_share,
                            onTap: () {},
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    place.name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.darkText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        place.category.name,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.orange,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ratingAsync.when(
                        loading: () => const SizedBox(
                          width: 12,
                          height: 12,
                          child: CircularProgressIndicator(strokeWidth: 1.5),
                        ),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (rating) => rating.reviewCount == 0
                            ? const Text(
                                'Hali baholanmagan',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: AppColors.mutedText,
                                ),
                              )
                            : Row(
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: AppColors.orange,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${rating.averageRating.toStringAsFixed(1)} (${rating.reviewCount})',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: AppColors.mutedText,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      if (place.distanceLabel != null)
                        _InfoPill(
                          icon: Icons.location_on_outlined,
                          label: place.distanceLabel!,
                          sub: 'sizdan',
                        ),
                      detailAsync.maybeWhen(
                        data: (detail) => detail.address != null
                            ? Padding(
                                padding: EdgeInsets.only(
                                  left: place.distanceLabel != null ? 10 : 0,
                                ),
                                child: _InfoPill(
                                  icon: Icons.map_outlined,
                                  label: 'Manzil',
                                  sub: detail.address!,
                                ),
                              )
                            : const SizedBox.shrink(),
                        orElse: () => const SizedBox.shrink(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  detailAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: CircularProgressIndicator(color: AppColors.orange),
                      ),
                    ),
                    error: (_, _) => const Text(
                      'Ma\'lumotni yuklab bo\'lmadi',
                      style: TextStyle(color: AppColors.mutedText, fontSize: 14),
                    ),
                    data: (detail) => Text(
                      detail.description?.isNotEmpty == true
                          ? detail.description!
                          : '${place.category.name} haqida hali tavsif qo\'shilmagan.',
                      style: const TextStyle(
                        fontSize: 14,
                        color: AppColors.darkText,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => CheckInScreen(place: place),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                ),
                child: const Text(
                  'Check-in',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.darkText, size: 18),
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label, required this.sub});

  final IconData icon;
  final String label;
  final String sub;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.fieldBorder),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppColors.orange, size: 16),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText,
                    ),
                  ),
                  Text(
                    sub,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.mutedText,
                    ),
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
