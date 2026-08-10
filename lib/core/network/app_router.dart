import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/accounts/accounts_list_screen.dart';
import '../../features/auth/login_screen.dart';
import '../../features/auth/register_screen.dart';
import '../../features/dashboard/main_navigation_screen.dart';
import '../../features/trade/trade_detail_screen.dart';
import '../../features/trade/trade_form_screen.dart';
import '../../providers/account_provider.dart';
import '../../providers/auth_provider.dart';

class SplashPage extends ConsumerWidget {
  const SplashPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    Future.microtask(() {
      final authState = ref.read(authNotifierProvider);

      if (authState.userId != null) {
        final selectedAccount = ref.read(selectedAccountProvider);
        if (selectedAccount != null) {
          context.go('/home');
        } else {
          context.go('/accounts');
        }
      } else {
        context.go('/login');
      }
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;

  RouterNotifier(this._ref) {
    _ref.listen(authNotifierProvider, (_, __) {
      notifyListeners();
    });
    _ref.listen(selectedAccountProvider, (_, __) {
      notifyListeners();
    });
  }
}

final routerNotifierProvider = Provider((ref) => RouterNotifier(ref));

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = ref.read(routerNotifierProvider);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: notifier,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const AccountsListScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const MainNavigationScreen(),
      ),
      GoRoute(
        path: '/trade/add',
        builder: (context, state) => const TradeFormScreen(),
      ),
      GoRoute(
        path: '/trade/edit/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TradeFormScreen(tradeId: id);
        },
      ),
      GoRoute(
        path: '/trade/detail/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return TradeDetailScreen(tradeId: id);
        },
      ),
    ],
    redirect: (context, state) {
      final authState = ref.read(authNotifierProvider);
      final selectedAccount = ref.read(selectedAccountProvider);
      
      final isAuthRoute = state.matchedLocation == '/login' || state.matchedLocation == '/register';
      final isSplash = state.matchedLocation == '/';

      if (isSplash) return null;

      final isLoggedIn = authState.userId != null;
      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn) {
        if (isAuthRoute) {
          return selectedAccount != null ? '/home' : '/accounts';
        }
        
        final hasSelectedAccount = selectedAccount != null;
        final goingToMainApp = state.matchedLocation == '/home' || state.matchedLocation.startsWith('/trade');
        
        if (goingToMainApp && !hasSelectedAccount) {
          return '/accounts';
        }
      }
      return null;
    },
  );
});
