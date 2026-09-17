import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/api_exception.dart';
import '../models/saved_place.dart';
import '../providers/saved_place_provider.dart';
import '../theme/app_colors.dart';
import '../theme/place_category_icon.dart';
import 'place_detail_screen.dart';

class SavedPlacesScreen extends ConsumerWidget {
  const SavedPlacesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedAsync = ref.watch(savedPlacesProvider);

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        title: Text(
          'Saqlangan joylar',
          style: TextStyle(
            color: AppColors.darkText(context),
            fontWeight: FontWeight.w700,
          ),
        ),
        iconTheme: IconThemeData(color: AppColors.darkText(context)),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(savedPlacesProvider),
        child: savedAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator(color: AppColors.orange)),
          error: (e, _) => _CenteredMessage(
            text: e is ApiException ? e.message : 'Yuklab bo\'lmadi',
          ),
          data: (items) {
            if (items.isEmpty) {
              return const _CenteredMessage(text: 'Hali saqlangan joy yo\'q');
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) => _SavedPlaceTile(item: items[index]),
            );
          },
        ),
      ),
    );
  }
}

class _CenteredMessage extends StatelessWidget {
  const _CenteredMessage({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 80),
          child: Center(
            child: Text(
              text,
              style: TextStyle(color: AppColors.mutedText(context)),
            ),
          ),
        ),
      ],
    );
  }
}

class _SavedPlaceTile extends StatelessWidget {
  const _SavedPlaceTile({required this.item});

  final SavedPlaceItem item;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => PlaceDetailScreen(place: item.toPlace())),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                placeCategoryIcon(item.category.name),
                color: AppColors.orange,
                size: 22,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    item.category.name,
                    style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.mutedText(context)),
          ],
        ),
      ),
    );
  }
}
