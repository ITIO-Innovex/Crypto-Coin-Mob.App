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
    try {
      return OrderData(
        coinName: json['coinName']?.toString() ?? '',
        orderType: json['orderType']?.toString() ?? '',
        side: json['side']?.toString() ?? '',
        amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
        stopPrice: (json['stopPrice'] as num?)?.toDouble(),
        status: json['status']?.toString() ?? '',
        createdAt: DateTime.tryParse(json['createdAt']?.toString() ?? '') ?? DateTime.now(),
        executedAt: json['executedAt'] != null ? DateTime.tryParse(json['executedAt'].toString()) : null,
      );
    } catch (e) {
      print('Error parsing OrderData: $e, JSON: $json');
      rethrow;
    }
  }
}
