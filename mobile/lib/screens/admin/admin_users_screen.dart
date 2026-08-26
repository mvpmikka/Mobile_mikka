import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../models/admin_user.dart';
import '../../models/user.dart';
import '../../providers/admin_provider.dart';
import '../../theme/app_colors.dart';
import 'widgets/admin_loading_indicator.dart';

class AdminUsersScreen extends ConsumerStatefulWidget {
  const AdminUsersScreen({super.key});

  @override
  ConsumerState<AdminUsersScreen> createState() => _AdminUsersScreenState();
}

class _AdminUsersScreenState extends ConsumerState<AdminUsersScreen> {
  final _searchController = TextEditingController();
  String _search = '';
  bool _isMutating = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _toggleBan(AdminUser user) async {
    setState(() => _isMutating = true);
    try {
      if (user.isBanned) {
        await ref.read(adminServiceProvider).unbanUser(user.id);
      } else {
        await ref.read(adminServiceProvider).banUser(user.id);
      }
      ref.invalidate(adminUsersProvider);
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message), backgroundColor: const Color(0xFFCB4B4B)),
      );
    } finally {
      if (mounted) setState(() => _isMutating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final usersAsync = ref.watch(adminUsersProvider);
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      appBar: AppBar(
        backgroundColor: AppColors.cream(context),
        elevation: 0,
        foregroundColor: AppColors.darkText(context),
        title: Text(
          'Foydalanuvchilar',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkText(context)),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Email, username yoki ism bo\'yicha qidirish',
                  prefixIcon: Icon(Icons.search, color: AppColors.mutedText(context)),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: AppColors.fieldBorder(context)),
                  ),
                ),
                onSubmitted: (value) {
                  setState(() => _search = value.trim());
                  ref.invalidate(adminUsersProvider);
                },
              ),
            ),
            Expanded(
              child: usersAsync.when(
                loading: () => const Center(
                  child: AdminLoadingIndicator(),
                ),
                error: (e, _) => Center(
                  child: Text(
                    e is ApiException ? e.message : 'Xatolik yuz berdi',
                    style: TextStyle(color: AppColors.mutedText(context)),
                  ),
                ),
                data: (page) {
                  final users = _search.isEmpty
                      ? page.items
                      : page.items
                          .where(
                            (u) =>
                                u.email.toLowerCase().contains(_search.toLowerCase()) ||
                                (u.username ?? '').toLowerCase().contains(
                                      _search.toLowerCase(),
                                    ) ||
                                (u.fullName ?? '').toLowerCase().contains(
                                      _search.toLowerCase(),
                                    ),
                          )
                          .toList();
                  if (users.isEmpty) {
                    return Center(
                      child: Text(
                        'Foydalanuvchi topilmadi',
                        style: TextStyle(color: AppColors.mutedText(context)),
                      ),
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: users.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      return Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surface(context),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.fieldBorder(context)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    user.fullName ?? user.username ?? user.email,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.darkText(context),
                                    ),
                                  ),
                                  Text(
                                    user.email,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: AppColors.mutedText(context),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _Badge(text: _roleLabel(user.role)),
                                      if (user.isBanned) ...[
                                        const SizedBox(width: 6),
                                        const _Badge(
                                          text: 'BANNED',
                                          color: Color(0xFFCB4B4B),
                                        ),
                                      ],
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            TextButton(
                              onPressed: _isMutating ? null : () => _toggleBan(user),
                              style: TextButton.styleFrom(
                                foregroundColor: user.isBanned
                                    ? AppColors.orange
                                    : const Color(0xFFCB4B4B),
                              ),
                              child: Text(user.isBanned ? 'Unban' : 'Ban'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _roleLabel(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'SUPER ADMIN';
      case UserRole.admin:
        return 'ADMIN';
      case UserRole.user:
        return 'USER';
    }
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.text, this.color = AppColors.orange});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}
