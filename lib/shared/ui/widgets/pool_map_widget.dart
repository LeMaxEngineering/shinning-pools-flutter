import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../../../features/pools/models/pool.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/location_service.dart';

class PoolMapWidget extends StatefulWidget {
  final List<Pool> pools;
  final double height;
  final bool interactive;
  final void Function(Pool selectedPool)? onPoolSelected;

  const PoolMapWidget({
    Key? key,
    required this.pools,
    this.height = 300,
    this.interactive = true,
    this.onPoolSelected,
  }) : super(key: key);

  @override
  State<PoolMapWidget> createState() => _PoolMapWidgetState();
}

class _PoolMapWidgetState extends State<PoolMapWidget> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  final GeocodingService _geocodingService = GeocodingService();
  final LocationService _locationService = LocationService();
  
  LatLng? _userLocation;
  bool _locationPermissionGranted = false;
  BitmapDescriptor? _userFlagIcon;
  
  // Default location (Florida area) - fallback if location not available
  static const LatLng _defaultLocation = LatLng(26.7153, -80.0534);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);
    await _loadUserFlagIcon();
    await _getCurrentLocation();
    await _buildMarkers();
    setState(() => _isLoading = false);
  }

  Future<void> _loadUserFlagIcon() async {
    try {
      // Try to load a proper flag icon first
      _userFlagIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/img/user_marker.png',
      );
      print('✅ User flag icon loaded successfully from user_marker.png');
    } catch (e) {
      print('⚠️ Could not load user_marker.png, trying green.png: $e');
      try {
        _userFlagIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(48, 48)),
          'assets/img/green.png',
        );
        print('✅ User flag icon loaded successfully from green.png');
      } catch (e2) {
        print('⚠️ Could not load any flag icon, creating custom flag: $e2');
        _userFlagIcon = await _createCustomFlagIcon();
      }
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

  Future<void> _getCurrentLocation() async {
    try {
      print('🔍 Requesting current location...');
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final newLocation = LatLng(position.latitude, position.longitude);
        print('✅ User location obtained: ${position.latitude}, ${position.longitude}');
        
        setState(() {
          _userLocation = newLocation;
          _locationPermissionGranted = true;
        });
        
        // If map controller is ready, center on user location
        if (_mapController != null) {
          print('🗺️ Centering map on user location...');
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(newLocation, 14.0),
          );
          print('✅ Map centered on user location');
        } else {
          print('⚠️ Map controller not ready yet, will center when created');
        }
      } else {
        print('⚠️ Could not get user location - using mock location for testing');
        // Use a mock location for testing purposes
        final mockLocation = const LatLng(25.7617, -80.1918); // Miami, FL
        setState(() {
          _userLocation = mockLocation;
          _locationPermissionGranted = true;
        });
        print('📍 Using mock location: ${mockLocation.latitude}, ${mockLocation.longitude}');
        
        // If map controller is ready, center on mock location
        if (_mapController != null) {
          print('🗺️ Centering map on mock location...');
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(mockLocation, 14.0),
          );
          print('✅ Map centered on mock location');
        }
      }
    } catch (e) {
      print('❌ Error getting user location: $e - using mock location');
      // Use a mock location for testing purposes
      final mockLocation = const LatLng(25.7617, -80.1918); // Miami, FL
      setState(() {
        _userLocation = mockLocation;
        _locationPermissionGranted = true;
      });
      print('📍 Using mock location: ${mockLocation.latitude}, ${mockLocation.longitude}');
      
      // If map controller is ready, center on mock location
      if (_mapController != null) {
        print('🗺️ Centering map on mock location...');
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(mockLocation, 14.0),
        );
        print('✅ Map centered on mock location');
      }
    }
  }

  Future<void> _buildMarkers() async {
    final markers = <Marker>{};

    for (final pool in widget.pools) {
      LatLng? position;
      
      // Try to use existing coordinates first
      if (pool.latitude != null && pool.longitude != null) {
        position = LatLng(pool.latitude!, pool.longitude!);
        print('✅ Using existing coordinates for ${pool.name}: ${position.latitude}, ${position.longitude}');
      } 
      // If no coordinates, geocode the address
      else if (pool.address.isNotEmpty && pool.address != 'No address') {
        try {
          final geocodeResult = await _geocodingService.geocodeAddress(pool.address);
          if (geocodeResult != null) {
            position = geocodeResult.coordinates;
            print('✅ Geocoded address for ${pool.name}: ${pool.address} -> ${position.latitude}, ${position.longitude}');
          } else {
            print('⚠️ Failed to geocode address for ${pool.name}: ${pool.address}');
          }
        } catch (e) {
          print('❌ Error geocoding address for ${pool.name}: $e');
        }
      } else {
        print('⚠️ No address available for ${pool.name}');
      }

      if (position != null) {
        markers.add(Marker(
          markerId: MarkerId(pool.id),
          position: position,
          infoWindow: InfoWindow(
            title: pool.name,
            snippet: pool.address,
            onTap: () => widget.onPoolSelected?.call(pool),
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
          onTap: () => widget.onPoolSelected?.call(pool),
        ));
      }
    }

    // Add user location marker if available
    if (_userLocation != null) {
      final markerIcon = _userFlagIcon ?? BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      markers.add(Marker(
        markerId: const MarkerId('user_location'),
        position: _userLocation!,
        icon: markerIcon,
        infoWindow: const InfoWindow(
          title: 'Your Location',
          snippet: 'Current device position',
        ),
      ));
      print('📍 User location marker added at: ${_userLocation!.latitude}, ${_userLocation!.longitude}');
      print('📍 Using icon: ${_userFlagIcon != null ? "green flag" : "default green marker"}');
    } else {
      print('⚠️ No user location available for marker');
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
      _fitBoundsToMarkers();
    }
  }

  void _fitBoundsToMarkers() {
    if (_markers.isEmpty || _mapController == null) return;

    try {
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;

      // Include user location in bounds if available
      if (_userLocation != null) {
        minLat = min(minLat, _userLocation!.latitude);
        maxLat = max(maxLat, _userLocation!.latitude);
        minLng = min(minLng, _userLocation!.longitude);
        maxLng = max(maxLng, _userLocation!.longitude);
      }

      for (final marker in _markers) {
        minLat = min(minLat, marker.position.latitude);
        maxLat = max(maxLat, marker.position.latitude);
        minLng = min(minLng, marker.position.longitude);
        maxLng = max(maxLng, marker.position.longitude);
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      _mapController!.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } catch (e) {
      print('❌ Error fitting bounds: $e');
    }
  }

  LatLng _getInitialCameraTarget() {
    // Priority: User location > First pool > Default location
    if (_userLocation != null) {
      print('🎯 Using user location as initial target: ${_userLocation!.latitude}, ${_userLocation!.longitude}');
      return _userLocation!;
    }
    if (_markers.isNotEmpty) {
      print('🎯 Using first pool as initial target');
      return _markers.first.position;
    }
    print('🎯 Using default location as initial target');
    return _defaultLocation;
  }

  Future<void> _refreshLocationAndCenter() async {
    print('🔄 Refreshing location and centering map...');
    setState(() => _isLoading = true);
    
    await _getCurrentLocation();
    
    if (_userLocation != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(_userLocation!, 14.0),
      );
      print('✅ Map refreshed and centered on user location');
    }
    
    setState(() => _isLoading = false);
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
          child: Text('No pools to display'),
        ),
      );
    }

    return Stack(
      children: [
        Container(
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
                      print('🗺️ Map controller created');
                      _mapController = controller;
                      
                      // If we have user location, center on it immediately
                      if (_userLocation != null) {
                        print('📍 Centering map on user location: ${_userLocation!.latitude}, ${_userLocation!.longitude}');
                        controller.animateCamera(
                          CameraUpdate.newLatLngZoom(_userLocation!, 14.0),
                        );
                      } else if (_markers.isNotEmpty) {
                        print('📍 Fitting bounds to markers');
                        _fitBoundsToMarkers();
                      }
                    },
                    initialCameraPosition: CameraPosition(
                      target: _getInitialCameraTarget(),
                      zoom: _userLocation != null ? 14.0 : 12.0,
                    ),
                    markers: _markers,
                    zoomControlsEnabled: widget.interactive,
                    scrollGesturesEnabled: widget.interactive,
                    tiltGesturesEnabled: widget.interactive,
                    rotateGesturesEnabled: widget.interactive,
                    myLocationButtonEnabled: _locationPermissionGranted,
                    myLocationEnabled: _locationPermissionGranted,
                    mapToolbarEnabled: widget.interactive,
                  ),
          ),
        ),
        // Location refresh button
        if (widget.interactive)
          Positioned(
            top: 16,
            right: 16,
            child: FloatingActionButton.small(
              onPressed: _refreshLocationAndCenter,
              backgroundColor: Colors.white,
              foregroundColor: Colors.blue,
              child: const Icon(Icons.my_location),
            ),
          ),
      ],
    );
  }
} 