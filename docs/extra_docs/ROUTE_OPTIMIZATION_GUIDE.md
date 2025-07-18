# Route Optimization Guide

## Overview

The Shinning Pools app now includes advanced route optimization capabilities using Google Maps Directions API. This feature allows users to create optimized routes between pools, starting from either the first pool in the route or the user's current GPS location.

## Features

### 🗺️ **Route Optimization**
- **Google Maps Directions API Integration**: Uses Google's optimization algorithm to find the most efficient route
- **User Location Support**: Option to start routes from the user's current GPS position
- **Visual Route Display**: Optimized routes shown with green polylines on the map
- **Real-time Optimization**: Calculate optimal route order in real-time

### 📍 **Map Visualization**
- **Pool Markers**: Each pool displayed with custom markers and info windows
- **Route Polylines**: Visual connection between pools showing the optimized path
- **User Location Marker**: Green marker showing user's starting position (when enabled)
- **Interactive Controls**: Toggle between original and optimized route views

### 🎯 **User Interface**
- **Optimization Controls**: Panel with user location toggle and optimize button
- **Status Updates**: Real-time feedback during route optimization
- **Address Panel**: Toggleable list of all pool addresses in optimized order
- **Map Centering**: Click to center map on specific pools

## How to Use

### 1. **Access Route Map**
- Navigate to any route in the routes list
- Click the map icon to open the route map screen

### 2. **Configure Optimization Settings**
- **Use User Location**: Check the box to start from your current GPS position
- **Optimize Route**: Click the "Optimize Route" button to calculate the best route

### 3. **View Results**
- **Optimized Route**: Green polyline shows the most efficient path
- **Updated Markers**: Pool markers show the new visit order
- **Address Panel**: Toggle to see all addresses in optimized order

## Technical Implementation

### **Dependencies**
```yaml
http: ^1.1.0  # For Google Maps API calls
geolocator: ^14.0.2  # For user location
google_maps_flutter: ^2.5.0  # For map display
```

### **Key Components**

#### **RouteMapScreen** (`lib/features/routes/screens/route_map_screen.dart`)
- Main screen for route visualization and optimization
- Handles Google Maps Directions API integration
- Manages user location and route optimization

#### **LocationService** (`lib/core/services/location_service.dart`)
- Provides user GPS location functionality
- Handles location permissions and accuracy settings
- Converts coordinates for map display

### **API Integration**

#### **Google Maps Directions API**
```dart
// Example API call for route optimization
final url = Uri.parse(
  'https://maps.googleapis.com/maps/api/directions/json?'
  'origin=$originStr&'
  'destination=$originStr&'
  'waypoints=optimize:true|$waypointsStr&'
  'key=$_googleMapsApiKey'
);
```

#### **Route Optimization Process**
1. **Get User Location** (if enabled)
2. **Prepare Waypoints** from pool coordinates
3. **Call Google Maps API** with optimization flag
4. **Decode Response** to get optimized route
5. **Update UI** with new route order and polylines

### **Polyline Decoding**
The app includes a custom polyline decoder to convert Google's encoded polyline format to map coordinates:

```dart
List<LatLng> _decodePolyline(String encoded) {
  // Decodes Google's polyline format to LatLng coordinates
  // Used for displaying the optimized route path
}
```

## Configuration

### **Google Maps API Key**
The route optimization feature requires a valid Google Maps API key with the following APIs enabled:
- **Directions API**: For route optimization
- **Maps JavaScript API**: For web map display
- **Geocoding API**: For address-to-coordinate conversion

### **API Key Setup**
1. Create a Google Cloud Project
2. Enable the required APIs
3. Create API credentials
4. Add the API key to the app configuration

## User Experience

### **Before Optimization**
- Pools displayed in original document order
- Straight-line connections between pools
- Blue polyline showing basic route

### **After Optimization**
- Pools reordered for maximum efficiency
- Curved route following actual roads
- Green polyline showing optimized path
- User location marker (if enabled)

### **Status Messages**
- "Getting user location..." - Retrieving GPS position
- "Calculating optimized route..." - Processing with Google Maps API
- "Route optimized successfully!" - Optimization complete
- Error messages for troubleshooting

## Benefits

### **For Pool Maintenance Companies**
- **Time Savings**: Optimized routes reduce travel time
- **Fuel Efficiency**: Shorter routes mean lower fuel costs
- **Better Planning**: Visual route optimization for daily planning
- **Customer Service**: More efficient service delivery

### **For Workers**
- **Easier Navigation**: Clear visual route with turn-by-turn directions
- **Time Management**: Optimized order reduces travel time
- **Professional Service**: Efficient route execution

## Troubleshooting

### **Common Issues**

#### **Location Permission Denied**
- **Solution**: Grant location permissions in app settings
- **Fallback**: Route will start from first pool instead

#### **API Key Issues**
- **Solution**: Verify Google Maps API key is valid and has required permissions
- **Fallback**: Route will display in original order

#### **Network Connectivity**
- **Solution**: Check internet connection
- **Fallback**: Route optimization will fail gracefully

#### **No Pools in Route**
- **Solution**: Ensure route contains at least one pool
- **Fallback**: Map will show default location

### **Error Handling**
The app includes comprehensive error handling:
- Graceful fallbacks when optimization fails
- User-friendly error messages
- Automatic retry mechanisms
- Fallback to original route order

## Future Enhancements

### **Planned Features**
- **Offline Route Optimization**: Local optimization when API unavailable
- **Multiple Route Types**: Different optimization strategies (fastest, shortest, etc.)
- **Traffic Integration**: Real-time traffic consideration
- **Route Sharing**: Share optimized routes with team members
- **Historical Optimization**: Learn from past route performance

### **Advanced Features**
- **AI-Powered Optimization**: Machine learning for route improvement
- **Predictive Maintenance**: Route optimization based on maintenance schedules
- **Weather Integration**: Weather-aware route planning
- **Multi-Vehicle Optimization**: Coordinate multiple workers on different routes

## Support

For technical support or questions about route optimization:
- Check the troubleshooting section above
- Review Google Maps API documentation
- Contact the development team for assistance

---

**Last Updated**: June 2025  
**Version**: 1.6.0  
**Status**: Production Ready 