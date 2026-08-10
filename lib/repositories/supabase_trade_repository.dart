import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trade.dart';
import 'trade_repository.dart';

class SupabaseTradeRepository implements TradeRepository {
  final SupabaseClient _client;

  SupabaseTradeRepository(this._client);

  @override
  Future<List<Trade>> getTrades(String accountId) async {
    final response = await _client
        .from('trades')
        .select()
        .eq('account_id', accountId)
        .order('entry_time', ascending: false);

    return (response as List).map((json) => Trade.fromJson(json)).toList();
  }

  @override
  Future<void> saveTrade(Trade trade) async {
    await _client.from('trades').insert(trade.toJson());
  }

  @override
  Future<void> updateTrade(Trade trade) async {
    await _client
        .from('trades')
        .update(trade.toJson())
        .eq('id', trade.id);
  }

  @override
  Future<void> deleteTrade(String tradeId) async {
    await _client.from('trades').delete().eq('id', tradeId);
  }

  @override
  Future<String?> uploadScreenshot(
    String tradeId,
    Uint8List fileBytes,
    String fileName,
    bool isBefore,
  ) async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return null;

    final path = '$userId/$tradeId/${isBefore ? "before" : "after"}_$fileName';
    
    // Upload bytes
    await _client.storage.from('screenshots').uploadBinary(
          path,
          fileBytes,
          fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
        );

    // Get public URL
    final publicUrl = _client.storage.from('screenshots').getPublicUrl(path);
    return publicUrl;
  }
}
