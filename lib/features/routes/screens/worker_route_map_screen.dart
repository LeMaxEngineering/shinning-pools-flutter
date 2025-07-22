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
import '../../../shared/ui/widgets/app_button.dart';
import '../../../core/services/geocoding_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/optimized_pool_service.dart';
import '../models/assignment.dart';
import '../../pools/screens/maintenance_form_screen.dart';

class WorkerRouteMapScreen extends StatefulWidget {
  final Map<String, dynamic> route;

  const WorkerRouteMapScreen({Key? key, required this.route}) : super(key: key);

  @override
  State<WorkerRouteMapScreen> createState() => _WorkerRouteMapScreenState();
}

class _WorkerRouteMapScreenState extends State<WorkerRouteMapScreen> {
  final Completer<GoogleMapController> _controllerCompleter = Completer();
  List<Marker> _markers = [];
  LatLng? _initialPosition;
  double _zoom = 14.0;
  List<Map<String, dynamic>> _routePools = [];
  bool _showAddressPanel = false;
  bool _isLoading = true;
  Map<String, bool> _maintenanceStatuses = {};
  String _routeName = 'Worker Route';
  final GeocodingService _geocodingService = GeocodingService();
  final OptimizedPoolService _poolService = OptimizedPoolService();

  // Custom markers for worker-specific features
  BitmapDescriptor? _greenIcon;
  BitmapDescriptor? _redIcon;
  BitmapDescriptor? _userIcon;

  @override
  void initState() {
    super.initState();
    _loadCustomMarkers();
    _loadRouteData();
  }

  @override
  void dispose() {
    // Cancel any pending operations and dispose the controller
    if (!_controllerCompleter.isCompleted) {
      _controllerCompleter.completeError('Widget disposed');
    }
    super.dispose();
  }

  Future<void> _loadCustomMarkers() async {
    _greenIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/img/green.png',
    );
    _redIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/img/red.png',
    );
    _userIcon = await BitmapDescriptor.fromAssetImage(
      const ImageConfiguration(size: Size(48, 48)),
      'assets/img/user_marker.png',
    );
  }

  Future<void> _loadRouteData() async {
    setState(() => _isLoading = true);

    try {
      final routeData = widget.route;
      final stops = routeData['stops'] as List? ?? [];

      if (stops.isEmpty) {
        _showMessage('No pools found in this route');
        setState(() => _isLoading = false);
        return;
      }

      setState(() {
        _routeName = routeData['routeName'] ?? 'Worker Route';
      });

      // Get auth service for company ID
      final authService = Provider.of<AuthService>(context, listen: false);
      final companyId = authService.currentUser?.companyId;

      if (companyId == null) {
        _showMessage('User not associated with a company');
        setState(() => _isLoading = false);
        return;
      }

      // Clear maintenance cache to ensure fresh data
      _poolService.clearMaintenanceCache();

      // Fetch all required data in parallel
      final results = await Future.wait([
        _fetchPoolsData(stops, companyId),
        _fetchMaintenanceStatuses(stops, companyId),
      ]);

      final poolsData = results[0] as List<Map<String, dynamic>>;
      final maintenanceStatuses = results[1] as Map<String, bool>;

      if (mounted) {
        setState(() {
          _routePools = poolsData;
          _maintenanceStatuses = maintenanceStatuses;
          _isLoading = false;
        });
      }

      // Create markers for pools
      await _createMarkers();

      // Fit bounds to show all markers
      if (mounted) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _fitBoundsToMarkers();
        });
      }
    } catch (e) {
      print('❌ Error loading route data: $e');
      _showMessage('Error loading route data: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<List<Map<String, dynamic>>> _fetchPoolsData(
    List stops,
    String companyId,
  ) async {
    final poolsData = <Map<String, dynamic>>[];

    for (int i = 0; i < stops.length; i++) {
      final poolId = stops[i].toString();

      try {
        final poolDoc = await FirebaseFirestore.instance
            .collection('pools')
            .doc(poolId)
            .get();

        if (poolDoc.exists) {
          final poolData = poolDoc.data()!;
          final address =
              poolData['address'] as String? ?? 'No address available';

          poolsData.add({
            'id': poolId,
            'name': poolData['name'] as String? ?? 'Unknown Pool',
            'address': address,
            'order': i + 1,
            'maintained': false, // Will be updated with maintenance status
          });
        }
      } catch (e) {
        print('❌ Error fetching pool $poolId: $e');
        poolsData.add({
          'id': poolId,
          'name': 'Unknown Pool',
          'address': 'Address not available',
          'order': i + 1,
          'maintained': false,
        });
      }
    }

    return poolsData;
  }

  Future<Map<String, bool>> _fetchMaintenanceStatuses(
    List stops,
    String companyId,
  ) async {
    try {
      final today = DateTime.utc(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      final maintenanceStatuses = await _poolService.getMaintenanceStatusBatch(
        stops.map((stop) => stop.toString()).toList(),
        today,
      );

      print(
        '✅ Fetched maintenance statuses for ${maintenanceStatuses.length} pools',
      );
      return maintenanceStatuses;
    } catch (e) {
      print('❌ Error fetching maintenance statuses: $e');
      return {};
    }
  }

  Future<void> _createMarkers() async {
    final markers = <Marker>[];
    final poolPositions = <LatLng>[];

    for (final pool in _routePools) {
      final address = pool['address'] as String;
      final poolId = pool['id'] as String;
      final isMaintained = _maintenanceStatuses[poolId] ?? false;

      print('🗺️ Creating marker for pool: ${pool['name']}');
      print('  - Address: $address');
      print('  - Maintained: $isMaintained');

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

      if (lat != null && lng != null) {
        final position = LatLng(lat, lng);

        // Only add non-maintained pools to route calculation
        if (!isMaintained) {
          poolPositions.add(position);
        }

        final marker = Marker(
          markerId: MarkerId(poolId),
          position: position,
          icon: isMaintained
              ? (_greenIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueGreen,
                    ))
              : (_redIcon ??
                    BitmapDescriptor.defaultMarkerWithHue(
                      BitmapDescriptor.hueRed,
                    )),
          infoWindow: InfoWindow(
            title: pool['name'],
            snippet: isMaintained ? 'Maintained' : 'Not Maintained',
            onTap: () => _onPoolTapped(pool, isMaintained),
          ),
        );

        markers.add(marker);
        print('✅ Created marker for ${pool['name']} at $lat, $lng');
      } else {
        print('❌ Could not create marker for ${pool['name']} - no coordinates');
      }
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }

    // Optimize route if we have multiple non-maintained pools
    if (poolPositions.length > 1) {
      await _optimizeRoute(poolPositions);
    }
  }

  Future<void> _optimizeRoute(List<LatLng> poolPositions) async {
    try {
      print('🔄 Optimizing route for ${poolPositions.length} pools');

      // TODO: Implement route optimization
      // For now, we'll just log the pool positions
      print('✅ Pool positions for optimization: ${poolPositions.length}');

      // This would be implemented with a proper route optimization service
      // For now, we'll keep the original order
    } catch (e) {
      print('❌ Error optimizing route: $e');
    }
  }

  void _updateMarkersWithOptimizedOrder(List<int> optimizedOrder) {
    // This method would update the marker order while preserving the green/red colors
    // For now, we'll just log the optimized order
    print('🔄 Updated markers with optimized order: $optimizedOrder');
  }

  void _onPoolTapped(Map<String, dynamic> pool, bool isMaintained) {
    if (!isMaintained) {
      // Show option to start maintenance report
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Start Maintenance Report'),
          content: Text(
            'Would you like to start a maintenance report for ${pool['name']}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _startMaintenanceReport(pool);
              },
              child: const Text('Start Report'),
            ),
          ],
        ),
      );
    } else {
      // Show maintenance completed message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${pool['name']} has already been maintained today'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _startMaintenanceReport(Map<String, dynamic> pool) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) =>
            MaintenanceFormScreen(poolId: pool['id'], poolName: pool['name']),
      ),
    );
  }

  Future<void> _fitBoundsToMarkers() async {
    if (_markers.isEmpty || !mounted) return;

    try {
      final controller = await _controllerCompleter.future;

      // Check if widget is still mounted before proceeding
      if (!mounted) return;

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

      // Determine optimal zoom level based on span - ensure all pinpoints are visible
      double optimalZoom = 13.0; // Default zoom (reduced to show all pinpoints)

      if (latSpan > 0.1 || lngSpan > 0.1) {
        // Large area - use wider zoom to show all
        optimalZoom = 10.0;
      } else if (latSpan > 0.05 || lngSpan > 0.05) {
        // Medium area - use wider zoom
        optimalZoom = 12.0;
      } else if (latSpan > 0.02 || lngSpan > 0.02) {
        // Small area - use medium zoom
        optimalZoom = 14.0;
      } else {
        // Very small area - use closer zoom
        optimalZoom = 15.0;
      }

      // Add padding to ensure all markers are visible
      final padding = 0.01; // Add small padding around bounds
      final centerLat = (minLat + maxLat) / 2;
      final centerLng = (minLng + maxLng) / 2;
      final center = LatLng(centerLat, centerLng);

      print('🗺️ Fitting bounds with optimal zoom: $optimalZoom');
      print('🗺️ Center: $centerLat, $centerLng');
      print(
        '🗺️ Span: ${latSpan.toStringAsFixed(4)} lat, ${lngSpan.toStringAsFixed(4)} lng',
      );

      // Check if widget is still mounted before animating camera
      if (!mounted) return;

      // Animate camera to center with optimal zoom
      await controller.animateCamera(
        CameraUpdate.newLatLngZoom(center, optimalZoom),
      );
    } catch (e) {
      if (mounted) {
        print('Error fitting bounds to markers: $e');
      }
    }
  }

  void _showMessage(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Worker Route Map'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        actions: [
          if (!_isLoading && _routePools.isNotEmpty)
            IconButton(
              icon: Icon(_showAddressPanel ? Icons.map : Icons.list),
              onPressed: () =>
                  setState(() => _showAddressPanel = !_showAddressPanel),
              tooltip: _showAddressPanel
                  ? 'Hide Address List'
                  : 'Show Address List',
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
                  if (mounted) {
                    _fitBoundsToMarkers();
                  }
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
          if (!_isLoading) _buildWorkerInfoPanel(),
          if (_showAddressPanel && _routePools.isNotEmpty) _buildAddressPanel(),
        ],
      ),
    );
  }

  Widget _buildWorkerInfoPanel() {
    final maintainedCount = _maintenanceStatuses.values
        .where((status) => status)
        .length;
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
              Text(_routeName, style: AppTextStyles.headline2),
              const SizedBox(height: 8),
              Text('Worker Route', style: AppTextStyles.body),
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
                  Text(
                    'Maintained: $maintainedCount',
                    style: AppTextStyles.body,
                  ),
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
                  Text(
                    'Not Maintained: ${totalCount - maintainedCount}',
                    style: AppTextStyles.body,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: AppButton(
                      label: 'Start from My Location',
                      onPressed: () {
                        // TODO: Implement start from current location
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Starting from your location...'),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppButton(
                      label: 'Optimize Route',
                      onPressed: () {
                        // TODO: Implement route optimization
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Optimizing route...')),
                        );
                      },
                    ),
                  ),
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
                    Text('Route Stops', style: AppTextStyles.headline2),
                    const Spacer(),
                    IconButton(
                      onPressed: () =>
                          setState(() => _showAddressPanel = false),
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
                        style: AppTextStyles.body.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text(
                        pool['address'],
                        style: AppTextStyles.caption,
                      ),
                      trailing: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isMaintained
                              ? Colors.green.withOpacity(0.1)
                              : Colors.red.withOpacity(0.1),
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
