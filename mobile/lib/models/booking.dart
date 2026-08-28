enum BookingStatus {
  pending,
  confirmed,
  seated,
  completed,
  cancelled;

  static BookingStatus fromJson(String value) {
    switch (value) {
      case 'PENDING':
        return BookingStatus.pending;
      case 'CONFIRMED':
        return BookingStatus.confirmed;
      case 'SEATED':
        return BookingStatus.seated;
      case 'COMPLETED':
        return BookingStatus.completed;
      case 'CANCELLED':
        return BookingStatus.cancelled;
      default:
        return BookingStatus.pending;
    }
  }

  String get apiValue {
    switch (this) {
      case BookingStatus.pending:
        return 'PENDING';
      case BookingStatus.confirmed:
        return 'CONFIRMED';
      case BookingStatus.seated:
        return 'SEATED';
      case BookingStatus.completed:
        return 'COMPLETED';
      case BookingStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case BookingStatus.pending:
        return 'Kutilmoqda';
      case BookingStatus.confirmed:
        return 'Tasdiqlandi';
      case BookingStatus.seated:
        return 'Joylashtirildi';
      case BookingStatus.completed:
        return 'Bajarildi';
      case BookingStatus.cancelled:
        return 'Bekor qilindi';
    }
  }

  bool get isTerminal => this == BookingStatus.completed || this == BookingStatus.cancelled;

  /// The next status in the staff workflow, or null if there is none
  /// (terminal states, or Seated which is completed manually).
  BookingStatus? get next {
    switch (this) {
      case BookingStatus.pending:
        return BookingStatus.confirmed;
      case BookingStatus.confirmed:
        return BookingStatus.seated;
      case BookingStatus.seated:
        return BookingStatus.completed;
      case BookingStatus.completed:
      case BookingStatus.cancelled:
        return null;
    }
  }
}

/// Mirrors the backend's `Booking` (`GET /places/:placeId/bookings`).
class Booking {
  const Booking({
    required this.id,
    required this.placeId,
    required this.customerName,
    required this.customerPhone,
    required this.bookingTime,
    required this.guests,
    required this.tableLabel,
    required this.note,
    required this.status,
    required this.createdAt,
  });

  final String id;
  final String placeId;
  final String customerName;
  final String? customerPhone;
  final DateTime bookingTime;
  final int guests;
  final String? tableLabel;
  final String? note;
  final BookingStatus status;
  final DateTime createdAt;

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'] as String,
      placeId: json['placeId'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String?,
      bookingTime: DateTime.parse(json['bookingTime'] as String),
      guests: json['guests'] as int,
      tableLabel: json['tableLabel'] as String?,
      note: json['note'] as String?,
      status: BookingStatus.fromJson(json['status'] as String),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class BookingPage {
  const BookingPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<Booking> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;

  factory BookingPage.fromJson(Map<String, dynamic> json) {
    return BookingPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
    );
  }
}

/// Mirrors the backend's `BookingStats` (`GET /places/:placeId/bookings/stats`).
class BookingStats {
  const BookingStats({
    required this.pendingCount,
    required this.confirmedCount,
    required this.seatedCount,
    required this.completedCount,
    required this.cancelledCount,
  });

  final int pendingCount;
  final int confirmedCount;
  final int seatedCount;
  final int completedCount;
  final int cancelledCount;

  factory BookingStats.fromJson(Map<String, dynamic> json) {
    return BookingStats(
      pendingCount: json['pendingCount'] as int,
      confirmedCount: json['confirmedCount'] as int,
      seatedCount: json['seatedCount'] as int,
      completedCount: json['completedCount'] as int,
      cancelledCount: json['cancelledCount'] as int,
    );
  }
}
