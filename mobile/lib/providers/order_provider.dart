import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../services/order_service.dart';
import 'auth_provider.dart';

final orderServiceProvider = Provider<OrderService>((ref) {
  return OrderService(apiClient: ref.watch(apiClientProvider));
});

class OrderQuery {
  const OrderQuery({this.search, this.status});

  final String? search;
  final OrderStatus? status;

  OrderQuery copyWith({String? search, OrderStatus? status, bool clearStatus = false}) {
    return OrderQuery(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

final orderQueryProvider = StateProvider.autoDispose<OrderQuery>((ref) {
  return const OrderQuery();
});

final orderStatsProvider =
    FutureProvider.autoDispose.family<OrderStats, String>((ref, placeId) async {
  return ref.watch(orderServiceProvider).getStats(placeId);
});

final orderListProvider =
    FutureProvider.autoDispose.family<OrderPage, String>((ref, placeId) async {
  final query = ref.watch(orderQueryProvider);
  return ref.watch(orderServiceProvider).listOrders(
        placeId,
        search: query.search,
        status: query.status,
      );
});
