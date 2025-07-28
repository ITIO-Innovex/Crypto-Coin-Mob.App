class Wallet {
  final String id;
  final String userId;
  final String currency;
  final double balance;
  final String? address; // Nullable to support fiat wallets without addresses

  Wallet({
    required this.id,
    required this.userId,
    required this.currency,
    required this.balance,
    this.address,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['_id']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      currency: json['currency'] ?? '',
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      address: json['address'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'currency': currency,
      'balance': balance,
      'address': address,
    };
  }
}
