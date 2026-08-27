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

enum _BookingsView { schedule, list }

class _DayHeader {
  const _DayHeader({required this.label, required this.dayNumber});
  final String label;
  final int dayNumber;
}

const _weekDays = [
  _DayHeader(label: 'Dush', dayNumber: 23),
  _DayHeader(label: 'Sesh', dayNumber: 24),
  _DayHeader(label: 'Chor', dayNumber: 25),
  _DayHeader(label: 'Pay', dayNumber: 26),
  _DayHeader(label: 'Jum', dayNumber: 27),
  _DayHeader(label: 'Shan', dayNumber: 28),
  _DayHeader(label: 'Yak', dayNumber: 29),
];

// "Bugun" (hozirgi kun) — namunaviy taqvimda Chorshanba (index 2) sifatida
// belgilangan, "hozir" chizig'i ham shu kunga chiziladi.
const _todayIndex = 2;
const _nowHour = 12.5;

class _ScheduleEvent {
  const _ScheduleEvent({
    required this.title,
    required this.table,
    required this.pax,
    required this.startHour,
    required this.endHour,
    this.cancelled = false,
  });

  final String title;
  final String table;
  final int pax;
  final double startHour;
  final double endHour;
  final bool cancelled;
}

const _scheduleByDay = <int, List<_ScheduleEvent>>{
  0: [
    _ScheduleEvent(title: 'Aziz', table: 'T12', pax: 4, startHour: 10.5, endHour: 12),
  ],
  2: [
    _ScheduleEvent(title: 'Sarah M.', table: 'T04', pax: 2, startHour: 12, endHour: 13, cancelled: true),
    _ScheduleEvent(title: 'Team Lunch', table: 'T20', pax: 8, startHour: 14, endHour: 16),
  ],
};

enum _TableStatus { available, occupied, pending }

class _SpaceTable {
  const _SpaceTable({required this.id, required this.pax, required this.status});
  final String id;
  final int pax;
  final _TableStatus status;
}

const _tables = [
  _SpaceTable(id: 'T01', pax: 2, status: _TableStatus.available),
  _SpaceTable(id: 'T02', pax: 4, status: _TableStatus.occupied),
  _SpaceTable(id: 'T03', pax: 2, status: _TableStatus.available),
  _SpaceTable(id: 'T04', pax: 2, status: _TableStatus.pending),
  _SpaceTable(id: 'T05', pax: 4, status: _TableStatus.available),
];

class _UpNextItem {
  const _UpNextItem({
    required this.name,
    required this.table,
    required this.pax,
    required this.time,
    required this.avatarColor,
  });
  final String name;
  final String table;
  final int pax;
  final String time;
  final Color avatarColor;
}

const _upNext = [
  _UpNextItem(
    name: 'Sarah M.',
    table: 'T04',
    pax: 2,
    time: '12:00',
    avatarColor: Color(0xFFFE5B01),
  ),
  _UpNextItem(
    name: 'Team Lunch',
    table: 'T20',
    pax: 8,
    time: '14:00',
    avatarColor: Color(0xFF8A7E72),
  ),
];

/// MIKKA Business mobil "Bandlar" ekrani — Figma dizayni asosidagi sof UI.
/// Ikkita ko'rinishga ega: kunlik jadval (taqvim) va status bo'yicha
/// filtrlanadigan ro'yxat. Barcha ma'lumotlar lokal namunaviy qiymatlar —
/// hech qanday backend/servis chaqiruvi yo'q.
class AdminBusinessBookingsScreen extends StatefulWidget {
  const AdminBusinessBookingsScreen({super.key});

  @override
  State<AdminBusinessBookingsScreen> createState() => _AdminBusinessBookingsScreenState();
}

class _AdminBusinessBookingsScreenState extends State<AdminBusinessBookingsScreen> {
  final _searchController = TextEditingController();
  _BookingStatus? _statusFilter;
  _BookingsView _view = _BookingsView.schedule;
  int _selectedDay = _todayIndex;

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
                searchController: _view == _BookingsView.list ? _searchController : null,
                searchHint: 'Band ID, mijoz bo\'yicha qidirish...',
                onSearchChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 10),
              _ViewToggle(
                view: _view,
                onChanged: (view) => setState(() => _view = view),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: _view == _BookingsView.schedule
                    ? _buildScheduleView(context)
                    : _buildListView(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScheduleView(BuildContext context) {
    final events = _scheduleByDay[_selectedDay] ?? const <_ScheduleEvent>[];
    return SingleChildScrollView(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.adminBrandGradient,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton.icon(
              onPressed: () => _showMessage('Yangi band qo\'shish tez orada qo\'shiladi'),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Yangi band', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ),
          const SizedBox(height: 16),
          _DateNavigatorRow(
            rangeLabel: '${_weekDays.first.dayNumber}-${_weekDays.last.dayNumber} Okt, 2026',
            onPrev: () => _showMessage('Oldingi hafta tez orada qo\'shiladi'),
            onNext: () => _showMessage('Keyingi hafta tez orada qo\'shiladi'),
            onToday: () => setState(() => _selectedDay = _todayIndex),
          ),
          const SizedBox(height: 10),
          _DayStrip(
            selectedIndex: _selectedDay,
            onSelected: (index) => setState(() => _selectedDay = index),
          ),
          const SizedBox(height: 14),
          _DayTimeline(events: events, showNowLine: _selectedDay == _todayIndex),
          const SizedBox(height: 20),
          _SpaceStatusCard(asOf: '12:30'),
          const SizedBox(height: 16),
          _UpNextCard(),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    final bookings = _filtered;
    final pendingCount = _bookings.where((b) => b.status == _BookingStatus.pending).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
                    Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.darkText(context)),
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
                    onTap: () => _showMessage('${bookings[index].id} tafsilotlari tez orada'),
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
    );
  }
}

class _ViewToggle extends StatelessWidget {
  const _ViewToggle({required this.view, required this.onChanged});

  final _BookingsView view;
  final ValueChanged<_BookingsView> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.cream(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Row(
        children: [
          Expanded(child: _ToggleSegment(
            label: 'Jadval',
            icon: Icons.calendar_view_week_outlined,
            isSelected: view == _BookingsView.schedule,
            onTap: () => onChanged(_BookingsView.schedule),
          )),
          Expanded(child: _ToggleSegment(
            label: 'Ro\'yxat',
            icon: Icons.view_list_outlined,
            isSelected: view == _BookingsView.list,
            onTap: () => onChanged(_BookingsView.list),
          )),
        ],
      ),
    );
  }
}

class _ToggleSegment extends StatelessWidget {
  const _ToggleSegment({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(9),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.surface(context) : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
          boxShadow: isSelected
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 4)]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 15,
                color: isSelected ? AppColors.adminGradientMid : AppColors.mutedText(context)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: isSelected ? AppColors.adminGradientMid : AppColors.mutedText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateNavigatorRow extends StatelessWidget {
  const _DateNavigatorRow({
    required this.rangeLabel,
    required this.onPrev,
    required this.onNext,
    required this.onToday,
  });

  final String rangeLabel;
  final VoidCallback onPrev;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            rangeLabel,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.darkText(context),
            ),
          ),
        ),
        _CircleIconButton(icon: Icons.chevron_left, onTap: onPrev),
        const SizedBox(width: 6),
        InkWell(
          onTap: onToday,
          borderRadius: BorderRadius.circular(20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface(context),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.fieldBorder(context)),
            ),
            child: Text('Bugun',
                style: TextStyle(fontSize: 12, color: AppColors.darkText(context))),
          ),
        ),
        const SizedBox(width: 6),
        _CircleIconButton(icon: Icons.chevron_right, onTap: onNext),
      ],
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.fieldBorder(context)),
        ),
        child: Icon(icon, size: 16, color: AppColors.darkText(context)),
      ),
    );
  }
}

class _DayStrip extends StatelessWidget {
  const _DayStrip({required this.selectedIndex, required this.onSelected});

  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _weekDays.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final day = _weekDays[index];
          final isSelected = index == selectedIndex;
          return InkWell(
            onTap: () => onSelected(index),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 52,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                gradient: isSelected ? AppColors.adminBrandGradient : null,
                color: isSelected ? null : AppColors.surface(context),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isSelected ? Colors.transparent : AppColors.fieldBorder(context),
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    day.label,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : AppColors.mutedText(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.dayNumber}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.darkText(context),
                    ),
                  ),
                  if (index == _todayIndex && !isSelected)
                    Container(
                      margin: const EdgeInsets.only(top: 3),
                      width: 4,
                      height: 4,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.adminGradientMid,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _DayTimeline extends StatelessWidget {
  const _DayTimeline({required this.events, required this.showNowLine});

  final List<_ScheduleEvent> events;
  final bool showNowLine;

  static const _startHour = 9;
  static const _endHour = 18;
  static const _rowHeight = 56.0;
  static const _labelWidth = 40.0;

  @override
  Widget build(BuildContext context) {
    final hourCount = _endHour - _startHour + 1;
    final totalHeight = hourCount * _rowHeight;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: SizedBox(
        height: totalHeight,
        child: Stack(
          children: [
            for (var i = 0; i < hourCount; i++)
              Positioned(
                top: i * _rowHeight,
                left: 0,
                right: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: _labelWidth,
                      child: _HourLabel(hour: _startHour + i),
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        margin: const EdgeInsets.only(top: 6),
                        color: AppColors.fieldBorder(context),
                      ),
                    ),
                  ],
                ),
              ),
            for (final event in events)
              Positioned(
                top: (event.startHour - _startHour) * _rowHeight + 2,
                left: _labelWidth + 8,
                right: 0,
                height: (event.endHour - event.startHour) * _rowHeight - 4,
                child: _ScheduleEventCard(event: event),
              ),
            if (showNowLine)
              Positioned(
                top: (_nowHour - _startHour) * _rowHeight,
                left: _labelWidth - 4,
                right: 0,
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: Color(0xFFCB4B4B),
                      ),
                    ),
                    Expanded(
                      child: Container(height: 1, color: const Color(0xFFCB4B4B)),
                    ),
                  ],
                ),
              ),
            if (events.isEmpty)
              Positioned.fill(
                left: _labelWidth + 8,
                child: Center(
                  child: Text(
                    'Bu kunda bandlar yo\'q',
                    style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _HourLabel extends StatelessWidget {
  const _HourLabel({required this.hour});

  final int hour;

  @override
  Widget build(BuildContext context) {
    final display = hour > 12 ? hour - 12 : hour;
    final period = hour < 12 ? 'AM' : 'PM';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$display',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppColors.darkText(context),
          ),
        ),
        Text(
          period,
          style: TextStyle(fontSize: 8, color: AppColors.mutedText(context)),
        ),
      ],
    );
  }
}

class _ScheduleEventCard extends StatelessWidget {
  const _ScheduleEventCard({required this.event});

  final _ScheduleEvent event;

  @override
  Widget build(BuildContext context) {
    final color = event.cancelled ? AppColors.mutedText(context) : AppColors.adminGradientMid;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            event.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              decoration: event.cancelled ? TextDecoration.lineThrough : null,
            ),
          ),
          Text(
            '${event.table} • ${event.pax} pax',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: color,
              decoration: event.cancelled ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _SpaceStatusCard extends StatelessWidget {
  const _SpaceStatusCard({required this.asOf});

  final String asOf;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
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
              Expanded(
                child: Text(
                  'Joylar holati',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.darkText(context),
                  ),
                ),
              ),
              Text(asOf, style: TextStyle(fontSize: 12, color: AppColors.mutedText(context))),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _LegendDot(color: const Color(0xFF3F9142), label: 'Bo\'sh'),
              const SizedBox(width: 14),
              _LegendDot(color: const Color(0xFFCB4B4B), label: 'Band'),
            ],
          ),
          const SizedBox(height: 12),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.15,
            children: [for (final table in _tables) _TableTile(table: table)],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 5),
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.mutedText(context))),
      ],
    );
  }
}

class _TableTile extends StatelessWidget {
  const _TableTile({required this.table});

  final _SpaceTable table;

  (Color, Color, bool) _meta(BuildContext context) {
    switch (table.status) {
      case _TableStatus.available:
        return (const Color(0xFF3F9142), const Color(0xFF3F9142).withValues(alpha: 0.06), false);
      case _TableStatus.occupied:
        return (const Color(0xFFCB4B4B), const Color(0xFFCB4B4B).withValues(alpha: 0.1), false);
      case _TableStatus.pending:
        return (const Color(0xFFC9922E), const Color(0xFFC9922E).withValues(alpha: 0.08), true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (borderColor, fillColor, dashed) = _meta(context);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: fillColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: dashed ? 1.4 : 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            table.status == _TableStatus.pending ? '${table.id}\n(Kutilmoqda)' : table.id,
            textAlign: TextAlign.center,
            maxLines: 2,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: borderColor),
          ),
          const SizedBox(height: 3),
          Text(
            '${table.pax} pax',
            style: TextStyle(fontSize: 10, color: AppColors.mutedText(context)),
          ),
        ],
      ),
    );
  }
}

class _UpNextCard extends StatelessWidget {
  const _UpNextCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.fieldBorder(context)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Navbatdagilar',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.darkText(context),
            ),
          ),
          const SizedBox(height: 10),
          for (final item in _upNext) ...[
            Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: item.avatarColor,
                  child: Text(
                    item.name.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.darkText(context)),
                      ),
                      Text(
                        'Stol ${item.table} • ${item.pax} kishi • ${item.time}',
                        style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (item != _upNext.last) const SizedBox(height: 12),
          ],
        ],
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
