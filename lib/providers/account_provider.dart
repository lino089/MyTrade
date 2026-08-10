import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import '../models/trading_account.dart';
import 'repository_providers.dart';
import 'auth_provider.dart';

class AccountsNotifier extends StateNotifier<AsyncValue<List<TradingAccount>>> {
  final Ref _ref;

  AccountsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _init();
  }

  void _init() {
    // Listen to auth state to reload accounts
    _ref.listen(authNotifierProvider, (previous, next) {
      if (next.userId == null) {
        state = const AsyncValue.data([]);
      } else {
        loadAccounts();
      }
    });
    loadAccounts();
  }

  Future<void> loadAccounts() async {
    final userId = _ref.read(authNotifierProvider).userId;
    if (userId == null) {
      state = const AsyncValue.data([]);
      return;
    }

    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(accountRepositoryProvider);
      final accounts = await repo.getAccounts();
      state = AsyncValue.data(accounts);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> addAccount(String name, double initialBalance, String currency) async {
    final userId = _ref.read(authNotifierProvider).userId;
    if (userId == null) return;

    final currentAccounts = state.value ?? [];
    state = const AsyncValue.loading();

    try {
      final repo = _ref.read(accountRepositoryProvider);
      final newAccount = TradingAccount(
        id: const Uuid().v4(),
        userId: userId,
        name: name,
        initialBalance: initialBalance,
        currency: currency,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await repo.saveAccount(newAccount);
      state = AsyncValue.data([...currentAccounts, newAccount]);
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }

  Future<void> deleteAccount(String accountId) async {
    final currentAccounts = state.value ?? [];
    state = const AsyncValue.loading();

    try {
      final repo = _ref.read(accountRepositoryProvider);
      await repo.deleteAccount(accountId);
      state = AsyncValue.data(currentAccounts.where((a) => a.id != accountId).toList());

      // Clear selection if active account was deleted
      final selected = _ref.read(selectedAccountProvider);
      if (selected?.id == accountId) {
        _ref.read(selectedAccountProvider.notifier).selectAccount(null);
      }
    } catch (e, stackTrace) {
      state = AsyncValue.error(e, stackTrace);
    }
  }
}

final accountsProvider = StateNotifierProvider<AccountsNotifier, AsyncValue<List<TradingAccount>>>((ref) {
  return AccountsNotifier(ref);
});

class SelectedAccountNotifier extends StateNotifier<TradingAccount?> {
  final Ref _ref;
  static const String _prefKey = 'selected_account_id';

  SelectedAccountNotifier(this._ref) : super(null) {
    _init();
  }

  Future<void> _init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedId = prefs.getString(_prefKey);
      if (cachedId != null) {
        _ref.listen<AsyncValue<List<TradingAccount>>>(
          accountsProvider,
          (previous, next) {
            next.whenData((accounts) {
              final matches = accounts.where((a) => a.id == cachedId);
              if (matches.isNotEmpty && state == null) {
                state = matches.first;
              }
            });
          },
          fireImmediately: true,
        );
      }
    } catch (_) {}
  }

  Future<void> selectAccount(TradingAccount? account) async {
    state = account;
    try {
      final prefs = await SharedPreferences.getInstance();
      if (account != null) {
        await prefs.setString(_prefKey, account.id);
      } else {
        await prefs.remove(_prefKey);
      }
    } catch (_) {}
  }
}

final selectedAccountProvider = StateNotifierProvider<SelectedAccountNotifier, TradingAccount?>((ref) {
  return SelectedAccountNotifier(ref);
});
