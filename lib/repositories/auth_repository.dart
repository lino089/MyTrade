abstract class AuthRepository {
  Stream<String?> get onAuthStateChanged;
  String? get currentUserId;
  String? get currentUserEmail;
  
  Future<void> signInWithEmailAndPassword({
    required String email,
    required String password,
  });

  Future<void> signUpWithEmailAndPassword({
    required String email,
    required String password,
    required String username,
  });

  Future<void> signOut();
}
