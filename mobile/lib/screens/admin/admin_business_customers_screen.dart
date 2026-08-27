import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'admin_business_customer_detail_screen.dart';
import 'widgets/admin_pagination_bar.dart';
import 'widgets/admin_section_topbar.dart';

/// A single customer summary shown in the list and passed through to the
/// detail screen. Pure UI data holder — no backend/service shape.
class AdminBusinessCustomer {
  const AdminBusinessCustomer({
    required this.name,
    required this.username,
    required this.phone,
    required this.visits,
    required this.orders,
    required this.bookings,
    required this.totalSpent,
    required this.location,
    required this.customerSince,
    required this.isActive,
    required this.avatarColor,
  });

  final String name;
  final String username;
  final String phone;
  final int visits;
  final int orders;
  final int bookings;
  final String totalSpent;
  final String location;
  final String customerSince;
  final bool isActive;
  final Color avatarColor;
}

const _customers = [
  AdminBusinessCustomer(
    name: 'Aziz Karimov',
    username: '@aziz_k',
    phone: '+998 90 123 45 67',
    visits: 12,
    orders: 8,
    bookings: 4,
    totalSpent: '450 000',
    location: 'Toshkent, O\'zbekiston',
    customerSince: 'Yanvar 2023',
    isActive: true,
    avatarColor: Color(0xFF3B6EA8),
  ),
  AdminBusinessCustomer(
    name: 'Madina Usmanova',
    username: '@madi_u',
    phone: '+998 93 987 65 43',
    visits: 5,
    orders: 5,
    bookings: 0,
    totalSpent: '210 000',
    location: 'Toshkent, O\'zbekiston',
    customerSince: 'Mart 2023',
    isActive: true,
    avatarColor: Color(0xFF8A5A3B),
  ),
  AdminBusinessCustomer(
    name: 'Bekzod Rakhimov',
    username: '@bek_r',
    phone: '+998 97 111 22 33',
    visits: 2,
    orders: 1,
    bookings: 1,
    totalSpent: '65 000',
    location: 'Samarqand, O\'zbekiston',
    customerSince: 'Iyun 2023',
    isActive: false,
    avatarColor: Color(0xFF6B6B6B),
  ),
];

/// MIKKA Business mobil "Mijozlar" ekrani — Figma dizayni asosidagi sof UI.
/// Mijozlar ro'yxati lokal namunaviy ma'lumot — hech qanday backend/servis
/// chaqiruvi yo'q.
class AdminBusinessCustomersScreen extends StatefulWidget {
  const AdminBusinessCustomersScreen({super.key});

  @override
  State<AdminBusinessCustomersScreen> createState() => _AdminBusinessCustomersScreenState();
}

class _AdminBusinessCustomersScreenState extends State<AdminBusinessCustomersScreen> {
  final _searchController = TextEditingController();

  static const _catalogTotal = 124;
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

  List<AdminBusinessCustomer> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _customers;
    return _customers.where((customer) {
      return customer.name.toLowerCase().contains(query) ||
          customer.username.toLowerCase().contains(query) ||
          customer.phone.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final customers = _filtered;

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
                onSearchChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Text(
                'Mijozlar bazangizni boshqaring va ko\'ring.',
                style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: customers.isEmpty
                    ? Center(
                        child: Text(
                          'Mijoz topilmadi',
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: customers.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, index) {
                          final customer = customers[index];
                          return _CustomerCard(
                            customer: customer,
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => AdminBusinessCustomerDetailScreen(customer: customer),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Text(
                      '${(_currentPage - 1) * _pageSize + 1}-${_currentPage * _pageSize} / $_catalogTotal mijoz',
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

class _CustomerCard extends StatelessWidget {
  const _CustomerCard({required this.customer, required this.onTap});

  final AdminBusinessCustomer customer;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
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
              backgroundColor: customer.avatarColor,
              child: Text(
                customer.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    customer.name,
                    style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText(context)),
                  ),
                  Text(
                    '${customer.username} • ${customer.phone}',
                    style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _MiniStat(icon: Icons.directions_walk, value: '${customer.visits}'),
                      const SizedBox(width: 12),
                      _MiniStat(icon: Icons.receipt_long_outlined, value: '${customer.orders}'),
                      const SizedBox(width: 12),
                      _MiniStat(icon: Icons.event_note_outlined, value: '${customer.bookings}'),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (customer.isActive ? const Color(0xFF3F9142) : const Color(0xFFCB4B4B))
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                customer.isActive ? 'FAOL' : 'BLOKLANGAN',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: customer.isActive ? const Color(0xFF3F9142) : const Color(0xFFCB4B4B),
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
