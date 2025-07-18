import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../features/pools/models/pool.dart';
import '../../../core/services/location_service.dart';
import 'package:flutter/foundation.dart';

class RobustPoolMap extends StatefulWidget {
  final List<Pool> pools;
  final double height;
  final bool interactive;
  final void Function(Pool selectedPool)? onPoolSelected;
  final LatLng? userLocation;

  const RobustPoolMap({
    Key? key,
    required this.pools,
    this.height = 200,
    this.interactive = true,
    this.onPoolSelected,
    this.userLocation,
  }) : super(key: key);

  @override
  State<RobustPoolMap> createState() => _RobustPoolMapState();
}

class _RobustPoolMapState extends State<RobustPoolMap> {
  GoogleMapController? _mapController;
  static const LatLng _defaultLocation = LatLng(34.0522, -118.2437); // Los Angeles
  final LocationService _locationService = LocationService();

  BitmapDescriptor? _userMarkerIcon;

  @override
  void initState() {
    super.initState();
    _loadUserMarkerIcon();
    _getCurrentLocation();
  }

  Future<void> _loadUserMarkerIcon() async {
    final icon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(),
      'assets/img/user_marker.png',
    );
    if (mounted) {
      setState(() {
        _userMarkerIcon = icon;
      });
    }
  }

  @override
  void dispose() {
    // Only dispose the controller if not on web
    if (!kIsWeb) {
      _mapController?.dispose();
    }
    super.dispose();
  }

  Set<Marker> _buildMarkers() {
    final poolMarkers = widget.pools
        .where((pool) => pool.latitude != null && pool.longitude != null)
        .map((pool) => Marker(
              markerId: MarkerId(pool.id),
              position: LatLng(pool.latitude!, pool.longitude!),
              infoWindow: InfoWindow(
                title: pool.name,
                snippet: (pool.address?.isNotEmpty ?? false) ? pool.address : 'No address',
                onTap: () {
                  if (widget.onPoolSelected != null) {
                    widget.onPoolSelected!(pool);
                  }
                },
              ),
              icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
              onTap: () {
                if (widget.onPoolSelected != null) {
                  widget.onPoolSelected!(pool);
                }
              },
            ))
        .toSet();
    
    // Add user location marker if available
    final userLocation = widget.userLocation ?? _locationService.getCurrentLatLng();
    if (userLocation != null && _userMarkerIcon != null) {
      poolMarkers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: userLocation,
          icon: _userMarkerIcon!,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }
    return poolMarkers;
  }

  Future<void> _getCurrentLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      
      if (position != null && mounted && _mapController != null) {
        // Update the map to center on user location if no userLocation is provided
        if (widget.userLocation == null) {
          _mapController?.animateCamera(
            CameraUpdate.newLatLngZoom(
              LatLng(position.latitude, position.longitude),
              14.0,
            ),
          );
        }
      }
    } catch (e) {
    }
  }

  LatLng _getInitialCameraTarget() {
    // Try to get current location for initial position
    final currentPosition = _locationService.currentPosition;
    if (currentPosition != null) {
      return LatLng(currentPosition.latitude, currentPosition.longitude);
    }
    
    if (widget.userLocation != null) {
      return widget.userLocation!;
    }
    if (widget.pools.isNotEmpty &&
        widget.pools.first.latitude != null &&
        widget.pools.first.longitude != null) {
      return LatLng(widget.pools.first.latitude!, widget.pools.first.longitude!);
    }
    return _defaultLocation;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.pools.isEmpty) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Text('No pools to display on the map'),
        ),
      );
    }

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GoogleMap(
          onMapCreated: (controller) {
            _mapController = controller;
            // Center on user location after map is created
            _getCurrentLocation();
          },
          initialCameraPosition: CameraPosition(
            target: _getInitialCameraTarget(),
            zoom: 12.0,
          ),
          markers: _buildMarkers(),
          zoomControlsEnabled: widget.interactive,
          scrollGesturesEnabled: widget.interactive,
          zoomGesturesEnabled: widget.interactive,
          tiltGesturesEnabled: widget.interactive,
          rotateGesturesEnabled: widget.interactive,
          myLocationButtonEnabled: false,
          mapToolbarEnabled: widget.interactive,
        ),
      ),
    );
  }
} 