import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/api_exception.dart';
import '../../models/booking.dart';
import '../../providers/booking_provider.dart';
import '../../theme/app_colors.dart';
import 'widgets/admin_section_topbar.dart';

const _statusColors = {
  BookingStatus.pending: Color(0xFFC9922E),
  BookingStatus.confirmed: AppColors.adminGradientMid,
  BookingStatus.seated: Color(0xFF3B6EA8),
  BookingStatus.completed: Color(0xFF3F9142),
  BookingStatus.cancelled: Color(0xFF8A7E72),
};

const _weekdayLabels = ['Dush', 'Sesh', 'Chor', 'Pay', 'Jum', 'Shan', 'Yak'];
const _monthLabels = [
  'Yan', 'Fev', 'Mar', 'Apr', 'May', 'Iyun',
  'Iyul', 'Avg', 'Sen', 'Okt', 'Noy', 'Dek',
];

String _fmtDate(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

bool _isSameDate(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

DateTime _mondayOf(DateTime d) => DateTime(d.year, d.month, d.day).subtract(Duration(days: d.weekday - 1));

enum _BookingsView { schedule, list }

/// MIKKA Business mobil "Bandlar" ekrani — [bookingListProvider]/
/// [bookingStatsProvider]/[upcomingBookingsProvider] orqali
/// `/places/:placeId/bookings` bilan ulangan.
class AdminBusinessBookingsScreen extends ConsumerStatefulWidget {
  const AdminBusinessBookingsScreen({super.key, required this.placeId});

  final String placeId;

  @override
  ConsumerState<AdminBusinessBookingsScreen> createState() =>
      _AdminBusinessBookingsScreenState();
}

class _AdminBusinessBookingsScreenState extends ConsumerState<AdminBusinessBookingsScreen> {
  final _searchController = TextEditingController();
  _BookingsView _view = _BookingsView.schedule;
  late DateTime _selectedDate;
  late DateTime _weekAnchor;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _selectedDate = DateTime(today.year, today.month, today.day);
    _weekAnchor = _mondayOf(today);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(bookingQueryProvider.notifier).update(
            (q) => q.copyWith(date: _fmtDate(_selectedDate)),
          );
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  void _refresh() {
    ref.invalidate(bookingListProvider(widget.placeId));
    ref.invalidate(bookingStatsProvider(widget.placeId));
    ref.invalidate(upcomingBookingsProvider(widget.placeId));
  }

  void _switchView(_BookingsView view) {
    setState(() => _view = view);
    if (view == _BookingsView.schedule) {
      ref.read(bookingQueryProvider.notifier).update(
            (q) => q.copyWith(date: _fmtDate(_selectedDate), clearStatus: true),
          );
    } else {
      ref.read(bookingQueryProvider.notifier).update((q) => q.copyWith(clearDate: true));
    }
  }

  void _selectDay(DateTime day) {
    setState(() => _selectedDate = day);
    ref.read(bookingQueryProvider.notifier).update(
          (q) => q.copyWith(date: _fmtDate(day)),
        );
  }

  void _shiftWeek(int deltaDays) {
    setState(() {
      _weekAnchor = _weekAnchor.add(Duration(days: deltaDays));
      _selectedDate = _weekAnchor;
    });
    ref.read(bookingQueryProvider.notifier).update(
          (q) => q.copyWith(date: _fmtDate(_selectedDate)),
        );
  }

  void _goToday() {
    final today = DateTime.now();
    setState(() {
      _selectedDate = DateTime(today.year, today.month, today.day);
      _weekAnchor = _mondayOf(today);
    });
    ref.read(bookingQueryProvider.notifier).update(
          (q) => q.copyWith(date: _fmtDate(_selectedDate)),
        );
  }

  Future<void> _updateStatus(Booking booking, BookingStatus status) async {
    try {
      await ref
          .read(bookingServiceProvider)
          .updateStatus(widget.placeId, booking.id, status);
      _refresh();
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    }
  }

  Future<void> _createBooking() async {
    final result = await showDialog<_NewBookingData>(
      context: context,
      builder: (_) => const _CreateBookingDialog(),
    );
    if (result == null) return;
    try {
      await ref.read(bookingServiceProvider).createBooking(
            widget.placeId,
            customerName: result.customerName,
            customerPhone: result.customerPhone,
            bookingTime: result.bookingTime,
            guests: result.guests,
            tableLabel: result.tableLabel,
            note: result.note,
          );
      _refresh();
      if (mounted) _showMessage('Band qo\'shildi');
    } on ApiException catch (e) {
      if (mounted) _showMessage(e.message);
    }
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
                onSearchChanged: (value) => ref.read(bookingQueryProvider.notifier).update(
                      (q) => q.copyWith(search: value),
                    ),
              ),
              const SizedBox(height: 10),
              _ViewToggle(view: _view, onChanged: _switchView),
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
    final bookingsAsync = ref.watch(bookingListProvider(widget.placeId));
    final weekEnd = _weekAnchor.add(const Duration(days: 6));
    final rangeLabel = weekEnd.month == _weekAnchor.month
        ? '${_weekAnchor.day}-${weekEnd.day} ${_monthLabels[_weekAnchor.month - 1]}, ${_weekAnchor.year}'
        : '${_weekAnchor.day} ${_monthLabels[_weekAnchor.month - 1]} - ${weekEnd.day} ${_monthLabels[weekEnd.month - 1]}, ${weekEnd.year}';

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
              onPressed: _createBooking,
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
            rangeLabel: rangeLabel,
            onPrev: () => _shiftWeek(-7),
            onNext: () => _shiftWeek(7),
            onToday: _goToday,
          ),
          const SizedBox(height: 10),
          _DayStrip(
            weekAnchor: _weekAnchor,
            selectedDate: _selectedDate,
            onSelected: _selectDay,
          ),
          const SizedBox(height: 14),
          bookingsAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => _ErrorState(
              message: error is ApiException ? error.message : 'Bandlar yuklanmadi',
              onRetry: _refresh,
            ),
            data: (page) => _DayTimeline(
              bookings: page.items,
              showNowLine: _isSameDate(_selectedDate, DateTime.now()),
            ),
          ),
          const SizedBox(height: 20),
          _UpNextCard(placeId: widget.placeId),
        ],
      ),
    );
  }

  Widget _buildListView(BuildContext context) {
    final query = ref.watch(bookingQueryProvider);
    final bookingsAsync = ref.watch(bookingListProvider(widget.placeId));
    final statsAsync = ref.watch(bookingStatsProvider(widget.placeId));
    final pendingCount = statsAsync.valueOrNull?.pendingCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'Joyingizdagi bandlarni boshqaring va kuzating.',
          style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
        ),
        const SizedBox(height: 10),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: AppColors.adminBrandGradient,
            borderRadius: BorderRadius.circular(12),
          ),
          child: TextButton.icon(
            onPressed: _createBooking,
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            icon: const Icon(Icons.add, size: 16),
            label: const Text('Yangi band', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 34,
          child: ListView(
            scrollDirection: Axis.horizontal,
            children: [
              _StatusChip(
                label: 'Barchasi',
                isSelected: query.status == null,
                onTap: () => ref.read(bookingQueryProvider.notifier).update(
                      (q) => q.copyWith(clearStatus: true),
                    ),
              ),
              for (final status in BookingStatus.values) ...[
                const SizedBox(width: 8),
                _StatusChip(
                  label: status == BookingStatus.pending && pendingCount != null
                      ? '${status.label} ($pendingCount)'
                      : status.label,
                  isSelected: query.status == status,
                  color: _statusColors[status],
                  onTap: () => ref.read(bookingQueryProvider.notifier).update(
                        (q) => q.copyWith(status: status),
                      ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: bookingsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (error, _) => _ErrorState(
              message: error is ApiException ? error.message : 'Bandlar yuklanmadi',
              onRetry: _refresh,
            ),
            data: (page) {
              if (page.items.isEmpty) {
                return Center(
                  child: Text(
                    'Band topilmadi',
                    style: TextStyle(color: AppColors.mutedText(context)),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.only(bottom: 16),
                itemCount: page.items.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (_, index) => _BookingCard(
                  booking: page.items[index],
                  onAccept: () => _updateStatus(page.items[index], BookingStatus.confirmed),
                  onDecline: () => _updateStatus(page.items[index], BookingStatus.cancelled),
                  onCancel: () => _updateStatus(page.items[index], BookingStatus.cancelled),
                  onAdvance: () {
                    final next = page.items[index].status.next;
                    if (next != null) _updateStatus(page.items[index], next);
                  },
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            bookingsAsync.valueOrNull != null
                ? '${bookingsAsync.value!.items.length} / ${bookingsAsync.value!.total} band'
                : '',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
          ),
        ),
      ],
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
  const _DayStrip({
    required this.weekAnchor,
    required this.selectedDate,
    required this.onSelected,
  });

  final DateTime weekAnchor;
  final DateTime selectedDate;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final today = DateTime.now();
    return SizedBox(
      height: 58,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: 7,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (_, index) {
          final day = weekAnchor.add(Duration(days: index));
          final isSelected = _isSameDate(day, selectedDate);
          final isToday = _isSameDate(day, today);
          return InkWell(
            onTap: () => onSelected(day),
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
                    _weekdayLabels[index],
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white70 : AppColors.mutedText(context),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.day}',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: isSelected ? Colors.white : AppColors.darkText(context),
                    ),
                  ),
                  if (isToday && !isSelected)
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
  const _DayTimeline({required this.bookings, required this.showNowLine});

  final List<Booking> bookings;
  final bool showNowLine;

  static const _startHour = 9;
  static const _endHour = 23;
  static const _rowHeight = 56.0;
  static const _labelWidth = 40.0;
  static const _defaultDurationHours = 1.5;

  @override
  Widget build(BuildContext context) {
    final hourCount = _endHour - _startHour + 1;
    final totalHeight = hourCount * _rowHeight;
    final now = DateTime.now();
    final nowHour = now.hour + now.minute / 60;

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
            for (final booking in bookings)
              if (booking.bookingTime.hour + booking.bookingTime.minute / 60 >= _startHour)
                Positioned(
                  top: (booking.bookingTime.hour + booking.bookingTime.minute / 60 - _startHour) *
                          _rowHeight +
                      2,
                  left: _labelWidth + 8,
                  right: 0,
                  height: _defaultDurationHours * _rowHeight - 4,
                  child: _ScheduleEventCard(booking: booking),
                ),
            if (showNowLine && nowHour >= _startHour && nowHour <= _endHour)
              Positioned(
                top: (nowHour - _startHour) * _rowHeight,
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
            if (bookings.isEmpty)
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
  const _ScheduleEventCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final cancelled = booking.status == BookingStatus.cancelled;
    final color = cancelled
        ? AppColors.mutedText(context)
        : _statusColors[booking.status] ?? AppColors.adminGradientMid;
    final tableLabel = booking.tableLabel;
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
            booking.customerName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: color,
              decoration: cancelled ? TextDecoration.lineThrough : null,
            ),
          ),
          Text(
            [?tableLabel, '${booking.guests} kishi'].join(' • '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: color,
              decoration: cancelled ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}

class _UpNextCard extends ConsumerWidget {
  const _UpNextCard({required this.placeId});

  final String placeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcomingAsync = ref.watch(upcomingBookingsProvider(placeId));
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
          upcomingAsync.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, _) => Text(
              'Yuklanmadi',
              style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
            ),
            data: (items) {
              if (items.isEmpty) {
                return Text(
                  'Yaqin orada band yo\'q',
                  style: TextStyle(fontSize: 12, color: AppColors.mutedText(context)),
                );
              }
              return Column(
                children: [
                  for (final booking in items) ...[
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: AppColors.adminGradientMid,
                          child: Text(
                            booking.customerName.substring(0, 1).toUpperCase(),
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                booking.customerName,
                                style: TextStyle(
                                    fontWeight: FontWeight.w700, color: AppColors.darkText(context)),
                              ),
                              Text(
                                [
                                  if (booking.tableLabel != null) booking.tableLabel!,
                                  '${booking.guests} kishi',
                                  '${booking.bookingTime.hour.toString().padLeft(2, '0')}:${booking.bookingTime.minute.toString().padLeft(2, '0')}',
                                ].join(' • '),
                                style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (booking != items.last) const SizedBox(height: 12),
                  ],
                ],
              );
            },
          ),
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
    required this.onAccept,
    required this.onDecline,
    required this.onCancel,
    required this.onAdvance,
  });

  final Booking booking;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback onCancel;
  final VoidCallback onAdvance;

  @override
  Widget build(BuildContext context) {
    final color = _statusColors[booking.status] ?? AppColors.mutedText(context);
    final next = booking.status.next;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.customerName,
                  style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.darkText(context)),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  booking.status.label,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color),
                ),
              ),
            ],
          ),
          if (booking.customerPhone != null) ...[
            const SizedBox(height: 4),
            Text(
              booking.customerPhone!,
              style: TextStyle(fontSize: 11, color: AppColors.mutedText(context)),
            ),
          ],
          const SizedBox(height: 10),
          Wrap(
            spacing: 14,
            runSpacing: 6,
            children: [
              _InfoChip(
                icon: Icons.calendar_today_outlined,
                label:
                    '${booking.bookingTime.day}.${booking.bookingTime.month} ${booking.bookingTime.hour.toString().padLeft(2, '0')}:${booking.bookingTime.minute.toString().padLeft(2, '0')}',
              ),
              _InfoChip(icon: Icons.person_outline, label: '${booking.guests} kishi'),
              if (booking.tableLabel != null)
                _InfoChip(icon: Icons.table_restaurant_outlined, label: booking.tableLabel!),
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
          if (booking.status == BookingStatus.pending) ...[
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
          ] else if (!booking.status.isTerminal) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                TextButton(
                  onPressed: onCancel,
                  style: TextButton.styleFrom(foregroundColor: const Color(0xFFCB4B4B)),
                  child: const Text('Bekor qilish', style: TextStyle(fontSize: 12)),
                ),
                const Spacer(),
                if (next != null)
                  OutlinedButton(
                    onPressed: onAdvance,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: color,
                      side: BorderSide(color: color),
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    child: Text(next.label, style: const TextStyle(fontSize: 12)),
                  ),
              ],
            ),
          ],
        ],
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

class _NewBookingData {
  const _NewBookingData({
    required this.customerName,
    this.customerPhone,
    required this.bookingTime,
    required this.guests,
    this.tableLabel,
    this.note,
  });

  final String customerName;
  final String? customerPhone;
  final DateTime bookingTime;
  final int guests;
  final String? tableLabel;
  final String? note;
}

class _CreateBookingDialog extends StatefulWidget {
  const _CreateBookingDialog();

  @override
  State<_CreateBookingDialog> createState() => _CreateBookingDialogState();
}

class _CreateBookingDialogState extends State<_CreateBookingDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _guestsController = TextEditingController(text: '2');
  final _tableController = TextEditingController();
  final _noteController = TextEditingController();
  DateTime _date = DateTime.now().add(const Duration(hours: 1));
  TimeOfDay _time = TimeOfDay.fromDateTime(DateTime.now().add(const Duration(hours: 1)));

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _guestsController.dispose();
    _tableController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) setState(() => _time = picked);
  }

  void _submit() {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;
    final guests = int.tryParse(_guestsController.text.trim()) ?? 0;
    if (guests <= 0) return;

    final bookingTime = DateTime(_date.year, _date.month, _date.day, _time.hour, _time.minute);

    Navigator.of(context).pop(
      _NewBookingData(
        customerName: name,
        customerPhone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        bookingTime: bookingTime,
        guests: guests,
        tableLabel: _tableController.text.trim().isEmpty ? null : _tableController.text.trim(),
        note: _noteController.text.trim().isEmpty ? null : _noteController.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yangi band'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Mijoz ismi'),
            ),
            TextField(
              controller: _phoneController,
              decoration: const InputDecoration(labelText: 'Telefon (ixtiyoriy)'),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickDate,
                    child: Text('${_date.day}.${_date.month}.${_date.year}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: _pickTime,
                    child: Text(_time.format(context)),
                  ),
                ),
              ],
            ),
            TextField(
              controller: _guestsController,
              decoration: const InputDecoration(labelText: 'Mehmonlar soni'),
              keyboardType: TextInputType.number,
            ),
            TextField(
              controller: _tableController,
              decoration: const InputDecoration(labelText: 'Stol/joy nomi (ixtiyoriy)'),
            ),
            TextField(
              controller: _noteController,
              decoration: const InputDecoration(labelText: 'Izoh (ixtiyoriy)'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Bekor qilish'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Yaratish')),
      ],
    );
  }
}
