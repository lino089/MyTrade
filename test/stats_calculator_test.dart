import 'package:flutter_test/flutter_test.dart';
import 'package:jurnal_trade_app/core/utils/stats_calculator.dart';
import 'package:jurnal_trade_app/models/trade.dart';

void main() {
  group('StatsCalculator Tests', () {
    test('Calculates metrics correctly for mixed wins, losses and break evens', () {
      final now = DateTime.now();
      final trades = [
        Trade(
          id: '1',
          userId: 'user',
          accountId: 'acc-123',
          pair: 'EURUSD',
          direction: 'Buy',
          entryTime: now.subtract(const Duration(days: 3)),
          profitLossPercent: 2.0,
          profitLossAmount: 200.0,
          status: 'Win',
          tp: 200.0,
          sl: 100.0,
          result: 'TP',
          setups: ['Breakout'],
          entryChecklist: [],
        ),
        Trade(
          id: '2',
          userId: 'user',
          accountId: 'acc-123',
          pair: 'XAUUSD',
          direction: 'Sell',
          entryTime: now.subtract(const Duration(days: 2)),
          profitLossPercent: -1.0,
          profitLossAmount: -100.0,
          status: 'Loss',
          tp: 200.0,
          sl: 100.0,
          result: 'SL',
          setups: ['Liquidity Sweep'],
          entryChecklist: [],
        ),
        Trade(
          id: '3',
          userId: 'user',
          accountId: 'acc-123',
          pair: 'BTCUSD',
          direction: 'Buy',
          entryTime: now.subtract(const Duration(days: 1)),
          profitLossPercent: 3.0,
          profitLossAmount: 300.0,
          status: 'Win',
          tp: 300.0,
          sl: 150.0,
          result: 'TP',
          setups: ['Breakout'],
          entryChecklist: [],
        ),
        Trade(
          id: '4',
          userId: 'user',
          accountId: 'acc-123',
          pair: 'USDJPY',
          direction: 'Buy',
          entryTime: now,
          profitLossPercent: 0.0,
          profitLossAmount: 0.0,
          status: 'Break Even',
          tp: 100.0,
          sl: 50.0,
          result: 'Break Even',
          setups: ['Pullback'],
          entryChecklist: [],
        ),
      ];

      final stats = StatsCalculator.calculate(trades);

      expect(stats.totalTrades, equals(4));
      expect(stats.totalWins, equals(2));
      expect(stats.totalLosses, equals(1));
      expect(stats.totalBreakEvens, equals(1));
      
      // Win rate = wins / (wins + losses) = 2 / 3 * 100 = 66.66%
      expect(stats.winRate, closeTo(66.66, 0.1));
      
      // Total profit amount = 200 - 100 + 300 = 400
      expect(stats.totalProfitAmount, equals(400.0));
      
      // Total profit percent = 2 - 1 + 3 = 4%
      expect(stats.totalProfitPercent, equals(4.0));

      // Profit factor = gross profits / gross losses = (200 + 300) / 100 = 5.0
      expect(stats.profitFactor, equals(5.0));
    });

    test('Calculates streaks correctly', () {
      final now = DateTime.now();
      
      // Sequence: Win (3 days ago), Loss (2 days ago), Win (1 day ago), Win (today)
      // Max win streak = 2, Max loss streak = 1
      final trades = [
        Trade(
          id: '1',
          userId: 'user',
          accountId: 'acc-123',
          pair: 'EURUSD',
          direction: 'Buy',
          entryTime: now.subtract(const Duration(days: 3)),
          profitLossPercent: 1.0,
          profitLossAmount: 100.0,
          status: 'Win',
          tp: 100.0,
          sl: 50.0,
          result: 'TP',
          setups: [],
          entryChecklist: [],
        ),
        Trade(
          id: '2',
          userId: 'user',
          accountId: 'acc-123',
          pair: 'GBPUSD',
          direction: 'Sell',
          entryTime: now.subtract(const Duration(days: 2)),
          profitLossPercent: -1.0,
          profitLossAmount: -100.0,
          status: 'Loss',
          tp: 100.0,
          sl: 100.0,
          result: 'SL',
          setups: [],
          entryChecklist: [],
        ),
        Trade(
          id: '3',
          userId: 'user',
          accountId: 'acc-123',
          pair: 'BTCUSD',
          direction: 'Buy',
          entryTime: now.subtract(const Duration(days: 1)),
          profitLossPercent: 2.0,
          profitLossAmount: 200.0,
          status: 'Win',
          tp: 200.0,
          sl: 100.0,
          result: 'TP',
          setups: [],
          entryChecklist: [],
        ),
        Trade(
          id: '4',
          userId: 'user',
          accountId: 'acc-123',
          pair: 'XAUUSD',
          direction: 'Buy',
          entryTime: now,
          profitLossPercent: 1.5,
          profitLossAmount: 150.0,
          status: 'Win',
          tp: 150.0,
          sl: 75.0,
          result: 'TP',
          setups: [],
          entryChecklist: [],
        ),
      ];

      final stats = StatsCalculator.calculate(trades);

      expect(stats.maxWinStreak, equals(2));
      expect(stats.maxLossStreak, equals(1));
    });
  });
}
