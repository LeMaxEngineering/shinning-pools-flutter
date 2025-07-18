import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AppInfoService {
  static final AppInfoService _instance = AppInfoService._internal();
  factory AppInfoService() => _instance;
  AppInfoService._internal();

  // App Information
  static const String appName = 'Shinning Pools';
  static const String companyName = 'Lemax Engineering LLC';
  static const String companyPhone = '+1 561 506 9714';
  static const String companyEmail = 'info@lemaxengineering.com';
  static const String appVersion = '0.1 Beta';
  static const String lastUpdate = 'December 2024';
  
  // Documentation URLs
  static const String userManualUrl = 'https://docs.shinningpools.com/user-manual.pdf';
  static const String quickStartUrl = 'https://docs.shinningpools.com/quick-start.pdf';
  static const String troubleshootingUrl = 'https://docs.shinningpools.com/troubleshooting.pdf';

  // Welcome message
  static const String welcomeMessage = '''
Welcome to Shinning Pools!

This app helps you manage swimming pool maintenance and services efficiently.

Key Features:
• Pool Management & Maintenance Tracking
• Customer Management
• Worker Assignment & Route Planning
• Real-time Location Services
• Maintenance Reports & Analytics

For support, contact us at $companyPhone or visit our documentation.
  ''';

  // Get package info
  Future<PackageInfo> getPackageInfo() async {
    return await PackageInfo.fromPlatform();
  }

  // Launch URL
  Future<bool> launchUrl(String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri.toString());
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Launch phone number
  Future<bool> launchPhone() async {
    try {
      final uri = Uri.parse('tel:$companyPhone');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri.toString());
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Launch email
  Future<bool> launchEmail() async {
    try {
      final uri = Uri.parse('mailto:$companyEmail?subject=Shinning Pools Support');
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri.toString());
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Check for updates (placeholder for future implementation)
  Future<Map<String, dynamic>> checkForUpdates() async {
    // This would typically call an API to check for updates
    // For now, return current version info
    final packageInfo = await getPackageInfo();
    
    return {
      'currentVersion': packageInfo.version,
      'latestVersion': packageInfo.version,
      'hasUpdate': false,
      'updateUrl': null,
      'releaseNotes': null,
    };
  }
} 