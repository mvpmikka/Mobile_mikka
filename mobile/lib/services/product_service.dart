import 'package:dio/dio.dart';

import '../core/api_client.dart';
import '../core/api_exception.dart';
import '../models/product.dart';

class ProductService {
  ProductService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<ProductPage> listProducts(
    String placeId, {
    int page = 1,
    int limit = 20,
    String? search,
    ProductStatus? status,
  }) async {
    try {
      final response = await _apiClient.dio.get(
        '/places/$placeId/products',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (status != null) 'status': _statusParam(status),
        },
      );
      return ProductPage.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<ProductStats> getStats(String placeId) async {
    try {
      final response = await _apiClient.dio.get('/places/$placeId/products/stats');
      return ProductStats.fromJson(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> createProduct(
    String placeId, {
    required String name,
    required String sku,
    int quantity = 0,
    int lowStockThreshold = 5,
  }) async {
    try {
      await _apiClient.dio.post(
        '/places/$placeId/products',
        data: {
          'name': name,
          'sku': sku,
          'quantity': quantity,
          'lowStockThreshold': lowStockThreshold,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> updateProduct(
    String placeId,
    String productId, {
    String? name,
    String? sku,
    int? lowStockThreshold,
  }) async {
    try {
      await _apiClient.dio.patch(
        '/places/$placeId/products/$productId',
        data: {
          'name': ?name,
          'sku': ?sku,
          'lowStockThreshold': ?lowStockThreshold,
        },
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> adjustStock(String placeId, String productId, int delta) async {
    try {
      await _apiClient.dio.post(
        '/places/$placeId/products/$productId/adjust-stock',
        data: {'delta': delta},
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  Future<void> deleteProduct(String placeId, String productId) async {
    try {
      await _apiClient.dio.delete('/places/$placeId/products/$productId');
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  String _statusParam(ProductStatus status) {
    switch (status) {
      case ProductStatus.inStock:
        return 'IN_STOCK';
      case ProductStatus.lowStock:
        return 'LOW_STOCK';
      case ProductStatus.outOfStock:
        return 'OUT_OF_STOCK';
    }
  }
}
