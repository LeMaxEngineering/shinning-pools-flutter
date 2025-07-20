import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:geocoding/geocoding.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../features/pools/services/pool_service.dart';

class CompanyPoolsMap extends StatefulWidget {
  final double height;
  final bool interactive;
  final void Function(Map<String, dynamic> selectedPool)? onPoolSelected;

  const CompanyPoolsMap({
    Key? key,
    this.height = 400,
    this.interactive = true,
    this.onPoolSelected,
  }) : super(key: key);

  @override
  State<CompanyPoolsMap> createState() => _CompanyPoolsMapState();
}

class _CompanyPoolsMapState extends State<CompanyPoolsMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  final LocationService _locationService = LocationService();
  
  LatLng? _userLocation;
  bool _locationPermissionGranted = false;
  BitmapDescriptor? _userFlagIcon;
  List<Map<String, dynamic>> _companyPools = [];
  PoolService? _poolService;
  bool _listenersInitialized = false;
  
  // Default location (Florida area) - fallback if location not available
  static const LatLng _defaultLocation = LatLng(26.7153, -80.0534);

  @override
  void initState() {
    super.initState();
    _initializeMap();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_listenersInitialized) {
      try {
        _poolService = Provider.of<PoolService>(context, listen: false);
        _poolService?.addListener(_onPoolsChanged);
        setState(() {
          _listenersInitialized = true;
        });
        print('✅ PoolService listener initialized');
        print('📊 PoolService pools count: ${_poolService?.pools.length ?? 0}');
      } catch (e) {
        print('⚠️ PoolService not available in context: $e');
      }
    }
  }

  @override
  void dispose() {
    _poolService?.removeListener(_onPoolsChanged);
    super.dispose();
  }

  void _onPoolsChanged() {
    if (mounted) {
      print('🔄 Pools data changed, updating map...');
      _loadCompanyPools();
    }
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);
    await _loadUserFlagIcon();
    await _getCurrentLocation();
    await _loadCompanyPools();
    await _buildMarkers();
    setState(() => _isLoading = false);
    print('✅ Map initialization complete');
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

  Future<BitmapDescriptor> _loadRedPinpointIcon() async {
    try {
      final redIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/img/red.png',
      );
      print('✅ Red pinpoint icon loaded successfully from red.png');
      return redIcon;
    } catch (e) {
      print('❌ Error loading red.png: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<BitmapDescriptor> _loadGreenPinpointIcon() async {
    try {
      final greenIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/img/green.png',
      );
      print('✅ Green pinpoint icon loaded successfully from green.png');
      return greenIcon;
    } catch (e) {
      print('❌ Error loading green.png: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
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

  Future<void> _loadCompanyPools() async {
    print('🏢 Loading company pools...');
    
    // Try to get AuthService from context
    String? companyId;
    
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      companyId = currentUser?.companyId;
      print('👤 Current user: ${currentUser?.email} | Role: ${currentUser?.role} | CompanyId: $companyId');
    } catch (e) {
      print('⚠️ AuthService not available, using default company ID');
      companyId = 'test-company';
    }
    
    // Wait a bit for PoolService to initialize if needed
    if (_poolService != null && _poolService!.pools.isEmpty) {
      print('⏳ PoolService is empty, waiting for initialization...');
      await Future.delayed(const Duration(milliseconds: 500));
    }
    
    List<Map<String, dynamic>> pools = [];
    
    // Try to load real pools from PoolService
    if (_poolService != null && companyId != null) {
      try {
        print('🔍 Loading real pools from PoolService for company: $companyId');
        pools = _poolService!.pools;
        print('📊 Total pools in PoolService: ${pools.length}');
        
        // Filter pools for the current company
        pools = pools.where((pool) => pool['companyId'] == companyId).toList();
        
        print('✅ Loaded ${pools.length} real pools from PoolService for company: $companyId');
        
        // Add maintenance status based on last maintenance date
        for (final pool in pools) {
          final lastMaintenance = pool['lastMaintenanceDate'];
          final isMaintained = _isPoolMaintained(lastMaintenance);
          pool['isMaintained'] = isMaintained;
          
          print('🏊 Pool: ${pool['name']} | Address: ${pool['address']} | Status: ${isMaintained ? 'Maintained' : 'Needs Maintenance'}');
        }
      } catch (e) {
        print('❌ Error loading real pools: $e');
        pools = [];
      }
    }
    
    // Fallback to mock data if no real pools available
    if (pools.isEmpty) {
      print('🔄 No real pools available, using mock data');
      pools = _createMockPools(companyId ?? 'test-company');
      print('🎯 Created ${pools.length} mock pools for testing');
    }
    
    setState(() {
      _companyPools = pools;
    });
    
    print('✅ Final pool count: ${pools.length}');
  }
  
  bool _isPoolMaintained(dynamic lastMaintenanceDate) {
    if (lastMaintenanceDate == null) return false;
    
    try {
      // If it's a Timestamp, convert to DateTime
      DateTime? maintenanceDate;
      if (lastMaintenanceDate is DateTime) {
        maintenanceDate = lastMaintenanceDate;
      } else if (lastMaintenanceDate.toString().contains('Timestamp')) {
        // Handle Firestore Timestamp
        final timestampStr = lastMaintenanceDate.toString();
        final dateStr = timestampStr.split('(')[1].split(')')[0];
        maintenanceDate = DateTime.fromMillisecondsSinceEpoch(int.parse(dateStr));
      }
      
      if (maintenanceDate != null) {
        final daysSinceMaintenance = DateTime.now().difference(maintenanceDate).inDays;
        // Consider pool maintained if maintenance was done within last 30 days
        return daysSinceMaintenance <= 30;
      }
    } catch (e) {
      print('⚠️ Error parsing maintenance date: $e');
    }
    
    return false;
  }
  
  List<Map<String, dynamic>> _createMockPools(String companyId) {
    return [
      {
        'id': 'pool1',
        'name': 'Miami Beach Resort Pool',
        'address': '123 Ocean Drive, Miami Beach, FL 33139',
        'latitude': 25.7907,
        'longitude': -80.1300,
        'companyId': companyId,
        'status': 'Active',
        'customerName': 'Miami Beach Resort',
        'isMaintained': false, // Red pinpoint - needs maintenance
      },
      {
        'id': 'pool2',
        'name': 'Downtown Miami Pool',
        'address': '456 Brickell Avenue, Miami, FL 33131',
        'latitude': 25.7617,
        'longitude': -80.1918,
        'companyId': companyId,
        'status': 'Active',
        'customerName': 'Downtown Miami Hotel',
        'isMaintained': true, // Green pinpoint - maintained
      },
      {
        'id': 'pool3',
        'name': 'Coral Gables Pool',
        'address': '789 Miracle Mile, Coral Gables, FL 33134',
        'latitude': 25.7215,
        'longitude': -80.2684,
        'companyId': companyId,
        'status': 'Active',
        'customerName': 'Coral Gables Country Club',
        'isMaintained': false, // Red pinpoint - needs maintenance
      },
      {
        'id': 'pool4',
        'name': 'Key Biscayne Pool',
        'address': '321 Crandon Boulevard, Key Biscayne, FL 33149',
        'latitude': 25.6907,
        'longitude': -80.1620,
        'companyId': companyId,
        'status': 'Active',
        'customerName': 'Key Biscayne Resort',
        'isMaintained': true, // Green pinpoint - maintained
      },
      {
        'id': 'pool5',
        'name': 'South Beach Pool',
        'address': '654 Collins Avenue, Miami Beach, FL 33139',
        'latitude': 25.7825,
        'longitude': -80.1340,
        'companyId': companyId,
        'status': 'Active',
        'customerName': 'South Beach Hotel',
        'isMaintained': false, // Red pinpoint - needs maintenance
      },
    ];
  }

  Future<void> _buildMarkers() async {
    print('🏗️ Building markers for ${_companyPools.length} pools...');
    final markers = <Marker>{};
    
    // Load pinpoint icons
    final redPinpointIcon = await _loadRedPinpointIcon();
    final greenPinpointIcon = await _loadGreenPinpointIcon();

    // Add company pools with appropriate pinpoint colors
    for (final pool in _companyPools) {
      LatLng? position;
      
      // Always prioritize physical address geocoding over stored coordinates
      if (pool['address'] != null && pool['address'].toString().isNotEmpty && pool['address'] != 'No address') {
        try {
          print('🔍 Geocoding address for ${pool['name']}: ${pool['address']}');
          
          // Use the geocoding package directly
          final locations = await locationFromAddress(pool['address'].toString());
          if (locations.isNotEmpty) {
            final location = locations.first;
            position = LatLng(location.latitude, location.longitude);
            print('✅ Geocoded address for ${pool['name']}: ${pool['address']} -> ${position.latitude}, ${position.longitude}');
          } else {
            print('⚠️ Failed to geocode address for ${pool['name']}: ${pool['address']}');
            // Fallback to stored coordinates if geocoding fails
            if (pool['latitude'] != null && pool['longitude'] != null) {
              position = LatLng(pool['latitude'] as double, pool['longitude'] as double);
              print('🔄 Using fallback coordinates for ${pool['name']}: ${position.latitude}, ${position.longitude}');
            }
          }
        } catch (e) {
          print('❌ Error geocoding address for ${pool['name']}: $e');
          // Fallback to stored coordinates if geocoding fails
          if (pool['latitude'] != null && pool['longitude'] != null) {
            position = LatLng(pool['latitude'] as double, pool['longitude'] as double);
            print('🔄 Using fallback coordinates for ${pool['name']}: ${position.latitude}, ${position.longitude}');
          }
        }
      } 
      // Only use stored coordinates if no address is available
      else if (pool['latitude'] != null && pool['longitude'] != null) {
        position = LatLng(pool['latitude'] as double, pool['longitude'] as double);
        print('📍 Using stored coordinates for ${pool['name']}: ${position.latitude}, ${position.longitude}');
      } else {
        print('⚠️ No address or coordinates available for ${pool['name']}');
      }

      if (position != null) {
        // Determine icon based on maintenance status
        final isMaintained = pool['isMaintained'] ?? false;
        final markerIcon = isMaintained ? greenPinpointIcon : redPinpointIcon;
        final markerColor = isMaintained ? 'green' : 'red';
        
        final marker = Marker(
          markerId: MarkerId(pool['id']),
          position: position,
          infoWindow: InfoWindow(
            title: pool['name'] ?? 'Unnamed Pool',
            snippet: '${pool['address'] ?? 'No address'} - ${isMaintained ? 'Maintained' : 'Needs Maintenance'}',
            onTap: () => widget.onPoolSelected?.call(pool),
          ),
          icon: markerIcon, // Use appropriate pinpoint icon
          onTap: () => widget.onPoolSelected?.call(pool),
          visible: true, // Ensure marker is visible
          zIndex: 1.0, // Ensure proper z-index
        );
        markers.add(marker);
        print('📍 Added $markerColor pinpoint for ${pool['name']} at ${position.latitude}, ${position.longitude}');
        print('📍 Marker ID: ${pool['id']}, Status: ${isMaintained ? 'Maintained' : 'Needs Maintenance'}, Z-Index: 1.0');
      } else {
        print('❌ No position available for ${pool['name']} - cannot create marker');
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
      print('✅ Created ${markers.length} markers (${markers.length - (_userLocation != null ? 1 : 0)} pools + ${_userLocation != null ? 1 : 0} user location)');
      print('✅ Markers set in state: ${_markers.length}');
      
      // Debug: Print all marker positions
      for (final marker in _markers) {
        print('🗺️ Marker: ${marker.markerId.value} at ${marker.position.latitude}, ${marker.position.longitude}');
      }
      
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
    if (_companyPools.isEmpty && !_isLoading) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Center(
          child: Text('No pools found for this company'),
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
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Loading pools and geocoding addresses...'),
                      ],
                    ),
                  )
                : GoogleMap(
                    onMapCreated: (controller) {
                      print('🗺️ Map controller created');
                      _mapController = controller;
                      print('🗺️ Current markers count: ${_markers.length}');
                      print('🗺️ Markers being passed to GoogleMap:');
                      for (final marker in _markers) {
                        print('  - ${marker.markerId.value}: ${marker.position.latitude}, ${marker.position.longitude}');
                      }
                      
                      // If we have user location, center on it immediately
                      if (_userLocation != null) {
                        print('📍 Centering map on user location: ${_userLocation!.latitude}, ${_userLocation!.longitude}');
                        controller.animateCamera(
                          CameraUpdate.newLatLngZoom(_userLocation!, 14.0),
                        );
                      } else if (_markers.isNotEmpty) {
                        print('📍 Fitting bounds to markers');
                        _fitBoundsToMarkers();
                      } else {
                        print('⚠️ No user location or markers available - using default location');
                        controller.animateCamera(
                          CameraUpdate.newLatLngZoom(_defaultLocation, 12.0),
                        );
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
        // Pool count indicator
        if (_companyPools.isNotEmpty)
          Positioned(
            top: 16,
            left: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${_companyPools.length} Pools',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
} 