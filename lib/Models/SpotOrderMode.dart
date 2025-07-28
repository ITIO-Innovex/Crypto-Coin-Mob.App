class OrderResponse {
  final int status;
  final String message;
  final List<OrderData> data;

  OrderResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      status: json['status'],
      message: json['message'],
      data: List<OrderData>.from(
        json['data'].map((order) => OrderData.fromJson(order)),
      ),
    );
  }
}

class OrderData {
  final String coinName;
  final String orderType;
  final String side;
  final double amount;
  final double price;
  final double? stopPrice;
  final String status;
  final DateTime createdAt;
  final DateTime? executedAt;

  OrderData({
    required this.coinName,
    required this.orderType,
    required this.side,
    required this.amount,
    required this.price,
    this.stopPrice,
    required this.status,
    required this.createdAt,
    this.executedAt,
  });

  factory OrderData.fromJson(Map<String, dynamic> json) {
    return OrderData(
      coinName: json['coinName'],
      orderType: json['orderType'],
      side: json['side'],
      amount: (json['amount'] as num).toDouble(),
      price: (json['price'] as num).toDouble(),
      stopPrice: json['stopPrice'] != null ? (json['stopPrice'] as num).toDouble() : null,
      status: json['status'],
      createdAt: DateTime.parse(json['createdAt']),
      executedAt: json['executedAt'] != null ? DateTime.parse(json['executedAt']) : null,
    );
  }
}
