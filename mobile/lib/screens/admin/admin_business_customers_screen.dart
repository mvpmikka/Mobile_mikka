import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../models/customer.dart';
import '../../providers/customer_provider.dart';
import '../../theme/app_colors.dart';
import 'admin_business_customer_detail_screen.dart';
import 'widgets/admin_section_topbar.dart';

const _avatarColors = [
  Color(0xFF3B6EA8),
  Color(0xFF8A5A3B),
  Color(0xFF6B6B6B),
  Color(0xFF3F9142),
  Color(0xFFC9922E),
  Color(0xFFCB4B4B),
];

Color avatarColorFor(String phone) => _avatarColors[phone.hashCode.abs() % _avatarColors.length];

/// MIKKA Business mobil "Mijozlar" ekrani — [customerListProvider] orqali
/// `/places/:placeId/customers` bilan ulangan.
class AdminBusinessCustomersScreen extends ConsumerStatefulWidget {
  const AdminBusinessCustomersScreen({super.key, required this.placeId});

  final String placeId;

  @override
  ConsumerState<AdminBusinessCustomersScreen> createState() =>
      _AdminBusinessCustomersScreenState();
}

class _AdminBusinessCustomersScreenState extends ConsumerState<AdminBusinessCustomersScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _refresh() {
    ref.invalidate(customerListProvider(widget.placeId));
  }

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref.watch(customerListProvider(widget.placeId));

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSectionTopBar(
                title: 'Mijozlar',
                onNotification: () => _showMessage('Bildirishnomalar tez orada qo\'shiladi'),
                searchController: _searchController,
                searchHint: 'Ism, telefon bo\'yicha qidirish...',
                onSearchChanged: (value) {
                  ref.read(customerQueryProvider.notifier).update(
                        (q) => q.copyWith(search: value, clearSearch: value.isEmpty),
                      );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'Mijozlar bazangizni boshqaring va ko\'ring.',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: customersAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => _ErrorState(
                    message: error is ApiException ? error.message : 'Mijozlar yuklanmadi',
                    onRetry: _refresh,
                  ),
                  data: (page) {
                    if (page.items.isEmpty) {
                      return Center(
                        child: Text(
                          'Mijoz topilmadi',
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      );
                    }
                    return ListView.separated(
                      padding: const EdgeInsets.only(bottom: 16),
                      itemCount: page.items.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final customer = page.items[index];
                        return _CustomerCard(
                          customer: customer,
                          onTap: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => AdminBusinessCustomerDetailScreen(
                                placeId: widget.placeId,
                                phone: customer.customerPhone,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  customersAsync.valueOrNull != null
                      ? '${customersAsync.value!.items.length} / ${customersAsync.value!.total} mijoz'
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

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.onTap});

  final Customer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isActive = !customer.isBlocked;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.fieldBorder(context)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 20,
              backgroundColor: _avatarColorFor(customer.customerPhone),
              child: Text(
                customer.customerName.isEmpty ? '?' : customer.customerName.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.customerName,
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText(context)),
                  ),
                  Text(
                    customer.customerPhone,
                    style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MiniStat(icon: Icons.receipt_long_outlined, value: '${customer.ordersCount}'),
                      const SizedBox(width: 12),
                      _MiniStat(icon: Icons.event_note_outlined, value: '${customer.bookingsCount}'),
                      const SizedBox(width: 12),
                      _MiniStat(icon: Icons.payments_outlined, value: '${customer.totalSpent}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (isActive ? const Color(0xFF3F9142) : const Color(0xFFCB4B4B))
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isActive ? 'FAOL' : 'BLOKLANGAN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isActive ? const Color(0xFF3F9142) : const Color(0xFFCB4B4B),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.mutedText(context)),
        const SizedBox(width: 3),
        Text(value, style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
      ],
    );
  }
}
