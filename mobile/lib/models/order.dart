enum OrderStatus {
  newOrder,
  accepted,
  preparing,
  ready,
  completed,
  cancelled;

  static OrderStatus fromJson(String value) {
    switch (value) {
      case 'NEW':
        return OrderStatus.newOrder;
      case 'ACCEPTED':
        return OrderStatus.accepted;
      case 'PREPARING':
        return OrderStatus.preparing;
      case 'READY':
        return OrderStatus.ready;
      case 'COMPLETED':
        return OrderStatus.completed;
      case 'CANCELLED':
        return OrderStatus.cancelled;
      default:
        return OrderStatus.newOrder;
    }
  }

  String get apiValue {
    switch (this) {
      case OrderStatus.newOrder:
        return 'NEW';
      case OrderStatus.accepted:
        return 'ACCEPTED';
      case OrderStatus.preparing:
        return 'PREPARING';
      case OrderStatus.ready:
        return 'READY';
      case OrderStatus.completed:
        return 'COMPLETED';
      case OrderStatus.cancelled:
        return 'CANCELLED';
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.newOrder:
        return 'Yangi';
      case OrderStatus.accepted:
        return 'Qabul qilindi';
      case OrderStatus.preparing:
        return 'Tayyorlanmoqda';
      case OrderStatus.ready:
        return 'Tayyor';
      case OrderStatus.completed:
        return 'Yakunlandi';
      case OrderStatus.cancelled:
        return 'Bekor qilindi';
    }
  }

  bool get isTerminal => this == OrderStatus.completed || this == OrderStatus.cancelled;

  /// The next status in the staff workflow, or null if there is none
  /// (terminal states, or Ready which is completed manually).
  OrderStatus? get next {
    switch (this) {
      case OrderStatus.newOrder:
        return OrderStatus.accepted;
      case OrderStatus.accepted:
        return OrderStatus.preparing;
      case OrderStatus.preparing:
        return OrderStatus.ready;
      case OrderStatus.ready:
        return OrderStatus.completed;
      case OrderStatus.completed:
      case OrderStatus.cancelled:
        return null;
    }
  }
}

class OrderItem {
  const OrderItem({required this.name, required this.quantity, required this.unitPrice});

  final String name;
  final int quantity;
  final int unitPrice;

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      unitPrice: json['unitPrice'] as int,
    );
  }
}

/// Mirrors the backend's `Order` (`GET /places/:placeId/orders`).
class Order {
  const Order({
    required this.id,
    required this.placeId,
    required this.customerName,
    required this.customerPhone,
    required this.status,
    required this.totalAmount,
    required this.items,
    required this.createdAt,
  });

  final String id;
  final String placeId;
  final String customerName;
  final String? customerPhone;
  final OrderStatus status;
  final int totalAmount;
  final List<OrderItem> items;
  final DateTime createdAt;

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      placeId: json['placeId'] as String,
      customerName: json['customerName'] as String,
      customerPhone: json['customerPhone'] as String?,
      status: OrderStatus.fromJson(json['status'] as String),
      totalAmount: json['totalAmount'] as int,
      items: (json['items'] as List<dynamic>)
          .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }
}

class OrderPage {
  const OrderPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<Order> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;

  factory OrderPage.fromJson(Map<String, dynamic> json) {
    return OrderPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
    );
  }
}

/// Mirrors the backend's `OrderStats` (`GET /places/:placeId/orders/stats`).
class OrderStats {
  const OrderStats({
    required this.newCount,
    required this.acceptedCount,
    required this.preparingCount,
    required this.readyCount,
    required this.completedCount,
    required this.cancelledCount,
  });

  final int newCount;
  final int acceptedCount;
  final int preparingCount;
  final int readyCount;
  final int completedCount;
  final int cancelledCount;

  factory OrderStats.fromJson(Map<String, dynamic> json) {
    return OrderStats(
      newCount: json['newCount'] as int,
      acceptedCount: json['acceptedCount'] as int,
      preparingCount: json['preparingCount'] as int,
      readyCount: json['readyCount'] as int,
      completedCount: json['completedCount'] as int,
      cancelledCount: json['cancelledCount'] as int,
    );
  }
}
