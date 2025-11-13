class OrderStatusCount {
  final String status;
  final int count;

  OrderStatusCount({required this.status, required this.count});

  factory OrderStatusCount.fromJson(Map<String, dynamic> json) {
    return OrderStatusCount(
      status: json['status'] as String,
      count: json['count'] as int,
    );
  }
}

class RevenueStats {
  final double overallTotal;
  final double pendingTotal;
  final double shippedTotal;
  final double completedTotal;
  final double cancelledTotal;

  RevenueStats({
    required this.overallTotal,
    required this.pendingTotal,
    required this.shippedTotal,
    required this.completedTotal,
    required this.cancelledTotal,
  });

  factory RevenueStats.fromJson(Map<String, dynamic> json) {
    return RevenueStats(
      overallTotal: (json['overallTotal'] as num).toDouble(),
      pendingTotal: (json['pendingTotal'] as num).toDouble(),
      shippedTotal: (json['shippedTotal'] as num?)?.toDouble() ?? 0.0,
      completedTotal: (json['completedTotal'] as num).toDouble(),
      cancelledTotal: (json['cancelledTotal'] as num).toDouble(),
    );
  }
}

class UserStats {
  final int totalProducts;
  final int totalCategories;
  final List<OrderStatusCount> ordersByStatus;
  final RevenueStats revenue;

  UserStats({
    required this.totalProducts,
    required this.totalCategories,
    required this.ordersByStatus,
    required this.revenue,
  });

  factory UserStats.fromJson(Map<String, dynamic> json) {
    return UserStats(
      totalProducts: json['totalProducts'] as int,
      totalCategories: json['totalCategories'] as int,
      ordersByStatus: (json['ordersByStatus'] as List)
          .map(
            (item) => OrderStatusCount.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      revenue: RevenueStats.fromJson(json['revenue'] as Map<String, dynamic>),
    );
  }
}
