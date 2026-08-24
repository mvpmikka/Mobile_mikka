import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/product.dart';
import '../services/product_service.dart';
import 'auth_provider.dart';

final productServiceProvider = Provider<ProductService>((ref) {
  return ProductService(apiClient: ref.watch(apiClientProvider));
});

class ProductQuery {
  const ProductQuery({this.search, this.status});

  final String? search;
  final ProductStatus? status;

  ProductQuery copyWith({String? search, ProductStatus? status, bool clearStatus = false}) {
    return ProductQuery(
      search: search ?? this.search,
      status: clearStatus ? null : (status ?? this.status),
    );
  }
}

final productQueryProvider = StateProvider.autoDispose<ProductQuery>((ref) {
  return const ProductQuery();
});

final productStatsProvider =
    FutureProvider.autoDispose.family<ProductStats, String>((ref, placeId) async {
  return ref.watch(productServiceProvider).getStats(placeId);
});

final productListProvider =
    FutureProvider.autoDispose.family<ProductPage, String>((ref, placeId) async {
  final query = ref.watch(productQueryProvider);
  return ref.watch(productServiceProvider).listProducts(
        placeId,
        search: query.search,
        status: query.status,
      );
});
