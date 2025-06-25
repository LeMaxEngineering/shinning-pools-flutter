import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'user.dart';
import 'auth_repository.dart';
import 'firebase_auth_repository.dart';

class AuthService extends ChangeNotifier {
  final FirebaseAuthRepository _authRepository;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  AppUser? _currentUser;
  AppUser? get currentUser => _currentUser;

  bool _isLoading = true;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  AuthService(this._authRepository) {
    _authRepository.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(firebase_auth.User? firebaseUser) async {
    if (firebaseUser == null) {
      _currentUser = null;
    } else {
      // User is logged in, now fetch their full profile from Firestore
      await _loadUserFromFirestore(firebaseUser.uid);
    }
      _isLoading = false;
      notifyListeners();
  }
  
  Future<void> _loadUserFromFirestore(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        // Correctly creating AppUser from the DocumentSnapshot
        _currentUser = AppUser.fromFirestore(doc); 
      } else {
        _currentUser = null;
        _setError('User profile not found in database.');
      }
    } catch (e) {
      _currentUser = null;
      _setError('Error loading user data: $e');
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    try {
      // The signIn method from the repository returns a firebase_auth.User
      final firebaseUser = await _authRepository.signInWithEmailAndPassword(email, password);
      if (firebaseUser != null) {
        // We use the uid from the returned firebase_auth.User
        await _loadUserFromFirestore(firebaseUser.uid);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> registerWithEmailAndPassword(String email, String password) async {
    _setLoading(true);
    try {
      final firebaseUser = await _authRepository.registerWithEmailAndPassword(email, password);
      if (firebaseUser != null) {
        // After registration, the authState listener will fire,
        // but we can also load the user data immediately.
        await _loadUserFromFirestore(firebaseUser.uid);
      }
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    await _authRepository.signOut();
    _currentUser = null;
    notifyListeners();
  }
  
  void _setLoading(bool loading) {
    _isLoading = loading;
    _error = null;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    if (kDebugMode) {
      debugPrint('AuthService: Error during authentication: $error');
    }
  }

  void clearError() {
    _error = null;
      notifyListeners();
  }

  Future<void> signInWithGoogle() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentUser = await _authRepository.signInWithGoogle();
      _error = null;
    } catch (e) {
      _currentUser = null;
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      await _authRepository.sendPasswordResetEmail(email);
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendEmailVerification() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.sendEmailVerification();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> reloadUser() async {
    if (currentUser != null) {
      await _authRepository.reloadUser();
      notifyListeners();
    }
  }

  // Refresh user data from Firestore (useful after role changes)
  Future<void> refreshUserData() async {
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser != null) {
      await _loadUserFromFirestore(firebaseUser.uid);
    }
  }

  Future<void> checkEmailVerification() async {
    if (currentUser != null) {
      await _authRepository.reloadUser();
    notifyListeners();
    }
  }

  void onLoginSuccess(BuildContext context) async {
    final role = await fetchUserRole();
    if (role != null) {
      navigateToDashboard(context, role);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User role not found.')),
      );
    }
  }
}

Future<String?> fetchUserRole() async {
  final user = firebase_auth.FirebaseAuth.instance.currentUser;
  if (user == null) return null;
  final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
  return doc.data()?['role'] as String?;
}

void navigateToDashboard(BuildContext context, String role) {
  if (role == 'root') {
    Navigator.pushReplacementNamed(context, '/rootDashboard');
  } else if (role == 'admin') {
    Navigator.pushReplacementNamed(context, '/adminDashboard');
  } else if (role == 'worker') {
    Navigator.pushReplacementNamed(context, '/workerDashboard');
  } else if (role == 'customer') {
    Navigator.pushReplacementNamed(context, '/customerDashboard');
  } else {
    Navigator.pushReplacementNamed(context, '/unknownRole');
  }
} 