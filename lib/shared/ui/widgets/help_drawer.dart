import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shinning_pools_flutter/core/services/app_info_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';
import 'package:provider/provider.dart';
import 'package:shinning_pools_flutter/core/app.dart' show ThemeModeNotifier;

class HelpDrawer extends StatefulWidget {
  const HelpDrawer({Key? key}) : super(key: key);

  @override
  State<HelpDrawer> createState() => _HelpDrawerState();
}

class _HelpDrawerState extends State<HelpDrawer> {
  final AppInfoService _appInfoService = AppInfoService();
  PackageInfo? _packageInfo;
  bool _isCheckingUpdates = false;
  Map<String, dynamic>? _updateInfo;

  @override
  void initState() {
    super.initState();
    _loadPackageInfo();
  }

  Future<void> _loadPackageInfo() async {
    final packageInfo = await _appInfoService.getPackageInfo();
    if (mounted) {
      setState(() {
        _packageInfo = packageInfo;
      });
    }
  }

  Future<void> _checkForUpdates() async {
    setState(() {
      _isCheckingUpdates = true;
    });

    try {
      final updateInfo = await _appInfoService.checkForUpdates();
      if (mounted) {
        setState(() {
          _updateInfo = updateInfo;
          _isCheckingUpdates = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isCheckingUpdates = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error checking for updates: $e')),
        );
      }
    }
  }

  void _showWelcomeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Welcome to ${AppInfoService.appName}'),
        content: SingleChildScrollView(
          child: Text(AppInfoService.welcomeMessage),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('About ${AppInfoService.appName}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Version: ${_packageInfo?.version ?? AppInfoService.appVersion}'),
              const SizedBox(height: 8),
              Text('Build: ${_packageInfo?.buildNumber ?? '1'}'),
              const SizedBox(height: 8),
              Text('Last Update: ${AppInfoService.lastUpdate}'),
              const SizedBox(height: 16),
              Text('Company: ${AppInfoService.companyName}'),
              const SizedBox(height: 8),
              Text('Phone: ${AppInfoService.companyPhone}'),
              const SizedBox(height: 8),
              Text('Email: ${AppInfoService.companyEmail}'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Drawer(
      elevation: 8,
      child: Container(
        color: theme.colorScheme.surface,
      child: Column(
        children: [
          // Header
          DrawerHeader(
              decoration: const BoxDecoration(
              color: AppColors.primary,
            ),
              child: Row(
                  children: [
                    Container(
                    width: 44,
                    height: 44,
                      decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(10),
                      ),
                      child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                        child: Image.asset(
                          'assets/img/icon.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            AppInfoService.appName,
                            style: AppTextStyles.headline.copyWith(
                            color: theme.colorScheme.onPrimary,
                            fontSize: 18,
                            ),
                          ),
                          Text(
                            'Help & Support',
                          style: AppTextStyles.caption.copyWith(
                            color: theme.colorScheme.onPrimary.withOpacity(0.7),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ),
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                ListTile(
                    leading: const Icon(Icons.home, color: AppColors.primary, size: 22),
                    title: Text('Welcome', style: AppTextStyles.subtitle.copyWith(color: AppColors.primary)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showWelcomeDialog();
                  },
                ),
                ListTile(
                    leading: const Icon(Icons.info, color: AppColors.primary, size: 22),
                    title: Text('About', style: AppTextStyles.subtitle.copyWith(color: AppColors.primary)),
                  onTap: () {
                    Navigator.of(context).pop();
                    _showAboutDialog();
                  },
                ),
                ListTile(
                    leading: const Icon(Icons.system_update, color: AppColors.primary, size: 22),
                    title: Text('Check for Updates', style: AppTextStyles.subtitle.copyWith(color: AppColors.primary)),
                  onTap: _isCheckingUpdates ? null : () {
                    Navigator.of(context).pop();
                    _checkForUpdates();
                  },
                ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                    child: Text('Documentation', style: AppTextStyles.subtitle.copyWith(color: AppColors.primary)),
                ),
                ListTile(
                    leading: const Icon(Icons.book, color: AppColors.primary, size: 22),
                    title: Text('User Manual', style: AppTextStyles.subtitle.copyWith(color: AppColors.primary)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final success = await _appInfoService.launchUrl(AppInfoService.userManualUrl);
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open user manual')),
                      );
                    }
                  },
                ),
                ListTile(
                    leading: const Icon(Icons.rocket_launch, color: AppColors.primary, size: 22),
                    title: Text('Quick Start Guide', style: AppTextStyles.subtitle.copyWith(color: AppColors.primary)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final success = await _appInfoService.launchUrl(AppInfoService.quickStartUrl);
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open quick start guide')),
                      );
                    }
                  },
                ),
                ListTile(
                    leading: const Icon(Icons.build, color: AppColors.primary, size: 22),
                    title: Text('Troubleshooting', style: AppTextStyles.subtitle.copyWith(color: AppColors.primary)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final success = await _appInfoService.launchUrl(AppInfoService.troubleshootingUrl);
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not open troubleshooting guide')),
                      );
                    }
                  },
                ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16, top: 16, bottom: 4),
                    child: Text('Contact', style: AppTextStyles.subtitle.copyWith(color: AppColors.primary)),
                ),
                ListTile(
                    leading: const Icon(Icons.phone, color: AppColors.primary, size: 22),
                    title: Text('Call Support', style: AppTextStyles.subtitle.copyWith(color: AppColors.primary)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final success = await _appInfoService.launchPhone();
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not launch phone app')),
                      );
                    }
                  },
                ),
                ListTile(
                    leading: const Icon(Icons.email, color: AppColors.primary, size: 22),
                    title: Text('Email Support', style: AppTextStyles.subtitle.copyWith(color: AppColors.primary)),
                  onTap: () async {
                    Navigator.of(context).pop();
                    final success = await _appInfoService.launchEmail();
                    if (!success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not launch email app')),
                      );
                    }
                  },
                ),
              ],
            ),
          ),
          // Footer
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
            child: Column(
              children: [
                Text(
                  AppInfoService.companyName,
                    style: AppTextStyles.caption.copyWith(
                      color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Version ${_packageInfo?.version ?? AppInfoService.appVersion}',
                  style: AppTextStyles.caption.copyWith(
                      color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }
}
