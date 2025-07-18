import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../../../core/services/location_service.dart';
import '../theme/colors.dart';
import '../theme/text_styles.dart';

class LocationPermissionWidget extends StatefulWidget {
  final VoidCallback? onLocationGranted;
  final VoidCallback? onLocationDenied;
  final String title;
  final String message;
  final bool showSkipOption;

  const LocationPermissionWidget({
    Key? key,
    this.onLocationGranted,
    this.onLocationDenied,
    this.title = 'Location Access Required',
    this.message = 'This app needs access to your location to show nearby pools and provide better service.',
    this.showSkipOption = false,
  }) : super(key: key);

  @override
  State<LocationPermissionWidget> createState() => _LocationPermissionWidgetState();
}

class _LocationPermissionWidgetState extends State<LocationPermissionWidget> {
  final LocationService _locationService = LocationService();
  bool _isLoading = false;
  bool _hasPermission = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _checkCurrentPermission();
  }

  Future<void> _checkCurrentPermission() async {
    final permission = await _locationService.checkPermission();
    if (mounted) {
      setState(() {
        _hasPermission = permission == LocationPermission.whileInUse || 
                        permission == LocationPermission.always;
      });
    }
  }

  Future<void> _requestLocationPermission() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position = await _locationService.requestLocationPermission();
      
      if (mounted) {
        setState(() {
          _isLoading = false;
          _hasPermission = position != null;
        });

        if (position != null) {
          widget.onLocationGranted?.call();
        } else {
          setState(() {
            _errorMessage = 'Location permission is required for worker functions.';
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Failed to get location: $e';
        });
      }
    }
  }

  Future<void> _openLocationSettings() async {
    try {
      await Geolocator.openLocationSettings();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open location settings: $e')),
        );
      }
    }
  }

  void _skipLocationRequest() {
    widget.onLocationDenied?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Location Icon
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Color.fromRGBO(59, 130, 246, 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.location_on,
                  size: 60,
                  color: AppColors.primary,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                widget.title,
                style: AppTextStyles.headline.copyWith(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Message
              Text(
                widget.message,
                style: AppTextStyles.body.copyWith(
                  fontSize: 16,
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 32),
              
              // Error Message
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(239, 68, 68, 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Color.fromRGBO(239, 68, 68, 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTextStyles.body.copyWith(
                            color: Colors.red[700],
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
              
              // Action Buttons
              if (_hasPermission) ...[
                // Already has permission
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Color.fromRGBO(34, 197, 94, 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Color.fromRGBO(34, 197, 94, 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.check_circle, color: Colors.green, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Location access granted',
                          style: AppTextStyles.body.copyWith(
                            color: Colors.green[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => widget.onLocationGranted?.call(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Continue',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ] else ...[
                // Request permission
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _requestLocationPermission,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Theme.of(context).colorScheme.onPrimary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).colorScheme.onPrimary),
                            ),
                          )
                        : const Text(
                            'Enable Location Access',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Open Settings Button
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: _openLocationSettings,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(color: AppColors.primary),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'Open Settings',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                
                // Skip Option
                if (widget.showSkipOption) ...[
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _skipLocationRequest,
                    child: Text(
                      'Skip for now',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.grey[600],
                        fontSize: 16,
                      ),
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}
