import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'admin_business_customers_screen.dart';

/// MIKKA Business mobil "Mijoz tafsilotlari" ekrani — Figma dizaynidagi
/// panel bilan mos sof UI. Faoliyat/buyurtma/band/sharh tarixi lokal
/// namunaviy ma'lumot — hech qanday backend/servis chaqiruvi yo'q.
class AdminBusinessCustomerDetailScreen extends StatefulWidget {
  const AdminBusinessCustomerDetailScreen({super.key, required this.customer});

  final AdminBusinessCustomer customer;

  @override
  State<AdminBusinessCustomerDetailScreen> createState() =>
      _AdminBusinessCustomerDetailScreenState();
}

class _AdminBusinessCustomerDetailScreenState extends State<AdminBusinessCustomerDetailScreen> {
  static const _tabs = ['Faoliyat', 'Buyurtmalar', 'Bandlar', 'Sharhlar'];
  int _selectedTab = 0;
  late bool _isActive = widget.customer.isActive;

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final customer = widget.customer;
    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  InkWell(
                    onTap: () => Navigator.of(context).maybePop(),
                    customBorder: const CircleBorder(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.fieldBorder(context)),
                      ),
                      child: Icon(Icons.arrow_back, size: 18, color: AppColors.darkText(context)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Mijoz profili',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText(context),
                      ),
                    ),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(top: 16, bottom: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _CustomerHeroCard(
                        customer: customer,
                        isActive: _isActive,
                        onMessage: () => _showMessage('Xabar yuborish tez orada qo\'shiladi'),
                        onToggleBlock: () => setState(() => _isActive = !_isActive),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _StatTile(
                              icon: Icons.directions_walk,
                              value: '${customer.visits}',
                              label: 'Jami tashriflar',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatTile(
                              icon: Icons.payments_outlined,
                              value: '${customer.totalSpent} so\'m',
                              label: 'Jami sarflangan',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      _OrdersBookingsTile(orders: customer.orders, bookings: customer.bookings),
                      const SizedBox(height: 16),
                      _ContactInfoCard(customer: customer),
                      const SizedBox(height: 20),
                      _TabSelector(
                        tabs: _tabs,
                        selectedIndex: _selectedTab,
                        onSelected: (index) => setState(() => _selectedTab = index),
                      ),
                      const SizedBox(height: 14),
                      _TabContent(index: _selectedTab),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CustomerHeroCard extends StatelessWidget {
  const _CustomerHeroCard({
    required this.customer,
    required this.isActive,
    required this.onMessage,
    required this.onToggleBlock,
  });

  final AdminBusinessCustomer customer;
  final bool isActive;
  final VoidCallback onMessage;
  final VoidCallback onToggleBlock;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: customer.avatarColor,
                child: Text(
                  customer.name.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText(context),
                      ),
                    ),
                    Text(
                      customer.username,
                      style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: AppColors.adminBrandGradient,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: TextButton.icon(
                    onPressed: onMessage,
                    style: TextButton.styleFrom(
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 16),
                    label: const Text('Xabar', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton(
                  onPressed: onToggleBlock,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFCB4B4B),
                    side: const BorderSide(color: Color(0xFFCB4B4B)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(isActive ? 'Bloklash' : 'Blokdan chiqarish'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.icon, required this.value, required this.label});

  final IconData icon;
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: AppColors.orange),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText(context),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 10, color: AppColors.mutedText(context)),
          ),
        ],
      ),
    );
  }
}

class _OrdersBookingsTile extends StatelessWidget {
  const _OrdersBookingsTile({required this.orders, required this.bookings});

  final int orders;
  final int bookings;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shopping_bag_outlined, color: AppColors.orange, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$orders / $bookings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.darkText(context),
                  ),
                ),
                Text(
                  'Buyurtmalar / Bandlar',
                  style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ContactInfoCard extends StatelessWidget {
  const _ContactInfoCard({required this.customer});

  final AdminBusinessCustomer customer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _ContactRow(icon: Icons.call_outlined, value: customer.phone),
          const SizedBox(height: 10),
          _ContactRow(icon: Icons.location_on_outlined, value: customer.location),
          const SizedBox(height: 10),
          _ContactRow(icon: Icons.calendar_today_outlined, value: '${customer.customerSince} dan buyon mijoz'),
        ],
      ),
    );
  }
}

class _ContactRow extends StatelessWidget {
  const _ContactRow({required this.icon, required this.value});

  final IconData icon;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.orange),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 13, color: AppColors.darkText(context)),
          ),
        ),
      ],
    );
  }
}

class _TabSelector extends StatelessWidget {
  const _TabSelector({required this.tabs, required this.selectedIndex, required this.onSelected});

  final List<String> tabs;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < tabs.length; i++)
          Expanded(
            child: InkWell(
              onTap: () => onSelected(i),
              child: Container(
                padding: const EdgeInsets.only(bottom: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: i == selectedIndex
                          ? AppColors.adminGradientMid
                          : AppColors.fieldBorder(context),
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  tabs[i],
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: i == selectedIndex
                        ? AppColors.adminGradientMid
                        : AppColors.mutedText(context),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _TimelineEntry {
  const _TimelineEntry({required this.title, required this.time, required this.isLatest});

  final String title;
  final String time;
  final bool isLatest;
}

const _activity = [
  _TimelineEntry(title: 'Buyurtma berdi #ORD-102 • 45 000 so\'m', time: '2 soat oldin', isLatest: true),
  _TimelineEntry(title: 'Band #BKG-05 ni yakunladi • 2 kishilik stol', time: 'Kecha', isLatest: false),
  _TimelineEntry(title: '5 yulduzli sharh qoldirdi', time: '1 hafta oldin', isLatest: false),
];

class _TabContent extends StatelessWidget {
  const _TabContent({required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 1:
        return const _InfoRowCard(
          icon: Icons.receipt_long_outlined,
          title: '#ORD-102',
          subtitle: '45 000 so\'m',
          time: '2 soat oldin',
        );
      case 2:
        return const _InfoRowCard(
          icon: Icons.event_note_outlined,
          title: '#BKG-05',
          subtitle: 'Stol T04 • 2 kishi',
          time: 'Kecha',
        );
      case 3:
        return const _InfoRowCard(
          icon: Icons.star_outline,
          title: '5 yulduz',
          subtitle: 'Zo\'r xizmat va mazali taomlar!',
          time: '1 hafta oldin',
        );
      default:
        return Column(
          children: [
            for (final entry in _activity) ...[
              _ActivityRow(entry: entry),
              if (entry != _activity.last) const SizedBox(height: 10),
            ],
          ],
        );
    }
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry});

  final _TimelineEntry entry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: entry.isLatest ? AppColors.adminGradientMid : AppColors.fieldBorder(context),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.fieldBorder(context)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.darkText(context),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  entry.time,
                  style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoRowCard extends StatelessWidget {
  const _InfoRowCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: AppColors.orange),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText(context)),
                ),
                Text(
                  subtitle,
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                ),
              ],
            ),
          ),
          Text(
            time,
            style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
          ),
        ],
      ),
    );
  }
}
