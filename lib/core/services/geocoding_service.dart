import 'package:cloud_functions/cloud_functions.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeocodingService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Geocode an address using Firebase Cloud Functions
  /// This avoids CORS issues on web and provides reliable geocoding for all platforms
  Future<LatLng?> geocodeAddress(String address) async {
    try {
      if (address.trim().isEmpty) {
        print('GeocodingService: Empty address provided');
        return null;
      }

      print('GeocodingService: Geocoding address: "$address"');

      final callable = _functions.httpsCallable('geocodeAddress');
      final result = await callable.call({'address': address.trim()});
      
      final data = result.data as Map<String, dynamic>;
      
      if (data['success'] == true) {
        final lat = data['latitude'] as double;
        final lng = data['longitude'] as double;
        final formattedAddress = data['formattedAddress'] as String?;
        
        print('GeocodingService: Success - $lat, $lng (${formattedAddress ?? address})');
        return LatLng(lat, lng);
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
  Future<Map<String, LatLng>> geocodeAddresses(List<String> addresses) async {
    final results = <String, LatLng>{};
    
    for (final address in addresses) {
      final location = await geocodeAddress(address);
      if (location != null) {
        results[address] = location;
      }
    }
    
    return results;
  }

  /// Check if geocoding service is available
  Future<bool> isServiceAvailable() async {
    try {
      final callable = _functions.httpsCallable('geocodeAddress');
      await callable.call({'address': 'test'});
      return true;
    } catch (e) {
      print('GeocodingService: Service unavailable - $e');
      return false;
    }
  }
} 