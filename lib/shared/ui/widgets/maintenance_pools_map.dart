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
import '../../../features/pools/models/pool.dart';
import '../../../core/services/pool_repository.dart';
import '../../../core/services/optimized_pool_service.dart';
import '../../../core/services/geocoding_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'dart:math';

class MaintenancePoolsMap extends StatefulWidget {
  final double height;
  final bool interactive;
  final void Function(Pool selectedPool)? onPoolSelected;
  final List<Pool>? pools;
  final String? title;
  final bool showMaintenanceStatus;

  const MaintenancePoolsMap({
    Key? key,
    this.height = 400,
    this.interactive = true,
    this.onPoolSelected,
    this.pools,
    this.title,
    this.showMaintenanceStatus = true,
  }) : super(key: key);

  @override
  State<MaintenancePoolsMap> createState() => _MaintenancePoolsMapState();
}

class _MaintenancePoolsMapState extends State<MaintenancePoolsMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  bool _isLoading = true;
  final LocationService _locationService = LocationService();

  LatLng? _userLocation;
  bool _locationPermissionGranted = false;
  BitmapDescriptor? _userFlagIcon;
  List<Pool> _companyPools = [];
  PoolService? _poolService;
  bool _listenersInitialized = false;
  Map<String, bool> _maintenanceStatuses = {};
  List<Pool> _filteredPools = [];
  bool _showOnlyNearbyPools = true;

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
        print('✅ PoolService listener initialized for maintenance map');
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
      print('🔄 Pools data changed, updating maintenance map...');
      _loadCompanyPools();
    }
  }

  Future<void> _initializeMap() async {
    setState(() => _isLoading = true);
    await _loadUserFlagIcon();
    await _getCurrentLocation();
    await _loadCompanyPools();

    // Load maintenance status before building markers
    if (_companyPools.isNotEmpty && widget.showMaintenanceStatus) {
      final companyId = _getCompanyId();
      print(
        '🔍 Loading maintenance status for ${_companyPools.length} pools in company: $companyId',
      );
      _maintenanceStatuses = await _loadMaintenanceStatusFromDB(
        _companyPools,
        companyId,
      );
      print('📊 Maintenance statuses loaded: $_maintenanceStatuses');
      if (mounted) {
        setState(() {}); // Update state with maintenance statuses
      }
    }

    await _buildMarkers();
    setState(() => _isLoading = false);
    print('✅ Maintenance map initialization complete');
  }

  Future<void> _loadUserFlagIcon() async {
    try {
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
      // Use a more professional green color for maintained pools
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
      canvas.drawCircle(const Offset(24, 42), 6, Paint()..color = Colors.green);

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

  void _showMaintainedPoolMessage(String poolName) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '⚠️ $poolName has been maintained today. Cannot create duplicate maintenance record.',
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 4),
          action: SnackBarAction(
            label: 'OK',
            textColor: Colors.white,
            onPressed: () {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
            },
          ),
        ),
      );
    }
  }

  String _getCompanyId() {
    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      return currentUser?.companyId ?? 'test-company';
    } catch (e) {
      return 'test-company';
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      print('🔍 Requesting current location for maintenance map...');
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final newLocation = LatLng(position.latitude, position.longitude);
        print(
          '✅ User location obtained for maintenance map: ${position.latitude}, ${position.longitude}',
        );

        if (mounted) {
          setState(() {
            _userLocation = newLocation;
            _locationPermissionGranted = true;
          });
        }

        // Filter pools by distance now that we have user location
        if (_showOnlyNearbyPools && _companyPools.isNotEmpty) {
          _filterPoolsByDistance();
        }

        // If map controller is ready, center on user location
        if (_mapController != null) {
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(newLocation, 14.0),
          );
          print('✅ Maintenance map centered on user location');
        } else {
          print('⚠️ Map controller not ready yet, will center when created');
        }
      } else {
        print(
          '⚠️ Could not get user location - using mock location for testing',
        );
        // Use a mock location for testing purposes
        final mockLocation = const LatLng(25.7617, -80.1918); // Miami, FL
        if (mounted) {
          setState(() {
            _userLocation = mockLocation;
            _locationPermissionGranted = true;
          });
        }
        print(
          '📍 Using mock location for maintenance map: ${mockLocation.latitude}, ${mockLocation.longitude}',
        );

        // If map controller is ready, center on mock location
        if (_mapController != null) {
          print('🗺️ Centering maintenance map on mock location...');
          await _mapController!.animateCamera(
            CameraUpdate.newLatLngZoom(mockLocation, 14.0),
          );
          print('✅ Maintenance map centered on mock location');
        }
      }
    } catch (e) {
      print(
        '❌ Error getting user location for maintenance map: $e - using mock location',
      );
      // Use a mock location for testing purposes
      final mockLocation = const LatLng(25.7617, -80.1918); // Miami, FL
      if (mounted) {
        setState(() {
          _userLocation = mockLocation;
          _locationPermissionGranted = true;
        });
      }
      print(
        '📍 Using mock location for maintenance map: ${mockLocation.latitude}, ${mockLocation.longitude}',
      );

      // If map controller is ready, center on mock location
      if (_mapController != null) {
        print('🗺️ Centering maintenance map on mock location...');
        await _mapController!.animateCamera(
          CameraUpdate.newLatLngZoom(mockLocation, 14.0),
        );
        print('✅ Maintenance map centered on mock location');
      }
    }
  }

  Future<void> _loadCompanyPools() async {
    print('🏢 Loading company pools for maintenance map...');

    // Try to get AuthService from context
    String? companyId;

    try {
      final authService = Provider.of<AuthService>(context, listen: false);
      final currentUser = authService.currentUser;
      companyId = currentUser?.companyId;
      print(
        '👤 Current user for maintenance map: ${currentUser?.email} | Role: ${currentUser?.role} | CompanyId: $companyId',
      );
    } catch (e) {
      print('⚠️ AuthService not available, using default company ID');
      companyId = 'test-company';
    }

    List<Pool> pools = [];

    // Use provided pools if available
    if (widget.pools != null && widget.pools!.isNotEmpty) {
      print('📊 Using provided pools: ${widget.pools!.length}');
      pools = widget.pools!;
    }
    // Try to load real pools directly from repository (following route maintenance map pattern)
    else if (companyId != null) {
      try {
        print(
          '🔍 Loading real pools directly from repository for company: $companyId',
        );
        final poolRepository = PoolRepository();
        final querySnapshot = await poolRepository.getCompanyPools(companyId);

        final poolSnapshots = querySnapshot.docs;
        print('📊 Total pools from repository: ${poolSnapshots.length}');

        // Convert to Pool objects following route maintenance map pattern
        pools = poolSnapshots
            .map((snapshot) {
              if (snapshot.data() != null) {
                final data = snapshot.data() as Map<String, dynamic>;
                return Pool(
                  id: snapshot.id,
                  name: data['name'] ?? 'Unknown',
                  address: data['address'] ?? 'No address',
                  latitude: (data['latitude'] ?? data['lat']) as double?,
                  longitude: (data['longitude'] ?? data['lng']) as double?,
                );
              }
              return null;
            })
            .where((pool) => pool != null)
            .cast<Pool>()
            .toList();

        print(
          '✅ Loaded ${pools.length} real pools from repository for company: $companyId',
        );

        // Print pool details for debugging
        for (final pool in pools) {
          print(
            '🏊 Pool: ${pool.name} | Address: ${pool.address} | Coords: ${pool.latitude}, ${pool.longitude}',
          );
        }

        // Get real maintenance status from database
        if (pools.isNotEmpty) {
          _maintenanceStatuses = await _loadMaintenanceStatusFromDB(
            pools,
            companyId,
          );
        }
      } catch (e) {
        print('❌ Error loading real pools from repository: $e');
        pools = [];
      }
    }

    // Fallback to mock data if no real pools available
    if (pools.isEmpty) {
      print('🔄 No real pools available, using mock data for maintenance map');
      pools = _createMockPools(companyId ?? 'test-company');
      print('🎯 Created ${pools.length} mock pools for maintenance testing');
    }

    if (mounted) {
      setState(() {
        _companyPools = pools;
      });
    }

    print('✅ Final pool count for maintenance map: ${pools.length}');

    // Filter pools by distance if user location is available
    if (_userLocation != null && _showOnlyNearbyPools) {
      _filterPoolsByDistance();
    } else {
      _filteredPools = pools;
    }
  }

  Future<Map<String, bool>> _loadMaintenanceStatusFromDB(
    List<Pool> pools,
    String companyId,
  ) async {
    try {
      print(
        '🔍 Loading maintenance status from database for ${pools.length} pools...',
      );

      final poolRepository = PoolRepository();
      final today = DateTime.now();
      final dateString =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';

      // Get pool IDs
      final poolIds = pools.map((pool) => pool.id).toList();

      // Get maintenance status for today
      final maintenanceStatuses = await poolRepository
          .getMaintenanceStatusForPools(
            poolIds,
            dateString,
            companyId: companyId,
          );

      print('📊 Maintenance statuses loaded: $maintenanceStatuses');

      // Update pools with maintenance status
      for (final pool in pools) {
        final isMaintained = maintenanceStatuses[pool.id] ?? false;
        print(
          '🏊 Pool: ${pool.name} | Address: ${pool.address} | DB Status: ${isMaintained ? 'Maintained Today' : 'Needs Maintenance'}',
        );
      }

      return maintenanceStatuses;
    } catch (e) {
      print('❌ Error loading maintenance status from DB: $e');
      // Return empty map (all pools need maintenance)
      return {};
    }
  }

  // Calculate distance between two coordinates using Haversine formula
  double _calculateDistance(LatLng point1, LatLng point2) {
    const double earthRadius = 6371; // Earth's radius in kilometers

    final double lat1Rad = point1.latitude * (pi / 180);
    final double lat2Rad = point2.latitude * (pi / 180);
    final double deltaLatRad = (point2.latitude - point1.latitude) * (pi / 180);
    final double deltaLonRad =
        (point2.longitude - point1.longitude) * (pi / 180);

    final double a =
        sin(deltaLatRad / 2) * sin(deltaLatRad / 2) +
        cos(lat1Rad) *
            cos(lat2Rad) *
            sin(deltaLonRad / 2) *
            sin(deltaLonRad / 2);
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return earthRadius * c; // Distance in kilometers
  }

  // Filter pools to show only the 10 closest to user location
  void _filterPoolsByDistance() {
    if (_userLocation == null || _companyPools.isEmpty) {
      _filteredPools = _companyPools;
      return;
    }

    print(
      '📍 Filtering pools by distance from user location: ${_userLocation!.latitude}, ${_userLocation!.longitude}',
    );

    // Calculate distances for all pools with valid coordinates
    final poolsWithDistance = <MapEntry<Pool, double>>[];

    for (final pool in _companyPools) {
      if (pool.latitude != null && pool.longitude != null) {
        final poolLocation = LatLng(pool.latitude!, pool.longitude!);
        final distance = _calculateDistance(_userLocation!, poolLocation);
        poolsWithDistance.add(MapEntry(pool, distance));
        print(
          '📏 Pool: ${pool.name} | Distance: ${distance.toStringAsFixed(2)} km',
        );
      }
    }

    // Sort by distance and take the 10 closest
    poolsWithDistance.sort((a, b) => a.value.compareTo(b.value));

    final closestPools = poolsWithDistance
        .take(10)
        .map((entry) => entry.key)
        .toList();

    print('✅ Filtered to ${closestPools.length} closest pools:');
    for (int i = 0; i < closestPools.length; i++) {
      final pool = closestPools[i];
      final distance = poolsWithDistance[i].value;
      print('  ${i + 1}. ${pool.name} - ${distance.toStringAsFixed(2)} km');
    }

    if (mounted) {
      setState(() {
        _filteredPools = closestPools;
      });
    }
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
        maintenanceDate = DateTime.fromMillisecondsSinceEpoch(
          int.parse(dateStr),
        );
      }

      if (maintenanceDate != null) {
        final daysSinceMaintenance = DateTime.now()
            .difference(maintenanceDate)
            .inDays;
        // Consider pool maintained if maintenance was done within last 30 days
        return daysSinceMaintenance <= 30;
      }
    } catch (e) {
      print('⚠️ Error parsing maintenance date: $e');
    }

    return false;
  }

  List<Pool> _createMockPools(String companyId) {
    return [
      Pool(
        id: 'pool1',
        name: 'Miami Beach Resort Pool',
        address: '123 Ocean Drive, Miami Beach, FL 33139',
        latitude: 25.7907,
        longitude: -80.1300,
      ),
      Pool(
        id: 'pool2',
        name: 'Downtown Miami Pool',
        address: '456 Brickell Avenue, Miami, FL 33131',
        latitude: 25.7617,
        longitude: -80.1918,
      ),
      Pool(
        id: 'pool3',
        name: 'Coral Gables Pool',
        address: '789 Miracle Mile, Coral Gables, FL 33134',
        latitude: 25.7215,
        longitude: -80.2684,
      ),
      Pool(
        id: 'pool4',
        name: 'Key Biscayne Pool',
        address: '321 Crandon Boulevard, Key Biscayne, FL 33149',
        latitude: 25.6907,
        longitude: -80.1620,
      ),
      Pool(
        id: 'pool5',
        name: 'South Beach Pool',
        address: '654 Collins Avenue, Miami Beach, FL 33139',
        latitude: 25.7825,
        longitude: -80.1340,
      ),
    ];
  }

  Future<void> _buildMarkers() async {
    // Use filtered pools if available, otherwise use all company pools
    final poolsToShow = _filteredPools.isNotEmpty
        ? _filteredPools
        : _companyPools;
    print(
      '🏗️ Building markers for ${poolsToShow.length} pools in maintenance map (${_showOnlyNearbyPools ? 'filtered by distance' : 'all pools'})...',
    );
    final markers = <Marker>{};

    // Load pinpoint icons
    final redPinpointIcon = await _loadRedPinpointIcon();
    final greenPinpointIcon = await _loadGreenPinpointIcon();

    // Initialize geocoding service (following route maintenance map pattern)
    final geocodingService = GeocodingService();

    // Add company pools with appropriate pinpoint colors (following route maintenance map pattern)
    for (final pool in poolsToShow) {
      LatLng? position;
      bool hasCoordinates = false;

      // Always prioritize physical address geocoding over stored coordinates
      if (pool.address.isNotEmpty && pool.address != 'No address') {
        try {
          print('🔍 Geocoding address for ${pool.name}: ${pool.address}');

          // Use the geocoding service (following route maintenance map pattern)
          final geocodeResult = await geocodingService.geocodeAddress(
            pool.address,
          );
          if (geocodeResult != null) {
            position = geocodeResult.coordinates;
            hasCoordinates = true;
            print(
              '✅ Geocoded address for ${pool.name}: ${pool.address} -> ${position.latitude}, ${position.longitude}',
            );
          } else {
            print(
              '⚠️ Failed to geocode address for ${pool.name}: ${pool.address}',
            );
            // Fallback to stored coordinates if geocoding fails
            if (pool.latitude != null && pool.longitude != null) {
              position = LatLng(pool.latitude!, pool.longitude!);
              hasCoordinates = true;
              print(
                '🔄 Using fallback coordinates for ${pool.name}: ${position.latitude}, ${position.longitude}',
              );
            }
          }
        } catch (e) {
          print('❌ Error geocoding address for ${pool.name}: $e');
          // Fallback to stored coordinates if geocoding fails
          if (pool.latitude != null && pool.longitude != null) {
            position = LatLng(pool.latitude!, pool.longitude!);
            hasCoordinates = true;
            print(
              '🔄 Using fallback coordinates for ${pool.name}: ${position.latitude}, ${position.longitude}',
            );
          }
        }
      }
      // Only use stored coordinates if no address is available
      else if (pool.latitude != null && pool.longitude != null) {
        position = LatLng(pool.latitude!, pool.longitude!);
        hasCoordinates = true;
        print(
          '📍 Using stored coordinates for ${pool.name}: ${position.latitude}, ${position.longitude}',
        );
      } else {
        print('⚠️ No address or coordinates available for ${pool.name}');
      }

      if (position != null && hasCoordinates) {
        // Determine icon based on maintenance status (if enabled)
        BitmapDescriptor markerIcon;
        String markerColor;
        String maintenanceStatus;

        if (widget.showMaintenanceStatus) {
          // Use real maintenance status from database
          final isMaintained = _maintenanceStatuses[pool.id] ?? false;
          markerIcon = isMaintained ? greenPinpointIcon : redPinpointIcon;
          markerColor = isMaintained ? 'green' : 'red';
          maintenanceStatus = isMaintained
              ? 'Maintained Today (Not Selectable)'
              : 'Needs Maintenance';
          print(
            '🎨 Pool ${pool.name} (${pool.id}): ${isMaintained ? 'GREEN' : 'RED'} marker - Status: $maintenanceStatus',
          );
        } else {
          // Use default marker for selection without maintenance status
          markerIcon = BitmapDescriptor.defaultMarkerWithHue(
            BitmapDescriptor.hueBlue,
          );
          markerColor = 'blue';
          maintenanceStatus = 'Selectable';
        }

        // Determine if pool is maintained for interaction logic
        final isMaintained = widget.showMaintenanceStatus
            ? (_maintenanceStatuses[pool.id] ?? false)
            : false;

        final marker = Marker(
          markerId: MarkerId(pool.id),
          position: position,
          infoWindow: InfoWindow(
            title: pool.name,
            snippet: '${pool.address} - $maintenanceStatus',
            onTap: isMaintained
                ? null
                : () => widget.onPoolSelected?.call(pool),
          ),
          icon: markerIcon,
          onTap: isMaintained
              ? () => _showMaintainedPoolMessage(pool.name)
              : () => widget.onPoolSelected?.call(pool),
          visible: true,
          zIndex: isMaintained
              ? 0.5
              : 1.0, // Lower z-index for maintained pools
        );
        markers.add(marker);
        print(
          '📍 Added $markerColor pinpoint for ${pool.name} at ${position.latitude}, ${position.longitude}',
        );
        print(
          '📍 Marker ID: ${pool.id}, Status: $maintenanceStatus, Z-Index: 1.0',
        );
      } else {
        print(
          '❌ No valid position available for ${pool.name} - cannot create marker',
        );
      }
    }

    // Add user location marker if available
    if (_userLocation != null) {
      final markerIcon =
          _userFlagIcon ??
          BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen);
      markers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userLocation!,
          icon: markerIcon,
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current device position',
          ),
        ),
      );
      print(
        '📍 User location marker added at: ${_userLocation!.latitude}, ${_userLocation!.longitude}',
      );
      print(
        '📍 Using icon: ${_userFlagIcon != null ? "green flag" : "default green marker"}',
      );
    } else {
      print('⚠️ No user location available for marker');
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });

      print(
        '✅ Created ${markers.length} markers (${_companyPools.length} pools + ${_userLocation != null ? 1 : 0} user location)',
      );
      print('✅ Markers set in state: ${markers.length}');

      // Debug: Print all markers
      for (final marker in markers) {
        print(
          '🗺️ Marker: ${marker.markerId.value} at ${marker.position.latitude}, ${marker.position.longitude}',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: widget.height,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading maintenance map...'),
            ],
          ),
        ),
      );
    }

    final initialTarget = _userLocation ?? _defaultLocation;
    print(
      '🎯 Using ${_userLocation != null ? 'user location' : 'default location'} as initial target: ${initialTarget.latitude}, ${initialTarget.longitude}',
    );

    return Container(
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                _mapController = controller;
                print('🗺️ Map controller created');
                print('🗺️ Current markers count: ${_markers.length}');
                print('🗺️ Markers being passed to GoogleMap:');
                for (final marker in _markers) {
                  print(
                    '  - ${marker.markerId.value}: ${marker.position.latitude}, ${marker.position.longitude}',
                  );
                }

                // Center map on user location or first pool
                if (_userLocation != null) {
                  print(
                    '📍 Centering map on user location: ${_userLocation!.latitude}, ${_userLocation!.longitude}',
                  );
                  controller.animateCamera(
                    CameraUpdate.newLatLngZoom(
                      _userLocation!,
                      14.0,
                    ), // Even closer zoom for detailed view
                  );
                } else if (_companyPools.isNotEmpty) {
                  // Center on first pool with coordinates
                  for (final pool in _companyPools) {
                    if (pool.latitude != null && pool.longitude != null) {
                      final poolLocation = LatLng(
                        pool.latitude!,
                        pool.longitude!,
                      );
                      print(
                        '📍 Centering map on first pool: ${pool.name} at ${poolLocation.latitude}, ${poolLocation.longitude}',
                      );
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(
                          poolLocation,
                          14.0,
                        ), // Even closer zoom for detailed view
                      );
                      break;
                    }
                  }
                }
              },
              initialCameraPosition: CameraPosition(
                target: initialTarget,
                zoom: 13.0, // Closer zoom for detailed view
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              zoomControlsEnabled: true,
              mapToolbarEnabled: false,
              compassEnabled: true,
              onTap: (_) {
                // Clear any selection when tapping on empty map area
              },
            ),
            // Pool count indicator
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
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
                    Icon(Icons.pool, size: 16, color: Colors.blue[700]),
                    const SizedBox(width: 4),
                    Text(
                      '${_filteredPools.isNotEmpty ? _filteredPools.length : _companyPools.length} Pools${_showOnlyNearbyPools && _filteredPools.isNotEmpty ? ' (Nearby)' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Toggle nearby pools button
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(20),
                    onTap: () {
                      if (mounted) {
                        setState(() {
                          _showOnlyNearbyPools = !_showOnlyNearbyPools;
                        });
                      }
                      if (_showOnlyNearbyPools && _userLocation != null) {
                        _filterPoolsByDistance();
                      } else {
                        if (mounted) {
                          setState(() {
                            _filteredPools = _companyPools;
                          });
                        }
                      }
                      _buildMarkers(); // Rebuild markers with new filter
                    },
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _showOnlyNearbyPools
                                ? Icons.location_on
                                : Icons.location_off,
                            size: 16,
                            color: _showOnlyNearbyPools
                                ? Colors.green[700]
                                : Colors.grey[700],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _showOnlyNearbyPools ? 'Nearby' : 'All',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: _showOnlyNearbyPools
                                  ? Colors.green[700]
                                  : Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            // Location refresh button
            Positioned(
              top: 70,
              right: 16,
              child: FloatingActionButton.small(
                onPressed: () async {
                  await _getCurrentLocation();
                  if (_userLocation != null && _mapController != null) {
                    await _mapController!.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        _userLocation!,
                        14.0,
                      ), // Closer zoom for detailed view
                    );
                  }
                },
                backgroundColor: Colors.white,
                foregroundColor: Colors.blue[700],
                child: const Icon(Icons.my_location),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
