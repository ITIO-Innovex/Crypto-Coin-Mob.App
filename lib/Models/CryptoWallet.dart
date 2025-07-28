class CryptoWallet {
  final String? id;
  final String? userId; // Make optional since not in API response
  final String currency;
  final String? address;
  final double balance;
  final String? mnemonic;
  final String? vaultAccountId;
  final DateTime? createdAt; // Add createdAt to match API

  CryptoWallet({
    this.id,
    this.userId,
    required this.currency, 
    this.address,
    this.balance = 0.0,
    this.mnemonic,
    this.vaultAccountId,
    this.createdAt,
  });

  factory CryptoWallet.fromJson(Map<String, dynamic> json) {
    return CryptoWallet(
      id: json['_id'] as String?,
      userId: json['userId'] as String?,
      currency: json['coinName'] as String? ?? json['currency'] as String? ?? 'Unknown',
      address: json['walletAddress'] as String? ?? json['address'] as String?,
      balance: (json['balance'] as num?)?.toDouble() ?? 0.0,
      mnemonic: json['mnemonic'] as String?,
      vaultAccountId: json['vaultAccountId'] as String?,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'coinName': currency,
      'walletAddress': address,
      'balance': balance,
      'mnemonic': mnemonic,
      'vaultAccountId': vaultAccountId,
      'createdAt': createdAt?.toIso8601String(),
    };
  }
}