import 'package:firebase_auth/firebase_auth.dart';

import 'firestore_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirestoreService _firestoreService = FirestoreService();

  /// Emits the current user (or null) every time auth state changes.
  /// This is the single source of truth the whole app should react to —
  /// nothing should read FirebaseAuth.instance.currentUser directly in a
  /// build() method, because on web that value can briefly be null while
  /// the session is being restored, which is what caused earlier crashes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
    required String role,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final uid = credential.user!.uid;

    await _firestoreService.saveUser(
      uid: uid,
      fullName: fullName.trim(),
      email: email.trim(),
      role: role,
    );
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
