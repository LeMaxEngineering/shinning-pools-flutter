import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user.dart';
import 'auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  FirebaseAuthRepository({firebase_auth.FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance;

  @override
  Stream<firebase_auth.User?> get authStateChanges {
    return _firebaseAuth.authStateChanges();
  }

  @override
  Future<firebase_auth.User?> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return userCredential.user;
    } on firebase_auth.FirebaseAuthException {
      rethrow; // Let the service handle the specific error codes
    }
  }

  @override
  Future<firebase_auth.User?> registerWithEmailAndPassword(String email, String password, {String? userphone}) async {
    try {
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      final firebaseUser = userCredential.user;
          
      if (firebaseUser != null) {
        // Create a document for the user with basic info including phone
        await _firestore.collection('users').doc(firebaseUser.uid).set({
          'uid': firebaseUser.uid,
          'email': email,
          'userphone': userphone, // Store phone number
          'displayName': firebaseUser.displayName,
          'photoUrl': firebaseUser.photoURL,
          'role': 'customer', // Default role
          'emailVerified': firebaseUser.emailVerified,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'pendingCompanyRequest': false,
          'companyId': null,
        });
      }
      return firebaseUser;
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  // Other methods like sendPasswordResetEmail, etc. can remain here as they are direct firebase calls.
  @override
  Future<void> sendPasswordResetEmail(String email) async {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> sendEmailVerification() async {
      final user = _firebaseAuth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  @override
  Future<void> reloadUser() async {
    await _firebaseAuth.currentUser?.reload();
  }
  
  // Add currentUser getter to fix compilation errors
  firebase_auth.User? get currentUser => _firebaseAuth.currentUser;
  
  // This repository should not be concerned with AppUser or GoogleSignIn
  // For simplicity, we remove signInWithGoogle from this refactoring
  Future<AppUser?> signInWithGoogle() async {
    // This should be implemented properly if needed, but is removed to fix the main issue
    throw UnimplementedError("Google Sign-In is not implemented in this refactoring.");
  }
} 