import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

/// Service for location-based voting features
class LocationVotingService {
  static LocationVotingService? _instance;
  static LocationVotingService get instance =>
      _instance ??= LocationVotingService._();

  LocationVotingService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  /// Check location permissions
  Future<bool> checkLocationPermission() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return false;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return false;
      }

      return true;
    } catch (e) {
      debugPrint('Check location permission error: $e');
      return false;
    }
  }

  /// Get current device location
  Future<Position?> getCurrentLocation() async {
    try {
      final hasPermission = await checkLocationPermission();
      if (!hasPermission) return null;

      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 100,
        ),
      );
    } catch (e) {
      debugPrint('Get current location error: $e');
      return null;
    }
  }

  /// Get nearby elections based on location
  Future<List<Map<String, dynamic>>> getNearbyElections({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    try {
      // Query elections with location data within radius
      final response = await _client
          .from('elections')
          .select('*, election_locations(*)')
          .eq('status', 'active')
          .order('created_at', ascending: false);

      final elections = List<Map<String, dynamic>>.from(response);

      // Filter by distance
      final nearbyElections = elections.where((election) {
        final locations = election['election_locations'] as List?;
        if (locations == null || locations.isEmpty) return false;

        for (var location in locations) {
          final electionLat = location['latitude'] as double?;
          final electionLon = location['longitude'] as double?;
          if (electionLat == null || electionLon == null) continue;

          final distance =
              Geolocator.distanceBetween(
                latitude,
                longitude,
                electionLat,
                electionLon,
              ) /
              1000; // Convert to km

          if (distance <= radiusKm) return true;
        }
        return false;
      }).toList();

      return nearbyElections;
    } catch (e) {
      debugPrint('Get nearby elections error: $e');
      return [];
    }
  }

  /// Get regional participation statistics
  Future<Map<String, dynamic>> getRegionalStats({
    required double latitude,
    required double longitude,
    double radiusKm = 50.0,
  }) async {
    try {
      final nearbyElections = await getNearbyElections(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      int totalVotes = 0;
      int totalElections = nearbyElections.length;
      int activeVoters = 0;

      for (var election in nearbyElections) {
        final electionId = election['id'] as String;
        final votes = await _client
            .from('votes')
            .select('id')
            .eq('election_id', electionId);
        totalVotes += votes.length;
      }

      // Get unique voters in region
      if (totalElections > 0) {
        final voters = await _client
            .from('votes')
            .select('user_id')
            .inFilter(
              'election_id',
              nearbyElections.map((e) => e['id']).toList(),
            );
        activeVoters = voters.map((v) => v['user_id']).toSet().length;
      }

      return {
        'total_elections': totalElections,
        'total_votes': totalVotes,
        'active_voters': activeVoters,
        'average_participation': totalElections > 0
            ? (totalVotes / totalElections).round()
            : 0,
        'radius_km': radiusKm,
      };
    } catch (e) {
      debugPrint('Get regional stats error: $e');
      return {
        'total_elections': 0,
        'total_votes': 0,
        'active_voters': 0,
        'average_participation': 0,
        'radius_km': radiusKm,
      };
    }
  }

  /// Get location-filtered elections by category
  Future<List<Map<String, dynamic>>> getLocationFilteredElections({
    required double latitude,
    required double longitude,
    String? category,
    double radiusKm = 50.0,
    int limit = 50,
  }) async {
    try {
      var nearbyElections = await getNearbyElections(
        latitude: latitude,
        longitude: longitude,
        radiusKm: radiusKm,
      );

      if (category != null) {
        nearbyElections = nearbyElections
            .where((e) => e['category'] == category)
            .toList();
      }

      // Sort by distance
      nearbyElections.sort((a, b) {
        final aLocations = a['election_locations'] as List;
        final bLocations = b['election_locations'] as List;

        if (aLocations.isEmpty || bLocations.isEmpty) return 0;

        final aLat = aLocations.first['latitude'] as double;
        final aLon = aLocations.first['longitude'] as double;
        final bLat = bLocations.first['latitude'] as double;
        final bLon = bLocations.first['longitude'] as double;

        final distanceA = Geolocator.distanceBetween(
          latitude,
          longitude,
          aLat,
          aLon,
        );
        final distanceB = Geolocator.distanceBetween(
          latitude,
          longitude,
          bLat,
          bLon,
        );

        return distanceA.compareTo(distanceB);
      });

      return nearbyElections.take(limit).toList();
    } catch (e) {
      debugPrint('Get location filtered elections error: $e');
      return [];
    }
  }

  /// Calculate distance to election location
  double calculateDistance({
    required double fromLat,
    required double fromLon,
    required double toLat,
    required double toLon,
  }) {
    return Geolocator.distanceBetween(fromLat, fromLon, toLat, toLon) /
        1000; // km
  }

  /// Get location name from coordinates (reverse geocoding)
  Future<String> getLocationName(double latitude, double longitude) async {
    try {
      // Simplified implementation without geocoding package
      return 'Location: ${latitude.toStringAsFixed(2)}, ${longitude.toStringAsFixed(2)}';
    } catch (e) {
      debugPrint('Get location name error: $e');
      return 'Unknown Location';
    }
  }
}
