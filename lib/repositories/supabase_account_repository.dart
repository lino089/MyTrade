import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/trading_account.dart';
import 'account_repository.dart';

class SupabaseAccountRepository implements AccountRepository {
  final SupabaseClient _client;

  SupabaseAccountRepository(this._client);

  @override
  Future<List<TradingAccount>> getAccounts() async {
    final response = await _client
        .from('trading_accounts')
        .select()
        .order('created_at', ascending: true);

    return (response as List).map((json) => TradingAccount.fromJson(json)).toList();
  }

  @override
  Future<void> saveAccount(TradingAccount account) async {
    await _client.from('trading_accounts').insert(account.toJson());
  }

  @override
  Future<void> deleteAccount(String accountId) async {
    await _client.from('trading_accounts').delete().eq('id', accountId);
  }
}
