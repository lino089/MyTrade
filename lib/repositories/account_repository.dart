import '../models/trading_account.dart';

abstract class AccountRepository {
  Future<List<TradingAccount>> getAccounts();
  Future<void> saveAccount(TradingAccount account);
  Future<void> deleteAccount(String accountId);
}
