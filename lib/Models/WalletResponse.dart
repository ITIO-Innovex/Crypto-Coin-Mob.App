class WalletResponse {
  final int status;
  final String message;
  final List<WalletData> data;

  WalletResponse({
    required this.status,
    required this.message,
    required this.data,
  });

  factory WalletResponse.fromJson(Map<String, dynamic> json) {
    return WalletResponse(
      status: json['status'],
      message: json['message'],
      data: List<WalletData>.from(
        json['data'].map((x) => WalletData.fromJson(x)),
      ),
    );
  }

  Map<String, dynamic> toJson() => {
    'status': status,
    'message': message,
    'data': data.map((x) => x.toJson()).toList(),
  };
}

class WalletData {
  final String coinName;
  final String walletAddress;
  final DateTime createdAt;

  WalletData({
    required this.coinName,
    required this.walletAddress,
    required this.createdAt,
  });

  factory WalletData.fromJson(Map<String, dynamic> json) {
    return WalletData(
      coinName: json['coinName'],
      walletAddress: json['walletAddress'],
      createdAt: DateTime.parse(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() => {
    'coinName': coinName,
    'walletAddress': walletAddress,
    'createdAt': createdAt.toIso8601String(),
  };
}
