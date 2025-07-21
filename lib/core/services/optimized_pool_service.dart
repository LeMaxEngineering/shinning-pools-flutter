import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/geocoding_result.dart';
import 'geocoding_service.dart';

class OptimizedPoolService {
  static final OptimizedPoolService _instance = OptimizedPoolService._internal();
  factory OptimizedPoolService() => _instance;
  OptimizedPoolService._internal();

  // Cache for geocoded addresses
  final Map<String, GeocodingResult> _geocodingCache = {};
  
  // Cache for maintenance status
  final Map<String, Map<String, bool>> _maintenanceCache = {};
  
  // Cache for pool data
  final Map<String, List<Map<String, dynamic>>> _poolCache = {};
  
  // Cache timestamp for invalidation
  final Map<String, DateTime> _cacheTimestamps = {};
  
  // Cache duration (5 minutes)
  static const Duration _cacheDuration = Duration(minutes: 5);

  /// Get company pools with caching
  Future<List<Map<String, dynamic>>> getCompanyPoolsWithCache(String companyId) async {
    final cacheKey = 'pools_$companyId';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      print('📦 Using cached pools for company: $companyId');
      return _poolCache[cacheKey]!;
    }

    try {
      print('🔄 Loading fresh pools for company: $companyId');
      final querySnapshot = await FirebaseFirestore.instance
          .collection('pools')
          .where('companyId', isEqualTo: companyId)
          .get();

      final pools = querySnapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();

      // Cache the results
      _poolCache[cacheKey] = pools;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      print('✅ Loaded and cached ${pools.length} pools for company: $companyId');
      return pools;
    } catch (e) {
      print('❌ Error loading pools for company $companyId: $e');
      return [];
    }
  }

  /// Get maintenance status for multiple pools in batch
  Future<Map<String, bool>> getMaintenanceStatusBatch(
    List<String> poolIds, 
    DateTime targetDate
  ) async {
    final cacheKey = 'maintenance_${targetDate.toIso8601String().split('T')[0]}';
    
    // Check cache first
    if (_isCacheValid(cacheKey)) {
      print('📦 Using cached maintenance status for date: ${targetDate.toIso8601String().split('T')[0]}');
      return _maintenanceCache[cacheKey]!;
    }

    try {
      print('🔄 Loading fresh maintenance status for ${poolIds.length} pools');
      
      // Create date range for the target date
      final startOfDay = DateTime(targetDate.year, targetDate.month, targetDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1)).subtract(const Duration(milliseconds: 1));
      
      // Batch query for all pools
      final querySnapshot = await FirebaseFirestore.instance
          .collection('maintenanceRecords')
          .where('poolId', whereIn: poolIds)
          .where('date', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('date', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('status', isEqualTo: 'Completed')
          .get();

      // Create maintenance status map
      final maintenanceStatus = <String, bool>{};
      for (final poolId in poolIds) {
        maintenanceStatus[poolId] = false;
      }
      
      // Mark maintained pools
      for (final doc in querySnapshot.docs) {
        final data = doc.data();
        final poolId = data['poolId'] as String?;
        if (poolId != null) {
          maintenanceStatus[poolId] = true;
        }
      }

      // Cache the results
      _maintenanceCache[cacheKey] = maintenanceStatus;
      _cacheTimestamps[cacheKey] = DateTime.now();
      
      print('✅ Loaded and cached maintenance status for ${poolIds.length} pools');
      return maintenanceStatus;
    } catch (e) {
      print('❌ Error loading maintenance status: $e');
      // Return default status (all false) on error
      return {for (final poolId in poolIds) poolId: false};
    }
  }

  /// Geocode address with caching
  Future<Map<String, dynamic>?> geocodeAddressWithCache(String address) async {
    // Check cache first
    if (_geocodingCache.containsKey(address)) {
      print('📦 Using cached geocoding for: $address');
      return {
        'latitude': _geocodingCache[address]!.coordinates.latitude,
        'longitude': _geocodingCache[address]!.coordinates.longitude,
        'formattedAddress': _geocodingCache[address]!.formattedAddress,
      };
    }

    try {
      print('🔄 Geocoding address: $address');
      final geocodingService = GeocodingService();
      final result = await geocodingService.geocodeAddress(address);
      
      if (result != null) {
        // Cache the result
        _geocodingCache[address] = result;
        print('✅ Cached geocoding result for: $address');
        
        return {
          'latitude': result.coordinates.latitude,
          'longitude': result.coordinates.longitude,
          'formattedAddress': result.formattedAddress,
        };
      }
      
      return null;
    } catch (e) {
      print('❌ Error geocoding address $address: $e');
      return null;
    }
  }

  /// Batch geocode multiple addresses
  Future<Map<String, Map<String, dynamic>>> geocodeAddressesBatch(List<String> addresses) async {
    final results = <String, Map<String, dynamic>>{};
    
    // Process in batches of 5 to avoid rate limiting
    const batchSize = 5;
    for (int i = 0; i < addresses.length; i += batchSize) {
      final batch = addresses.skip(i).take(batchSize).toList();
      
      // Process batch concurrently
      final batchResults = await Future.wait(
        batch.map((address) => geocodeAddressWithCache(address))
      );
      
      // Add results to map
      for (int j = 0; j < batch.length; j++) {
        final address = batch[j];
        final result = batchResults[j];
        if (result != null) {
          results[address] = result;
        }
      }
      
      // Small delay between batches to avoid rate limiting
      if (i + batchSize < addresses.length) {
        await Future.delayed(const Duration(milliseconds: 200));
      }
    }
    
    return results;
  }

  /// Clear cache for specific company or all cache
  void clearCache([String? companyId]) {
    if (companyId != null) {
      final cacheKey = 'pools_$companyId';
      _poolCache.remove(cacheKey);
      _cacheTimestamps.remove(cacheKey);
      print('🗑️ Cleared cache for company: $companyId');
    } else {
      _poolCache.clear();
      _maintenanceCache.clear();
      _geocodingCache.clear();
      _cacheTimestamps.clear();
      print('🗑️ Cleared all cache');
    }
  }

  /// Check if cache is still valid
  bool _isCacheValid(String cacheKey) {
    final timestamp = _cacheTimestamps[cacheKey];
    if (timestamp == null) return false;
    
    final isValid = DateTime.now().difference(timestamp) < _cacheDuration;
    if (!isValid) {
      print('⏰ Cache expired for key: $cacheKey');
    }
    return isValid;
  }

  /// Get cache statistics for debugging
  Map<String, dynamic> getCacheStats() {
    return {
      'poolCacheSize': _poolCache.length,
      'maintenanceCacheSize': _maintenanceCache.length,
      'geocodingCacheSize': _geocodingCache.length,
      'totalCacheEntries': _cacheTimestamps.length,
    };
  }
} 