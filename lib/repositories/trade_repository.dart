import 'dart:typed_data';
import '../models/trade.dart';

abstract class TradeRepository {
  Future<List<Trade>> getTrades(String accountId);
  Future<void> saveTrade(Trade trade);
  Future<void> updateTrade(Trade trade);
  Future<void> deleteTrade(String tradeId);
  Future<String?> uploadScreenshot(
    String tradeId,
    Uint8List fileBytes,
    String fileName,
    bool isBefore,
  );
}
