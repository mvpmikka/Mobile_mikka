import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/customer.dart';
import '../services/customer_service.dart';
import 'auth_provider.dart';

final customerServiceProvider = Provider<CustomerService>((ref) {
  return CustomerService(apiClient: ref.watch(apiClientProvider));
});

class CustomerQuery {
  const CustomerQuery({this.search});

  final String? search;

  CustomerQuery copyWith({String? search, bool clearSearch = false}) {
    return CustomerQuery(search: clearSearch ? null : (search ?? this.search));
  }
}

final customerQueryProvider = StateProvider.autoDispose<CustomerQuery>((ref) {
  return const CustomerQuery();
});

final customerListProvider =
    FutureProvider.autoDispose.family<CustomerPage, String>((ref, placeId) async {
  final query = ref.watch(customerQueryProvider);
  return ref.watch(customerServiceProvider).listCustomers(
        placeId,
        limit: 100,
        search: query.search,
      );
});

typedef CustomerDetailKey = ({String placeId, String phone});

final customerDetailProvider =
    FutureProvider.autoDispose.family<CustomerDetail, CustomerDetailKey>((ref, key) async {
  return ref.watch(customerServiceProvider).getDetail(key.placeId, key.phone);
});
