class MapsConfig {
  // For production, configure API keys using build-time or runtime environment variables.
  // Do NOT hardcode API keys in source code.

  // Example usage (pseudo-code):
  // static String get googleMapsApiKey => const String.fromEnvironment('GOOGLE_MAPS_API_KEY');

  // Web-specific configuration
  // static String get webMapsApiKey => const String.fromEnvironment('GOOGLE_MAPS_WEB_API_KEY');

  static const bool enableMapsInDevelopment = true;
  static const bool showAddressOnMapError = true;
  static const double defaultZoom = 16.0;
  static const double defaultLatitude = 37.7749; // San Francisco default
  static const double defaultLongitude = -122.4194;
} 