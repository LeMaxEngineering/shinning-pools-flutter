import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../features/pools/models/pool.dart';
import '../../../core/services/location_service.dart';
import 'package:flutter/foundation.dart';
import '../../../core/services/geocoding_service.dart';

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
  final GeocodingService _geocodingService = GeocodingService();
  Set<Marker> _markers = {};
  bool _isLoading = true;
  final LocationService _locationService = LocationService();

  BitmapDescriptor? _userMarkerIcon;

  @override
  void initState() {
    super.initState();
    _loadUserMarkerIcon();
    _geocodeAndBuildMarkers();
    _loadUserLocationIfNeeded(); // Automatically load user location if not provided
  }

  Future<void> _geocodeAndBuildMarkers() async {
    setState(() => _isLoading = true);
    final poolMarkers = <Marker>{};

    for (final pool in widget.pools) {
      LatLng? position;
      if (pool.latitude != null && pool.longitude != null) {
        position = LatLng(pool.latitude!, pool.longitude!);
      } else if (pool.address?.isNotEmpty == true && pool.address != 'No address') {
        try {
          final geocodeResult = await _geocodingService.geocodeAddress(pool.address!);
          if (geocodeResult != null) {
            position = geocodeResult.coordinates;
          } else {
            print('⚠️ Geocoding failed for address: ${pool.address}');
          }
        } catch (e) {
          print('❌ Error geocoding address "${pool.address}": $e');
        }
      }

      if (position != null) {
        poolMarkers.add(Marker(
          markerId: MarkerId(pool.id),
          position: position,
          infoWindow: InfoWindow(
            title: pool.name,
            snippet: pool.address ?? 'No address',
            onTap: () => widget.onPoolSelected?.call(pool),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          onTap: () => widget.onPoolSelected?.call(pool),
        ));
      } else {
        print('⚠️ Could not determine position for pool ${pool.id}');
      }
    }
    
    // Add user location marker if available
    if (widget.userLocation != null && _userMarkerIcon != null) {
      poolMarkers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: widget.userLocation!,
          icon: _userMarkerIcon!,
          infoWindow: const InfoWindow(title: 'Your Location'),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = poolMarkers;
        _isLoading = false;
      });
      _fitBoundsToMarkers();
    }
  }

  Future<void> _loadUserMarkerIcon() async {
    try {
      // Try to load a proper flag icon first
      _userMarkerIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/img/user_marker.png',
      );
      print('✅ User flag icon loaded successfully from user_marker.png');
    } catch (e) {
      print('⚠️ Could not load user_marker.png, trying green.png: $e');
      try {
        _userMarkerIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(48, 48)),
          'assets/img/green.png',
        );
        print('✅ User flag icon loaded successfully from green.png');
      } catch (e2) {
        print('⚠️ Could not load any flag icon, creating custom flag: $e2');
        _userMarkerIcon = await _createCustomFlagIcon();
      }
    }
    
    if (mounted) {
      setState(() {});
    }
  }

  Future<BitmapDescriptor> _createCustomFlagIcon() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = Size(48, 48);
      
      // Create a flag icon
      final paint = Paint()
        ..color = Colors.green
        ..style = PaintingStyle.fill;
      
      // Draw flag pole (vertical line)
      canvas.drawRect(
        Rect.fromLTWH(22, 8, 4, 32),
        Paint()..color = Colors.brown,
      );
      
      // Draw flag (triangle)
      final path = Path();
      path.moveTo(26, 12);
      path.lineTo(40, 16);
      path.lineTo(26, 20);
      path.close();
      canvas.drawPath(path, paint);
      
      // Draw flag base (circle)
      canvas.drawCircle(
        const Offset(24, 42),
        6,
        Paint()..color = Colors.green,
      );
      
      final picture = recorder.endRecording();
      final image = await picture.toImage(48, 48);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      
      print('✅ Custom flag icon created successfully');
      return BitmapDescriptor.fromBytes(bytes);
    } catch (e) {
      print('❌ Error creating custom flag icon: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
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

  Future<void> _fitBoundsToMarkers() async {
    // Wait for the controller to be available
    if (_mapController == null || _markers.isEmpty) {
      return;
    }

    // Small delay to ensure the map has rendered
    await Future.delayed(const Duration(milliseconds: 100));

    if (_markers.length == 1) {
      // If only one marker, just zoom in on it
      _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_markers.first.position, 15.0),
      );
    } else {
      // If multiple markers, calculate bounds and animate
      LatLngBounds bounds = _getBoundsForMarkers(_markers);
      _mapController!.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 50.0), // 50px padding
      );
    }
  }

  LatLngBounds _getBoundsForMarkers(Set<Marker> markers) {
    double minLat = markers.first.position.latitude;
    double maxLat = markers.first.position.latitude;
    double minLng = markers.first.position.longitude;
    double maxLng = markers.first.position.longitude;

    for (final marker in markers) {
      minLat = marker.position.latitude < minLat ? marker.position.latitude : minLat;
      maxLat = marker.position.latitude > maxLat ? marker.position.latitude : maxLat;
      minLng = marker.position.longitude < minLng ? marker.position.longitude : minLng;
      maxLng = marker.position.longitude > maxLng ? marker.position.longitude : maxLng;
    }
    return LatLngBounds(
      southwest: LatLng(minLat, minLng),
      northeast: LatLng(maxLat, maxLng),
    );
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

  Future<void> _loadUserLocationIfNeeded() async {
    // Only load user location if not provided by parent widget
    if (widget.userLocation == null) {
      try {
        print('📍 Automatically loading user location for RobustPoolMap...');
        final position = await _locationService.getCurrentPosition();
        if (position != null && _userMarkerIcon != null) {
          final userLatLng = LatLng(position.latitude, position.longitude);
          print('✅ User position obtained: ${position.latitude}, ${position.longitude}');
          
          setState(() {
            _markers.add(
              Marker(
                markerId: const MarkerId('user_location'),
                position: userLatLng,
                icon: _userMarkerIcon!,
                infoWindow: const InfoWindow(title: 'Your Location'),
              ),
            );
          });
          print('✅ User location marker automatically added to RobustPoolMap');
        } else {
          print('⚠️ Could not get user position or marker icon not ready');
        }
      } catch (e) {
        print('❌ Error getting user location automatically: $e');
      }
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
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : GoogleMap(
                onMapCreated: (controller) {
                  _mapController = controller;
                  _fitBoundsToMarkers();
                },
                initialCameraPosition: CameraPosition(
                  target: _getInitialCameraTarget(),
                  zoom: 12.0,
                ),
                markers: _markers,
                zoomControlsEnabled: widget.interactive,
                scrollGesturesEnabled: widget.interactive,
                tiltGesturesEnabled: widget.interactive,
                rotateGesturesEnabled: widget.interactive,
                myLocationButtonEnabled: false,
                mapToolbarEnabled: widget.interactive,
              ),
      ),
    );
  }
} 