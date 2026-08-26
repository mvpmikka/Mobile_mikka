import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'widgets/admin_pagination_bar.dart';
import 'widgets/admin_section_topbar.dart';

enum _OrderStatus { newOrder, accepted, preparing, ready, completed, cancelled }

extension on _OrderStatus {
  String get label {
    switch (this) {
      case _OrderStatus.newOrder:
        return 'Yangi';
      case _OrderStatus.accepted:
        return 'Qabul qilindi';
      case _OrderStatus.preparing:
        return 'Tayyorlanmoqda';
      case _OrderStatus.ready:
        return 'Tayyor';
      case _OrderStatus.completed:
        return 'Bajarildi';
      case _OrderStatus.cancelled:
        return 'Bekor qilindi';
    }
  }

  Color get color {
    switch (this) {
      case _OrderStatus.newOrder:
        return const Color(0xFFCB4B4B);
      case _OrderStatus.accepted:
        return AppColors.adminGradientMid;
      case _OrderStatus.preparing:
        return const Color(0xFFC9922E);
      case _OrderStatus.ready:
        return const Color(0xFF3B6EA8);
      case _OrderStatus.completed:
        return const Color(0xFF3F9142);
      case _OrderStatus.cancelled:
        return const Color(0xFF8A7E72);
    }
  }
}

class _Order {
  const _Order({
    required this.id,
    required this.customer,
    required this.phone,
    required this.items,
    required this.total,
    required this.time,
    required this.status,
    required this.avatarColor,
  });

  final String id;
  final String customer;
  final String phone;
  final String items;
  final String total;
  final String time;
  final _OrderStatus status;
  final Color avatarColor;
}

const _orders = [
  _Order(
    id: '#1025',
    customer: 'Madina',
    phone: '+998 90 123 45 67',
    items: 'Margarita pitsa x1, Fanta x2',
    total: '145 000',
    time: 'Bugun, 14:32',
    status: _OrderStatus.newOrder,
    avatarColor: Color(0xFF3B6EA8),
  ),
  _Order(
    id: '#1024',
    customer: 'Aziz',
    phone: '+998 99 765 43 21',
    items: 'Lavash x2, Kola x1',
    total: '85 000',
    time: 'Bugun, 13:15',
    status: _OrderStatus.completed,
    avatarColor: Color(0xFF6B6B6B),
  ),
  _Order(
    id: '#1023',
    customer: 'Jasur',
    phone: '+998 94 555 12 34',
    items: 'Burger combo x3',
    total: '180 000',
    time: 'Bugun, 12:45',
    status: _OrderStatus.preparing,
    avatarColor: Color(0xFF8A5A3B),
  ),
];

/// MIKKA Business mobil "Buyurtmalar" ekrani — Figma dizayni asosidagi
/// sof UI. Buyurtmalar ro'yxati lokal namunaviy ma'lumot — hech qanday
/// backend/servis chaqiruvi yo'q.
class AdminBusinessOrdersScreen extends StatefulWidget {
  const AdminBusinessOrdersScreen({super.key});

  @override
  State<AdminBusinessOrdersScreen> createState() => _AdminBusinessOrdersScreenState();
}

class _AdminBusinessOrdersScreenState extends State<AdminBusinessOrdersScreen> {
  final _searchController = TextEditingController();
  _OrderStatus? _statusFilter;

  // Namunaviy jami buyurtmalar soni (Figma dizaynidagi "42" bilan mos) —
  // sahifalash faqat UI ko'rinishi, chunki lokal ma'lumotda atigi 3 ta namuna bor.
  static const _catalogTotal = 42;
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

  List<_Order> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _orders.where((order) {
      final matchesStatus = _statusFilter == null || order.status == _statusFilter;
      final matchesQuery = query.isEmpty ||
          order.customer.toLowerCase().contains(query) ||
          order.id.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final orders = _filtered;
    final newCount = _orders.where((order) => order.status == _OrderStatus.newOrder).length;

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSectionTopBar(
                title: 'Buyurtmalar',
                onNotification: () => _showMessage('Bildirishnomalar tez orada qo\'shiladi'),
                searchController: _searchController,
                searchHint: 'Buyurtma ID, mijoz bo\'yicha qidirish...',
                onSearchChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Mijozlar buyurtmalarini boshqaring va kuzating.',
                      style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                    ),
                  ),
                  InkWell(
                    onTap: () => _showMessage('Sana filtri tez orada qo\'shiladi'),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.surface(context),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.fieldBorder(context)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12, color: AppColors.darkText(context)),
                          const SizedBox(width: 6),
                          Text('Bugun',
                              style: TextStyle(fontSize: 12, color: AppColors.darkText(context))),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showMessage('Filtrlar tez orada qo\'shiladi'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.darkText(context),
                        side: BorderSide(color: AppColors.fieldBorder(context)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.filter_list, size: 16),
                      label: const Text('Filtrlar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.adminBrandGradient,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton.icon(
                        onPressed: () => _showMessage('Eksport qilish tez orada qo\'shiladi'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.download_outlined, size: 16),
                        label: const Text('Eksport', style: TextStyle(fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    _StatusChip(
                      label: 'Barchasi',
                      isSelected: _statusFilter == null,
                      onTap: () => setState(() => _statusFilter = null),
                    ),
                    for (final status in _OrderStatus.values) ...[
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: status == _OrderStatus.newOrder
                            ? '${status.label} ($newCount)'
                            : status.label,
                        isSelected: _statusFilter == status,
                        color: status.color,
                        onTap: () => setState(() => _statusFilter = status),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: orders.isEmpty
                    ? Center(
                        child: Text(
                          'Buyurtma topilmadi',
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: orders.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _OrderCard(
                          order: orders[index],
                          onTap: () =>
                              _showMessage('${orders[index].id} tafsilotlari tez orada'),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Text(
                      '${(_currentPage - 1) * _pageSize + 1}-${_currentPage * _pageSize} / $_catalogTotal buyurtma',
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

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.color,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? AppColors.adminGradientMid;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onTap(),
      selectedColor: chipColor.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: isSelected ? chipColor : AppColors.mutedText(context),
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
      side: BorderSide(color: isSelected ? chipColor : AppColors.fieldBorder(context)),
      backgroundColor: AppColors.surface(context),
    );
  }
}

class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.onTap});

  final _Order order;
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
          border: Border(left: BorderSide(color: order.status.color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  order.id,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: order.status.color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: order.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: order.status.color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: order.avatarColor,
                  child: Text(
                    order.customer.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        order.customer,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText(context),
                        ),
                      ),
                      Text(
                        order.phone,
                        style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              order.items,
              style: TextStyle(fontSize: 13, color: AppColors.darkText(context)),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  order.time,
                  style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                ),
                const Spacer(),
                Text(
                  '${order.total} so\'m',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText(context),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
