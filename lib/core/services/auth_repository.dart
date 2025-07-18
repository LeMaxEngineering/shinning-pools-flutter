import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

abstract class AuthRepository {
  Stream<firebase_auth.User?> get authStateChanges;
  
  Future<firebase_auth.User?> signInWithEmailAndPassword(String email, String password);
  
  Future<firebase_auth.User?> registerWithEmailAndPassword(String email, String password, {String? userphone});
  
  Future<void> signOut();
  
  Future<void> sendPasswordResetEmail(String email);
  
  Future<void> sendEmailVerification();
  
  Future<void> reloadUser();
} 