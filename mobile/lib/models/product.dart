enum ProductStatus {
  inStock,
  lowStock,
  outOfStock;

  static ProductStatus fromJson(String value) {
    switch (value) {
      case 'IN_STOCK':
        return ProductStatus.inStock;
      case 'LOW_STOCK':
        return ProductStatus.lowStock;
      case 'OUT_OF_STOCK':
        return ProductStatus.outOfStock;
      default:
        return ProductStatus.inStock;
    }
  }

  String get label {
    switch (this) {
      case ProductStatus.inStock:
        return 'Mavjud';
      case ProductStatus.lowStock:
        return 'Kam qoldi';
      case ProductStatus.outOfStock:
        return 'Tugagan';
    }
  }
}

/// Mirrors the backend's `Product` (`GET /places/:placeId/products`).
class Product {
  const Product({
    required this.id,
    required this.placeId,
    required this.name,
    required this.sku,
    required this.quantity,
    required this.lowStockThreshold,
    required this.status,
    required this.updatedAt,
  });

  final String id;
  final String placeId;
  final String name;
  final String sku;
  final int quantity;
  final int lowStockThreshold;
  final ProductStatus status;
  final DateTime updatedAt;

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['id'] as String,
      placeId: json['placeId'] as String,
      name: json['name'] as String,
      sku: json['sku'] as String,
      quantity: json['quantity'] as int,
      lowStockThreshold: json['lowStockThreshold'] as int,
      status: ProductStatus.fromJson(json['status'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }
}

class ProductPage {
  const ProductPage({
    required this.items,
    required this.total,
    required this.page,
    required this.limit,
  });

  final List<Product> items;
  final int total;
  final int page;
  final int limit;

  bool get hasMore => page * limit < total;

  factory ProductPage.fromJson(Map<String, dynamic> json) {
    return ProductPage(
      items: (json['items'] as List<dynamic>)
          .map((e) => Product.fromJson(e as Map<String, dynamic>))
          .toList(),
      total: json['total'] as int,
      page: json['page'] as int,
      limit: json['limit'] as int,
    );
  }
}

/// Mirrors the backend's `ProductStats` (`GET /places/:placeId/products/stats`).
class ProductStats {
  const ProductStats({
    required this.totalProducts,
    required this.lowStock,
    required this.outOfStock,
  });

  final int totalProducts;
  final int lowStock;
  final int outOfStock;

  factory ProductStats.fromJson(Map<String, dynamic> json) {
    return ProductStats(
      totalProducts: json['totalProducts'] as int,
      lowStock: json['lowStock'] as int,
      outOfStock: json['outOfStock'] as int,
    );
  }
}
