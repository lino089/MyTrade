import 'package:uuid/uuid.dart';

class Trade {
  final String id;
  final String userId;
  final String accountId; // New field
  final String pair;
  final String direction; // 'Buy' or 'Sell'
  final DateTime entryTime;
  final DateTime? exitTime;
  final double profitLossPercent;
  final double profitLossAmount;
  final double? lotSize;
  final double? riskPercent;
  final double? riskRewardRatio;
  final String status; // 'Win', 'Loss', 'Break Even'
  final double tp; // New field
  final double sl; // New field
  final String result; // 'TP', 'SL', 'Break Even' - New field
  final List<String> setups;
  final List<String> entryChecklist;
  final String? screenshotBeforeUrl;
  final String? screenshotAfterUrl;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Trade({
    required this.id,
    required this.userId,
    required this.accountId,
    required this.pair,
    required this.direction,
    required this.entryTime,
    this.exitTime,
    required this.profitLossPercent,
    required this.profitLossAmount,
    this.lotSize,
    this.riskPercent,
    this.riskRewardRatio,
    required this.status,
    required this.tp,
    required this.sl,
    required this.result,
    required this.setups,
    required this.entryChecklist,
    this.screenshotBeforeUrl,
    this.screenshotAfterUrl,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Trade.create({
    required String userId,
    required String accountId,
    required String pair,
    required String direction,
    required DateTime entryTime,
    DateTime? exitTime,
    required double profitLossPercent,
    required double profitLossAmount,
    double? lotSize,
    double? riskPercent,
    double? riskRewardRatio,
    required String status,
    required double tp,
    required double sl,
    required String result,
    required List<String> setups,
    required List<String> entryChecklist,
    String? screenshotBeforeUrl,
    String? screenshotAfterUrl,
    String? notes,
  }) {
    return Trade(
      id: const Uuid().v4(),
      userId: userId,
      accountId: accountId,
      pair: pair,
      direction: direction,
      entryTime: entryTime,
      exitTime: exitTime,
      profitLossPercent: profitLossPercent,
      profitLossAmount: profitLossAmount,
      lotSize: lotSize,
      riskPercent: riskPercent,
      riskRewardRatio: riskRewardRatio,
      status: status,
      tp: tp,
      sl: sl,
      result: result,
      setups: setups,
      entryChecklist: entryChecklist,
      screenshotBeforeUrl: screenshotBeforeUrl,
      screenshotAfterUrl: screenshotAfterUrl,
      notes: notes,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  Trade copyWith({
    String? id,
    String? userId,
    String? accountId,
    String? pair,
    String? direction,
    DateTime? entryTime,
    DateTime? exitTime,
    double? profitLossPercent,
    double? profitLossAmount,
    double? lotSize,
    double? riskPercent,
    double? riskRewardRatio,
    String? status,
    double? tp,
    double? sl,
    String? result,
    List<String>? setups,
    List<String>? entryChecklist,
    String? screenshotBeforeUrl,
    String? screenshotAfterUrl,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Trade(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      accountId: accountId ?? this.accountId,
      pair: pair ?? this.pair,
      direction: direction ?? this.direction,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      profitLossPercent: profitLossPercent ?? this.profitLossPercent,
      profitLossAmount: profitLossAmount ?? this.profitLossAmount,
      lotSize: lotSize ?? this.lotSize,
      riskPercent: riskPercent ?? this.riskPercent,
      riskRewardRatio: riskRewardRatio ?? this.riskRewardRatio,
      status: status ?? this.status,
      tp: tp ?? this.tp,
      sl: sl ?? this.sl,
      result: result ?? this.result,
      setups: setups ?? this.setups,
      entryChecklist: entryChecklist ?? this.entryChecklist,
      screenshotBeforeUrl: screenshotBeforeUrl ?? this.screenshotBeforeUrl,
      screenshotAfterUrl: screenshotAfterUrl ?? this.screenshotAfterUrl,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory Trade.fromJson(Map<String, dynamic> json) {
    return Trade(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      accountId: json['account_id'] as String? ?? '', // Fallback for old database migrations
      pair: json['pair'] as String,
      direction: json['direction'] as String,
      entryTime: DateTime.parse(json['entry_time'] as String),
      exitTime: json['exit_time'] != null ? DateTime.parse(json['exit_time'] as String) : null,
      profitLossPercent: (json['profit_loss_percent'] as num).toDouble(),
      profitLossAmount: (json['profit_loss_amount'] as num).toDouble(),
      lotSize: json['lot_size'] != null ? (json['lot_size'] as num).toDouble() : null,
      riskPercent: json['risk_percent'] != null ? (json['risk_percent'] as num).toDouble() : null,
      riskRewardRatio: json['risk_reward_ratio'] != null ? (json['risk_reward_ratio'] as num).toDouble() : null,
      status: json['status'] as String,
      tp: (json['tp'] as num? ?? 0.0).toDouble(),
      sl: (json['sl'] as num? ?? 0.0).toDouble(),
      result: json['result'] as String? ?? 'Break Even',
      setups: List<String>.from(json['setups'] ?? []),
      entryChecklist: List<String>.from(json['entry_checklist'] ?? []),
      screenshotBeforeUrl: json['screenshot_before_url'] as String?,
      screenshotAfterUrl: json['screenshot_after_url'] as String?,
      notes: json['notes'] as String?,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at'] as String) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'account_id': accountId,
      'pair': pair,
      'direction': direction,
      'entry_time': entryTime.toIso8601String(),
      'exit_time': exitTime?.toIso8601String(),
      'profit_loss_percent': profitLossPercent,
      'profit_loss_amount': profitLossAmount,
      'lot_size': lotSize,
      'risk_percent': riskPercent,
      'risk_reward_ratio': riskRewardRatio,
      'status': status,
      'tp': tp,
      'sl': sl,
      'result': result,
      'setups': setups,
      'entry_checklist': entryChecklist,
      'screenshot_before_url': screenshotBeforeUrl,
      'screenshot_after_url': screenshotAfterUrl,
      'notes': notes,
    };
  }
}
