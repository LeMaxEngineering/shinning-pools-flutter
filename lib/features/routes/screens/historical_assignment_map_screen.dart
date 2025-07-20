import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_card.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/auth_service.dart';
import '../models/assignment.dart';

class HistoricalAssignmentMapScreen extends StatefulWidget {
  final Assignment assignment;
  final DateTime? routeDate;

  const HistoricalAssignmentMapScreen({
    Key? key,
    required this.assignment,
    required this.routeDate,
  }) : super(key: key);

  @override
  State<HistoricalAssignmentMapScreen> createState() => _HistoricalAssignmentMapScreenState();
}

class _HistoricalAssignmentMapScreenState extends State<HistoricalAssignmentMapScreen> {
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  List<Marker> _markers = [];
  LatLng? _initialPosition;
  double _zoom = 12.0;
  List<Map<String, dynamic>> _routePools = [];
  bool _showAddressPanel = false;
  bool _isLoading = true;
  Map<String, bool> _maintenanceStatuses = {};
  String _routeName = 'Historical Route';
  String _workerName = '';
  final GeocodingService _geocodingService = GeocodingService();

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
    
    try {
      // Get route data
      final routeSnapshot = await FirebaseFirestore.instance
          .collection('routes')
          .doc(widget.assignment.routeId)
          .get();
      
      if (!routeSnapshot.exists) {
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

      setState(() {
        _routeName = routeData['routeName'] ?? 'Historical Route';
      });
      
      final stops = routeData['stops'] as List;
      final poolIds = stops.map((stop) => stop.toString()).toList();
      if (poolIds.isEmpty) {
        _showMessage('No valid pool IDs found');
        setState(() => _isLoading = false);
        return;
      }

      // Get worker name
      final workerSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.assignment.workerId)
          .get();
      
      if (workerSnapshot.exists) {
        final workerData = workerSnapshot.data() as Map<String, dynamic>?;
        setState(() {
          _workerName = workerData?['displayName'] ?? workerData?['email']?.split('@').first ?? 'Unknown Worker';
        });
      }

      // Get auth service for company ID
      final authService = Provider.of<AuthService>(context, listen: false);
      final companyId = authService.currentUser?.companyId;

      // Fetch all required data in parallel
      final results = await Future.wait([
        _getMaintenanceStatusForPools(poolIds, companyId),
        Future.wait(poolIds.map((id) => FirebaseFirestore.instance.collection('pools').doc(id).get())),
      ]);

      final maintenanceStatuses = results[0] as Map<String, bool>;
      _maintenanceStatuses = maintenanceStatuses;
      final poolSnapshots = results[1] as List<DocumentSnapshot>;

      // Process pool data - use existing pattern from route_maintenance_map_screen
      final pools = poolSnapshots.map((snapshot) {
        if (snapshot.exists && snapshot.data() != null) {
          final data = snapshot.data() as Map<String, dynamic>;
          return {
            'id': snapshot.id,
            'name': data['name'] ?? 'Unknown Pool',
            'address': data['address'] ?? 'No address',
            'latitude': (data['latitude'] ?? data['lat']) as double?,
            'longitude': (data['longitude'] ?? data['lng']) as double?,
          };
        }
        return null;
      }).where((pool) => pool != null).cast<Map<String, dynamic>>().toList();

      List<LatLng> poolPositions = [];
      _routePools = [];
      List<Marker> newMarkers = [];
      LatLng? firstValidPosition;

      for (int i = 0; i < pools.length; i++) {
        final pool = pools[i];
        final address = pool['address'] as String;
        
        LatLng? position;
        bool hasCoords = false;
        
        // Always use geocoding for the address (as requested by user)
        if (address.isNotEmpty) {
          try {
            final geocodeResult = await _geocodingService.geocodeAddress(address);
            if (geocodeResult != null) {
              position = geocodeResult.coordinates;
              hasCoords = true;
              print('✅ Geocoded address for pool ${pool['id']}: $address -> ${position.latitude}, ${position.longitude}');
            } else {
              print('⚠️ Failed to geocode address for pool ${pool['id']}: $address');
            }
          } catch (e) {
            print('❌ Error geocoding address for pool ${pool['id']}: $e');
            hasCoords = false;
          }
        } else {
          print('⚠️ No valid address for pool ${pool['id']}: $address');
        }

        _routePools.add({
          'id': pool['id'],
          'name': pool['name'],
          'address': address,
          'position': position,
          'order': i + 1,
          'hasCoordinates': hasCoords,
          'maintained': maintenanceStatuses[pool['id']] ?? false,
        });

        if (position != null) {
          poolPositions.add(position);
          if (firstValidPosition == null) firstValidPosition = position;
          
                  // Create marker with color based on maintenance status
        final isMaintained = maintenanceStatuses[pool['id']] ?? false;
        print('📍 Pool ${pool['id']} (${pool['name']}): ${isMaintained ? 'GREEN' : 'RED'} marker');
        print('   🏠 Address: ${pool['address']}');
        print('   🔍 Maintenance status: $isMaintained');
        print('   🎨 Creating marker with color: ${isMaintained ? 'GREEN' : 'RED'}');
        
        // Use custom pinpoint images
        final markerIcon = isMaintained 
            ? await BitmapDescriptor.fromAssetImage(
                const ImageConfiguration(size: Size(36, 36)), 
                'assets/img/green.png'
              )
            : await BitmapDescriptor.fromAssetImage(
                const ImageConfiguration(size: Size(36, 36)), 
                'assets/img/red.png'
              );
        
        final marker = Marker(
          markerId: MarkerId(pool['id']),
          position: position,
          icon: markerIcon,
          infoWindow: InfoWindow(
            title: pool['name'],
            snippet: '${address}\nStop ${i + 1} - ${isMaintained ? 'Maintained' : 'Not Maintained'}',
          ),
        );
        
        newMarkers.add(marker);
        print('   ✅ Marker added to newMarkers list (total: ${newMarkers.length})');
        print('   🎨 Marker using custom image: ${isMaintained ? 'green.png' : 'red.png'}');
        }
      }
      
      // Set initial position and zoom with better zoom level
      if (poolPositions.isNotEmpty) {
        // Use the first position as initial target, will be updated when map is ready
        _initialPosition = poolPositions.first;
        _zoom = 13.0; // Balanced zoom level
      } else {
        _initialPosition = firstValidPosition ?? const LatLng(26.7153, -80.0534);
        _zoom = 13.0; // Balanced zoom level
      }
      
      if (mounted) {
        setState(() {
          _markers = newMarkers;
          _isLoading = false;
        });
        
        print('🎯 MARKERS SET IN STATE:');
        print('   Total markers: ${_markers.length}');
        
        // Count markers by checking their maintenance status
        int greenCount = 0;
        int redCount = 0;
        for (var marker in _markers) {
          final poolId = marker.markerId.value;
          final isMaintained = maintenanceStatuses[poolId] ?? false;
          if (isMaintained) {
            greenCount++;
          } else {
            redCount++;
          }
        }
        print('   Green markers: $greenCount');
        print('   Red markers: $redCount');
        print('   Maintenance statuses: $maintenanceStatuses');
        
        // Fit bounds after markers are loaded
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitBoundsToMarkers();
        });
        
        // Print final summary
        print('📊 FINAL SUMMARY:');
        print('   Total pools in route: ${_routePools.length}');
        print('   Maintained pools: ${maintenanceStatuses.values.where((status) => status).length}');
        print('   Not maintained pools: ${maintenanceStatuses.values.where((status) => !status).length}');
        print('   Route date: ${widget.routeDate?.toString()}');
      }

    } catch (e) {
      print('Error loading historical assignment data: $e');
      _showMessage('Error loading route data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<Map<String, bool>> _getMaintenanceStatusForPools(
    List<String> poolIds, 
    String? companyId
  ) async {
    Map<String, bool> maintenanceStatuses = {};
    
    if (companyId == null) {
      print('Warning: No companyId provided for maintenance status query. Setting all to false.');
      for (String poolId in poolIds) {
        maintenanceStatuses[poolId] = false;
      }
      return maintenanceStatuses;
    }
    
    // Create start and end of day for the route date
    final routeDate = widget.routeDate ?? DateTime.now();
    final startOfDay = DateTime(routeDate.year, routeDate.month, routeDate.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    print('🔍 DEBUG: Route date: ${routeDate.toString()}');
    print('🔍 DEBUG: Querying maintenance for date range: ${startOfDay.toIso8601String()} to ${endOfDay.toIso8601String()}');
    print('🔍 DEBUG: Company ID: $companyId');
    print('🔍 DEBUG: Pool IDs to check: $poolIds');
    
    // Get all maintenance records for the company only, then filter by date and pool
    try {
      print('🔍 DEBUG: Fetching all maintenance records for company $companyId');
      
      QuerySnapshot maintenanceQuery = await FirebaseFirestore.instance
          .collection('pool_maintenances')
          .where('companyId', isEqualTo: companyId)
          .where('date', isGreaterThanOrEqualTo: startOfDay)
          .where('date', isLessThan: endOfDay)
          .get();

      print('🔍 DEBUG: Found ${maintenanceQuery.docs.length} maintenance records for the given date range.');
      
      // Create a set of pool IDs that have maintenance records for quick lookup
      final maintainedPoolIds = maintenanceQuery.docs.map((doc) => doc['poolId'] as String).toSet();
      
      // Check each pool in the route
      for (String poolId in poolIds) {
        maintenanceStatuses[poolId] = maintainedPoolIds.contains(poolId);
        
        if (maintainedPoolIds.contains(poolId)) {
          print('✅ Found maintenance for pool $poolId on ${routeDate.toString()}');
        } else {
          print('❌ No maintenance found for pool $poolId on ${routeDate.toString()}');
        }
      }
    } catch (e) {
      print('Error getting maintenance status: $e');
      // Set all pools to false if there's an error
      for (String poolId in poolIds) {
        maintenanceStatuses[poolId] = false;
      }
    }
    return maintenanceStatuses;
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _fitBoundsToMarkers() async {
    if (_markers.isEmpty) return;
    
    try {
      final controller = await _controllerCompleter.future;
      
      // Calculate bounds
      double minLat = double.infinity;
      double maxLat = -double.infinity;
      double minLng = double.infinity;
      double maxLng = -double.infinity;
      
      for (final marker in _markers) {
        minLat = min(minLat, marker.position.latitude);
        maxLat = max(maxLat, marker.position.latitude);
        minLng = min(minLng, marker.position.longitude);
        maxLng = max(maxLng, marker.position.longitude);
      }
      
      // Calculate the span of the markers
      final latSpan = maxLat - minLat;
      final lngSpan = maxLng - minLng;
      
      // Determine optimal zoom level based on span
      double optimalZoom = 13.0; // Default zoom
      
      if (latSpan > 0.1 || lngSpan > 0.1) {
        // Large area - use wider zoom
        optimalZoom = 10.0;
      } else if (latSpan > 0.05 || lngSpan > 0.05) {
        // Medium area - use medium zoom
        optimalZoom = 12.0;
      } else if (latSpan > 0.02 || lngSpan > 0.02) {
        // Small area - use closer zoom
        optimalZoom = 14.0;
      } else {
        // Very small area - use very close zoom
        optimalZoom = 15.0;
      }
      
      // Calculate center point
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      final center = LatLng(centerLat, centerLng);
      
      print('🗺️ Fitting bounds with optimal zoom: $optimalZoom');
      print('🗺️ Center: $centerLat, $centerLng');
      print('🗺️ Span: ${latSpan.toStringAsFixed(4)} lat, ${lngSpan.toStringAsFixed(4)} lng');
      
      // Animate camera to center with optimal zoom
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(center, optimalZoom),
      );
    } catch (e) {
      print('Error fitting bounds to markers: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateString = widget.routeDate != null 
        ? DateFormat('MMMM dd, yyyy').format(widget.routeDate!)
        : 'Unknown Date';

    return Scaffold(
      appBar: AppBar(
        title: Text('Historical Route Map'),
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
                // Fit bounds after map is created
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  _fitBoundsToMarkers();
                });
              },
              initialCameraPosition: CameraPosition(
                target: _initialPosition ?? const LatLng(26.7153, -80.0534),
                zoom: _zoom,
              ),
              markers: _markers.toSet(),
              mapType: MapType.normal,
              zoomControlsEnabled: true,
              myLocationButtonEnabled: false,
            ),
          if (!_isLoading) _buildInfoPanel(dateString),
          if (_showAddressPanel && _routePools.isNotEmpty) _buildAddressPanel(),
        ],
      ),
    );
  }

  Widget _buildInfoPanel(String dateString) {
    final maintainedCount = _maintenanceStatuses.values.where((status) => status).length;
    final totalCount = _maintenanceStatuses.length;
    
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: AppCard(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _routeName,
                style: AppTextStyles.headline2,
              ),
              const SizedBox(height: 8),
              Text(
                'Worker: $_workerName',
                style: AppTextStyles.body,
              ),
              Text(
                'Date: $dateString',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.green,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Maintained: $maintainedCount', style: AppTextStyles.body),
                  const SizedBox(width: 16),
                  Container(
                    width: 12,
                    height: 12,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('Not Maintained: ${totalCount - maintainedCount}', style: AppTextStyles.body),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAddressPanel() {
    return Positioned(
      bottom: 16,
      left: 16,
      right: 16,
      child: Container(
        constraints: const BoxConstraints(maxHeight: 300),
        child: AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    const Icon(Icons.list, color: AppColors.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Route Stops',
                      style: AppTextStyles.headline2,
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => setState(() => _showAddressPanel = false),
                      icon: const Icon(Icons.close),
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
                    final isMaintained = pool['maintained'] as bool? ?? false;
                    
                    return ListTile(
                      leading: Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: isMaintained ? Colors.green : Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${pool['order']}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      title: Text(
                        pool['name'],
                        style: AppTextStyles.body.copyWith(fontWeight: FontWeight.w600),
                      ),
                      subtitle: Text(
                        pool['address'],
                        style: AppTextStyles.caption,
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isMaintained ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          isMaintained ? 'Maintained' : 'Not Maintained',
                          style: TextStyle(
                            color: isMaintained ? Colors.green : Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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