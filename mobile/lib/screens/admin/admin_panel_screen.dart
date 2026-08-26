import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../models/user.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme/app_colors.dart';
import 'admin_categories_screen.dart';
import 'admin_places_screen.dart';
import 'admin_super_dashboard_screen.dart';
import 'admin_users_screen.dart';
import 'widgets/admin_loading_indicator.dart';

class AdminPanelScreen extends ConsumerWidget {
  const AdminPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);
    final isSuperAdmin =
        ref.watch(authControllerProvider).value?.user?.role == UserRole.superAdmin;
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        foregroundColor: AppColors.darkText(context),
        title: Text(
          'Admin panel',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkText(context)),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            statsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: AdminLoadingIndicator(),
                ),
              ),
              error: (e, _) => Text(
                e is ApiException ? e.message : 'Statistikani yuklab bo\'lmadi',
                style: TextStyle(color: AppColors.mutedText(context)),
              ),
              data: (stats) => Row(
                children: [
                  _StatCard(label: 'Foydalanuvchi', value: stats.totalUsers),
                  const SizedBox(width: 10),
                  _StatCard(label: 'Joylar', value: stats.totalPlaces),
                  const SizedBox(width: 10),
                  _StatCard(label: 'Sharhlar', value: stats.totalReviews),
                  const SizedBox(width: 10),
                  _StatCard(label: 'Check-inlar', value: stats.totalCheckIns),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _AdminMenuCard(
              icon: Icons.storefront_outlined,
              title: 'Joylar',
              subtitle: 'Restoran, kafe va boshqa joylarni qo\'shish, tahrirlash',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminPlacesScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _AdminMenuCard(
              icon: Icons.category_outlined,
              title: 'Kategoriyalar',
              subtitle: 'Joy turlarini boshqarish (restoran, kafe, park...)',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminCategoriesScreen()),
                );
              },
            ),
            const SizedBox(height: 12),
            _AdminMenuCard(
              icon: Icons.people_outline,
              title: 'Foydalanuvchilar',
              subtitle: 'Ro\'yxat, qidiruv, ban qilish',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AdminUsersScreen()),
                );
              },
            ),
            if (isSuperAdmin) ...[
              const SizedBox(height: 12),
              _AdminMenuCard(
                icon: Icons.insights_outlined,
                title: 'Super admin dashboard',
                subtitle: 'Rollar, moderatsiya, o\'sish va hudud statistikasi',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AdminSuperDashboardScreen()),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.fieldBorder(context)),
        ),
        child: Column(
          children: [
            Text(
              '$value',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.orange,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 10, color: AppColors.mutedText(context)),
            ),
          ],
        ),
      ),
    );
  }
}

class _AdminMenuCard extends StatelessWidget {
  const _AdminMenuCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.fieldBorder(context)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: AppColors.orange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppColors.orange, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.darkText(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
