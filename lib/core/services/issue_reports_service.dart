import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shinning_pools_flutter/core/services/auth_service.dart';
import 'dart:async';

class IssueReport {
  final String id;
  final String title;
  final String description;
  final String issueType;
  final String priority;
  final String reportedBy;
  final String reporterName;
  final String reporterEmail;
  final String companyId;
  final String status;
  final DateTime reportedAt;
  final String location;
  final String deviceInfo;
  final String? assignedTo;
  final String? assignedToName;
  final DateTime? assignedAt;
  final String? resolution;
  final DateTime? resolvedAt;
  final String? resolvedBy;
  final String? resolvedByName;

  IssueReport({
    required this.id,
    required this.title,
    required this.description,
    required this.issueType,
    required this.priority,
    required this.reportedBy,
    required this.reporterName,
    required this.reporterEmail,
    required this.companyId,
    required this.status,
    required this.reportedAt,
    required this.location,
    required this.deviceInfo,
    this.assignedTo,
    this.assignedToName,
    this.assignedAt,
    this.resolution,
    this.resolvedAt,
    this.resolvedBy,
    this.resolvedByName,
  });

  factory IssueReport.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return IssueReport(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      issueType: data['issueType'] ?? '',
      priority: data['priority'] ?? '',
      reportedBy: data['reportedBy'] ?? '',
      reporterName: data['reporterName'] ?? '',
      reporterEmail: data['reporterEmail'] ?? '',
      companyId: data['companyId'] ?? '',
      status: data['status'] ?? 'Open',
      reportedAt: (data['reportedAt'] as Timestamp).toDate(),
      location: data['location'] ?? '',
      deviceInfo: data['deviceInfo'] ?? '',
      assignedTo: data['assignedTo'],
      assignedToName: data['assignedToName'],
      assignedAt: data['assignedAt'] != null
          ? (data['assignedAt'] as Timestamp).toDate()
          : null,
      resolution: data['resolution'],
      resolvedAt: data['resolvedAt'] != null
          ? (data['resolvedAt'] as Timestamp).toDate()
          : null,
      resolvedBy: data['resolvedBy'],
      resolvedByName: data['resolvedByName'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'issueType': issueType,
      'priority': priority,
      'reportedBy': reportedBy,
      'reporterName': reporterName,
      'reporterEmail': reporterEmail,
      'companyId': companyId,
      'status': status,
      'reportedAt': Timestamp.fromDate(reportedAt),
      'location': location,
      'deviceInfo': deviceInfo,
      'assignedTo': assignedTo,
      'assignedToName': assignedToName,
      'assignedAt': assignedAt != null ? Timestamp.fromDate(assignedAt!) : null,
      'resolution': resolution,
      'resolvedAt': resolvedAt != null ? Timestamp.fromDate(resolvedAt!) : null,
      'resolvedBy': resolvedBy,
      'resolvedByName': resolvedByName,
    };
  }
}

class IssueReportsService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService;

  List<IssueReport> _issueReports = [];
  bool _isLoading = false;
  String? _error;

  // Real-time listeners
  StreamSubscription? _breakRequestsListener;
  IssueReport? _latestBreakRequestUpdate;

  List<IssueReport> get issueReports => _issueReports;
  bool get isLoading => _isLoading;
  String? get error => _error;
  IssueReport? get latestBreakRequestUpdate => _latestBreakRequestUpdate;

  IssueReportsService(this._authService);

  // Load issue reports for a company
  Future<void> loadIssueReports(String companyId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      print('🔍 Loading issue reports for company: $companyId');
      print('🔍 Current user role: ${currentUser.role}');
      print('🔍 Current user ID: ${currentUser.id}');

      Query query = _firestore.collection('issue_reports');

      // Filter based on user role
      if (currentUser.role == 'worker') {
        // Workers can only see their own reports
        query = query.where('reportedBy', isEqualTo: currentUser.id);
        print('🔍 Worker query: filtering by reportedBy = ${currentUser.id}');
      } else {
        // Admins and root can see all company reports
        query = query.where('companyId', isEqualTo: companyId);
        print('🔍 Admin query: filtering by companyId = $companyId');
      }

      final querySnapshot = await query
          .orderBy('reportedAt', descending: true)
          .get();

      print('🔍 Query result: ${querySnapshot.docs.length} documents found');

      _issueReports = querySnapshot.docs
          .map((doc) => IssueReport.fromFirestore(doc))
          .toList();

      print('🔍 Loaded ${_issueReports.length} issue reports');
      
      // Debug: Print each report
      for (int i = 0; i < _issueReports.length; i++) {
        final report = _issueReports[i];
        print('🔍 Report $i: ID=${report.id}, Status=${report.status}, Priority=${report.priority}, Title=${report.title}');
      }
      
      // Debug: Print statistics
      final stats = getIssueStatistics();
      print('🔍 Issue statistics: $stats');
    } catch (e) {
      _error = 'Error loading issue reports: $e';
      print('❌ IssueReportsService: Error loading issue reports: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create a new issue report
  Future<String?> createIssueReport(Map<String, dynamic> issueData) async {
    try {
      final docRef = await _firestore
          .collection('issue_reports')
          .add(issueData);
      return docRef.id;
    } catch (e) {
      _error = 'Error creating issue report: $e';
      if (kDebugMode) {
        print('IssueReportsService: Error creating issue report: $e');
      }
      notifyListeners();
      return null;
    }
  }

  // Update issue report status
  Future<bool> updateIssueStatus(
    String issueId,
    String status, {
    String? resolution,
    String? assignedTo,
    String? assignedToName,
  }) async {
    try {
      final currentUser = _authService.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final updateData = {
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (status == 'Resolved' && resolution != null) {
        updateData['resolution'] = resolution;
        updateData['resolvedAt'] = FieldValue.serverTimestamp();
        updateData['resolvedBy'] = currentUser.id;
        updateData['resolvedByName'] = currentUser.name;
      }

      if (assignedTo != null) {
        updateData['assignedTo'] = assignedTo;
        updateData['assignedToName'] = assignedToName ?? '';
        updateData['assignedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore
          .collection('issue_reports')
          .doc(issueId)
          .update(updateData);

      // Refresh the list
      if (currentUser.companyId != null) {
        await loadIssueReports(currentUser.companyId!);
      }

      return true;
    } catch (e) {
      _error = 'Error updating issue status: $e';
      if (kDebugMode) {
        print('IssueReportsService: Error updating issue status: $e');
      }
      notifyListeners();
      return false;
    }
  }

  // Get issue report by ID
  Future<IssueReport?> getIssueReport(String issueId) async {
    try {
      final doc = await _firestore
          .collection('issue_reports')
          .doc(issueId)
          .get();
      if (doc.exists) {
        return IssueReport.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      _error = 'Error getting issue report: $e';
      if (kDebugMode) {
        print('IssueReportsService: Error getting issue report: $e');
      }
      notifyListeners();
      return null;
    }
  }

  // Get statistics for dashboard
  Map<String, int> getIssueStatistics() {
    final total = _issueReports.length;
    final open = _issueReports.where((issue) => issue.status == 'Open').length;
    final inProgress = _issueReports
        .where((issue) => issue.status == 'In Progress')
        .length;
    final resolved = _issueReports
        .where((issue) => issue.status == 'Resolved')
        .length;
    final active = open + inProgress; // Total active issues
    final critical = _issueReports
        .where(
          (issue) =>
              issue.priority == 'Critical' &&
              (issue.status == 'Open' || issue.status == 'In Progress'),
        )
        .length;

    print('🔍 getIssueStatistics() called');
    print('🔍 Total reports: $total');
    print('🔍 Open reports: $open');
    print('🔍 In Progress reports: $inProgress');
    print('🔍 Resolved reports: $resolved');
    print('🔍 Active reports (open + inProgress): $active');
    print('🔍 Critical reports: $critical');

    return {
      'total': total,
      'open': open,
      'inProgress': inProgress,
      'resolved': resolved,
      'active': active, // New field for active issues
      'critical': critical, // Only unresolved critical issues
    };
  }

  // Get worker-specific issue statistics
  Map<String, int> getWorkerIssueStatistics(List<String> workerIds) {
    final workerReports = _issueReports
        .where((issue) => workerIds.contains(issue.reportedBy))
        .toList();

    final total = workerReports.length;
    final open = workerReports.where((issue) => issue.status == 'Open').length;
    final inProgress = workerReports
        .where((issue) => issue.status == 'In Progress')
        .length;
    final resolved = workerReports
        .where((issue) => issue.status == 'Resolved')
        .length;
    final active = open + inProgress; // Total active issues
    final critical = workerReports
        .where(
          (issue) =>
              issue.priority == 'Critical' &&
              (issue.status == 'Open' || issue.status == 'In Progress'),
        )
        .length;

    return {
      'total': total,
      'open': open,
      'inProgress': inProgress,
      'resolved': resolved,
      'active': active, // New field for active issues
      'critical': critical, // Only unresolved critical issues
    };
  }

  // Filter issue reports
  List<IssueReport> filterIssueReports({
    String? status,
    String? priority,
    String? issueType,
    String? reporterId,
  }) {
    return _issueReports.where((issue) {
      bool matchesStatus = status == null || issue.status == status;
      bool matchesPriority = priority == null || issue.priority == priority;
      bool matchesType = issueType == null || issue.issueType == issueType;
      bool matchesReporter =
          reporterId == null || issue.reportedBy == reporterId;

      return matchesStatus && matchesPriority && matchesType && matchesReporter;
    }).toList();
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Start listening for break request updates
  void startListeningForBreakRequests(String workerId) {
    _breakRequestsListener?.cancel();

    print('🎯 Setting up break request listener for worker: $workerId');

    _breakRequestsListener = _firestore
        .collection('issue_reports')
        .where('reportedBy', isEqualTo: workerId)
        .where('title', isEqualTo: 'Request Break')
        .snapshots()
        .listen(
          (snapshot) {
            print(
              '🎯 Break request listener received ${snapshot.docChanges.length} changes',
            );

            for (final change in snapshot.docChanges) {
              print(
                '🎯 Document change type: ${change.type} for doc: ${change.doc.id}',
              );

              if (change.type == DocumentChangeType.modified) {
                final issueReport = IssueReport.fromFirestore(change.doc);
                print(
                  '🎯 Modified break request - Status: ${issueReport.status}',
                );

                // Check if the break request was authorized (status changed to 'Resolved')
                if (issueReport.status == 'Resolved') {
                  print('🎯 Break request RESOLVED! Setting latest update...');
                  _latestBreakRequestUpdate = issueReport;
                  notifyListeners();

                  if (kDebugMode) {
                    print('☕ Break request authorized for worker: $workerId');
                    print('  - Issue ID: ${issueReport.id}');
                    print('  - Resolved by: ${issueReport.resolvedByName}');
                    print('  - Resolution: ${issueReport.resolution}');
                  }
                }
              }
            }
          },
          onError: (error) {
            print('❌ Error in break request listener: $error');
          },
        );
  }

  // Stop listening for break request updates
  void stopListeningForBreakRequests() {
    _breakRequestsListener?.cancel();
    _breakRequestsListener = null;
    _latestBreakRequestUpdate = null;
  }

  // Clear the latest break request update (after showing notification)
  void clearLatestBreakRequestUpdate() {
    _latestBreakRequestUpdate = null;
    notifyListeners();
  }
}
