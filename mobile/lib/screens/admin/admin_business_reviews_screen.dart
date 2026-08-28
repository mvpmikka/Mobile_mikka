import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../models/place.dart';
import '../../models/review.dart';
import '../../providers/place_provider.dart';
import '../../providers/review_provider.dart';
import '../../theme/app_colors.dart';
import 'widgets/admin_section_topbar.dart';

const _avatarColors = [
  Color(0xFF3B6EA8),
  Color(0xFF8A5A3B),
  Color(0xFF6B6B6B),
  Color(0xFF3F9142),
  Color(0xFFC9922E),
];

Color _avatarColorFor(String id) => _avatarColors[id.hashCode.abs() % _avatarColors.length];

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

/// MIKKA Business mobil "Sharhlar" ekrani — [placeReviewListProvider] orqali
/// `/places/:placeId/reviews` va [placeRatingProvider] orqali
/// `/places/:placeId/rating` bilan ulangan.
class AdminBusinessReviewsScreen extends ConsumerStatefulWidget {
  const AdminBusinessReviewsScreen({super.key, required this.placeId});

  final String placeId;

  @override
  ConsumerState<AdminBusinessReviewsScreen> createState() =>
      _AdminBusinessReviewsScreenState();
}

class _AdminBusinessReviewsScreenState extends ConsumerState<AdminBusinessReviewsScreen> {
  final _searchController = TextEditingController();
  String _filter = 'Barchasi';
  static const _filters = ['Barchasi', 'Javobsiz', '5 yulduz', '4 yulduz', '3 va past'];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _refresh() {
    ref.invalidate(placeReviewListProvider(widget.placeId));
    ref.invalidate(placeRatingProvider(widget.placeId));
  }

  List<PlaceReview> _applyFilters(List<PlaceReview> reviews) {
    final query = _searchController.text.trim().toLowerCase();
    return reviews.where((review) {
      final matchesFilter = switch (_filter) {
        'Javobsiz' => review.ownerReply == null,
        '5 yulduz' => review.rating == 5,
        '4 yulduz' => review.rating == 4,
        '3 va past' => review.rating <= 3,
        _ => true,
      };
      final matchesQuery = query.isEmpty ||
          review.user.username.toLowerCase().contains(query) ||
          (review.user.fullName?.toLowerCase().contains(query) ?? false) ||
          (review.comment?.toLowerCase().contains(query) ?? false);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  Future<void> _openReplySheet(PlaceReview review) async {
    final controller = TextEditingController();
    final text = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 16,
            bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Javob berish',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText(sheetContext),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                maxLines: 4,
                decoration: const InputDecoration(hintText: 'Javobingizni yozing...'),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.adminBrandGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextButton(
                    onPressed: () => Navigator.of(sheetContext).pop(controller.text.trim()),
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Yuborish', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
    if (text == null || text.isEmpty) return;
    try {
      await ref.read(reviewServiceProvider).replyToReview(widget.placeId, review.id, text);
      _refresh();
      if (mounted) _showMessage('Javob yuborildi');
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(placeReviewListProvider(widget.placeId));
    final ratingAsync = ref.watch(placeRatingProvider(widget.placeId));
    final unansweredCount =
        reviewsAsync.valueOrNull?.items.where((r) => r.ownerReply == null).length;

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSectionTopBar(
                title: 'Sharhlar',
                onNotification: () => _showMessage('Bildirishnomalar tez orada qo\'shiladi'),
                searchController: _searchController,
                searchHint: 'Mijoz yoki sharh bo\'yicha qidirish...',
                onSearchChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 12),
              Text(
                'Mijozlar fikr-mulohazalarini kuzating va javob bering.',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
              ),
              const SizedBox(height: 12),
              _RatingSummaryCard(rating: ratingAsync.valueOrNull),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _filters.length,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (_, index) {
                    final filter = _filters[index];
                    final isSelected = filter == _filter;
                    final label = filter == 'Javobsiz' && unansweredCount != null
                        ? '$filter ($unansweredCount)'
                        : filter;
                    return ChoiceChip(
                      label: Text(label),
                      selected: isSelected,
                      onSelected: (_) => setState(() => _filter = filter),
                      selectedColor: AppColors.adminGradientMid.withValues(alpha: 0.15),
                      labelStyle: TextStyle(
                        color: isSelected
                            ? AppColors.adminGradientMid
                            : AppColors.mutedText(context),
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                      side: BorderSide(
                        color: isSelected
                            ? AppColors.adminGradientMid
                            : AppColors.fieldBorder(context),
                      ),
                      backgroundColor: AppColors.surface(context),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: reviewsAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ErrorState(
                    message: error is ApiException ? error.message : 'Sharhlar yuklanmadi',
                    onRetry: _refresh,
                  ),
                  data: (page) {
                    final reviews = _applyFilters(page.items);
                    if (reviews.isEmpty) {
                      return Center(
                        child: Text(
                          'Sharh topilmadi',
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: reviews.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) => _ReviewCard(
                        review: reviews[index],
                        onReply: () => _openReplySheet(reviews[index]),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  reviewsAsync.valueOrNull != null
                      ? '${reviewsAsync.value!.items.length} / ${reviewsAsync.value!.total} sharh'
                      : '',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.mutedText(context)),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text('Qayta urinish')),
          ],
        ),
      ),
    );
  }
}

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard({required this.rating});

  final PlaceRating? rating;

  @override
  Widget build(BuildContext context) {
    final average = rating?.averageRating ?? 0;
    final total = rating?.reviewCount ?? 0;
    final breakdown = rating?.breakdown ?? const {};
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Column(
            children: [
              Text(
                average.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText(context),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < average.round();
                  return Icon(
                    filled ? Icons.star : Icons.star_border,
                    size: 13,
                    color: const Color(0xFFC9922E),
                  );
                }),
              ),
              const SizedBox(height: 2),
              Text(
                '$total sharh',
                style: TextStyle(fontSize: 10, color: AppColors.mutedText(context)),
              ),
            ],
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              children: [
                for (final star in [5, 4, 3, 2, 1])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Text(
                          '$star',
                          style: TextStyle(fontSize: 10, color: AppColors.mutedText(context)),
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: total > 0 ? (breakdown[star] ?? 0) / total : 0,
                              minHeight: 6,
                              backgroundColor: AppColors.cream(context),
                              valueColor:
                                  const AlwaysStoppedAnimation(Color(0xFFC9922E)),
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

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.review, required this.onReply});

  final PlaceReview review;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
    final displayName = review.user.fullName?.isNotEmpty == true
        ? review.user.fullName!
        : review.user.username;
    return Container(
      padding: const EdgeInsets.all(12),
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
              CircleAvatar(
                radius: 16,
                backgroundColor: _avatarColorFor(review.user.id),
                child: Text(
                  displayName.isEmpty ? '?' : displayName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText(context),
                      ),
                    ),
                    Row(
                      children: [
                        ...List.generate(
                          5,
                          (i) => Icon(
                            i < review.rating ? Icons.star : Icons.star_border,
                            size: 12,
                            color: const Color(0xFFC9922E),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _fmtDate(review.createdAt),
                          style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment != null && review.comment!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              review.comment!,
              style: TextStyle(fontSize: 13, color: AppColors.darkText(context)),
            ),
          ],
          const SizedBox(height: 10),
          if (review.ownerReply != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.cream(context),
                borderRadius: BorderRadius.circular(12),
                border: Border(left: BorderSide(color: AppColors.adminGradientMid, width: 3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sizning javobingiz',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: AppColors.adminGradientMid,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    review.ownerReply!,
                    style: TextStyle(fontSize: 12, color: AppColors.darkText(context)),
                  ),
                ],
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onReply,
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.darkText(context),
                  side: BorderSide(color: AppColors.fieldBorder(context)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.reply, size: 15),
                label: const Text('Javob berish', style: TextStyle(fontSize: 12)),
              ),
            ),
        ],
      ),
    );
  }
}
