# Map Integration Guide

This document describes the map integration features in the Shinning Pools application, including pool selection, maintenance status visualization, and route management.

## Overview

The application includes several map components that provide different functionalities:

1. **CompanyPoolsMap** - Displays all company pools with maintenance status
2. **MaintenancePoolsMap** - Enhanced pool selection for maintenance tasks
3. **RouteMaintenanceMapScreen** - Route visualization with maintenance status

## Map Components

### 1. CompanyPoolsMap

**Location**: `lib/shared/ui/widgets/company_pools_map.dart`

**Purpose**: Displays all company pools on a map with maintenance status indicators.

**Features**:
- Red pinpoints for pools needing maintenance
- Green pinpoints for maintained pools
- Green flag for user location
- Real-time data from PoolService
- Fallback to mock data when no real pools available
- Interactive pool selection

**Usage**:
```dart
CompanyPoolsMap(
  height: 400,
  interactive: true,
  onPoolSelected: (pool) {
    // Handle pool selection
  },
)
```

**Integration**: Used in Company Dashboard → Pools Tab

### 2. MaintenancePoolsMap

**Location**: `lib/shared/ui/widgets/maintenance_pools_map.dart`

**Purpose**: Enhanced pool selection specifically for maintenance tasks.

**Features**:
- Maintenance status indicators (red/green pinpoints)
- Pool selection functionality
- User location tracking
- Asset-based pinpoint icons (@red.png, @green.png)
- Real-time updates from PoolService
- Configurable maintenance status display

**Usage**:
```dart
MaintenancePoolsMap(
  height: 400,
  interactive: true,
  showMaintenanceStatus: true,
  onPoolSelected: (pool) {
    // Handle pool selection for maintenance
  },
)
```

**Integration**: Used in Maintenance Form → Pool Selection

### 3. RouteMaintenanceMapScreen

**Location**: `lib/features/routes/screens/route_maintenance_map_screen.dart`

**Purpose**: Displays route information with pool maintenance status.

**Features**:
- Route visualization with polylines
- Pool markers with maintenance status
- Route optimization
- Address geocoding
- User location integration

## Pinpoint System

### Asset Icons

The application uses specific asset icons for different map markers:

- **@red.png** - Pools needing maintenance
- **@green.png** - Maintained pools
- **@user_marker.png** - User location

### Maintenance Status Logic

Pools are considered "maintained" if:
- Last maintenance was performed within 30 days
- Maintenance date is properly recorded in the database

Pools are marked as "needs maintenance" if:
- No maintenance record exists
- Last maintenance was more than 30 days ago

## Integration Points

### 1. Pool Selection in Maintenance Form

The maintenance form now uses `MaintenancePoolsMap` for pool selection:

```dart
// In maintenance_form_screen.dart
if (_poolSelectionMethod == 'map') ...[
  SizedBox(
    height: 400,
    child: MaintenancePoolsMap(
      height: 400,
      interactive: true,
      showMaintenanceStatus: true,
      onPoolSelected: (pool) {
        _selectPool({
          'id': pool.id,
          'name': pool.name,
          'address': pool.address,
          'latitude': pool.latitude,
          'longitude': pool.longitude,
        });
      },
    ),
  ),
],
```

### 2. Company Dashboard Integration

The company dashboard displays all pools with maintenance status:

```dart
// In company_dashboard.dart
Container(
  height: 300,
  margin: const EdgeInsets.symmetric(horizontal: 16),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(12),
    child: CompanyPoolsMap(
      height: 300,
      interactive: true,
      onPoolSelected: (pool) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PoolDetailsScreen(poolId: pool['id']),
          ),
        );
      },
    ),
  ),
),
```

## Data Flow

### 1. Pool Data Loading

1. **PoolService** provides real-time pool data
2. **MaintenancePoolsMap** listens to PoolService changes
3. **CompanyPoolsMap** loads pools and determines maintenance status
4. **Fallback** to mock data if no real pools available

### 2. Maintenance Status Calculation

```dart
bool _isPoolMaintained(dynamic lastMaintenanceDate) {
  if (lastMaintenanceDate == null) return false;
  
  try {
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
      return daysSinceMaintenance <= 30;
    }
  } catch (e) {
    print('⚠️ Error parsing maintenance date: $e');
  }
  
  return false;
}
```

## Testing

### Test Files

1. **test/simple_map_test.dart** - Tests CompanyPoolsMap with mock data
2. **test/map_integration_test.dart** - Tests map integration with PoolService
3. **test/maintenance_map_test.dart** - Tests MaintenancePoolsMap functionality

### Running Tests

```bash
# Test company pools map
flutter run -d chrome test/simple_map_test.dart

# Test map integration
flutter run -d chrome test/map_integration_test.dart

# Test maintenance map
flutter run -d chrome test/maintenance_map_test.dart
```

## Configuration

### Google Maps API

The application requires a Google Maps API key configured in:
- `web/index.html` for web builds
- `android/app/src/main/AndroidManifest.xml` for Android builds
- `ios/Runner/AppDelegate.swift` for iOS builds

### Asset Configuration

Ensure the following assets are available:
```
assets/img/
├── red.png          # Red pinpoint for maintenance needed
├── green.png        # Green pinpoint for maintained pools
└── user_marker.png  # User location flag
```

## Best Practices

1. **Always provide fallback data** when real data is unavailable
2. **Use asset-based icons** for consistent visual appearance
3. **Implement proper error handling** for geocoding failures
4. **Listen to service changes** for real-time updates
5. **Provide loading states** during map initialization

## Troubleshooting

### Common Issues

1. **No pinpoints visible**: Check if PoolService is properly initialized
2. **Geocoding errors**: Verify address format and API key configuration
3. **Asset loading failures**: Ensure asset files are properly configured
4. **Provider errors**: Verify all required providers are in the widget tree

### Debug Logging

The map components include extensive debug logging. Check the console for:
- Pool loading status
- Geocoding results
- Marker creation
- Service initialization

## Future Enhancements

1. **Route optimization** for maintenance tasks
2. **Clustering** for large numbers of pools
3. **Offline support** with cached map data
4. **Custom map styles** for different use cases
5. **Real-time location tracking** for workers 