import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/location_service.dart';
import '../theme/colors.dart';

class PoolLocationMap extends StatefulWidget {
  final String address;
  final String poolName;
  final double height;
  final bool interactive;

  const PoolLocationMap({
    Key? key,
    required this.address,
    required this.poolName,
    this.height = 200,
    this.interactive = true,
  }) : super(key: key);

  @override
  State<PoolLocationMap> createState() => _PoolLocationMapState();
}

class _PoolLocationMapState extends State<PoolLocationMap> {
  GoogleMapController? _mapController;
  LatLng? _poolLocation;
  bool _isLoading = true;
  String? _error;
  bool _disposed = false;
  bool _mapReady = false;
  
  final GeocodingService _geocodingService = GeocodingService();
  final LocationService _locationService = LocationService();

  // Default location for Connecticut area
  static const LatLng _defaultLocation = LatLng(41.3083, -72.9279); // New Haven, CT

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void dispose() {
    _disposed = true;
    if (_mapReady && _mapController != null) {
      _mapController!.dispose();
    }
    super.dispose();
  }

  Future<void> _initializeMap() async {
    if (_disposed) return;

      setState(() {
        _isLoading = true;
        _error = null;
      });

    // Start with default location to avoid null issues
    _poolLocation = _defaultLocation;

      if (widget.address.trim().isEmpty) {
      if (!_disposed) {
        setState(() {
          _error = 'No address provided';
          _isLoading = false;
        });
      }
        return;
      }

      try {
      final latLng = await _geocodingService.geocodeAddress(widget.address);
      if (latLng != null && !_disposed) {
          setState(() {
          _poolLocation = latLng;
            _isLoading = false;
          });
          return;
      }
    } catch (e) {
    }

    if (!_disposed) {
      setState(() {
        _poolLocation = _defaultLocation;
        _isLoading = false;
        _error = 'Unable to find location for this address. Showing approximate location (demo mode). Please check the address or your API key.';
      });
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    if (!_disposed) {
      _mapController = controller;
      _mapReady = true;
      // Center on user location if pool location is not available
      if (_poolLocation == null || _error != null) {
        _centerOnUserLocation();
      }
    }
  }

  Future<void> _centerOnUserLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (position != null && _mapController != null && !_disposed) {
        _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(
            LatLng(position.latitude, position.longitude),
            14.0,
          ),
        );
      }
    } catch (e) {
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 8),
              Text('Loading map location...'),
            ],
          ),
        ),
      );
    }

    // Always show a map, even if geocoding failed
      return Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: _error != null && _error!.contains('demo mode')
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  )
                : BorderRadius.circular(12),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: _error != null && _error!.contains('demo mode')
                ? const BorderRadius.only(
                    bottomLeft: Radius.circular(12),
                    bottomRight: Radius.circular(12),
                  )
                : BorderRadius.circular(12),
        child: _poolLocation != null
            ? GoogleMap(
              initialCameraPosition: CameraPosition(
                target: _poolLocation!,
                  zoom: _error != null && _error!.contains('demo mode') ? 10.0 : 16.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('pool_location'),
                  position: _poolLocation!,
                  infoWindow: InfoWindow(
                    title: widget.poolName,
                    snippet: _error != null && _error!.contains('demo mode')
                        ? 'Demo location - ${widget.address}'
                        : widget.address,
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    _error != null && _error!.contains('demo mode')
                        ? BitmapDescriptor.hueOrange
                        : BitmapDescriptor.hueBlue,
                  ),
                ),
              },
              zoomControlsEnabled: widget.interactive,
              scrollGesturesEnabled: widget.interactive,
              zoomGesturesEnabled: widget.interactive,
              tiltGesturesEnabled: widget.interactive,
              rotateGesturesEnabled: widget.interactive,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: widget.interactive,
                onMapCreated: _onMapCreated,
              )
            : Container(
                color: Colors.grey[100],
                child: Center(
                  child: Text(_error ?? 'Map not available'),
            ),
          ),
        ),
    );
  }
} 