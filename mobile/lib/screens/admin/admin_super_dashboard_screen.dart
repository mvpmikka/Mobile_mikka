import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../models/super_admin_dashboard.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_colors.dart';

const _monthLabels = [
  'Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyun',
  'Iyul', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek',
];

class AdminSuperDashboardScreen extends ConsumerWidget {
  const AdminSuperDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(adminSuperDashboardProvider);
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        foregroundColor: AppColors.darkText(context),
        title: Text(
          'Super admin dashboard',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkText(context)),
        ),
      ),
      body: SafeArea(
        child: dashboardAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.orange),
          ),
          error: (e, _) => Center(
            child: Text(
              e is ApiException ? e.message : 'Xatolik yuz berdi',
              style: TextStyle(color: AppColors.mutedText(context)),
            ),
          ),
          data: (dashboard) => RefreshIndicator(
            color: AppColors.orange,
            onRefresh: () async => ref.invalidate(adminSuperDashboardProvider),
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _StatCard(label: 'Adminlar', value: dashboard.totalAdmins),
                    _StatCard(label: 'Super adminlar', value: dashboard.totalSuperAdmins),
                    _StatCard(
                      label: 'Bloklangan',
                      value: dashboard.bannedUsers,
                      color: const Color(0xFFCB4B4B),
                    ),
                    _StatCard(label: 'Suhbatlar', value: dashboard.totalConversations),
                    _StatCard(label: 'Xabarlar', value: dashboard.totalMessages),
                  ],
                ),
                const SizedBox(height: 24),
                _SectionCard(
                  title: 'Foydalanuvchilar o\'sishi (6 oy)',
                  child: _MonthlyGrowthChart(data: dashboard.userGrowthLast6Months),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Hudud bo\'yicha joylar',
                  child: _RegionBreakdownList(data: dashboard.placesByRegion),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, this.color = AppColors.orange});

  final String label;
  final int value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 104,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Column(
        children: [
          Text(
            '$value',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText(context),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _MonthlyGrowthChart extends StatelessWidget {
  const _MonthlyGrowthChart({required this.data});

  final List<MonthlyUserGrowth> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Text(
        'Ma\'lumot yo\'q',
        style: TextStyle(color: AppColors.mutedText(context)),
      );
    }
    final maxValue = data.map((e) => e.newUsers).fold(0, (a, b) => a > b ? a : b);
    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in data)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      '${point.newUsers}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.darkText(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                      child: Container(
                        height: maxValue == 0
                            ? 4
                            : 4 + (point.newUsers / maxValue) * 88,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [AppColors.orange, Color(0xFFF4A94F)],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _formatMonth(point.month),
                      style: TextStyle(fontSize: 10, color: AppColors.mutedText(context)),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatMonth(String month) {
    final parts = month.split('-');
    if (parts.length != 2) return month;
    final index = int.tryParse(parts[1]);
    if (index == null || index < 1 || index > 12) return month;
    return _monthLabels[index - 1];
  }
}

class _RegionBreakdownList extends StatelessWidget {
  const _RegionBreakdownList({required this.data});

  final List<RegionPlaceBreakdown> data;

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return Text(
        'Ma\'lumot yo\'q',
        style: TextStyle(color: AppColors.mutedText(context)),
      );
    }
    final maxCount = data.map((e) => e.placeCount).fold(0, (a, b) => a > b ? a : b);
    return Column(
      children: [
        for (final region in data)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      region.regionName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.darkText(context),
                      ),
                    ),
                    Text(
                      '${region.placeCount}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: maxCount == 0 ? 0 : region.placeCount / maxCount,
                    minHeight: 6,
                    backgroundColor: AppColors.fieldBorder(context),
                    valueColor: const AlwaysStoppedAnimation(AppColors.orange),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
