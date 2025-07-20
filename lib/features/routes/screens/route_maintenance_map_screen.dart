import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:shinning_pools_flutter/core/services/pool_repository.dart';
import 'package:shinning_pools_flutter/core/services/route_repository.dart';
import 'package:shinning_pools_flutter/core/services/auth_service.dart';
import 'package:shinning_pools_flutter/features/pools/models/pool.dart';
import 'package:shinning_pools_flutter/features/routes/models/route.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math';
import 'package:shinning_pools_flutter/shared/ui/theme/colors.dart';
import 'package:shinning_pools_flutter/shared/ui/theme/text_styles.dart';
import 'package:shinning_pools_flutter/core/services/location_service.dart';
import 'package:google_polyline_algorithm/google_polyline_algorithm.dart';
import 'package:shinning_pools_flutter/core/services/geocoding_service.dart';

class RouteMaintenanceMapScreen extends StatefulWidget {
  final String routeId;

  const RouteMaintenanceMapScreen({Key? key, required this.routeId}) : super(key: key);

  @override
  _RouteMaintenanceMapScreenState createState() => _RouteMaintenanceMapScreenState();
}

class _RouteMaintenanceMapScreenState extends State<RouteMaintenanceMapScreen> {
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  Set<Marker> markers = {};
  Set<Polyline> polylines = {};

  late Future<DocumentSnapshot?> _routeFuture;
  Future<Map<String, bool>>? _maintenanceFuture;
  Future<List<Pool?>>? _poolsFuture;
  List<String>? _poolIds;
  
  // Route optimization variables
  bool _isOptimizingRoute = false;
  String _optimizationStatus = '';
  bool _useUserLocation = false;
  LatLng? _userPosition;
  List<Map<String, dynamic>> _routePools = [];
  bool _showAddressPanel = false;
  final LocationService _locationService = LocationService();
  BitmapDescriptor _userLocationIcon = BitmapDescriptor.defaultMarker;
  LatLng? _initialPosition;
  bool _isLoading = true;
  Map<String, bool> _maintenanceStatuses = {};
  String _routeName = 'Route Maintenance Map';
  final GeocodingService _geocodingService = GeocodingService();

  @override
  void initState() {
    super.initState();
    _loadAllData();
    _loadCustomIcons();
    _loadUserLocation(); // Automatically load user location
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    
    try {
      final routeSnapshot = await Provider.of<RouteRepository>(context, listen: false).getRoute(widget.routeId);
      
      if (routeSnapshot == null || !routeSnapshot.exists) {
        _showMessage('Route not found');
        setState(() => _isLoading = false);
        return;
      }

      final routeData = routeSnapshot.data() as Map<String, dynamic>?;
      if (routeData == null || !routeData.containsKey('stops')) {
        _showMessage('No pool IDs found for this route');
        setState(() => _isLoading = false);
        return;
      }

      if (mounted && routeData.containsKey('routeName') && routeData['routeName'] != null) {
        setState(() {
          _routeName = routeData['routeName'] as String;
        });
      }
      
      final stops = routeData['stops'] as List;
      final poolIds = stops.map((stop) => stop.toString()).toList();
      if (poolIds.isEmpty) {
        _showMessage('No valid pool IDs found');
        setState(() => _isLoading = false);
        return;
      }
      _poolIds = poolIds;

      final poolRepository = Provider.of<PoolRepository>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);
      final companyId = authService.currentUser?.companyId;

      // Fetch all required data in parallel
      final results = await Future.wait([
        poolRepository.getMaintenanceStatusForPools(poolIds, DateFormat('yyyy-MM-dd').format(DateTime.now()), companyId: companyId),
        Future.wait(poolIds.map((id) => poolRepository.getPool(id))),
      ]);

      final maintenanceStatuses = results[0] as Map<String, bool>;
      _maintenanceStatuses = maintenanceStatuses; // Cache the statuses
      final poolSnapshots = results[1] as List<DocumentSnapshot?>;

      final pools = poolSnapshots.map((snapshot) {
        if (snapshot != null && snapshot.data() != null) {
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
      }).toList();

      List<LatLng> poolPositions = [];
      _routePools = [];
      Set<Marker> newMarkers = {};
      LatLng? firstValidPosition;

      for (int i = 0; i < pools.length; i++) {
        final pool = pools[i];
        if (pool == null) continue;

        LatLng? position;
        bool hasCoordinates = false;
        
        if (pool.address.isNotEmpty && pool.address != 'No address') {
          try {
            final geocodeResult = await _geocodingService.geocodeAddress(pool.address);
            if (geocodeResult != null) {
              position = geocodeResult.coordinates;
              hasCoordinates = true;
              print('✅ Geocoded address for pool ${pool.id}: ${pool.address} -> ${position.latitude}, ${position.longitude}');

              if (geocodeResult.formattedAddress.toLowerCase() != pool.address.toLowerCase()) {
                await _promptForAddressCorrection(pool, geocodeResult.formattedAddress, position);
              }
            } else {
              print('⚠️ Failed to geocode address for pool ${pool.id}: ${pool.address}');
            }
          } catch (e) {
            print('❌ Error geocoding address for pool ${pool.id}: $e');
            hasCoordinates = false;
          }
        } else {
          print('⚠️ No valid address for pool ${pool.id}: ${pool.address}');
        }

        _routePools.add({
          'id': pool.id, 'name': pool.name, 'address': pool.address, 
          'position': position, 'order': i + 1, 'hasCoordinates': hasCoordinates,
        });

        if (position != null) {
          poolPositions.add(position);
          if (firstValidPosition == null) firstValidPosition = position;
          
          newMarkers.add(Marker(
            markerId: MarkerId(pool.id),
            position: position,
            icon: BitmapDescriptor.defaultMarkerWithHue(
              (maintenanceStatuses[pool.id] ?? false) ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed,
            ),
            infoWindow: InfoWindow(title: pool.name, snippet: 'Stop ${i + 1}'),
          ));
        }
      }
      
      _initialPosition = firstValidPosition ?? const LatLng(26.7153, -80.0534);
      Set<Polyline> newPolylines = {};
      if (poolPositions.length >= 2) {
        newPolylines = await _createInitialRoute(poolPositions);
      }
      
      if (!mounted) return;
      setState(() {
        markers = newMarkers;
        polylines = newPolylines;
        _isLoading = false;
      });

      if (poolPositions.isNotEmpty) {
        await _fitMapToBounds(poolPositions);
      }
    } catch (e, stackTrace) {
      print('❌ Error loading route data: $e\n$stackTrace');
      _showMessage('Failed to load route data.');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _promptForAddressCorrection(Pool pool, String suggestedAddress, LatLng coordinates) async {
    if (!mounted) return;

    final bool? confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Address'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                const Text('The address provided is slightly different from the one found on the map.'),
                const SizedBox(height: 16),
                Text('Original: ', style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold)),
                Text(pool.address),
                const SizedBox(height: 10),
                Text('Suggested: ', style: AppTextStyles.body2.copyWith(fontWeight: FontWeight.bold, color: AppColors.primary)),
                Text(suggestedAddress),
                const SizedBox(height: 16),
                const Text('Do you want to update to the suggested address? This will permanently update the pool record.'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('No, Keep Original'),
              onPressed: () => Navigator.of(context).pop(false),
            ),
            ElevatedButton(
              child: const Text('Yes, Update'),
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      print('✅ User confirmed address correction for pool ${pool.id}.');
      try {
        final poolRepository = Provider.of<PoolRepository>(context, listen: false);
        await poolRepository.updatePoolAddress(pool.id, suggestedAddress, coordinates.latitude, coordinates.longitude);
        _showMessage('Pool address updated successfully.');
        
        final poolToUpdate = _routePools.firstWhere((p) => p['id'] == pool.id);
        setState(() {
          poolToUpdate['address'] = suggestedAddress;
        });
      } catch (e) {
        print('❌ Failed to update pool address: $e');
        _showMessage('Error updating address. Please try again.');
      }
    } else {
      print('⚠️ User rejected address correction for pool ${pool.id}.');
    }
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

  Future<void> _loadUserLocation() async {
    try {
      print('📍 Automatically loading user location...');
      final position = await _locationService.getCurrentPosition();
      if (position != null) {
        final userLatLng = LatLng(position.latitude, position.longitude);
        print('✅ User position obtained: ${position.latitude}, ${position.longitude}');
        
        Set<Marker> currentMarkers = Set.from(markers);
        currentMarkers.removeWhere((m) => m.markerId.value == 'user_location');
        currentMarkers.add(
          Marker(
            markerId: const MarkerId('user_location'),
            position: userLatLng,
            icon: _userLocationIcon,
            infoWindow: const InfoWindow(title: 'My Location'),
          ),
        );

        if (!mounted) return;
        setState(() {
          _userPosition = userLatLng;
          markers = currentMarkers;
        });
        print('✅ User location marker automatically added. Total markers: ${markers.length}');
      } else {
        print('⚠️ Could not get user position automatically');
      }
    } catch (e) {
      print('❌ Error getting user location automatically: $e');
    }
  }

  Future<Set<Polyline>> _createInitialRoute(List<LatLng> poolPositions) async {
    print('🛣️ Creating initial route for maintenance map...');
    if (poolPositions.length < 2) {
      print('⚠️ Not enough points to create a route.');
      return {};
    }

    try {
      final origin = {
        'location': {
          'latLng': {
            'latitude': poolPositions.first.latitude,
            'longitude': poolPositions.first.longitude,
          }
        }
      };
      final destination = {
        'location': {
          'latLng': {
            'latitude': poolPositions.last.latitude,
            'longitude': poolPositions.last.longitude,
          }
        }
      };
      List<Map<String, dynamic>> intermediates = [];
      if (poolPositions.length > 2) {
        intermediates = poolPositions
            .sublist(1, poolPositions.length - 1)
            .map((pos) => ({
                  'location': {
                    'latLng': {'latitude': pos.latitude, 'longitude': pos.longitude}
                  }
                }))
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
          final encodedPolyline = data['routes'][0]['polyline']['encodedPolyline'];
          final points = _decodePolyline(encodedPolyline);
          print('✅ Initial route polyline processed successfully.');
          return {
            Polyline(
              polylineId: const PolylineId('initial_route'),
              points: points,
              color: AppColors.primary,
              width: 5,
            ),
          };
        } else {
          print('⚠️ No routes found in API response. Drawing straight lines as fallback.');
          return _drawStraightFallbackRoute(poolPositions);
        }
      } else {
        print('❌ Failed to get initial route from proxy. Status: ${response.statusCode}');
        return _drawStraightFallbackRoute(poolPositions);
      }
    } catch (e) {
      print('❌ Error calling backend for initial route: $e');
      return _drawStraightFallbackRoute(poolPositions);
    }
  }

  Set<Polyline> _drawStraightFallbackRoute(List<LatLng> poolPositions) {
    print('-- Drawing straight line fallback route --');
    return {
      Polyline(
        polylineId: const PolylineId('fallback_route'),
        points: poolPositions,
        color: Colors.red.withOpacity(0.7),
        width: 4,
      ),
    };
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

  List<LatLng> _decodePolyline(String encoded) {
    final List<List<num>> points = decodePolyline(encoded, accuracyExponent: 5);
    return points.map((point) => LatLng(point[0].toDouble(), point[1].toDouble())).toList();
  }

  // NOTE: _updateMarkersWithOptimizedOrder is now OBSOLETE and can be removed.
  // void _updateMarkersWithOptimizedOrder(List<dynamic> optimizedOrder) { ... }

  Future<void> _toggleUserLocation(bool useLocation) async {
    print('🔄 Toggle user location: $useLocation');
    setState(() {
      _useUserLocation = useLocation;
    });

    if (useLocation) {
      try {
        print('📍 Getting current position...');
        final position = await _locationService.getCurrentPosition();
        if (position != null) {
          final userLatLng = LatLng(position.latitude, position.longitude);
          print('✅ User position obtained: ${position.latitude}, ${position.longitude}');
          
          Set<Marker> currentMarkers = Set.from(markers);
          currentMarkers.removeWhere((m) => m.markerId.value == 'user_location');
          currentMarkers.add(
            Marker(
              markerId: const MarkerId('user_location'),
              position: userLatLng,
              icon: _userLocationIcon,
              infoWindow: const InfoWindow(title: 'My Location'),
            ),
          );

          if (!mounted) return;
          setState(() {
            _userPosition = userLatLng;
            markers = currentMarkers;
          });
          print('✅ User location marker added. Total markers: ${markers.length}');
          
          final allMarkerPositions = markers.map((m) => m.position).toList();
          if (allMarkerPositions.isNotEmpty) {
            await _fitMapToBounds(allMarkerPositions);
          }
        } else {
          print('❌ Failed to get user position');
          if (!mounted) return;
          _showMessage('Could not get your current location. Please check location permissions.');
          setState(() => _useUserLocation = false); // Revert checkbox if location fails
        }
      } catch (e) {
        print('❌ Error getting user location: $e');
        if (!mounted) return;
        _showMessage('Error getting location: $e');
        setState(() => _useUserLocation = false); // Revert on error
      }
    } else {
      print('📍 Removing user location');
      
      Set<Marker> currentMarkers = Set.from(markers);
      currentMarkers.removeWhere((m) => m.markerId.value == 'user_location');

      if (!mounted) return;
      setState(() {
        _userPosition = null;
        markers = currentMarkers;
      });
      print('✅ User location marker removed. Total markers: ${markers.length}');

      // Refit the map to the original pools
      final poolPositions = _routePools
        .where((p) => p['position'] != null)
        .map((p) => p['position'] as LatLng)
        .toList();
      
      if (poolPositions.isNotEmpty) {
        await _fitMapToBounds(poolPositions);
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_routeName),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _routePools.isNotEmpty)
            IconButton(
              icon: Icon(_showAddressPanel ? Icons.map : Icons.list),
              onPressed: () => setState(() => _showAddressPanel = !_showAddressPanel),
              tooltip: _showAddressPanel ? 'Hide Address List' : 'Show Address List',
            ),
        ],
      ),
      body: Stack(
        children: [
          if (_isLoading)
            const Center(child: CircularProgressIndicator())
          else
            GoogleMap(
              onMapCreated: (controller) {
                if (!_controllerCompleter.isCompleted) {
                  _controllerCompleter.complete(controller);
                }
                          },
                          initialCameraPosition: CameraPosition(
                target: _initialPosition ?? const LatLng(26.7153, -80.0534),
                zoom: 12.0,
              ),
              markers: markers,
              polylines: polylines,
              mapType: MapType.normal,
              zoomControlsEnabled: true,
              myLocationButtonEnabled: false,
            ),
          if (!_isLoading && _routePools.isNotEmpty) _buildOptimizationPanel(),
          if (_showAddressPanel && _routePools.isNotEmpty) _buildAddressPanel(),
        ],
      ),
    );
  }

  Widget _buildOptimizationPanel() {
    return Positioned(
      top: 10,
      left: 10,
      child: SizedBox(
        width: 190,
        child: Card(
          elevation: 4.0,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Checkbox(
                      visualDensity: VisualDensity.compact,
                      value: _useUserLocation,
                      onChanged: (value) {
                        if (value != null) {
                          _toggleUserLocation(value);
                        }
                      },
                    ),
                    Flexible(
                      child: Text(
                        'My Position',
                        style: AppTextStyles.body2.copyWith(fontSize: 12),
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _isOptimizingRoute ? null : _optimizeRoute,
                    icon: const Icon(Icons.route, size: 18),
                    label: Text(
                      _isOptimizingRoute ? 'Optimizing...' : 'Optimize Route',
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                  ),
                ),
                if (_optimizationStatus.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _optimizationStatus,
                    style: AppTextStyles.caption.copyWith(color: Colors.grey[600], fontSize: 10),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddressPanel() {
    if (_routePools.isEmpty) return const SizedBox.shrink();

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
                    const Text('Route Stops', style: TextStyle(fontWeight: FontWeight.bold)),
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
                  itemCount: _routePools.length,
                  itemBuilder: (context, index) {
                    final pool = _routePools[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: AppColors.primary,
                        child: Text('${pool['order']}'),
                      ),
                      title: Text(pool['name']),
                      subtitle: Text(pool['address']),
                      onTap: () async {
                        if (pool['position'] != null) {
                          try {
                            final controller = await _controllerCompleter.future;
                            await controller.animateCamera(
                              CameraUpdate.newLatLngZoom(pool['position'], 15),
                            );
                          } catch (e) {
                            print('❌ Error animating camera: $e');
                          }
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

  void _optimizeRoute() async {
    if (_isOptimizingRoute) return;

    setState(() {
      _isOptimizingRoute = true;
      _optimizationStatus = 'Preparing route...';
      polylines.clear(); 
    });

    try {
      // Step 1: Consolidate all points for the route into a single list.
      List<Map<String, dynamic>> pointsForRouting = [];
      Map<String, dynamic> apiOrigin;

      final List<Map<String, dynamic>> validPools = _routePools
          .where((pool) => (pool['address'] as String).isNotEmpty && pool['position'] != null)
          .toList();

      if (_useUserLocation && _userPosition != null) {
        // Start with user's location, then add all valid pools.
        final userPoint = {'name': 'My Location', 'isUserLocation': true, 'position': _userPosition, 'address': 'Current Location', 'id': 'user_location'};
        pointsForRouting.add(userPoint);
        pointsForRouting.addAll(validPools);
        apiOrigin = {'location': {'latLng': {'latitude': _userPosition!.latitude, 'longitude': _userPosition!.longitude}}};
      } else {
        // Start with the first valid pool.
        pointsForRouting.addAll(validPools);
        if (pointsForRouting.isNotEmpty) {
          final firstPosition = pointsForRouting.first['position'] as LatLng;
          apiOrigin = {'location': {'latLng': {'latitude': firstPosition.latitude, 'longitude': firstPosition.longitude}}};
        } else {
          _showMessage('No valid pools to create a route.');
          setState(() => _isOptimizingRoute = false);
          return;
        }
      }

      if (pointsForRouting.length < 2) {
        _showMessage('Not enough points to create a route. At least an origin and destination are required.');
        setState(() => _isOptimizingRoute = false);
        return;
      }
      
      // Step 2: Prepare the API payload from our consolidated list.
      Map<String, dynamic> apiDestination;
      List<Map<String, dynamic>> apiIntermediates;
      List<Map<String, dynamic>> originalIntermediatePools;
      Map<String, dynamic> destinationPoint;

      if (_useUserLocation && _userPosition != null) {
        // One-way from user location. All pools are waypoints to be optimized.
        List<Map<String, dynamic>> allPools = pointsForRouting.sublist(1);
        if (allPools.isEmpty) {
          _showMessage('No pools to route to from your location.');
          setState(() => _isOptimizingRoute = false);
          return;
        }
        destinationPoint = allPools.removeLast();
        originalIntermediatePools = allPools; // The rest are intermediates
      } else {
        // Point-to-point between first and last pools.
        if (pointsForRouting.length < 2) {
          _showMessage('Not enough points for a point-to-point route.');
          setState(() => _isOptimizingRoute = false);
          return;
        }
        destinationPoint = pointsForRouting.last;
        originalIntermediatePools = pointsForRouting.length > 2 ? pointsForRouting.sublist(1, pointsForRouting.length - 1) : [];
      }
      
      // Convert to API format
      final destPosition = destinationPoint['position'] as LatLng;
      apiDestination = {'location': {'latLng': {'latitude': destPosition.latitude, 'longitude': destPosition.longitude}}};

      apiIntermediates = originalIntermediatePools.map((p) {
        final pos = p['position'] as LatLng;
        return {'location': {'latLng': {'latitude': pos.latitude, 'longitude': pos.longitude}}};
      }).toList();
      
      // This is the original list of intermediate pools that we'll reorder using the API response.
      final requestBody = {
        'origin': apiOrigin,
        'destination': apiDestination,
        'intermediates': apiIntermediates,
        'travelMode': 'DRIVE',
        'routingPreference': 'TRAFFIC_AWARE',
        'optimizeWaypointOrder': apiIntermediates.isNotEmpty,
      };

      print('➡️ Sending optimization request: ${json.encode(requestBody)}');
      setState(() => _optimizationStatus = 'Requesting optimized route...');

      final response = await http.post(
        Uri.parse('http://localhost:4000/computeRoutes'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (!mounted) return;

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['routes'] != null && data['routes'].isNotEmpty) {
          final route = data['routes'][0];
          final optimizedOrderIndices = (route['optimizedIntermediateWaypointIndex'] as List<dynamic>?) ?? [];
          
          // Step 3: Reconstruct the route list in the new optimized order.
          List<Map<String, dynamic>> reorderedPools = [];
          reorderedPools.add(pointsForRouting.first); // Add the origin

          // Add intermediates in the order provided by the API.
          for (final index in optimizedOrderIndices) {
            reorderedPools.add(originalIntermediatePools[index as int]);
          }
          
          // Add the final destination.
          if (pointsForRouting.length > 1) {
            reorderedPools.add(destinationPoint);
          }

          // Step 4: Update the UI with the new route and markers.
          Set<Marker> newMarkers = {};
          final polylinePoints = _decodePolyline(route['polyline']['encodedPolyline']);

          for (int i = 0; i < reorderedPools.length; i++) {
            final pool = reorderedPools[i];
            pool['order'] = i + 1; // Update order for the address panel

            if (pool['isUserLocation'] == true) {
              newMarkers.add(Marker(markerId: const MarkerId('user_location'), position: pool['position'], icon: _userLocationIcon, infoWindow: InfoWindow(title: pool['name'], snippet: 'Start of Route')));
            } else {
              final isMaintained = _maintenanceStatuses[pool['id']] ?? false;
              newMarkers.add(
                Marker(
                  markerId: MarkerId(pool['id']),
                  position: pool['position'],
                  icon: BitmapDescriptor.defaultMarkerWithHue(isMaintained ? BitmapDescriptor.hueGreen : BitmapDescriptor.hueRed),
                  infoWindow: InfoWindow(title: pool['name'], snippet: 'Optimized Stop #${i + 1}'),
                )
              );
            }
          }
          
          final newPolylines = {
            Polyline(polylineId: const PolylineId('optimized_route'), points: polylinePoints, color: Colors.green, width: 6),
          };

          setState(() {
            _routePools = reorderedPools;
            markers = newMarkers;
            polylines = newPolylines;
            _optimizationStatus = 'Route optimized successfully!';
            _isOptimizingRoute = false;
          });
          
          await _fitMapToBounds(polylinePoints);

        } else {
          final errorBody = json.decode(response.body);
          final errorMsg = errorBody['error']?['message'] ?? 'Unknown API Error';
          final fullError = errorBody['error']?.toString() ?? 'No error object in response';
          print('❌ API Error from proxy: $errorMsg. Full error: $fullError');
          _showMessage('Could not optimize route: $errorMsg');
          setState(() => _isOptimizingRoute = false);
        }
      } else {
        print('❌ Server Error: ${response.statusCode} - ${response.body}');
        _showMessage('Failed to optimize route. Server returned status ${response.statusCode}');
        setState(() => _isOptimizingRoute = false);
      }
    } catch (e, stackTrace) {
      print('❌ Fatal Error calculating optimized route: $e\n$stackTrace');
      if (!mounted) return;
      _showMessage('An unexpected error occurred: $e');
      setState(() => _isOptimizingRoute = false);
    }
  }
} 