import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'role.dart';

class AppUser {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool emailVerified;
  final UserRole role;
  final String? companyId; // Added companyId
  final String? companyName; // Added companyName
  final String name; // Added name
  final bool pendingCompanyRequest;

  AppUser({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    required this.emailVerified,
    required this.role,
    this.companyId, // Added to constructor
    this.companyName, // Added to constructor
    required this.name, // Added to constructor
    this.pendingCompanyRequest = false,
  });

  factory AppUser.fromFirebaseUser(firebase_auth.User firebaseUser) {
    // SECURITY FIX: Removed hardcoded root user logic
    // This method is a fallback and should only be used when Firestore data is not available.
    // All role assignments should be done through the database, not hardcoded in the application.
    final email = firebaseUser.email?.toLowerCase() ?? '';
    
    // Default to customer role for security - proper role assignment should be done through database
    const userRole = UserRole.customer;
    
    final name = firebaseUser.displayName ?? (email.isNotEmpty ? email.split('@').first : '');
    return AppUser(
      id: firebaseUser.uid,
      email: email,
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      emailVerified: firebaseUser.emailVerified,
      role: userRole,
      companyId: null, // Company ID is not available here
      companyName: null, // Company name is not available here
      name: name,
      pendingCompanyRequest: false,
    );
  }

  // Factory method to create user from DocumentSnapshot (for auth_service.dart)
  factory AppUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
        final roleString = data['role'] as String? ?? 'customer';
        
        UserRole userRole;
        switch (roleString.toLowerCase()) {
          case 'root':
            userRole = UserRole.root;
            break;
          case 'admin':
            userRole = UserRole.admin;
            break;
          case 'worker':
            userRole = UserRole.worker;
            break;
          default:
            userRole = UserRole.customer;
            break;
        }
    final displayName = data['displayName'] as String?;
    final email = data['email'] as String? ?? '';
    final name = displayName ?? (email.isNotEmpty ? email.split('@').first : '');
        return AppUser(
      id: doc.id,
      email: email,
      displayName: displayName,
          photoUrl: data['photoUrl'] as String?,
          emailVerified: data['emailVerified'] as bool? ?? false,
          role: userRole,
      companyId: data['companyId'] as String?,
      companyName: data['companyName'] as String?,
      name: name,
          pendingCompanyRequest: data['pendingCompanyRequest'] as bool? ?? false,
        );
      }

  String get currentName => name;
  String? get currentCompanyName => companyName;

  bool get isRoot => role.isRoot;
  bool get isAdmin => role.isAdmin;
  bool get isWorker => role.isWorker;
  bool get isCustomer => role.isCustomer;
}