import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shinning_pools_flutter/features/users/models/worker_invitation.dart';
import 'firestore_service.dart';
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';

class WorkerInvitationRepository {
  final FirestoreService _firestoreService;

  WorkerInvitationRepository({FirestoreService? firestoreService})
      : _firestoreService = firestoreService ?? FirestoreService();

  // Create a new worker invitation
  Future<WorkerInvitation> createInvitation({
    required String companyId,
    required String companyName,
    required String invitedUserEmail,
    required String invitedByUserId,
    required String invitedByUserName,
    String? message,
  }) async {
    // 1. Find the user by email
    final userDoc = await findUserByEmail(invitedUserEmail);
    if (userDoc == null || !userDoc.exists) {
      throw Exception('No user found with the email address: $invitedUserEmail');
    }
    final invitedUserId = userDoc.id;

    // 2. Validate that the found user is eligible to be a worker
    final validationResult = await validateUserForWorkerInvitation(invitedUserId);
    if (!validationResult['isValid']) {
      throw Exception(validationResult['error'] ?? 'User is not eligible to be invited as a worker.');
    }

    // 3. Check if the user is already invited or part of the company
    final isAlreadyInvited = await isEmailAlreadyInvited(invitedUserEmail, companyId);
    if (isAlreadyInvited) {
      throw Exception('This user has already been invited or is already part of the company.');
    }
    
    final now = DateTime.now();
    final expiresAt = now.add(const Duration(days: 7));
    
    final invitationData = {
      'companyId': companyId,
      'companyName': companyName,
      'invitedUserEmail': invitedUserEmail,
      'invitedUserId': invitedUserId, // Use the ID found via email lookup
      'invitedByUserId': invitedByUserId,
      'invitedByUserName': invitedByUserName,
      'status': 'pending',
      'message': message,
      'createdAt': Timestamp.fromDate(now),
      'expiresAt': Timestamp.fromDate(expiresAt),
    };

    final docRef = await _firestoreService.addDocument(
      _firestoreService.workerInvitationsCollection,
      invitationData,
    );

    // Get the created document and return as WorkerInvitation object
    final doc = await docRef.get();
    return WorkerInvitation.fromFirestore(doc);
  }

  // Get an invitation by ID
  Future<WorkerInvitation> getInvitation(String invitationId) async {
    final doc = await _firestoreService.getDocument(
      _firestoreService.workerInvitationsCollection,
      invitationId,
    );
    return WorkerInvitation.fromFirestore(doc);
  }

  // Stream an invitation's updates
  Stream<WorkerInvitation> streamInvitation(String invitationId) {
    return _firestoreService.streamDocument(
      _firestoreService.workerInvitationsCollection,
      invitationId,
    ).map((doc) => WorkerInvitation.fromFirestore(doc));
  }

  // Update invitation status
  Future<void> updateInvitationStatus(String invitationId, String status) async {
    final now = DateTime.now();
    await _firestoreService.updateDocument(
      _firestoreService.workerInvitationsCollection,
      invitationId,
      {
        'status': status,
        'respondedAt': Timestamp.fromDate(now),
      },
    );
  }

  // Delete an invitation
  Future<void> deleteInvitation(String invitationId) async {
    await _firestoreService.deleteDocument(
      _firestoreService.workerInvitationsCollection,
      invitationId,
    );
  }

  // Get all pending invitations for a user
  Stream<List<WorkerInvitation>> streamUserInvitations(String userId) {
    return _firestoreService.streamCollection(
      _firestoreService.workerInvitationsCollection,
      queryBuilder: (query) => query
          .where('invitedUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true),
    ).map((snapshot) => snapshot.docs
        .map((doc) => WorkerInvitation.fromFirestore(doc))
        .toList());
  }

  // Get all pending invitations for a company
  Stream<List<WorkerInvitation>> streamCompanyInvitations(String companyId) {
    return _firestoreService.streamCollection(
      _firestoreService.workerInvitationsCollection,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true),
    ).map((snapshot) => snapshot.docs
        .map((doc) => WorkerInvitation.fromFirestore(doc))
        .toList());
  }

  // Get all pending invitations for a company (non-stream version)
  Future<List<WorkerInvitation>> getCompanyInvitations(String companyId) async {
    final snapshot = await _firestoreService.getCollection(
      _firestoreService.workerInvitationsCollection,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('status', isEqualTo: 'pending')
          .orderBy('createdAt', descending: true),
    );
    return snapshot.docs
        .map((doc) => WorkerInvitation.fromFirestore(doc))
        .toList();
  }

  // Stream all responded invitations (accepted or rejected) for a company that have not been seen by admin
  Stream<List<WorkerInvitation>> streamRespondedInvitationsForCompany(String companyId) {
    return _firestoreService.streamCollection(
      _firestoreService.workerInvitationsCollection,
      queryBuilder: (query) => query
          .where('companyId', isEqualTo: companyId)
          .where('status', whereIn: ['accepted', 'rejected'])
          .where('isSeenByAdmin', isEqualTo: false)
          .orderBy('respondedAt', descending: true),
    ).map((snapshot) => snapshot.docs
        .map((doc) => WorkerInvitation.fromFirestore(doc))
        .toList());
  }

  // Mark an invitation as seen by the admin
  Future<void> markInvitationAsSeen(String invitationId) async {
    await _firestoreService.updateDocument(
      _firestoreService.workerInvitationsCollection,
      invitationId,
      {'isSeenByAdmin': true},
    );
  }

  // Check if user has pending invitations
  Future<bool> hasPendingInvitations(String userId) async {
    final snapshot = await _firestoreService.getCollection(
      _firestoreService.workerInvitationsCollection,
      queryBuilder: (query) => query
          .where('invitedUserId', isEqualTo: userId)
          .where('status', isEqualTo: 'pending'),
    );
    return snapshot.docs.isNotEmpty;
  }

  // Check if email is already invited
  Future<bool> isEmailAlreadyInvited(String email, String companyId) async {
    final snapshot = await _firestoreService.getCollection(
      _firestoreService.workerInvitationsCollection,
      queryBuilder: (query) => query
          .where('invitedUserEmail', isEqualTo: email)
          .where('companyId', isEqualTo: companyId)
          .where('status', whereIn: ['pending', 'accepted']),
    );
    return snapshot.docs.isNotEmpty;
  }

  // Find user by email
  Future<DocumentSnapshot?> findUserByEmail(String email) async {
    final snapshot = await _firestoreService.getCollection(
      _firestoreService.usersCollection,
      queryBuilder: (query) => query.where('email', isEqualTo: email.toLowerCase()),
    );
    return snapshot.docs.isNotEmpty ? snapshot.docs.first : null;
  }

  // Validate user eligibility for worker invitation
  Future<Map<String, dynamic>> validateUserForWorkerInvitation(String userId) async {
    try {
      // Get user document
      final userDoc = await _firestoreService.getDocument(
        _firestoreService.usersCollection,
        userId,
      );
      
      if (!userDoc.exists) {
        return {
          'isValid': false,
          'error': 'User not found',
        };
      }

      final userData = userDoc.data() as Map<String, dynamic>;
      final userRole = userData['role'] ?? 'customer';

      // Check if user has customer role
      if (userRole != 'customer') {
        return {
          'isValid': false,
          'error': 'User must have customer role to be invited as worker',
        };
      }

      // Check if user has registered swimming pools
      final poolsSnapshot = await _firestoreService.getCollection(
        _firestoreService.poolsCollection,
        queryBuilder: (query) => query.where('ownerId', isEqualTo: userId),
      );

      if (poolsSnapshot.docs.isNotEmpty) {
        return {
          'isValid': false,
          'error': 'User has registered swimming pools and cannot be invited as worker',
        };
      }

      return {
        'isValid': true,
        'userData': userData,
      };
    } catch (e) {
      return {
        'isValid': false,
        'error': 'Failed to validate user: $e',
      };
    }
  }

  // Accept invitation and create worker
  Future<void> acceptInvitation(WorkerInvitation invitation) async {
    try {
      debugPrint('Starting acceptInvitation for user ${invitation.invitedUserId}');
      
      // Update invitation status
      await _firestoreService.updateDocument(
        _firestoreService.workerInvitationsCollection,
        invitation.id,
        {
          'status': 'accepted',
          'respondedAt': FieldValue.serverTimestamp(),
          'isSeenByAdmin': false, // Mark as a new notification for the admin
        },
      );
      debugPrint('✓ Invitation status updated to accepted for ${invitation.id}');
      
      // Update user role to worker and add company association
      // Fetch user data for name/email if needed
      final userDoc = await _firestoreService.getDocument(
        _firestoreService.usersCollection,
        invitation.invitedUserId,
      );
      
      if (!userDoc.exists) {
        throw Exception('User document not found for ${invitation.invitedUserId}');
      }
      
      final userData = userDoc.data() as Map<String, dynamic>? ?? {};
      final name = userData['name'] ?? userData['displayName'] ?? invitation.invitedByUserName ?? invitation.invitedUserEmail.split('@').first;
      final email = userData['email'] ?? invitation.invitedUserEmail;
      final phone = userData['phone'] ?? '';
      final photoUrl = userData['photoUrl'];
      
      debugPrint('✓ User data retrieved: name=$name, email=$email');
      
      // Update displayName in users collection
      await _firestoreService.updateDocument(
        _firestoreService.usersCollection,
        invitation.invitedUserId,
        {
          'role': 'worker',
          'companyId': invitation.companyId,
          'displayName': name,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );
      debugPrint('✓ User document updated for ${invitation.invitedUserId}');

      // Create or update a worker document in the workers collection
      debugPrint('Checking if worker document exists for ${invitation.invitedUserId}');
      final workerDoc = await _firestoreService.getDocument(
        _firestoreService.workersCollection,
        invitation.invitedUserId,
      );
      
      final workerData = {
        'userId': invitation.invitedUserId,
        'name': name,
        'email': email,
        'phone': phone,
        'photoUrl': photoUrl,
        'companyId': invitation.companyId,
        'status': 'available',
        'poolsAssigned': 0,
        'rating': 0.0,
        'lastActive': FieldValue.serverTimestamp(),
      };
      
      if (workerDoc.exists) {
        debugPrint('Worker document exists, updating...');
        await _firestoreService.updateDocument(
          _firestoreService.workersCollection,
          invitation.invitedUserId,
          workerData,
        );
        debugPrint('✓ Worker document updated for ${invitation.invitedUserId}');
      } else {
        debugPrint('Worker document does not exist, creating new one...');
        // Create new worker document with explicit timestamps
        await _firestoreService.workersCollection
          .doc(invitation.invitedUserId)
          .set({
            ...workerData,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
        debugPrint('✓ Worker document created for ${invitation.invitedUserId}');
        
        // Verify the document was created
        final verifyDoc = await _firestoreService.getDocument(
          _firestoreService.workersCollection,
          invitation.invitedUserId,
        );
        if (verifyDoc.exists) {
          debugPrint('✓ Worker document creation verified successfully');
        } else {
          debugPrint('✗ ERROR: Worker document was not created despite set() call');
          throw Exception('Failed to create worker document');
        }
      }
      
      debugPrint('✓ acceptInvitation completed successfully for ${invitation.invitedUserId}');
    } catch (e, stack) {
      debugPrint('✗ Error in acceptInvitation: $e');
      debugPrint('Stack trace: $stack');
      rethrow;
    }
  }

  // Reject invitation
  Future<void> rejectInvitation(WorkerInvitation invitation) async {
    await _firestoreService.updateDocument(
      _firestoreService.workerInvitationsCollection,
      invitation.id,
      {
        'status': 'rejected',
        'respondedAt': FieldValue.serverTimestamp(),
        'isSeenByAdmin': false, // Mark as a new notification for the admin
      },
    );
  }

  // Remove worker from company (revert to customer)
  Future<void> removeWorkerFromCompany(String workerId) async {
    try {
      // Update user role back to customer and remove company association
      await _firestoreService.updateDocument(
        _firestoreService.usersCollection,
        workerId,
        {
          'role': 'customer',
          'companyId': '', // Set to empty string instead of null
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      // Delete worker document if it exists
      try {
        await _firestoreService.deleteDocument(
          _firestoreService.workersCollection,
          workerId,
        );
      } catch (e) {
        // Worker document might not exist, which is fine
        if (kDebugMode) {
          debugPrint('WorkerInvitationRepository: Worker document not found for deletion: $e');
        }
      }
    } catch (e) {
      throw Exception('Failed to remove worker from company: $e');
    }
  }

  // Clean up expired invitations
  Future<void> cleanupExpiredInvitations() async {
    final now = DateTime.now();
    final snapshot = await _firestoreService.getCollection(
      _firestoreService.workerInvitationsCollection,
      queryBuilder: (query) => query
          .where('status', isEqualTo: 'pending')
          .where('expiresAt', isLessThan: Timestamp.fromDate(now)),
    );

    for (final doc in snapshot.docs) {
      await updateInvitationStatus(doc.id, 'expired');
    }
  }

  // Send reminder for a specific invitation
  Future<bool> sendReminder(String invitationId) async {
    try {
      final invitation = await getInvitation(invitationId);
      
      if (invitation.status != InvitationStatus.pending) {
        throw Exception('Cannot send reminder for non-pending invitation');
      }
      
      if (!invitation.canSendReminder) {
        throw Exception('Reminder already sent recently. Please wait 24 hours between reminders.');
      }
      
      // Call Cloud Function to send the actual reminder
      final functions = FirebaseFunctions.instance;
      final result = await functions.httpsCallable('sendWorkerInvitationReminder').call({
        'invitationId': invitationId,
        'invitedUserEmail': invitation.invitedUserEmail,
        'companyName': invitation.companyName,
        'invitedByUserName': invitation.invitedByUserName,
        'message': invitation.message,
      });
      
      if (result.data['success'] == true) {
        // Update the invitation with reminder tracking
        final now = DateTime.now();
        final updatedReminderSentAt = [...invitation.reminderSentAt, now];
        
        await _firestoreService.updateDocument(
          _firestoreService.workerInvitationsCollection,
          invitationId,
          {
            'reminderSentAt': updatedReminderSentAt.map((date) => Timestamp.fromDate(date)).toList(),
            'lastReminderSentAt': Timestamp.fromDate(now),
          },
        );
        
        return true;
      } else {
        throw Exception(result.data['error'] ?? 'Failed to send reminder');
      }
    } catch (e) {
      debugPrint('Error sending reminder: $e');
      rethrow;
    }
  }

  // Send reminders to all pending invitations that need them
  Future<Map<String, dynamic>> sendRemindersToPendingInvitations(String companyId) async {
    try {
      final pendingInvitations = await getCompanyInvitations(companyId);
      final invitationsNeedingReminders = pendingInvitations.where((inv) => inv.needsReminder && inv.canSendReminder).toList();
      
      if (invitationsNeedingReminders.isEmpty) {
        return {
          'success': true,
          'message': 'No invitations need reminders at this time',
          'sentCount': 0,
          'totalPending': pendingInvitations.length,
        };
      }
      
      int successCount = 0;
      List<String> errors = [];
      
      for (final invitation in invitationsNeedingReminders) {
        try {
          final success = await sendReminder(invitation.id);
          if (success) successCount++;
        } catch (e) {
          errors.add('Failed to send reminder to ${invitation.invitedUserEmail}: $e');
        }
      }
      
      return {
        'success': true,
        'message': 'Reminders sent successfully',
        'sentCount': successCount,
        'totalPending': pendingInvitations.length,
        'errors': errors,
      };
    } catch (e) {
      return {
        'success': false,
        'error': 'Failed to send reminders: $e',
        'sentCount': 0,
        'totalPending': 0,
      };
    }
  }
} 