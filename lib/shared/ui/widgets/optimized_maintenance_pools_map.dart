import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geocoding/geocoding.dart';

import '../../../core/services/optimized_pool_service.dart';
import '../../../core/services/auth_service.dart';
import '../../../shared/ui/theme/colors.dart';
import '../../../shared/ui/theme/text_styles.dart';
import '../../../shared/ui/widgets/app_button.dart';
import 'package:provider/provider.dart';

class OptimizedMaintenancePoolsMap extends StatefulWidget {
  final String? companyId;
  final Function(String poolId, String poolName, String address)?
  onPoolSelected;
  final bool showMapView;
  final double? height;

  const OptimizedMaintenancePoolsMap({
    Key? key,
    this.companyId,
    this.onPoolSelected,
    this.showMapView = false,
    this.height,
  }) : super(key: key);

  @override
  State<OptimizedMaintenancePoolsMap> createState() =>
      _OptimizedMaintenancePoolsMapState();
}

class _OptimizedMaintenancePoolsMapState
    extends State<OptimizedMaintenancePoolsMap> {
  GoogleMapController? _mapController;
  Set<Marker> _markers = {};
  Position? _userLocation;
  List<Map<String, dynamic>> _companyPools = [];
  Map<String, bool> _maintenanceStatuses = {};
  Map<String, Map<String, dynamic>> _geocodedAddresses = {};
  bool _isLoading = true;
  String? _selectedPoolId;
  String? _selectedPoolName;
  String? _selectedPoolAddress;
  int _loadedPools = 0;
  int _totalPools = 0;

  // Cache for icons to avoid reloading
  BitmapDescriptor? _redIcon;
  BitmapDescriptor? _greenIcon;
  BitmapDescriptor? _userIcon;

  // Optimized service instance
  final OptimizedPoolService _optimizedService = OptimizedPoolService();

  @override
  void initState() {
    super.initState();
    _initializeMapOptimized();
  }

  Future<void> _initializeMapOptimized() async {
    try {
      print(
        '🚀 Initializing optimized maintenance pools map with ultra-fast loading...',
      );

      // Show map immediately
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }

      // Load user location and icons in parallel
      await Future.wait([_loadUserLocation(), _preloadIcons()]);

      // Load pools first
      await _loadCompanyPoolsOptimized();

      // Then load maintenance statuses
      if (_companyPools.isNotEmpty) {
        await _loadMaintenanceStatusesOptimized();
        await _buildAllMarkersAtOnce();
      }

      print('✅ Ultra-fast map initialization complete');
    } catch (e) {
      print('❌ Error initializing map: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _preloadIcons() async {
    try {
      print('🎨 Preloading icons...');
      final iconFutures = await Future.wait([
        _loadPinpointIcon('red.png'),
        _loadPinpointIcon('green.png'),
        _loadUserMarkerIcon(),
      ]);

      _redIcon = iconFutures[0];
      _greenIcon = iconFutures[1];
      _userIcon = iconFutures[2];

      print('✅ Icons preloaded successfully');
    } catch (e) {
      print('❌ Error preloading icons: $e');
      // Use default icons as fallback
      _redIcon = BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
      _greenIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueGreen,
      );
      _userIcon = BitmapDescriptor.defaultMarkerWithHue(
        BitmapDescriptor.hueBlue,
      );
    }
  }

  Future<void> _buildAllMarkersAtOnce() async {
    try {
      if (_companyPools.isEmpty) {
        print('❌ No pools to build markers for');
        return;
      }

      print(
        '🏗️ Building all markers at once for ${_companyPools.length} pools...',
      );
      print(
        '🔍 Available icons - Red: ${_redIcon != null}, Green: ${_greenIcon != null}, User: ${_userIcon != null}',
      );

      final markers = <Marker>{};

      // Add user location marker if available
      if (_userLocation != null && _userIcon != null) {
        final userMarker = Marker(
          markerId: const MarkerId('user_location'),
          position: LatLng(_userLocation!.latitude, _userLocation!.longitude),
          icon: _userIcon!,
          infoWindow: const InfoWindow(
            title: 'Your Location',
            snippet: 'Current position',
          ),
          zIndexInt: 2,
        );
        markers.add(userMarker);
        print(
          '📍 User location marker added at: ${_userLocation!.latitude}, ${_userLocation!.longitude}',
        );
      }

      // Geocode all addresses at once
      final addresses = _companyPools
          .map((pool) => pool['address'] as String)
          .toList();
      print('🌍 Geocoding ${addresses.length} addresses...');
      final geocodedResults = await _optimizedService.geocodeAddressesBatch(
        addresses,
      );
      _geocodedAddresses = geocodedResults;
      print('✅ Geocoded ${geocodedResults.length} addresses successfully');

      // Create all pool markers at once
      for (final pool in _companyPools) {
        final poolId = pool['id'] as String;
        final poolName = pool['name'] as String;
        final address = pool['address'] as String;
        final geocodedResult = geocodedResults[address];

        if (geocodedResult != null) {
          final isMaintained = _maintenanceStatuses[poolId] ?? false;
          final icon = isMaintained ? _greenIcon : _redIcon;

          if (icon != null) {
            final marker = Marker(
              markerId: MarkerId(poolId),
              position: LatLng(
                geocodedResult['latitude'] as double,
                geocodedResult['longitude'] as double,
              ),
              icon: icon,
              infoWindow: InfoWindow(
                title: address,
                snippet: isMaintained
                    ? 'Maintained Today'
                    : 'Needs Maintenance',
              ),
              onTap: () =>
                  _onMarkerTapped(poolId, poolName, address, isMaintained),
              zIndexInt: 1,
            );

            markers.add(marker);
            print(
              '📍 Added ${isMaintained ? "green" : "red"} marker for $address at ${geocodedResult['latitude']}, ${geocodedResult['longitude']}',
            );
          } else {
            print('❌ No icon available for pool $poolName');
          }
        } else {
          print('❌ Could not geocode address for pool $poolName: $address');
        }
      }

      // Single setState to update all markers
      if (mounted) {
        setState(() {
          _markers = markers;
          _loadedPools = _companyPools.length;
        });
        print('✅ Set ${markers.length} markers in state');
      }

      print('✅ Created ${markers.length} markers at once');
    } catch (e) {
      print('❌ Error building markers: $e');
    }
  }

  Future<void> _loadUserLocation() async {
    try {
      print('🔍 Requesting current location for optimized maintenance map...');
      final position = await Geolocator.getCurrentPosition();

      if (mounted) {
        setState(() {
          _userLocation = position;
        });
      }
      print(
        '✅ User location obtained for optimized maintenance map: ${position.latitude}, ${position.longitude}',
      );
    } catch (e) {
      print('❌ Error getting user location: $e');
      // Use mock location as fallback
      _userLocation = Position(
        latitude: 26.6069708,
        longitude: -80.1543766,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0,
        altitudeAccuracy: 0,
        headingAccuracy: 0,
      );
    }
  }

  Future<void> _loadCompanyPoolsOptimized() async {
    try {
      final companyId = widget.companyId ?? await _getCurrentUserCompanyId();
      if (companyId == null) {
        print('❌ No company ID available');
        return;
      }

      print(
        '🏢 Loading company pools with optimization for company: $companyId',
      );
      final pools = await _optimizedService.getCompanyPoolsWithCache(companyId);

      if (mounted) {
        setState(() {
          _companyPools = pools;
          _totalPools = pools.length;
        });
      }

      print('✅ Loaded ${pools.length} pools with optimization');
    } catch (e) {
      print('❌ Error loading company pools: $e');
    }
  }

  Future<void> _loadMaintenanceStatusesOptimized() async {
    try {
      final poolIds = _companyPools
          .map((pool) => pool['id'] as String)
          .toList();
      final today = DateTime.now();

      print('🔍 Loading maintenance statuses for ${poolIds.length} pools...');
      final maintenanceStatuses = await _optimizedService
          .getMaintenanceStatusBatch(poolIds, today);

      if (mounted) {
        setState(() {
          _maintenanceStatuses = maintenanceStatuses;
        });
      }

      print(
        '✅ Loaded maintenance statuses for ${maintenanceStatuses.length} pools',
      );
    } catch (e) {
      print('❌ Error loading maintenance statuses: $e');
    }
  }

  Future<BitmapDescriptor> _loadPinpointIcon(String iconName) async {
    try {
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/img/$iconName',
      );
    } catch (e) {
      print('❌ Error loading pinpoint icon $iconName: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed);
    }
  }

  Future<BitmapDescriptor> _loadUserMarkerIcon() async {
    try {
      return await BitmapDescriptor.fromAssetImage(
        const ImageConfiguration(size: Size(48, 48)),
        'assets/img/user_marker.png',
      );
    } catch (e) {
      print('❌ Error loading user marker icon: $e');
      return BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue);
    }
  }

  void _onMarkerTapped(
    String poolId,
    String poolName,
    String address,
    bool isMaintained,
  ) {
    if (isMaintained) {
      _showMaintainedPoolMessage(address);
      return;
    }

    setState(() {
      _selectedPoolId = poolId;
      _selectedPoolName = poolName;
      _selectedPoolAddress = address;
    });

    widget.onPoolSelected?.call(poolId, poolName, address);
  }

  void _showMaintainedPoolMessage(String address) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('🏊 $address has been maintained today'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<String?> _getCurrentUserCompanyId() async {
    try {
      // Get auth service from Provider context
      final authService = Provider.of<AuthService>(context, listen: false);
      final user = authService.currentUser;

      if (user != null) {
        print('✅ Got company ID from current user: ${user.companyId}');
        return user.companyId;
      } else {
        print('❌ No current user available');
        return null;
      }
    } catch (e) {
      print('❌ Error getting current user company ID: $e');
      return null;
    }
  }

  void _centerOnUserLocation() async {
    if (_userLocation != null && _mapController != null) {
      await _mapController!.animateCamera(
        CameraUpdate.newLatLngZoom(
          LatLng(_userLocation!.latitude, _userLocation!.longitude),
          14.0,
        ),
      );
      print('✅ Map centered on user location');
    }
  }

  @override
  Widget build(BuildContext context) {
    final initialTarget = _userLocation != null
        ? LatLng(_userLocation!.latitude, _userLocation!.longitude)
        : const LatLng(26.6069708, -80.1543766);

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary, width: 2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: Stack(
          children: [
            GoogleMap(
              onMapCreated: (GoogleMapController controller) {
                if (mounted) {
                  _mapController = controller;
                  print('🗺️ Optimized map controller created');

                  // Center map on user location or first pool
                  if (_userLocation != null) {
                    controller.animateCamera(
                      CameraUpdate.newLatLngZoom(
                        LatLng(
                          _userLocation!.latitude,
                          _userLocation!.longitude,
                        ),
                        14.0,
                      ),
                    );
                  } else if (_companyPools.isNotEmpty) {
                    // Center on first pool if no user location
                    final firstPool = _companyPools.first;
                    final address = firstPool['address'] as String;
                    final geocodedResult = _geocodedAddresses[address];
                    if (geocodedResult != null) {
                      final poolLocation = LatLng(
                        geocodedResult['latitude'] as double,
                        geocodedResult['longitude'] as double,
                      );
                      controller.animateCamera(
                        CameraUpdate.newLatLngZoom(poolLocation, 14.0),
                      );
                    }
                  }
                }
              },
              initialCameraPosition: CameraPosition(
                target: initialTarget,
                zoom: 14.0,
              ),
              markers: _markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: false,
              zoomControlsEnabled: false,
              mapToolbarEnabled: false,
            ),
            // Center on location button in upper right corner
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: _centerOnUserLocation,
                  icon: const Icon(Icons.my_location, color: AppColors.primary),
                  tooltip: 'Center on My Location',
                ),
              ),
            ),
            // Loading overlay
            if (_isLoading)
              Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _totalPools > 0
                            ? 'Loading pools... $_loadedPools/$_totalPools'
                            : 'Loading pools...',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    // Safely dispose map controller with a delay to prevent web-specific race conditions
    if (_mapController != null) {
      Future.delayed(const Duration(milliseconds: 200), () {
        if (mounted) {
          try {
            _mapController!.dispose();
          } catch (e) {
            print('⚠️ Warning: Error disposing map controller: $e');
            // Ignore disposal errors as they are common during widget disposal
          }
        }
      });
    }
    super.dispose();
  }
}
