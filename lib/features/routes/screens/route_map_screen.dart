import 'dart:async';
import 'dart:math';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../core/services/location_service.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/optimized_pool_service.dart';

class RouteMapScreen extends StatefulWidget {
  final Map<String, dynamic> route;

  const RouteMapScreen({Key? key, required this.route}) : super(key: key);

  @override
  State<RouteMapScreen> createState() => _RouteMapScreenState();
}

class _RouteMapScreenState extends State<RouteMapScreen> {
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  final Set<Marker> _markers = {};
  final Set<Polyline> _polylines = {};
  LatLng? _initialPosition;
  LatLng? _userPosition;
  List<Map<String, dynamic>> _routePools = [];
  List<Map<String, dynamic>> _allPools = []; // Track all pools for display
  bool _showAddressPanel = false;
  bool _isOptimizingRoute = false;
  bool _useUserLocation = false;
  String _optimizationStatus = '';
  final LocationService _locationService = LocationService();
  final GeocodingService _geocodingService = GeocodingService();
  final OptimizedPoolService _poolService = OptimizedPoolService();
  BitmapDescriptor _userLocationIcon = BitmapDescriptor.defaultMarker;
  BitmapDescriptor? _greenIcon;
  BitmapDescriptor? _redIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomIcons();
    _loadRouteData();
    _loadUserLocation(); // Automatically load user location
  }

  Future<void> _loadCustomIcons() async {
    try {
      // Try to load a proper flag icon first
      _userLocationIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/img/user_marker.png',
      );
      print('✅ User flag icon loaded successfully from user_marker.png');
    } catch (e) {
      print('⚠️ Could not load user_marker.png, trying green.png: $e');
      try {
        _userLocationIcon = await BitmapDescriptor.fromAssetImage(
          const ImageConfiguration(size: Size(48, 48)),
          'assets/img/green.png',
        );
        print('✅ User flag icon loaded successfully from green.png');
      } catch (e2) {
        print('⚠️ Could not load any flag icon, creating custom flag: $e2');
        _userLocationIcon = await _createCustomFlagIcon();
      }
    }

    // Load green and red icons for pool markers
    try {
      _greenIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/img/green.png',
      );
      print('✅ Green pool icon loaded successfully');
    } catch (e) {
      print('⚠️ Could not load green.png, using default green marker: $e');
      _greenIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );
    }

    try {
      _redIcon = await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/img/red.png',
      );
      print('✅ Red pool icon loaded successfully');
    } catch (e) {
      print('⚠️ Could not load red.png, using default red marker: $e');
      _redIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
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

  Future<void> _loadUserLocation() async {
    try {
      print('📍 Automatically loading user location...');
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final userLatLng = LatLng(position.latitude, position.longitude);
        print(
          '✅ User position obtained: ${position.latitude}, ${position.longitude}',
        );

        setState(() {
          _userPosition = userLatLng;
          _markers.removeWhere((m) => m.markerId.value == 'user_location');
          _markers.add(
            Marker(
              markerId: const MarkerId('user_location'),
              position: userLatLng,
              icon: _userLocationIcon,
              infoWindow: const InfoWindow(title: 'My Location'),
            ),
          );
        });
        print(
          '✅ User location marker automatically added. Total markers: ${_markers.length}',
        );
      } else {
        print('⚠️ Could not get user position automatically');
      }
    } catch (e) {
      print('❌ Error getting user location automatically: $e');
    }
  }

  Future<void> _loadRouteData() async {
    print('🔄 Loading route data for: ${widget.route['routeName']}');

    try {
      final stops = widget.route['stops'] ?? [];
      List<String> poolIds = [];

      if (stops.isNotEmpty && stops.first is String) {
        poolIds = List<String>.from(stops);
      } else if (stops.isNotEmpty && stops.first is Map<String, dynamic>) {
        poolIds = stops
            .map((stop) => stop['poolId'] ?? stop['id'] ?? '')
            .where((id) => id.isNotEmpty)
            .toList();
      }

      if (poolIds.isEmpty) {
        print('⚠️ No pool IDs found in route');
        _setDefaultLocation();
        return;
      }

      print('📍 Fetching ${poolIds.length} pools from Firestore');
      print('📍 Pool IDs: $poolIds');

      final poolsSnapshot = await FirebaseFirestore.instance
          .collection('pools')
          .where(FieldPath.documentId, whereIn: poolIds)
          .get();

      print('📍 Found ${poolsSnapshot.docs.length} pools in database');

      final Map<String, Map<String, dynamic>> poolData = {
        for (var doc in poolsSnapshot.docs) doc.id: doc.data(),
      };

      // Check which pool IDs were not found
      final foundPoolIds = poolData.keys.toList();
      final missingPoolIds = poolIds
          .where((id) => !foundPoolIds.contains(id))
          .toList();

      if (missingPoolIds.isNotEmpty) {
        print('⚠️ Missing pool IDs in database: $missingPoolIds');
        print('⚠️ This might be due to hardcoded pool IDs in the route data');
      }

      if (poolData.isEmpty) {
        print('❌ No pools found in database for the provided IDs');
        _setDefaultLocation();
        return;
      }

      // Get maintenance status for today (use UTC to match Firestore timestamps)
      final today = DateTime.utc(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      print(
        '🔍 Checking maintenance status for date: ${today.toIso8601String().split('T')[0]}',
      );
      print('🔍 Pool IDs to check: $foundPoolIds');
      print('🔍 Using UTC date: ${today.toIso8601String()}');

      // Clear maintenance cache to ensure fresh data
      _poolService.clearMaintenanceCache();

      final maintenanceStatus = await _poolService.getMaintenanceStatusBatch(
        foundPoolIds,
        today,
      );

      print('🔍 Maintenance status for today:');
      for (final entry in maintenanceStatus.entries) {
        print(
          '  - Pool ${entry.key}: ${entry.value ? 'Maintained' : 'Not Maintained'}',
        );
      }

      // Debug: Check if any pools are actually marked as maintained
      final maintainedPools = maintenanceStatus.entries
          .where((e) => e.value)
          .toList();
      print('🔍 Total maintained pools found: ${maintainedPools.length}');
      for (final entry in maintainedPools) {
        print('  ✅ Pool ${entry.key} is maintained');
      }

      // Debug: Check non-maintained pools
      final nonMaintainedPools = maintenanceStatus.entries
          .where((e) => !e.value)
          .toList();
      print(
        '🔍 Total non-maintained pools found: ${nonMaintainedPools.length}',
      );
      for (final entry in nonMaintainedPools) {
        print('  🔄 Pool ${entry.key} is NOT maintained');
      }

      List<Map<String, dynamic>> routePools = [];
      List<Map<String, dynamic>> allPools = []; // Track all pools for display
      List<LatLng> poolPositions = [];
      List<LatLng> maintainedPoolPositions = [];

      // Process only the pools that were found in the database
      for (int i = 0; i < foundPoolIds.length; i++) {
        final poolId = foundPoolIds[i];
        final data = poolData[poolId]!; // Safe to use ! since we know it exists

        final name = data['name'] ?? data['poolName'] ?? 'Pool ${i + 1}';
        final address = data['address'] ?? 'No address available';

        print('📍 Pool $i: $name at address: $address');

        // Always geocode the physical address - no stored coordinates
        double? lat;
        double? lng;

        if (address.isNotEmpty && address != 'No address available') {
          try {
            final geocodingResult = await _geocodingService.geocodeAddress(
              address,
            );
            if (geocodingResult != null) {
              lat = geocodingResult.coordinates.latitude;
              lng = geocodingResult.coordinates.longitude;
              print('✅ Successfully geocoded address: $address -> $lat, $lng');
            } else {
              print('❌ Failed to geocode address: $address');
            }
          } catch (e) {
            print('❌ Error geocoding address: $address - $e');
          }
        }

        if (lat == null || lng == null) {
          print(
            '⚠️ No coordinates available for pool $poolId (address: $address)',
          );
          routePools.add({
            'id': poolId,
            'name': name,
            'address': address,
            'position': null,
            'order': i + 1,
            'hasCoordinates': false,
          });
          continue;
        }

        final position = LatLng(lat, lng);
        final isMaintained = maintenanceStatus[poolId] ?? false;

        print('🔍 Pool $poolId ($name) - Maintenance status: $isMaintained');
        print(
          '🔍 Pool $poolId - Position: ${position.latitude}, ${position.longitude}',
        );
        print(
          '🔍 Pool $poolId - Will create ${isMaintained ? 'GREEN' : 'BLUE'} marker',
        );

        if (isMaintained) {
          // Pool has been maintained today - show as green pinpoint but don't include in route
          print(
            '✅ Pool $poolId ($name) has been maintained today - showing as green pinpoint',
          );
          maintainedPoolPositions.add(position);

          // Add to allPools for display purposes but not to routePools
          allPools.add({
            'id': poolId,
            'name': name,
            'address': address,
            'position': position,
            'order': allPools.length + 1,
            'hasCoordinates': true,
            'isMaintained': true,
          });

          print('🎯 Creating GREEN marker for maintained pool: $poolId');
          final greenMarker = Marker(
            markerId: MarkerId(poolId),
            position: position,
            infoWindow: InfoWindow(
              title: name,
              snippet: '✅ Maintained Today\n📍 $address',
              onTap: () => _showPoolDetails(
                name,
                address,
                allPools.length,
                poolIds.length,
              ),
            ),
            icon:
                _greenIcon ??
                BitmapDescriptor.defaultMarkerWithHue(
                  BitmapDescriptor.hueGreen,
                ),
          );
          _markers.add(greenMarker);
          print('✅ GREEN marker created for pool: $poolId');
          print('✅ GREEN marker icon: ${greenMarker.icon}');
          print('✅ GREEN marker position: ${greenMarker.position}');
        } else {
          // Pool has not been maintained - include in active route
          print(
            '🔄 Pool $poolId ($name) not maintained - including in active route',
          );
          poolPositions.add(position);

          routePools.add({
            'id': poolId,
            'name': name,
            'address': address,
            'position': position,
            'order':
                routePools.length + 1, // Adjust order for active route only
            'hasCoordinates': true,
            'isMaintained': false,
          });

          // Also add to allPools for display purposes
          allPools.add({
            'id': poolId,
            'name': name,
            'address': address,
            'position': position,
            'order': allPools.length + 1,
            'hasCoordinates': true,
            'isMaintained': false,
          });

          print('🎯 Creating BLUE marker for active pool: $poolId');
          _markers.add(
            Marker(
              markerId: MarkerId(poolId),
              position: position,
              infoWindow: InfoWindow(
                title: name,
                snippet:
                    '📍 $address\n🔄 Stop ${routePools.length} of active route',
                onTap: () => _showPoolDetails(
                  name,
                  address,
                  routePools.length,
                  poolPositions.length,
                ),
              ),
              icon:
                  _redIcon ??
                  BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueRed,
                  ),
            ),
          );
          print('✅ BLUE marker created for pool: $poolId');
        }

        if (_initialPosition == null) {
          _initialPosition = position;
        }
      }

      print(
        '✅ Loaded ${routePools.length} active pools, ${poolPositions.length} with coordinates',
      );
      print('✅ Maintained pools today: ${maintainedPoolPositions.length}');
      print('✅ Total markers created: ${_markers.length}');

      // Debug: Show which pools are in the route vs maintained
      print('🔍 Route calculation breakdown:');
      print(
        '  - Pools included in route (non-maintained): ${poolPositions.length}',
      );
      for (int i = 0; i < poolPositions.length; i++) {
        final pool = routePools[i];
        print(
          '    ${i + 1}. ${pool['name']} (${pool['id']}) - ${pool['address']}',
        );
      }
      print(
        '  - Pools excluded from route (maintained): ${maintainedPoolPositions.length}',
      );
      for (int i = 0; i < maintainedPoolPositions.length; i++) {
        final maintainedPool = allPools
            .where((p) => p['isMaintained'] == true)
            .toList()[i];
        print(
          '    ${i + 1}. ${maintainedPool['name']} (${maintainedPool['id']}) - ${maintainedPool['address']}',
        );
      }

      // Debug: Count markers by color - improved logic
      int greenMarkers = 0;
      int blueMarkers = 0;
      int userMarkers = 0;

      print('🔍 Debugging marker count:');
      for (final marker in _markers) {
        print('  - Marker ID: ${marker.markerId.value}');
        print(
          '    Position: ${marker.position.latitude}, ${marker.position.longitude}',
        );

        if (marker.markerId.value == 'user_location') {
          userMarkers++;
          print('    Type: User location marker');
        } else {
          // Check if this is a maintained pool marker by comparing with pool IDs
          final poolId = marker.markerId.value;
          final isMaintained = maintenanceStatus[poolId] ?? false;

          if (isMaintained) {
            greenMarkers++;
            print('    Type: GREEN marker (maintained pool)');
          } else {
            blueMarkers++;
            print('    Type: BLUE marker (active pool)');
          }
        }
      }

      print('✅ User location markers: $userMarkers');
      print('✅ Green markers (maintained): $greenMarkers');
      print('✅ Blue markers (active): $blueMarkers');
      print('✅ Total pool markers: ${greenMarkers + blueMarkers}');

      // Check if we have pools without coordinates
      final poolsWithoutCoordinates = routePools
          .where((pool) => !pool['hasCoordinates'])
          .length;
      if (poolsWithoutCoordinates > 0) {
        print(
          '⚠️ Warning: $poolsWithoutCoordinates pools are missing coordinates and cannot be displayed on the map',
        );
        _showCoordinateWarning(poolsWithoutCoordinates);
      }

      // Create route only with non-maintained pools
      if (poolPositions.length >= 2) {
        await _createInitialRoute(poolPositions);
      } else if (poolPositions.isNotEmpty) {
        _fitMapToBounds(poolPositions);
      } else if (maintainedPoolPositions.isNotEmpty) {
        // Only maintained pools - fit map to show them
        _fitMapToBounds(maintainedPoolPositions);
        _showAllMaintainedMessage();
      } else {
        // No pools with coordinates at all
        print(
          '⚠️ No pools with coordinates found. Cannot display route on map.',
        );
        _showNoCoordinatesWarning();
      }

      _initialPosition ??= const LatLng(26.7153, -80.0534);

      setState(() {
        _routePools =
            routePools; // Keep routePools for optimization (non-maintained only)
        _allPools = allPools; // Store all pools for display purposes
      });
    } catch (e) {
      print('❌ Error loading route data: $e');
      _setDefaultLocation();
    }
  }

  void _setDefaultLocation() {
    setState(() {
      _initialPosition = const LatLng(26.7153, -80.0534);
      _routePools = [];
    });
  }

  Future<void> _createInitialRoute(List<LatLng> poolPositions) async {
    print('🛣️ Calling backend proxy to create initial route...');
    print(
      '🔍 Route calculation - using ${poolPositions.length} non-maintained pools:',
    );
    for (int i = 0; i < poolPositions.length; i++) {
      print(
        '  ${i + 1}. Position: ${poolPositions[i].latitude}, ${poolPositions[i].longitude}',
      );
    }

    if (poolPositions.length < 2) {
      print('⚠️ Not enough points to create a route.');
      return;
    }

    try {
      final origin = {
        'location': {
          'latLng': {
            'latitude': poolPositions.first.latitude,
            'longitude': poolPositions.first.longitude,
          },
        },
      };
      final destination = {
        'location': {
          'latLng': {
            'latitude': poolPositions.last.latitude,
            'longitude': poolPositions.last.longitude,
          },
        },
      };
      List<Map<String, dynamic>> intermediates = [];
      if (poolPositions.length > 2) {
        intermediates = poolPositions
            .sublist(1, poolPositions.length - 1)
            .map(
              (pos) => ({
                'location': {
                  'latLng': {
                    'latitude': pos.latitude,
                    'longitude': pos.longitude,
                  },
                },
              }),
            )
            .toList();
      }

      final response = await http.post(
        Uri.parse('http://localhost:4000/computeRoutes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'origin': origin,
          'destination': destination,
          'intermediates': intermediates,
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE',
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final encodedPolyline =
              data['routes'][0]['polyline']['encodedPolyline'];
          final points = _decodePolyline(encodedPolyline);

          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('initial_route'),
                points: points,
                color: AppColors.primary,
                width: 5,
              ),
            );
          });

          if (points.isNotEmpty) {
            await _fitMapToBounds(points);
          }

          print('✅ Initial route polyline drawn successfully.');
        } else {
          print(
            '⚠️ No routes found in API response. Drawing straight lines as fallback.',
          );
          _drawStraightFallbackRoute(poolPositions);
        }
      } else {
        print(
          '❌ Failed to get initial route from proxy. Status: ${response.statusCode}',
        );
        print('   Response: ${response.body}');
        _drawStraightFallbackRoute(poolPositions);
      }
    } catch (e) {
      print('❌ Error calling backend for initial route: $e');
      _drawStraightFallbackRoute(poolPositions);
    }
  }

  List<LatLng> _decodePolyline(String encoded) {
    final List<List<num>> points = decodePolyline(encoded, accuracyExponent: 5);
    return points
        .map((point) => LatLng(point[0].toDouble(), point[1].toDouble()))
        .toList();
  }

  Future<void> _toggleUserLocation(bool useLocation) async {
    setState(() {
      _useUserLocation = useLocation;
    });

    if (useLocation) {
      try {
        final position = await _locationService.getCurrentPosition();
        if (position != null) {
          final userLatLng = LatLng(position.latitude, position.longitude);
          setState(() {
            _userPosition = userLatLng;
            _markers.removeWhere((m) => m.markerId.value == 'user_location');
            _markers.add(
              Marker(
                markerId: const MarkerId('user_location'),
                position: userLatLng,
                icon: _userLocationIcon,
                infoWindow: const InfoWindow(title: 'My Location'),
              ),
            );
          });
        }
      } catch (e) {
        print('❌ Error getting user location: $e');
      }
    } else {
      setState(() {
        _userPosition = null;
        _markers.removeWhere((m) => m.markerId.value == 'user_location');
      });
    }
  }

  void _drawStraightFallbackRoute(List<LatLng> poolPositions) {
    setState(() {
      _polylines.add(
        Polyline(
          polylineId: const PolylineId('fallback_route'),
          points: poolPositions,
          color: Colors.red.withOpacity(0.7),
          width: 4,
        ),
      );
    });
    print('-- Drawing straight line fallback route --');
  }

  void _optimizeRoute() async {
    setState(() {
      _isOptimizingRoute = true;
      _optimizationStatus = 'Optimizing route...';
      _polylines.clear();
    });

    try {
      List<Map<String, dynamic>> waypoints = _routePools
          .where((pool) => pool['hasCoordinates'] as bool)
          .map(
            (pool) => {
              'location': {
                'latLng': {
                  'latitude': (pool['position'] as LatLng).latitude,
                  'longitude': (pool['position'] as LatLng).longitude,
                },
              },
            },
          )
          .toList();

      if (waypoints.length < 2 &&
          !(_useUserLocation &&
              _userPosition != null &&
              waypoints.isNotEmpty)) {
        _showMessage('Not enough points to optimize.');
        setState(() => _isOptimizingRoute = false);
        return;
      }

      Map<String, dynamic> origin;
      List<Map<String, dynamic>> intermediates;
      Map<String, dynamic> destination;

      if (_useUserLocation && _userPosition != null) {
        origin = {
          'location': {
            'latLng': {
              'latitude': _userPosition!.latitude,
              'longitude': _userPosition!.longitude,
            },
          },
        };
        if (waypoints.isNotEmpty) {
          destination = waypoints.removeLast();
          intermediates = waypoints;
        } else {
          // No pools to visit, so we can't make a route.
          _showMessage('No pools selected for the route.');
          setState(() => _isOptimizingRoute = false);
          return;
        }
      } else {
        if (waypoints.length < 2) {
          _showMessage('Not enough pools to create a route.');
          setState(() => _isOptimizingRoute = false);
          return;
        }
        origin = waypoints.removeAt(0);
        destination = waypoints.removeLast();
        intermediates = waypoints;
      }

      final response = await http.post(
        Uri.parse('http://localhost:4000/computeRoutes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'origin': origin,
          'destination': destination,
          'intermediates': intermediates,
          'travelMode': 'DRIVE',
          'routingPreference': 'TRAFFIC_AWARE',
          'optimizeWaypointOrder': true,
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final encodedPolyline = route['polyline']['encodedPolyline'];
          final points = _decodePolyline(encodedPolyline);
          final optimizedOrder =
              route['optimizedIntermediateWaypointIndex'] ?? [];

          setState(() {
            _polylines.add(
              Polyline(
                polylineId: const PolylineId('optimized_route'),
                points: points,
                color: Colors.green,
                width: 6,
              ),
            );
            _optimizationStatus = 'Route optimized successfully!';
            _updateMarkersWithOptimizedOrder(optimizedOrder);
          });

          List<LatLng> allPoints = List.from(points);
          if (_useUserLocation && _userPosition != null) {
            allPoints.add(_userPosition!);
          }
          await _fitMapToBounds(allPoints);
        } else {
          print('❌ API error: ${data['error'] ?? 'Unknown error'}');
          _showMessage(
            'Could not optimize route: ${data['error']?['message'] ?? 'Unknown API Error'}',
          );
        }
      } else {
        print('❌ HTTP error: ${response.statusCode} - ${response.body}');
        _showMessage(
          'Failed to optimize route. Server returned status ${response.statusCode}',
        );
      }
    } catch (e) {
      print('❌ Error calculating optimized route: $e');
      _showMessage('An error occurred during route optimization.');
    }

    setState(() {
      _isOptimizingRoute = false;
    });
  }

  void _updateMarkersWithOptimizedOrder(List<dynamic> optimizedOrder) {
    List<Map<String, dynamic>> originalPools = List.from(_routePools);
    List<Map<String, dynamic>> reorderedPools = [];
    Set<Marker> newMarkers = {};

    // Only preserve non-maintained pool markers (red pinpoints) - hide maintained ones (green pinpoints)
    for (final marker in _markers) {
      // Keep user location marker
      if (marker.markerId.value == 'user_location') {
        newMarkers.add(marker);
        continue;
      }

      // Check if this marker is for a maintained pool (green pinpoint)
      final isMaintainedPool = _allPools.any(
        (pool) =>
            pool['id'] == marker.markerId.value && pool['isMaintained'] == true,
      );

      // Only keep non-maintained pools (red pinpoints)
      if (!isMaintainedPool) {
        newMarkers.add(marker);
      }
    }

    if (_useUserLocation && _userPosition != null) {
      // Update or add user location marker
      newMarkers.removeWhere((m) => m.markerId.value == 'user_location');
      newMarkers.add(
        Marker(
          markerId: const MarkerId('user_location'),
          position: _userPosition!,
          icon: _userLocationIcon,
          infoWindow: const InfoWindow(title: 'My Location (Start/End)'),
        ),
      );
      reorderedPools.add({
        'name': 'My Location',
        'isUserLocation': true,
        'position': _userPosition,
        'address': 'Current Location',
      });

      List<Map<String, dynamic>> allPools = originalPools
          .where((p) => p['hasCoordinates'] as bool)
          .toList();

      // When using user location, the last pool was removed to be used as destination
      // So we need to add all pools except the last one as intermediates, then add the last one as destination
      if (allPools.isNotEmpty) {
        List<Map<String, dynamic>> intermediatePools = allPools.length > 1
            ? allPools.sublist(0, allPools.length - 1)
            : [];
        Map<String, dynamic> destinationPool = allPools.last;

        // Add intermediate pools in optimized order
        for (var index in optimizedOrder) {
          final intIndex = index as int;
          if (intIndex >= 0 && intIndex < intermediatePools.length) {
            reorderedPools.add(intermediatePools[intIndex]);
          } else {
            print(
              '⚠️ Warning: Optimized order index $intIndex is out of bounds for intermediate pools (length: ${intermediatePools.length})',
            );
          }
        }

        // Add destination pool at the end
        reorderedPools.add(destinationPool);
      }
    } else {
      Map<String, dynamic> startPool = originalPools.firstWhere(
        (p) => p['hasCoordinates'] as bool,
      );
      Map<String, dynamic> endPool = originalPools.lastWhere(
        (p) => p['hasCoordinates'] as bool,
      );
      List<Map<String, dynamic>> intermediatePools = originalPools
          .where(
            (p) =>
                p != startPool && p != endPool && p['hasCoordinates'] as bool,
          )
          .toList();

      reorderedPools.add(startPool);
      for (var index in optimizedOrder) {
        final intIndex = index as int;
        if (intIndex >= 0 && intIndex < intermediatePools.length) {
          reorderedPools.add(intermediatePools[intIndex]);
        } else {
          print(
            '⚠️ Warning: Optimized order index $intIndex is out of bounds for intermediate pools (length: ${intermediatePools.length})',
          );
        }
      }
      reorderedPools.add(endPool);
    }

    // Update info windows only for pools that are part of the optimized route
    for (int i = 0; i < reorderedPools.length; i++) {
      final pool = reorderedPools[i];
      if (pool['isUserLocation'] == true) continue;

      // Find the existing marker for this pool
      final existingMarker = newMarkers.firstWhere(
        (m) => m.markerId.value == pool['id'],
        orElse: () =>
            Marker(markerId: MarkerId('dummy')), // This shouldn't happen
      );

      if (existingMarker.markerId.value != 'dummy') {
        // Remove the old marker and add the updated one
        newMarkers.remove(existingMarker);
        newMarkers.add(
          existingMarker.copyWith(
            infoWindowParam: InfoWindow(
              title: pool['name'],
              snippet: 'Optimized Stop #${i + 1}',
            ),
            iconParam: existingMarker.icon, // Preserve the original color
          ),
        );
      }
    }

    for (int i = 0; i < reorderedPools.length; i++) {
      reorderedPools[i]['order'] = i + 1;
    }

    setState(() {
      _routePools = reorderedPools;
      _markers.clear();
      _markers.addAll(newMarkers);
    });
  }

  Future<void> _fitMapToBounds(List<LatLng> points) async {
    if (points.isEmpty) return;

    try {
      final controller = await _controllerCompleter.future;

      double minLat = points.first.latitude;
      double maxLat = points.first.latitude;
      double minLng = points.first.longitude;
      double maxLng = points.first.longitude;

      for (final point in points) {
        minLat = min(minLat, point.latitude);
        maxLat = max(maxLat, point.latitude);
        minLng = min(minLng, point.longitude);
        maxLng = max(maxLng, point.longitude);
      }

      final bounds = LatLngBounds(
        southwest: LatLng(minLat, minLng),
        northeast: LatLng(maxLat, maxLng),
      );

      await controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 50));
    } catch (e) {
      print('❌ Error fitting map to bounds: $e');
    }
  }

  void _showPoolDetails(String name, String address, int stop, int totalStops) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(name),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Stop $stop of $totalStops', style: AppTextStyles.caption),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Expanded(child: Text('Address:', style: AppTextStyles.caption)),
              ],
            ),
            const SizedBox(height: 4),
            Text(address, style: AppTextStyles.body),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _showCoordinateWarning(int count) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '⚠️ Warning: $count pools are missing coordinates and cannot be displayed on the map',
        ),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showNoCoordinatesWarning() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '⚠️ No pools with coordinates found. Cannot display route on map.',
        ),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showAllMaintainedMessage() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          '✅ All pools in this route have been maintained today!',
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final routeName = widget.route['routeName'] ?? 'Route Map';
    final hasPools = _routePools.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Text(routeName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (hasPools)
            IconButton(
              icon: Icon(_showAddressPanel ? Icons.map : Icons.list),
              onPressed: () {
                setState(() {
                  _showAddressPanel = !_showAddressPanel;
                });
              },
              tooltip: _showAddressPanel
                  ? 'Hide Address List'
                  : 'Show Address List',
            ),
        ],
      ),
      body: Stack(
        children: [
          _buildMap(),
          if (hasPools) _buildOptimizationPanel(),
          if (_showAddressPanel && hasPools) _buildAddressPanel(),
        ],
      ),
    );
  }

  Widget _buildMap() {
    if (_initialPosition == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return GoogleMap(
      initialCameraPosition: CameraPosition(
        target: _initialPosition!,
        zoom: 12,
      ),
      onMapCreated: (controller) {
        if (!_controllerCompleter.isCompleted) {
          _controllerCompleter.complete(controller);
        }
      },
      markers: _markers,
      polylines: _polylines,
      mapType: MapType.normal,
      zoomControlsEnabled: true,
      myLocationButtonEnabled: false,
    );
  }

  Widget _buildOptimizationPanel() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _useUserLocation,
                    onChanged: (value) {
                      if (value != null) {
                        _toggleUserLocation(value);
                      }
                    },
                  ),
                  const Text('Start from my location'),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isOptimizingRoute ? null : _optimizeRoute,
                  icon: const Icon(Icons.route),
                  label: Text(
                    _isOptimizingRoute ? 'Optimizing...' : 'Optimize Route',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
              if (_optimizationStatus.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _optimizationStatus,
                  style: AppTextStyles.caption.copyWith(
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressPanel() {
    if (_allPools.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Card(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 200),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.list, color: AppColors.primary),
                    const SizedBox(width: 8),
                    const Text(
                      'All Pools',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _showAddressPanel = false;
                        });
                      },
                    ),
                  ],
                ),
              ),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _allPools.length,
                  itemBuilder: (context, index) {
                    final pool = _allPools[index];
                    final isMaintained = pool['isMaintained'] == true;

                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: isMaintained
                            ? Colors.green
                            : AppColors.primary,
                        child: Text('${pool['order']}'),
                      ),
                      title: Text(
                        pool['name'],
                        style: TextStyle(
                          color: isMaintained ? Colors.green : null,
                          fontWeight: isMaintained ? FontWeight.bold : null,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(pool['address']),
                          if (isMaintained)
                            const Text(
                              '✅ Maintained Today',
                              style: TextStyle(
                                color: Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                        ],
                      ),
                      onTap: () {
                        if (pool['position'] != null) {
                          _fitMapToBounds([pool['position']]);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
