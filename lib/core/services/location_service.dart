import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geocoding/geocoding.dart';

class LocationService {
  static final LocationService _instance = LocationService._internal();
  factory LocationService() => _instance;
  LocationService._internal();

  Position? _currentPosition;
  bool _isLocationEnabled = false;
  bool _hasLocationPermission = false;

  Position? get currentPosition => _currentPosition;
  bool get isLocationEnabled => _isLocationEnabled;
  bool get hasLocationPermission => _hasLocationPermission;

  /// Request location permission and get current position
  Future<Position?> requestLocationPermission() async {
    try {
      // Check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        _isLocationEnabled = false;
        return null;
      }
      _isLocationEnabled = true;

      // Check location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          _hasLocationPermission = false;
          return null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        _hasLocationPermission = false;
        return null;
      }

      _hasLocationPermission = true;

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

      _currentPosition = position;
      return position;
    } catch (e) {
      debugPrint('LocationService: Error getting location: $e');
      return null;
    }
  }

  /// Get current position without requesting permission (if already granted)
  Future<Position?> getCurrentPosition() async {
    debugPrint('LocationService: getCurrentPosition called, hasPermission: $_hasLocationPermission');
    
    if (!_hasLocationPermission) {
      debugPrint('LocationService: No permission, requesting...');
      return await requestLocationPermission();
    }

    try {
      debugPrint('LocationService: Getting current position...');
      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );
      _currentPosition = position;
      debugPrint('LocationService: Position obtained: ${position.latitude}, ${position.longitude}');
      return position;
    } catch (e) {
      debugPrint('LocationService: Error getting current position: $e');
      return null;
    }
  }

  /// Convert Position to LatLng for Google Maps
  LatLng? getCurrentLatLng() {
    if (_currentPosition != null) {
      return LatLng(_currentPosition!.latitude, _currentPosition!.longitude);
    }
    return null;
  }

  /// Check if location services are enabled
  Future<bool> isLocationServiceEnabled() async {
    bool enabled = await Geolocator.isLocationServiceEnabled();
    _isLocationEnabled = enabled;
    return enabled;
  }

  /// Check current permission status
  Future<LocationPermission> checkPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    _hasLocationPermission = permission == LocationPermission.whileInUse || 
                            permission == LocationPermission.always;
    return permission;
  }

  /// Calculate distance between two points in kilometers
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    return Geolocator.distanceBetween(lat1, lon1, lat2, lon2) / 1000; // Convert to km
  }

  /// Get formatted address from coordinates (reverse geocoding)
  Future<String?> getAddressFromCoordinates(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        return '${place.street}, ${place.locality}, ${place.administrativeArea}';
      }
      return null;
    } catch (e) {
      debugPrint('LocationService: Error reverse geocoding: $e');
      return null;
    }
  }

  /// Clear cached position
  void clearPosition() {
    _currentPosition = null;
  }
} 