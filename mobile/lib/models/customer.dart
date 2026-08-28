import 'booking.dart';
import 'order.dart';

/// Mirrors the backend's `CustomerSummary`
/// (`GET /places/:placeId/customers`, `.items[i]`).
class Customer {
  const Customer({
    required this.customerName,
    required this.customerPhone,
    required this.ordersCount,
    required this.bookingsCount,
    required this.totalSpent,
    required this.lastActivityAt,
    required this.isBlocked,
  });

  final String customerName;
  final String customerPhone;
  final int ordersCount;
  final int bookingsCount;
  final int totalSpent;
  final DateTime lastActivityAt;
  final bool isBlocked;

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      ordersCount: json['ordersCount'] as int,
      bookingsCount: json['bookingsCount'] as int,
      totalSpent: json['totalSpent'] as int,
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
      isBlocked: json['isBlocked'] as bool,
    );
  }
}

class CustomerPage {
  const CustomerPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<Customer> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;

  factory CustomerPage.fromJson(Map<String, dynamic> json) {
    return CustomerPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => Customer.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
    );
  }
}

/// Mirrors the backend's `CustomerDetail`
/// (`GET /places/:placeId/customers/:phone`).
class CustomerDetail {
  const CustomerDetail({
    required this.customerName,
    required this.customerPhone,
    required this.ordersCount,
    required this.bookingsCount,
    required this.totalSpent,
    required this.lastActivityAt,
    required this.isBlocked,
    required this.recentOrders,
    required this.recentBookings,
  });

  final String customerName;
  final String customerPhone;
  final int ordersCount;
  final int bookingsCount;
  final int totalSpent;
  final DateTime lastActivityAt;
  final bool isBlocked;
  final List<Order> recentOrders;
  final List<Booking> recentBookings;

  factory CustomerDetail.fromJson(Map<String, dynamic> json) {
    return CustomerDetail(
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String,
      ordersCount: json['ordersCount'] as int,
      bookingsCount: json['bookingsCount'] as int,
      totalSpent: json['totalSpent'] as int,
      lastActivityAt: DateTime.parse(json['lastActivityAt'] as String),
      isBlocked: json['isBlocked'] as bool,
      recentOrders: (json['recentOrders'] as List<dynamic>)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList(),
      recentBookings: (json['recentBookings'] as List<dynamic>)
          .map((e) => Booking.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
