import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'repository_providers.dart';

class AuthState {
  final String? userId;
  final String? email;
  final bool isLoading;
  final String? errorMessage;

  AuthState({
    this.userId,
    this.email,
    this.isLoading = false,
    this.errorMessage,
  });

  AuthState copyWith({
    String? userId,
    String? email,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
      email: email ?? this.email,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final Ref _ref;
  StreamSubscription<String?>? _authSubscription;

  AuthNotifier(this._ref) : super(AuthState()) {
    _init();
  }

  void _init() {
    final repo = _ref.read(authRepositoryProvider);
    state = AuthState(userId: repo.currentUserId, email: repo.currentUserEmail);
    
    // Listen to Supabase auth state changes
    _authSubscription = repo.onAuthStateChanged.listen((userId) {
      state = AuthState(
        userId: userId, 
        email: repo.currentUserEmail,
        isLoading: false,
      );
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  Future<bool> signIn(String email, String password) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.signInWithEmailAndPassword(email: email, password: password);
      state = AuthState(userId: repo.currentUserId, email: repo.currentUserEmail);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<bool> signUp(String email, String password, String username) async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.signUpWithEmailAndPassword(
        email: email,
        password: password,
        username: username,
      );
      state = AuthState(userId: repo.currentUserId, email: repo.currentUserEmail);
      return true;
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
      return false;
    }
  }

  Future<void> signOut() async {
    state = state.copyWith(isLoading: true);
    try {
      final repo = _ref.read(authRepositoryProvider);
      await repo.signOut();
      state = AuthState();
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.toString());
    }
  }
}

final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier(ref);
});
