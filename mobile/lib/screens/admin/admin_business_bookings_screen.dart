import 'package:flutter/material.dart';

import '../../theme/app_colors.dart';
import 'widgets/admin_pagination_bar.dart';
import 'widgets/admin_section_topbar.dart';

enum _BookingStatus { pending, confirmed, seated, completed, cancelled }

extension on _BookingStatus {
  String get label {
    switch (this) {
      case _BookingStatus.pending:
        return 'Kutilmoqda';
      case _BookingStatus.confirmed:
        return 'Tasdiqlandi';
      case _BookingStatus.seated:
        return 'Joylashtirildi';
      case _BookingStatus.completed:
        return 'Bajarildi';
      case _BookingStatus.cancelled:
        return 'Bekor qilindi';
    }
  }

  Color get color {
    switch (this) {
      case _BookingStatus.pending:
        return const Color(0xFFC9922E);
      case _BookingStatus.confirmed:
        return AppColors.adminGradientMid;
      case _BookingStatus.seated:
        return const Color(0xFF3B6EA8);
      case _BookingStatus.completed:
        return const Color(0xFF3F9142);
      case _BookingStatus.cancelled:
        return const Color(0xFF8A7E72);
    }
  }
}

class _Booking {
  const _Booking({
    required this.id,
    required this.customer,
    required this.phone,
    required this.time,
    required this.guests,
    required this.table,
    required this.status,
    required this.avatarColor,
    this.note,
  });

  final String id;
  final String customer;
  final String phone;
  final String time;
  final int guests;
  final String table;
  final _BookingStatus status;
  final Color avatarColor;
  final String? note;
}

const _bookings = [
  _Booking(
    id: '#B102',
    customer: 'Aziz',
    phone: '+998 99 765 43 21',
    time: 'Bugun, 19:00',
    guests: 4,
    table: '4-stol, Zal',
    status: _BookingStatus.pending,
    avatarColor: Color(0xFF3B6EA8),
    note: 'Tug\'ilgan kun torti kerak',
  ),
  _Booking(
    id: '#B101',
    customer: 'Madina',
    phone: '+998 90 123 45 67',
    time: 'Bugun, 20:30',
    guests: 2,
    table: 'Balkon',
    status: _BookingStatus.confirmed,
    avatarColor: Color(0xFF8A5A3B),
  ),
  _Booking(
    id: '#B098',
    customer: 'Jasur',
    phone: '+998 94 555 12 34',
    time: 'Kecha, 18:15',
    guests: 6,
    table: 'VIP xona',
    status: _BookingStatus.completed,
    avatarColor: Color(0xFF6B6B6B),
  ),
];

/// MIKKA Business mobil "Bandlar" ekrani — Figma dizayni asosidagi sof UI.
/// Bandlar ro'yxati lokal namunaviy ma'lumot — hech qanday backend/servis
/// chaqiruvi yo'q.
class AdminBusinessBookingsScreen extends StatefulWidget {
  const AdminBusinessBookingsScreen({super.key});

  @override
  State<AdminBusinessBookingsScreen> createState() => _AdminBusinessBookingsScreenState();
}

class _AdminBusinessBookingsScreenState extends State<AdminBusinessBookingsScreen> {
  final _searchController = TextEditingController();
  _BookingStatus? _statusFilter;

  // Namunaviy jami bandlar soni (Figma dizaynidagi sahifalash uslubi bilan
  // mos) — sahifalash faqat UI ko'rinishi, chunki lokal ma'lumotda atigi
  // 3 ta namuna bor.
  static const _catalogTotal = 18;
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

  List<_Booking> get _filtered {
    final query = _searchController.text.trim().toLowerCase();
    return _bookings.where((booking) {
      final matchesStatus = _statusFilter == null || booking.status == _statusFilter;
      final matchesQuery = query.isEmpty ||
          booking.customer.toLowerCase().contains(query) ||
          booking.id.toLowerCase().contains(query);
      return matchesStatus && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final bookings = _filtered;
    final pendingCount = _bookings.where((b) => b.status == _BookingStatus.pending).length;

    return Scaffold(
      backgroundColor: AppColors.cream(context),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminSectionTopBar(
                title: 'Bandlar',
                onNotification: () => _showMessage('Bildirishnomalar tez orada qo\'shiladi'),
                searchController: _searchController,
                searchHint: 'Band ID, mijoz bo\'yicha qidirish...',
                onSearchChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Joyingizdagi bandlarni boshqaring va kuzating.',
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
                        onPressed: () => _showMessage('Yangi band qo\'shish tez orada qo\'shiladi'),
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Yangi band', style: TextStyle(fontWeight: FontWeight.w700)),
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
                    for (final status in _BookingStatus.values) ...[
                      const SizedBox(width: 8),
                      _StatusChip(
                        label: status == _BookingStatus.pending
                            ? '${status.label} ($pendingCount)'
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
                child: bookings.isEmpty
                    ? Center(
                        child: Text(
                          'Band topilmadi',
                          style: TextStyle(color: AppColors.mutedText(context)),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.only(bottom: 16),
                        itemCount: bookings.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 10),
                        itemBuilder: (_, index) => _BookingCard(
                          booking: bookings[index],
                          onTap: () =>
                              _showMessage('${bookings[index].id} tafsilotlari tez orada'),
                          onAccept: () => _showMessage('${bookings[index].id} qabul qilindi'),
                          onDecline: () => _showMessage('${bookings[index].id} rad etildi'),
                        ),
                      ),
              ),
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  children: [
                    Text(
                      '${(_currentPage - 1) * _pageSize + 1}-${_currentPage * _pageSize} / $_catalogTotal band',
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

class _BookingCard extends StatelessWidget {
  const _BookingCard({
    required this.booking,
    required this.onTap,
    required this.onAccept,
    required this.onDecline,
  });

  final _Booking booking;
  final VoidCallback onTap;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

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
          border: Border(left: BorderSide(color: booking.status.color, width: 3)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  booking.id,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    color: booking.status.color,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: booking.status.color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    booking.status.label,
                    style: TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700, color: booking.status.color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: booking.avatarColor,
                  child: Text(
                    booking.customer.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.customer,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: AppColors.darkText(context),
                        ),
                      ),
                      Text(
                        booking.phone,
                        style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 14,
              runSpacing: 6,
              children: [
                _InfoChip(icon: Icons.calendar_today_outlined, label: booking.time),
                _InfoChip(icon: Icons.person_outline, label: '${booking.guests} kishi'),
                _InfoChip(icon: Icons.table_restaurant_outlined, label: booking.table),
              ],
            ),
            if (booking.note != null) ...[
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.sticky_note_2_outlined, size: 14, color: AppColors.mutedText(context)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      booking.note!,
                      style: TextStyle(
                        fontSize: 11,
                        fontStyle: FontStyle.italic,
                        color: AppColors.mutedText(context),
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (booking.status == _BookingStatus.pending) ...[
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onDecline,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFCB4B4B),
                        side: const BorderSide(color: Color(0xFFCB4B4B)),
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text('Rad etish', style: TextStyle(fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppColors.adminBrandGradient,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: TextButton(
                        onPressed: onAccept,
                        style: TextButton.styleFrom(
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                        ),
                        child: const Text('Qabul qilish',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: AppColors.mutedText(context)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(fontSize: 12, color: AppColors.darkText(context)),
        ),
      ],
    );
  }
}
