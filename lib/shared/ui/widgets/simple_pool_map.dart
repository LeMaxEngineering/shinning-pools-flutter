import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import '../theme/colors.dart';

class SimplePoolMap extends StatefulWidget {
  final String address;
  final String poolName;
  final double height;
  final bool interactive;
  final VoidCallback? onDirectionsTap;

  const SimplePoolMap({
    Key? key,
    required this.address,
    required this.poolName,
    this.height = 200,
    this.interactive = true,
    this.onDirectionsTap,
  }) : super(key: key);

  @override
  State<SimplePoolMap> createState() => _SimplePoolMapState();
}

class _SimplePoolMapState extends State<SimplePoolMap> {
  GoogleMapController? _mapController;
  static const LatLng _defaultLocation = LatLng(34.0522, -118.2437); // Los Angeles, CA

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Demo mode banner
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(12),
              topRight: Radius.circular(12),
            ),
            border: Border.all(color: Colors.blue[200]!),
          ),
          child: Row(
            children: [
              Icon(Icons.map, size: 16, color: Colors.blue[700]),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Map Demo - Click for directions to actual address',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(12),
              bottomRight: Radius.circular(12),
            ),
            child: GoogleMap(
              onMapCreated: _onMapCreated,
              initialCameraPosition: const CameraPosition(
                target: _defaultLocation,
                zoom: 14.0,
              ),
              markers: {
                Marker(
                  markerId: const MarkerId('pool_demo_location'),
                  position: _defaultLocation,
                  infoWindow: InfoWindow(
                    title: '${widget.poolName} (Demo)',
                    snippet: 'Tap "Directions" below for actual location',
                  ),
                  icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueBlue),
                ),
              },
              zoomControlsEnabled: widget.interactive,
              scrollGesturesEnabled: widget.interactive,
              zoomGesturesEnabled: widget.interactive,
              tiltGesturesEnabled: widget.interactive,
              rotateGesturesEnabled: widget.interactive,
              myLocationButtonEnabled: false,
              mapToolbarEnabled: false, // Disable to avoid confusion
            ),
          ),
        ),
        // Directions button
        if (widget.onDirectionsTap != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              border: Border.all(color: Colors.grey[300]!),
            ),
            child: ElevatedButton.icon(
              onPressed: widget.onDirectionsTap,
              icon: const Icon(Icons.directions, size: 18),
              label: const Text('Get Directions'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
            ),
          ),
        ),
      ],
    );
  }
} 