class OrderStatusCount {
  final String status;
  final int count;

  OrderStatusCount({
    required this.status,
    required this.count,
  });

  factory OrderStatusCount.fromJson(Map<String, dynamic> json) {
    return OrderStatusCount(
      status: json['status'] as String,
      count: json['count'] as int,
    );
  }
}

class UserStats {
  final int totalProducts;
  final int totalCategories;
  final List<OrderStatusCount> ordersByStatus;

  UserStats({
    required this.totalProducts,
    required this.totalCategories,
    required this.ordersByStatus,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalProducts: json['totalProducts'] as int,
      totalCategories: json['totalCategories'] as int,
      ordersByStatus: (json['ordersByStatus'] as List)
          .map((item) => OrderStatusCount.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

