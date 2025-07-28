class Transactions {
  final String id;
  final String userId;
  final double amount;
  final String currency;
  final String type;
  final String status;
  final String gateway;
  final DateTime createdAt;

  Transactions({
    required this.id,
    required this.userId,
    required this.amount,
    required this.currency,
    required this.type,
    required this.status,
    required this.gateway,
    required this.createdAt,
  });

  factory Transactions.fromJson(Map<String, dynamic> json) {
    return Transactions(
      id: json['_id'],
      userId: json['userId'],
      amount: json['amount'].toDouble(),
      currency: json['currency'],
      type: json['type'],
      status: json['status'],
      gateway: json['gateway'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  get walletType => null;
}