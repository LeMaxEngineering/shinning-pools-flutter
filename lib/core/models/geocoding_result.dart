import 'package:google_maps_flutter/google_maps_flutter.dart';

class GeocodingResult {
  final LatLng coordinates;
  final String formattedAddress;

  GeocodingResult({
    required this.coordinates,
    required this.formattedAddress,
  });
} 