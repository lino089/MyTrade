import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trade.dart';
import '../models/trading_account.dart';
import 'account_provider.dart';
import 'repository_providers.dart';

class TradeNotifier extends StateNotifier<AsyncValue<List<Trade>>> {
  final Ref _ref;
  final TradingAccount? _selectedAccount;

  TradeNotifier(this._ref, this._selectedAccount) : super(const AsyncValue.loading()) {
    loadTrades();
  }

  Future<void> loadTrades() async {
    if (_selectedAccount == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(tradeRepositoryProvider);
      final trades = await repo.getTrades(_selectedAccount!.id);

      // Perform chronological running balance calculations
      final calculatedTrades = _calculateRunningBalances(trades, _selectedAccount!.initialBalance);

      state = AsyncValue.data(calculatedTrades);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  List<Trade> _calculateRunningBalances(List<Trade> rawTrades, double initialBalance) {
    // Sort trades chronologically (ASC) to calculate running balance
    final tradesAsc = List<Trade>.from(rawTrades)
      ..sort((a, b) => a.entryTime.compareTo(b.entryTime));

    double runningBalance = initialBalance;
    for (int i = 0; i < tradesAsc.length; i++) {
      final trade = tradesAsc[i];
      
      // Calculate PnL based on TP/SL values
      final double amount;
      if (trade.result == 'TP') {
        amount = trade.tp;
      } else if (trade.result == 'SL') {
        amount = -trade.sl;
      } else {
        amount = 0.0;
      }

      // Percentage is relative to the balance BEFORE this trade was taken
      final double percent = (runningBalance > 0) ? (amount / runningBalance) * 100 : 0.0;
      final String status = trade.result == 'TP' ? 'Win' : (trade.result == 'SL' ? 'Loss' : 'Break Even');

      tradesAsc[i] = trade.copyWith(
        profitLossAmount: amount,
        profitLossPercent: percent,
        status: status,
      );

      runningBalance += amount;
    }

    // Return descending (newest first) for UI
    return tradesAsc.reversed.toList();
  }

  Future<void> addTrade(Trade trade) async {
    if (_selectedAccount == null) return;
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(tradeRepositoryProvider);
      await repo.saveTrade(trade);
      await loadTrades(); // Reload to recalculate everything chronologically
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> updateTrade(Trade trade) async {
    if (_selectedAccount == null) return;
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(tradeRepositoryProvider);
      await repo.updateTrade(trade);
      await loadTrades(); // Reload to recalculate running balances
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteTrade(String tradeId) async {
    if (_selectedAccount == null) return;
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(tradeRepositoryProvider);
      await repo.deleteTrade(tradeId);
      await loadTrades(); // Reload to recalculate running balances
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<String?> uploadScreenshot(
    String tradeId,
    Uint8List fileBytes,
    String fileName,
    bool isBefore,
  ) async {
    try {
      final repo = _ref.read(tradeRepositoryProvider);
      return await repo.uploadScreenshot(tradeId, fileBytes, fileName, isBefore);
    } catch (e) {
      return null;
    }
  }
}

final tradeNotifierProvider =
    StateNotifierProvider<TradeNotifier, AsyncValue<List<Trade>>>((ref) {
  final selectedAccount = ref.watch(selectedAccountProvider);
  return TradeNotifier(ref, selectedAccount);
});
