class NotificationModel{
  final String id;
  final String title;
  final String message;
  final String currency;
  final double amount;
  final DateTime createdAt;
  final bool read;

  NotificationModel({
    required this.id,
    required this.title,
    required this.message,
    required this.currency,
    required this.amount,
    required this.createdAt,
    required this.read,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['_id'] ?? json['id'],
      title: json['title'],
      message: json['message'],
      currency: json['currency'],
      amount: (json['amount'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt']),
      read: json['read'] ?? false,
    );
  }
}
