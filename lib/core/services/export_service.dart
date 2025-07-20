import 'dart:convert';
import 'dart:io';
import 'dart:html' as html;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../features/users/models/worker.dart';
import '../../features/users/models/worker_invitation.dart';

class ExportService {
  static const String _dateFormat = 'yyyy-MM-dd HH:mm:ss';

  /// Export worker data to CSV format
  static Future<String?> exportWorkersToCSV(List<Worker> workers, List<WorkerInvitation> invitations) async {
    try {
      final csvData = _generateWorkersCSV(workers, invitations);
      return await _saveAndShareFile(csvData, 'workers_export.csv', 'text/csv');
    } catch (e) {
      debugPrint('Error exporting workers to CSV: $e');
      return null;
    }
  }

  /// Export worker data to JSON format
  static Future<String?> exportWorkersToJSON(List<Worker> workers, List<WorkerInvitation> invitations) async {
    try {
      final jsonData = _generateWorkersJSON(workers, invitations);
      return await _saveAndShareFile(jsonData, 'workers_export.json', 'application/json');
    } catch (e) {
      debugPrint('Error exporting workers to JSON: $e');
      return null;
    }
  }

  /// Generate CSV content for workers data
  static String _generateWorkersCSV(List<Worker> workers, List<WorkerInvitation> invitations) {
    final buffer = StringBuffer();
    final dateFormat = DateFormat(_dateFormat);

    // CSV Header
    buffer.writeln('Name,Email,Phone,Status,Pools Assigned,Rating,Last Active,Company ID');

    // Worker data
    for (final worker in workers) {
      buffer.writeln([
        _escapeCSVField(worker.name),
        _escapeCSVField(worker.email),
        _escapeCSVField(worker.phone),
        _escapeCSVField(worker.status),
        worker.poolsAssigned.toString(),
        worker.rating.toStringAsFixed(2),
        _escapeCSVField(worker.lastActive != null ? dateFormat.format(worker.lastActive!) : ''),
        _escapeCSVField(worker.companyId),
      ].join(','));
    }

    // Add invitation data if available
    if (invitations.isNotEmpty) {
      buffer.writeln(''); // Empty line separator
      buffer.writeln('Invitation Data');
      buffer.writeln('Email,Status,Invited By,Sent Date,Responded Date,Reminder Count,Message');

      for (final invitation in invitations) {
        buffer.writeln([
          _escapeCSVField(invitation.invitedUserEmail),
          _escapeCSVField(invitation.statusDisplay),
          _escapeCSVField(invitation.invitedByUserName),
          _escapeCSVField(dateFormat.format(invitation.createdAt)),
          _escapeCSVField(invitation.respondedAt != null ? dateFormat.format(invitation.respondedAt!) : ''),
          invitation.reminderCount.toString(),
          _escapeCSVField(invitation.message ?? ''),
        ].join(','));
      }
    }

    return buffer.toString();
  }

  /// Generate JSON content for workers data
  static String _generateWorkersJSON(List<Worker> workers, List<WorkerInvitation> invitations) {
    final dateFormat = DateFormat(_dateFormat);
    
    final exportData = {
      'exportDate': dateFormat.format(DateTime.now()),
      'totalWorkers': workers.length,
      'totalInvitations': invitations.length,
      'workers': workers.map((worker) => {
        'name': worker.name,
        'email': worker.email,
        'phone': worker.phone,
        'status': worker.status,
        'poolsAssigned': worker.poolsAssigned,
        'rating': worker.rating,
        'lastActive': worker.lastActive != null ? dateFormat.format(worker.lastActive!) : null,
        'companyId': worker.companyId,
        'id': worker.id,
      }).toList(),
      'invitations': invitations.map((invitation) => {
        'email': invitation.invitedUserEmail,
        'status': invitation.statusDisplay,
        'invitedBy': invitation.invitedByUserName,
        'sentDate': dateFormat.format(invitation.createdAt),
        'respondedDate': invitation.respondedAt != null ? dateFormat.format(invitation.respondedAt!) : null,
        'reminderCount': invitation.reminderCount,
        'message': invitation.message,
        'isExpired': invitation.isExpired,
        'needsReminder': invitation.needsReminder,
      }).toList(),
      'summary': {
        'activeWorkers': workers.where((w) => w.status == 'active').length,
        'availableWorkers': workers.where((w) => w.status == 'available').length,
        'onRouteWorkers': workers.where((w) => w.status == 'on_route').length,
        'pendingInvitations': invitations.where((i) => i.status == InvitationStatus.pending).length,
        'acceptedInvitations': invitations.where((i) => i.status == InvitationStatus.accepted).length,
        'rejectedInvitations': invitations.where((i) => i.status == InvitationStatus.rejected).length,
        'expiredInvitations': invitations.where((i) => i.status == InvitationStatus.expired).length,
        'averageRating': workers.isNotEmpty ? workers.map((w) => w.rating).reduce((a, b) => a + b) / workers.length : 0.0,
        'totalPoolsAssigned': workers.fold(0, (sum, w) => sum + w.poolsAssigned),
      }
    };

    return JsonEncoder.withIndent('  ').convert(exportData);
  }

  /// Escape CSV field to handle commas and quotes
  static String _escapeCSVField(String field) {
    if (field.contains(',') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }

  /// Save file and share it
  static Future<String?> _saveAndShareFile(String content, String fileName, String mimeType) async {
    try {
      Directory? directory;
      
      if (kIsWeb) {
        // For web, implement proper file download
        try {
          final bytes = utf8.encode(content);
          final blob = html.Blob([bytes]);
          final url = html.Url.createObjectUrlFromBlob(blob);
          
          // Create timestamped filename
          final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
          final timestampedFileName = '${timestamp}_$fileName';
          
          // Create download link and trigger download
          final anchor = html.AnchorElement(href: url)
            ..setAttribute('download', timestampedFileName)
            ..click();
          
          // Clean up the URL object
          html.Url.revokeObjectUrl(url);
          
          debugPrint('Web file download initiated: $timestampedFileName');
          return 'Downloaded: $timestampedFileName';
        } catch (e) {
          debugPrint('Error in web download: $e');
          return 'Web download failed: $e';
        }
      } else {
        // For mobile platforms - use Downloads directory if available
        if (Platform.isAndroid) {
          // Try to use Downloads directory first
          try {
            directory = Directory('/storage/emulated/0/Download');
            if (!await directory.exists()) {
              directory = await getTemporaryDirectory();
            }
          } catch (e) {
            directory = await getTemporaryDirectory();
          }
        } else if (Platform.isIOS) {
          // For iOS, use Documents directory which is accessible via Files app
          directory = await getApplicationDocumentsDirectory();
        } else {
          directory = await getApplicationDocumentsDirectory();
        }

        // Create a timestamped filename to avoid conflicts
        final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
        final timestampedFileName = '${timestamp}_$fileName';
        
        final file = File('${directory.path}/$timestampedFileName');
        await file.writeAsString(content);

        debugPrint('File saved to: ${file.path}');
        debugPrint('File size: ${await file.length()} bytes');

        // Share the file with more options
        await Share.shareXFiles(
          [XFile(file.path)],
          text: 'Worker data export from Shinning Pools - $timestampedFileName',
          subject: 'Shinning Pools Worker Export',
        );

        return file.path;
      }
    } catch (e) {
      debugPrint('Error saving and sharing file: $e');
      return null;
    }
  }

  /// Show export format selection dialog
  static Future<String?> showExportFormatDialog(BuildContext context) async {
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Format'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.table_chart, color: Colors.blue),
              title: const Text('CSV Format'),
              subtitle: const Text('Compatible with Excel, Google Sheets'),
              onTap: () => Navigator.of(context).pop('csv'),
            ),
            ListTile(
              leading: const Icon(Icons.code, color: Colors.green),
              title: const Text('JSON Format'),
              subtitle: const Text('Structured data with metadata'),
              onTap: () => Navigator.of(context).pop('json'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  /// Get file location help text based on platform
  static String getFileLocationHelp() {
    if (kIsWeb) {
      return 'File downloaded to your browser\'s default download folder. Check your Downloads folder or browser download history.';
    } else if (Platform.isAndroid) {
      return 'File saved to Downloads folder. Check your device\'s Downloads folder or use a file manager app.';
    } else if (Platform.isIOS) {
      return 'File saved to Documents folder. Open Files app and check "On My iPhone/iPad" > "Shinning Pools".';
    } else {
      return 'File saved to application documents directory.';
    }
  }

  /// Get export statistics
  static Map<String, dynamic> getExportStats(List<Worker> workers, List<WorkerInvitation> invitations) {
    return {
      'totalWorkers': workers.length,
      'activeWorkers': workers.where((w) => w.status == 'active').length,
      'availableWorkers': workers.where((w) => w.status == 'available').length,
      'onRouteWorkers': workers.where((w) => w.status == 'on_route').length,
      'totalInvitations': invitations.length,
      'pendingInvitations': invitations.where((i) => i.status == InvitationStatus.pending).length,
      'acceptedInvitations': invitations.where((i) => i.status == InvitationStatus.accepted).length,
      'rejectedInvitations': invitations.where((i) => i.status == InvitationStatus.rejected).length,
      'expiredInvitations': invitations.where((i) => i.status == InvitationStatus.expired).length,
      'averageRating': workers.isNotEmpty ? workers.map((w) => w.rating).reduce((a, b) => a + b) / workers.length : 0.0,
      'totalPoolsAssigned': workers.fold(0, (sum, w) => sum + w.poolsAssigned),
    };
  }
} 