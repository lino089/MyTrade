import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/trade.dart';
import 'trade_provider.dart';

class TradeFilterState {
  final String? pair;
  final String? setup;
  final String? direction;
  final String? status;
  final String searchQuery;
  final DateTimeRange? dateRange;

  TradeFilterState({
    this.pair,
    this.setup,
    this.direction,
    this.status,
    this.searchQuery = '',
    this.dateRange,
  });

  TradeFilterState copyWith({
    String? pair,
    String? setup,
    String? direction,
    String? status,
    String? searchQuery,
    DateTimeRange? dateRange,
    bool clearPair = false,
    bool clearSetup = false,
    bool clearDirection = false,
    bool clearStatus = false,
    bool clearDateRange = false,
  }) {
    return TradeFilterState(
      pair: clearPair ? null : (pair ?? this.pair),
      setup: clearSetup ? null : (setup ?? this.setup),
      direction: clearDirection ? null : (direction ?? this.direction),
      status: clearStatus ? null : (status ?? this.status),
      searchQuery: searchQuery ?? this.searchQuery,
      dateRange: clearDateRange ? null : (dateRange ?? this.dateRange),
    );
  }
}

class TradeFilterNotifier extends StateNotifier<TradeFilterState> {
  TradeFilterNotifier() : super(TradeFilterState());

  void setPair(String? pair) => state = state.copyWith(pair: pair);
  void setSetup(String? setup) => state = state.copyWith(setup: setup);
  void setDirection(String? direction) => state = state.copyWith(direction: direction);
  void setStatus(String? status) => state = state.copyWith(status: status);
  void setSearchQuery(String query) => state = state.copyWith(searchQuery: query);
  void setDateRange(DateTimeRange? range) => state = state.copyWith(dateRange: range);

  void clearAll() {
    state = TradeFilterState();
  }
}

final tradeFilterProvider =
    StateNotifierProvider<TradeFilterNotifier, TradeFilterState>((ref) {
  return TradeFilterNotifier();
});

// A computed provider that filters the trades list automatically based on the filter state
final filteredTradesProvider = Provider<List<Trade>>((ref) {
  final tradesAsync = ref.watch(tradeNotifierProvider);
  final filter = ref.watch(tradeFilterProvider);

  return tradesAsync.maybeWhen(
    data: (trades) {
      return trades.where((trade) {
        // Filter by pair
        if (filter.pair != null && trade.pair != filter.pair) {
          return false;
        }

        // Filter by setup
        if (filter.setup != null && !trade.setups.contains(filter.setup)) {
          return false;
        }

        // Filter by direction (Buy/Sell)
        if (filter.direction != null && trade.direction != filter.direction) {
          return false;
        }

        // Filter by status (Win/Loss/Break Even)
        if (filter.status != null && trade.status != filter.status) {
          return false;
        }

        // Filter by date range
        if (filter.dateRange != null) {
          final entryNormalized = DateTime(trade.entryTime.year, trade.entryTime.month, trade.entryTime.day);
          final startNormalized = DateTime(filter.dateRange!.start.year, filter.dateRange!.start.month, filter.dateRange!.start.day);
          final endNormalized = DateTime(filter.dateRange!.end.year, filter.dateRange!.end.month, filter.dateRange!.end.day);
          
          if (entryNormalized.isBefore(startNormalized) || entryNormalized.isAfter(endNormalized)) {
            return false;
          }
        }

        // Search query
        if (filter.searchQuery.isNotEmpty) {
          final query = filter.searchQuery.toLowerCase();
          final inPair = trade.pair.toLowerCase().contains(query);
          final inSetup = trade.setups.any((s) => s.toLowerCase().contains(query));
          final inNote = trade.notes?.toLowerCase().contains(query) ?? false;
          final inDate = trade.entryTime.toIso8601String().contains(query);
          
          if (!inPair && !inSetup && !inNote && !inDate) {
            return false;
          }
        }

        return true;
      }).toList();
    },
    orElse: () => [],
  );
});
