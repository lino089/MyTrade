import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../repositories/account_repository.dart';
import '../repositories/auth_repository.dart';
import '../repositories/supabase_account_repository.dart';
import '../repositories/supabase_auth_repository.dart';
import '../repositories/supabase_trade_repository.dart';
import '../repositories/trade_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return SupabaseAuthRepository(Supabase.instance.client);
});

final tradeRepositoryProvider = Provider<TradeRepository>((ref) {
  return SupabaseTradeRepository(Supabase.instance.client);
});

final accountRepositoryProvider = Provider<AccountRepository>((ref) {
  return SupabaseAccountRepository(Supabase.instance.client);
});
