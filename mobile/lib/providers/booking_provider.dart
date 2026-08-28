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
