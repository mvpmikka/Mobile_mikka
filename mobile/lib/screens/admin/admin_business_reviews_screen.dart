import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'widgets/admin_pagination_bar.dart';
import 'widgets/admin_section_topbar.dart';

class _Review {
  const _Review({
    required this.id,
    required this.customer,
    required this.avatarColor,
    required this.rating,
    required this.comment,
    required this.date,
    this.reply,
  });

  final String id;
  final String customer;
  final Color avatarColor;
  final int rating;
  final String comment;
  final String date;
  final String? reply;
}

const _reviews = [
  _Review(
    id: '#R331',
    customer: 'Madina',
    avatarColor: Color(0xFF3B6EA8),
    rating: 5,
    comment: 'Ovqat juda mazali va xizmat tez edi! Albatta yana qaytaman.',
    date: '2 kun oldin',
  ),
  _Review(
    id: '#R328',
    customer: 'Aziz',
    avatarColor: Color(0xFF8A5A3B),
    rating: 3,
    comment: 'Yaxshi, lekin zalda biroz shovqinli edi.',
    date: '5 kun oldin',
    reply: 'Fikr-mulohazangiz uchun rahmat, buni hisobga olamiz!',
  ),
  _Review(
    id: '#R320',
    customer: 'Jasur',
    avatarColor: Color(0xFF6B6B6B),
    rating: 4,
    comment: 'Yetkazib berish tez bo\'ldi, ammo taom biroz sovuq keldi.',
    date: '1 hafta oldin',
  ),
];

// Namunaviy umumiy reyting statistikasi (Figma dizaynidagi uslub bilan mos)
// — lokal ma'lumotda atigi 3 ta sharh bor, shuning uchun bu qiymatlar
// faqat UI ko'rinishi uchun qattiq kodlangan.
const _averageRating = 4.6;
const _totalReviews = 128;
const _ratingBreakdown = {5: 0.70, 4: 0.20, 3: 0.07, 2: 0.02, 1: 0.01};

/// MIKKA Business mobil "Sharhlar" ekrani — Figma dizayni asosidagi sof UI.
/// Sharhlar ro'yxati lokal namunaviy ma'lumot — hech qanday backend/servis
/// chaqiruvi yo'q.
class AdminBusinessReviewsScreen extends StatefulWidget {
  const AdminBusinessReviewsScreen({super.key});

  @override
  State<AdminBusinessReviewsScreen> createState() => _AdminBusinessReviewsScreenState();
}

class _AdminBusinessReviewsScreenState extends State<AdminBusinessReviewsScreen> {
  final _searchController = TextEditingController();
  String _filter = 'Barchasi';
  static const _filters = ['Barchasi', 'Javobsiz', '5 yulduz', '4 yulduz', '3 va past'];

  static const _catalogTotal = 128;
  static const _pageSize = 3;
  int _currentPage = 1;
  int get _totalPages => (_catalogTotal / _pageSize).ceil();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  List<_Review> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _reviews.where((review) {
      final matchesFilter = switch (_filter) {
        'Javobsiz' => review.reply == null,
        '5 yulduz' => review.rating == 5,
        '4 yulduz' => review.rating == 4,
        '3 va past' => review.rating <= 3,
        _ => true,
      };
      final matchesQuery = query.isEmpty ||
          review.customer.toLowerCase().contains(query) ||
          review.comment.toLowerCase().contains(query);
      return matchesFilter && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final reviews = _filtered;
    final unansweredCount = _reviews.where((r) => r.reply == null).length;

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
              const _RatingSummaryCard(),
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
                    final label =
                        filter == 'Javobsiz' ? '$filter ($unansweredCount)' : filter;
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
                child: reviews.isEmpty
                    ? Center(
                        child: Text(
                          'Sharh topilmadi',
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: reviews.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _ReviewCard(
                          review: reviews[index],
                          onReply: () => _showMessage('${reviews[index].id} ga javob berish tez orada'),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Text(
                      '${(_currentPage - 1) * _pageSize + 1}-${_currentPage * _pageSize} / $_catalogTotal sharh',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                    ),
                    const SizedBox(height: 8),
                    AdminPaginationBar(
                      currentPage: _currentPage,
                      totalPages: _totalPages,
                      onPageChanged: (page) {
                        setState(() => _currentPage = page);
                        if (page != 1) {
                          _showMessage('Namunada faqat 1-sahifa ma\'lumotlari mavjud');
                        }
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RatingSummaryCard extends StatelessWidget {
  const _RatingSummaryCard();

  @override
  Widget build(BuildContext context) {
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
                _averageRating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  color: AppColors.darkText(context),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (i) {
                  final filled = i < _averageRating.round();
                  return Icon(
                    filled ? Icons.star : Icons.star_border,
                    size: 13,
                    color: const Color(0xFFC9922E),
                  );
                }),
              ),
              const SizedBox(height: 2),
              Text(
                '$_totalReviews sharh',
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
                              value: _ratingBreakdown[star],
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

  final _Review review;
  final VoidCallback onReply;

  @override
  Widget build(BuildContext context) {
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
                backgroundColor: review.avatarColor,
                child: Text(
                  review.customer.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.customer,
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
                          review.date,
                          style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            review.comment,
            style: TextStyle(fontSize: 13, color: AppColors.darkText(context)),
          ),
          const SizedBox(height: 10),
          if (review.reply != null)
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
                    review.reply!,
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
