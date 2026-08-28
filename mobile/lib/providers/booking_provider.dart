import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/booking.dart';
import '../services/booking_service.dart';
import 'auth_provider.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(apiClient: ref.watch(apiClientProvider));
});

class BookingQuery {
  const BookingQuery({this.search, this.status, this.date});

  final String? search;
  final BookingStatus? status;
  final String? date;

  BookingQuery copyWith({
    String? search,
    BookingStatus? status,
    String? date,
    bool clearStatus = false,
    bool clearDate = false,
  }) {
    return BookingQuery(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
      date: clearDate ? null : (date ?? this.date),
    );
  }
}

final bookingQueryProvider = StateProvider.autoDispose<BookingQuery>((ref) {
  return const BookingQuery();
});

final bookingStatsProvider =
    FutureProvider.autoDispose.family<BookingStats, String>((ref, placeId) async {
  return ref.watch(bookingServiceProvider).getStats(placeId);
});

final bookingListProvider =
    FutureProvider.autoDispose.family<BookingPage, String>((ref, placeId) async {
  final query = ref.watch(bookingQueryProvider);
  return ref.watch(bookingServiceProvider).listBookings(
        placeId,
        search: query.search,
        status: query.status,
        date: query.date,
      );
});

/// Upcoming (PENDING/CONFIRMED, still in the future) bookings across all
/// days, sorted soonest-first — used by the schedule view's "Navbatdagilar"
/// card. Independent of [bookingQueryProvider]'s date filter.
final upcomingBookingsProvider =
    FutureProvider.autoDispose.family<List<Booking>, String>((ref, placeId) async {
  final page = await ref.watch(bookingServiceProvider).listBookings(placeId, limit: 50);
  final now = DateTime.now();
  final upcoming = page.items
      .where((b) =>
          (b.status == BookingStatus.pending || b.status == BookingStatus.confirmed) &&
          b.bookingTime.isAfter(now))
      .toList()
    ..sort((a, b) => a.bookingTime.compareTo(b.bookingTime));
  return upcoming.take(3).toList();
});
