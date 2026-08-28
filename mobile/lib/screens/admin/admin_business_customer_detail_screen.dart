import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../models/booking.dart';
import '../../models/customer.dart';
import '../../models/order.dart';
import '../../providers/customer_provider.dart';
import '../../theme/app_colors.dart';
import 'admin_business_customers_screen.dart' show avatarColorFor;

/// MIKKA Business mobil "Mijoz tafsilotlari" ekrani —
/// [customerDetailProvider] orqali `/places/:placeId/customers/:phone`
/// bilan ulangan.
class AdminBusinessCustomerDetailScreen extends ConsumerStatefulWidget {
  const AdminBusinessCustomerDetailScreen({
    super.key,
    required this.placeId,
    required this.phone,
  });

  final String placeId;
  final String phone;

  @override
  ConsumerState<AdminBusinessCustomerDetailScreen> createState() =>
      _AdminBusinessCustomerDetailScreenState();
}

class _AdminBusinessCustomerDetailScreenState
    extends ConsumerState<AdminBusinessCustomerDetailScreen> {
  static const _tabs = ['Faoliyat', 'Buyurtmalar', 'Bandlar'];
  int _selectedTab = 0;
  bool _busy = false;

  CustomerDetailKey get _key => (placeId: widget.placeId, phone: widget.phone);

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _toggleBlock(bool isBlocked) async {
    setState(() => _busy = true);
    try {
      final service = ref.read(customerServiceProvider);
      if (isBlocked) {
        await service.unblock(widget.placeId, widget.phone);
      } else {
        await service.block(widget.placeId, widget.phone);
      }
      ref.invalidate(customerDetailProvider(_key));
      ref.invalidate(customerListProvider(widget.placeId));
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(customerDetailProvider(_key));

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
                child: detailAsync.when(
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (error, _) => Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            error is ApiException ? error.message : 'Mijoz topilmadi',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.mutedText(context)),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton(
                            onPressed: () => ref.invalidate(customerDetailProvider(_key)),
                            child: const Text('Qayta urinish'),
                          ),
                        ],
                      ),
                    ),
                  ),
                  data: (customer) => SingleChildScrollView(
                    padding: const EdgeInsets.only(top: 16, bottom: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _CustomerHeroCard(
                          customer: customer,
                          busy: _busy,
                          onToggleBlock: () => _toggleBlock(customer.isBlocked),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatTile(
                                icon: Icons.receipt_long_outlined,
                                value: '${customer.ordersCount}',
                                label: 'Buyurtmalar',
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
                        _OrdersBookingsTile(
                          orders: customer.ordersCount,
                          bookings: customer.bookingsCount,
                        ),
                        const SizedBox(height: 16),
                        _ContactInfoCard(customer: customer),
                        const SizedBox(height: 20),
                        _TabSelector(
                          tabs: _tabs,
                          selectedIndex: _selectedTab,
                          onSelected: (index) => setState(() => _selectedTab = index),
                        ),
                        const SizedBox(height: 14),
                        _TabContent(index: _selectedTab, customer: customer),
                      ],
                    ),
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
    required this.busy,
    required this.onToggleBlock,
  });

  final CustomerDetail customer;
  final bool busy;
  final VoidCallback onToggleBlock;

  @override
  Widget build(BuildContext context) {
    final isActive = !customer.isBlocked;
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
                backgroundColor: avatarColorFor(customer.customerPhone),
                child: Text(
                  customer.customerName.isEmpty
                      ? '?'
                      : customer.customerName.substring(0, 1).toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 20),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.customerName,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.darkText(context),
                      ),
                    ),
                    Text(
                      customer.customerPhone,
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
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: busy ? null : onToggleBlock,
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

  final CustomerDetail customer;

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
          _ContactRow(icon: Icons.call_outlined, value: customer.customerPhone),
          const SizedBox(height: 10),
          _ContactRow(
            icon: Icons.access_time_outlined,
            value: 'So\'nggi faoliyat: ${_fmtDate(customer.lastActivityAt)}',
          ),
        ],
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}.${d.month.toString().padLeft(2, '0')}.${d.year}';

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

class _ActivityEntry {
  const _ActivityEntry({required this.title, required this.subtitle, required this.time, required this.at});

  final String title;
  final String subtitle;
  final String time;
  final DateTime at;
}

class _TabContent extends StatelessWidget {
  const _TabContent({required this.index, required this.customer});

  final int index;
  final CustomerDetail customer;

  @override
  Widget build(BuildContext context) {
    switch (index) {
      case 1:
        if (customer.recentOrders.isEmpty) {
          return _EmptyTabState(text: 'Buyurtmalar yo\'q');
        }
        return Column(
          children: [
            for (final order in customer.recentOrders) ...[
              _InfoRowCard(
                icon: Icons.receipt_long_outlined,
                title: order.items.map((i) => '${i.name} x${i.quantity}').join(', '),
                subtitle: '${order.totalAmount} so\'m • ${order.status.label}',
                time: _fmtDate(order.createdAt),
              ),
              if (order != customer.recentOrders.last) const SizedBox(height: 10),
            ],
          ],
        );
      case 2:
        if (customer.recentBookings.isEmpty) {
          return _EmptyTabState(text: 'Bandlar yo\'q');
        }
        return Column(
          children: [
            for (final booking in customer.recentBookings) ...[
              _InfoRowCard(
                icon: Icons.event_note_outlined,
                title: [?booking.tableLabel, '${booking.guests} kishi'].join(' • '),
                subtitle: '${_fmtDate(booking.bookingTime)} • ${booking.status.label}',
                time: _fmtDate(booking.createdAt),
              ),
              if (booking != customer.recentBookings.last) const SizedBox(height: 10),
            ],
          ],
        );
      default:
        final activity = _buildActivity(customer);
        if (activity.isEmpty) {
          return _EmptyTabState(text: 'Faoliyat yo\'q');
        }
        return Column(
          children: [
            for (final entry in activity) ...[
              _ActivityRow(entry: entry, isLatest: entry == activity.first),
              if (entry != activity.last) const SizedBox(height: 10),
            ],
          ],
        );
    }
  }

  List<_ActivityEntry> _buildActivity(CustomerDetail customer) {
    final entries = <_ActivityEntry>[
      for (final order in customer.recentOrders)
        _ActivityEntry(
          title: 'Buyurtma berdi • ${order.totalAmount} so\'m',
          subtitle: order.status.label,
          time: _fmtDate(order.createdAt),
          at: order.createdAt,
        ),
      for (final booking in customer.recentBookings)
        _ActivityEntry(
          title: 'Band qildi • ${booking.guests} kishilik',
          subtitle: booking.status.label,
          time: _fmtDate(booking.bookingTime),
          at: booking.bookingTime,
        ),
    ]..sort((a, b) => b.at.compareTo(a.at));
    return entries;
  }
}

class _EmptyTabState extends StatelessWidget {
  const _EmptyTabState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: Text(text, style: TextStyle(color: AppColors.mutedText(context))),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.entry, required this.isLatest});

  final _ActivityEntry entry;
  final bool isLatest;

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
              color: isLatest ? AppColors.adminGradientMid : AppColors.fieldBorder(context),
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
                  '${entry.subtitle} • ${entry.time}',
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
                  title.isEmpty ? '—' : title,
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
