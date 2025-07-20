import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shinning_pools_flutter/core/models/geocoding_result.dart';

class GeocodingService {
  FirebaseFunctions? _functions;
  bool _initialized = false;

  Future<void> _initialize() async {
    if (_initialized) return;
    
    try {
      _functions = FirebaseFunctions.instance;
      _initialized = true;
      print('GeocodingService: Firebase Functions initialized successfully');
    } catch (e) {
      print('GeocodingService: Failed to initialize Firebase Functions: $e');
      _functions = null;
      _initialized = true;
    }
  }

  /// Geocode an address using Firebase Cloud Functions
  /// Returns a GeocodingResult object with both coordinates and the formatted address.
  Future<GeocodingResult?> geocodeAddress(String address) async {
    try {
      if (address.trim().isEmpty) {
        print('GeocodingService: Empty address provided');
        return null;
      }

      await _initialize();
      
      if (_functions == null) {
        print('GeocodingService: Firebase Functions not available');
        return null;
      }

      print('GeocodingService: Geocoding address: "$address"');

      final callable = _functions!.httpsCallable('geocodeAddress');
      final result = await callable.call({'address': address.trim()});
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final lat = data['latitude'] as double;
        final lng = data['longitude'] as double;
        final formattedAddress = data['formattedAddress'] as String? ?? address;
        
        print('GeocodingService: Success - $lat, $lng ($formattedAddress)');
        return GeocodingResult(
          coordinates: LatLng(lat, lng),
          formattedAddress: formattedAddress,
        );
      } else {
        print('GeocodingService: Failed - ${data['error'] ?? 'Unknown error'}');
        return null;
      }
    } catch (e) {
      print('GeocodingService: Error - $e');
      return null;
    }
  }

  /// Batch geocode multiple addresses
  Future<Map<String, GeocodingResult?>> geocodeAddresses(List<String> addresses) async {
    final results = <String, GeocodingResult?>{};
    
    for (final address in addresses) {
      results[address] = await geocodeAddress(address);
    }
    
    return results;
  }

  /// Check if geocoding service is available
  Future<bool> isServiceAvailable() async {
    try {
      await _initialize();
      if (_functions == null) return false;
      
      final callable = _functions!.httpsCallable('geocodeAddress');
      await callable.call({'address': 'test'});
      return true;
    } catch (e) {
      print('GeocodingService: Service unavailable - $e');
      return false;
    }
  }
} 