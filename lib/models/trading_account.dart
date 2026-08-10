class TradingAccount {
  final String id;
  final String userId;
  final String name;
  final double initialBalance;
  final String currency; // 'USD', 'USC', 'IDR'
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TradingAccount({
    required this.id,
    required this.userId,
    required this.name,
    required this.initialBalance,
    required this.currency,
    this.createdAt,
    this.updatedAt,
  });

  factory TradingAccount.fromJson(Map<String, dynamic> json) {
    return TradingAccount(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      name: json['name'] as String,
      initialBalance: (json['initial_balance'] as num).toDouble(),
      currency: json['currency'] as String,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'initial_balance': initialBalance,
      'currency': currency,
    };
  }

  TradingAccount copyWith({
    String? id,
    String? userId,
    String? name,
    double? initialBalance,
    String? currency,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TradingAccount(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      initialBalance: initialBalance ?? this.initialBalance,
      currency: currency ?? this.currency,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
