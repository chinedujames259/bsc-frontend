class OrderItem {
  final int id;
  final int productId;
  final int quantity;
  final String price;
  final ProductInfo? product;

  OrderItem({
    required this.id,
    required this.productId,
    required this.quantity,
    required this.price,
    this.product,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      id: json['id'],
      productId: json['productId'],
      quantity: json['quantity'],
      price: json['price'],
      product: json['product'] != null ? ProductInfo.fromJson(json['product']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }
}

class ProductInfo {
  final int id;
  final String name;
  final String slug;
  final String sku;
  final String? description;

  ProductInfo({
    required this.id,
    required this.name,
    required this.slug,
    required this.sku,
    this.description,
  });

  factory ProductInfo.fromJson(Map<String, dynamic> json) {
    return ProductInfo(
      id: json['id'],
      name: json['name'],
      slug: json['slug'],
      sku: json['sku'],
      description: json['description'],
    );
  }
}

class Order {
  final int id;
  final int userId;
  final String status;
  final String total;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.userId,
    required this.status,
    required this.total,
    required this.createdAt,
    required this.updatedAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List?)
            ?.map((item) => OrderItem.fromJson(item))
            .toList() ??
        [];

    return Order(
      id: json['id'],
      userId: json['userId'],
      status: json['status'],
      total: json['total'],
      createdAt: DateTime.parse(json['createdAt'].toString()),
      updatedAt: DateTime.parse(json['updatedAt'].toString()),
      items: items,
    );
  }
}

class InvoiceItem {
  final int productId;
  final String productName;
  final String? productSku;
  final String? price;
  int quantity;
  double get total {
    if (price == null) return 0.0;
    final priceValue = double.tryParse(price!) ?? 0.0;
    return priceValue * quantity;
  }

  InvoiceItem({
    required this.productId,
    required this.productName,
    this.productSku,
    this.price,
    this.quantity = 1,
  });

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'quantity': quantity,
    };
  }
}

