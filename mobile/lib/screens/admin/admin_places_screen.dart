import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../models/place.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_colors.dart';
import '../../theme/place_category_icon.dart';
import 'admin_place_form_screen.dart';

class AdminPlacesScreen extends ConsumerWidget {
  const AdminPlacesScreen({super.key});

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Place place,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Joyni o\'chirish'),
        content: Text('"${place.name}" o\'chirilsinmi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Yo\'q'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFCB4B4B)),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('O\'chirish'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await ref.read(adminServiceProvider).deletePlace(place.id);
      ref.invalidate(adminPlacesProvider);
    } on ApiException catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFCB4B4B)),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placesAsync = ref.watch(adminPlacesProvider);
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.darkText,
        title: const Text(
          'Joylar',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkText),
        ),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.orange,
          onRefresh: () async => ref.invalidate(adminPlacesProvider),
          child: placesAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(color: AppColors.orange),
            ),
            error: (e, _) => Center(
              child: Text(
                e is ApiException ? e.message : 'Xatolik yuz berdi',
                style: const TextStyle(color: AppColors.mutedText),
              ),
            ),
            data: (places) {
              if (places.isEmpty) {
                return ListView(
                  children: const [
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 80),
                      child: Text(
                        'Hali joy yo\'q. Pastdagi + tugmasi orqali qo\'shing.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                    ),
                  ],
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: places.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final place = places[index];
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.fieldBorder),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            placeCategoryIcon(place.category.name),
                            color: AppColors.orange,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                place.name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.darkText,
                                ),
                              ),
                              Text(
                                '${place.category.name} • ${place.status}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.mutedText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, color: Color(0xFFCB4B4B)),
                          onPressed: () => _confirmDelete(context, ref, place),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.orange,
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const AdminPlaceFormScreen()),
          );
          if (created == true) {
            ref.invalidate(adminPlacesProvider);
          }
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
