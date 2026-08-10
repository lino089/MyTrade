import '../../models/trade.dart';

class TradeStats {
  final int totalTrades;
  final int totalWins;
  final int totalLosses;
  final int totalBreakEvens;
  final double winRate;
  final double totalProfitPercent;
  final double totalProfitAmount;
  final double averageRR;
  final double averageProfitAmount;
  final double averageLossAmount;
  final double averageProfitPercent;
  final double averageLossPercent;
  final double profitFactor;
  final Trade? bestTrade;
  final Trade? worstTrade;
  final int maxWinStreak;
  final int maxLossStreak;
  final double maxDrawdownAmount;
  final double maxDrawdownPercent;

  TradeStats({
    required this.totalTrades,
    required this.totalWins,
    required this.totalLosses,
    required this.totalBreakEvens,
    required this.winRate,
    required this.totalProfitPercent,
    required this.totalProfitAmount,
    required this.averageRR,
    required this.averageProfitAmount,
    required this.averageLossAmount,
    required this.averageProfitPercent,
    required this.averageLossPercent,
    required this.profitFactor,
    this.bestTrade,
    this.worstTrade,
    required this.maxWinStreak,
    required this.maxLossStreak,
    required this.maxDrawdownAmount,
    required this.maxDrawdownPercent,
  });

  factory TradeStats.empty() {
    return TradeStats(
      totalTrades: 0,
      totalWins: 0,
      totalLosses: 0,
      totalBreakEvens: 0,
      winRate: 0.0,
      totalProfitPercent: 0.0,
      totalProfitAmount: 0.0,
      averageRR: 0.0,
      averageProfitAmount: 0.0,
      averageLossAmount: 0.0,
      averageProfitPercent: 0.0,
      averageLossPercent: 0.0,
      profitFactor: 0.0,
      maxWinStreak: 0,
      maxLossStreak: 0,
      maxDrawdownAmount: 0.0,
      maxDrawdownPercent: 0.0,
    );
  }
}

class SetupStats {
  final String name;
  final int totalTrades;
  final int totalWins;
  final double winRate;
  final double totalProfitPercent;

  SetupStats({
    required this.name,
    required this.totalTrades,
    required this.totalWins,
    required this.winRate,
    required this.totalProfitPercent,
  });
}

class ChecklistStats {
  final String combination;
  final int totalTrades;
  final int totalWins;
  final double winRate;

  ChecklistStats({
    required this.combination,
    required this.totalTrades,
    required this.totalWins,
    required this.winRate,
  });
}

class StatsCalculator {
  static TradeStats calculate(List<Trade> trades, {double initialBalance = 0.0}) {
    if (trades.isEmpty) return TradeStats.empty();

    int wins = 0;
    int losses = 0;
    int breakEvens = 0;
    double totalPnlPercent = 0.0;
    double totalPnlAmount = 0.0;
    double sumRR = 0.0;
    int countRR = 0;

    double sumProfitAmount = 0.0;
    double sumLossAmount = 0.0;
    double sumProfitPercent = 0.0;
    double sumLossPercent = 0.0;

    double grossProfit = 0.0;
    double grossLoss = 0.0;

    Trade? best;
    Trade? worst;

    // Sort by entry time ascending to calculate streaks and drawdown
    final sortedTrades = List<Trade>.from(trades)
      ..sort((a, b) => a.entryTime.compareTo(b.entryTime));

    int currentWinStreak = 0;
    int currentLossStreak = 0;
    int maxWinStreak = 0;
    int maxLossStreak = 0;

    double currentBalance = initialBalance;
    double peakBalance = initialBalance;
    double maxDrawdownAmt = 0.0;
    double maxDrawdownPct = 0.0;

    for (final trade in sortedTrades) {
      totalPnlPercent += trade.profitLossPercent;
      totalPnlAmount += trade.profitLossAmount;
      
      currentBalance += trade.profitLossAmount;
      if (currentBalance > peakBalance) {
        peakBalance = currentBalance;
      }
      
      double ddAmt = peakBalance - currentBalance;
      if (ddAmt > maxDrawdownAmt) {
        maxDrawdownAmt = ddAmt;
      }
      
      double ddPct = peakBalance > 0 ? (ddAmt / peakBalance) * 100 : 0.0;
      if (ddPct > maxDrawdownPct) {
        maxDrawdownPct = ddPct;
      }

      if (trade.riskRewardRatio != null) {
        sumRR += trade.riskRewardRatio!;
        countRR++;
      }

      if (trade.status == 'Win') {
        wins++;
        sumProfitAmount += trade.profitLossAmount;
        sumProfitPercent += trade.profitLossPercent;
        grossProfit += trade.profitLossAmount;

        currentWinStreak++;
        currentLossStreak = 0;
        if (currentWinStreak > maxWinStreak) {
          maxWinStreak = currentWinStreak;
        }

        if (best == null || trade.profitLossAmount > best.profitLossAmount) {
          best = trade;
        }
      } else if (trade.status == 'Loss') {
        losses++;
        sumLossAmount += trade.profitLossAmount;
        sumLossPercent += trade.profitLossPercent;
        grossLoss += trade.profitLossAmount.abs();

        currentLossStreak++;
        currentWinStreak = 0;
        if (currentLossStreak > maxLossStreak) {
          maxLossStreak = currentLossStreak;
        }

        if (worst == null || trade.profitLossAmount < worst.profitLossAmount) {
          worst = trade;
        }
      } else {
        breakEvens++;
        currentWinStreak = 0;
        currentLossStreak = 0;
      }
    }

    final total = trades.length;
    final winRate = total > 0 ? (wins / (wins + losses > 0 ? wins + losses : 1)) * 100 : 0.0;

    final avgRR = countRR > 0 ? sumRR / countRR : 0.0;
    final avgProfitAmt = wins > 0 ? sumProfitAmount / wins : 0.0;
    final avgLossAmt = losses > 0 ? sumLossAmount / losses : 0.0;
    final avgProfitPct = wins > 0 ? sumProfitPercent / wins : 0.0;
    final avgLossPct = losses > 0 ? sumLossPercent / losses : 0.0;

    final profitFactor = grossLoss > 0 ? grossProfit / grossLoss : (grossProfit > 0 ? double.infinity : 0.0);

    return TradeStats(
      totalTrades: total,
      totalWins: wins,
      totalLosses: losses,
      totalBreakEvens: breakEvens,
      winRate: winRate,
      totalProfitPercent: totalPnlPercent,
      totalProfitAmount: totalPnlAmount,
      averageRR: avgRR,
      averageProfitAmount: avgProfitAmt,
      averageLossAmount: avgLossAmt,
      averageProfitPercent: avgProfitPct,
      averageLossPercent: avgLossPct,
      profitFactor: profitFactor,
      bestTrade: best,
      worstTrade: worst,
      maxWinStreak: maxWinStreak,
      maxLossStreak: maxLossStreak,
      maxDrawdownAmount: maxDrawdownAmt,
      maxDrawdownPercent: maxDrawdownPct,
    );
  }

  static List<SetupStats> calculateSetupStats(List<Trade> trades) {
    final Map<String, List<Trade>> setupsMap = {};

    for (final trade in trades) {
      for (final setup in trade.setups) {
        setupsMap.putIfAbsent(setup, () => []).add(trade);
      }
    }

    final List<SetupStats> result = [];
    setupsMap.forEach((setupName, tradeList) {
      final stats = calculate(tradeList);
      result.add(SetupStats(
        name: setupName,
        totalTrades: tradeList.length,
        totalWins: stats.totalWins,
        winRate: stats.winRate,
        totalProfitPercent: stats.totalProfitPercent,
      ));
    });

    // Sort by profit percent descending
    result.sort((a, b) => b.totalProfitPercent.compareTo(a.totalProfitPercent));
    return result;
  }

  static List<ChecklistStats> calculateChecklistStats(List<Trade> trades) {
    // We want to analyze checklist items. For simplicity, we can calculate stats for:
    // 1. Single checklist items (e.g. "Trend sesuai")
    // 2. Combinations that appear together.
    final Map<String, List<Trade>> comboMap = {};

    for (final trade in trades) {
      if (trade.entryChecklist.isEmpty) continue;
      
      // Let's create key by joining checklist sorted alphabetically
      final sortedChecklist = List<String>.from(trade.entryChecklist)..sort();
      final key = sortedChecklist.join(' + ');
      
      comboMap.putIfAbsent(key, () => []).add(trade);

      // Also map single items to see individual checklist items win rate
      for (final item in trade.entryChecklist) {
        comboMap.putIfAbsent('$item (Individual)', () => []).add(trade);
      }
    }

    final List<ChecklistStats> result = [];
    comboMap.forEach((comboName, tradeList) {
      final wins = tradeList.where((t) => t.status == 'Win').length;
      final losses = tradeList.where((t) => t.status == 'Loss').length;
      final winRate = (wins + losses > 0) ? (wins / (wins + losses)) * 100 : 0.0;

      result.add(ChecklistStats(
        combination: comboName,
        totalTrades: tradeList.length,
        totalWins: wins,
        winRate: winRate,
      ));
    });

    // Sort by win rate descending
    result.sort((a, b) => b.winRate.compareTo(a.winRate));
    return result;
  }
}
