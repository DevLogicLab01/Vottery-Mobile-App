import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

class IPGeolocationService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static const String API_URL = 'https://ipapi.co/json/';

  /// Validates user location and checks if country is enabled
  static Future<Map<String, dynamic>> validateUserLocation() async {
    try {
      // Get IP-based location
      final locationData = await _getIPLocation();
      final String countryCode = locationData['country_code'] ?? 'UNKNOWN';
      final String countryName = locationData['country_name'] ?? 'Unknown';
      final String ipAddress = locationData['ip'] ?? 'Unknown';
      final double? latitude = locationData['latitude'];
      final double? longitude = locationData['longitude'];

      // Check if country is enabled in database
      final countryRestriction = await _supabase
          .from('country_restrictions')
          .select()
          .eq('country_code', countryCode)
          .maybeSingle();

      bool isEnabled = true;
      String? blockedReason;

      if (countryRestriction != null) {
        isEnabled = countryRestriction['is_enabled'] ?? true;
        blockedReason = countryRestriction['blocked_reason'];
      }

      // Log access attempt
      await _logAccessAttempt(
        countryCode: countryCode,
        countryName: countryName,
        ipAddress: ipAddress,
        latitude: latitude,
        longitude: longitude,
        accessGranted: isEnabled,
        blockedReason: blockedReason,
      );

      return {
        'allowed': isEnabled,
        'country_code': countryCode,
        'country_name': countryName,
        'ip_address': ipAddress,
        'blocked_reason': blockedReason,
      };
    } catch (e) {
      if (kDebugMode) {
        print('IP Geolocation validation error: $e');
      }
      // In case of error, allow access (fail-open for better UX)
      return {
        'allowed': true,
        'country_code': 'UNKNOWN',
        'country_name': 'Unknown',
        'error': e.toString(),
      };
    }
  }

  /// Get IP-based location using ipapi.co (free, no API key required)
  static Future<Map<String, dynamic>> _getIPLocation() async {
    try {
      final response = await http
          .get(Uri.parse(API_URL))
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'country_code': data['country_code'],
          'country_name': data['country_name'],
          'ip': data['ip'],
          'latitude': data['latitude'],
          'longitude': data['longitude'],
          'city': data['city'],
          'region': data['region'],
        };
      } else {
        throw Exception('Failed to fetch IP location: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) {
        print('IP location fetch error: $e');
      }
      rethrow;
    }
  }

  /// Log access attempt to database
  static Future<void> _logAccessAttempt({
    required String countryCode,
    required String countryName,
    required String ipAddress,
    double? latitude,
    double? longitude,
    required bool accessGranted,
    String? blockedReason,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      await _supabase.from('access_logs').insert({
        'user_id': userId,
        'country_code': countryCode,
        'country_name': countryName,
        'ip_address': ipAddress,
        'latitude': latitude,
        'longitude': longitude,
        'access_granted': accessGranted,
        'blocked_reason': blockedReason,
        'device_info': kIsWeb ? 'Web' : 'Mobile',
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      if (kDebugMode) {
        print('Failed to log access attempt: $e');
      }
    }
  }

  /// Get device GPS location (mobile only, optional)
  static Future<Position?> getDeviceLocation() async {
    if (kIsWeb) return null;

    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
    } catch (e) {
      if (kDebugMode) {
        print('Device location error: $e');
      }
      return null;
    }
  }

  /// Get all access logs (admin only)
  static Future<List<Map<String, dynamic>>> getAccessLogs({
    int limit = 100,
    String? countryCode,
    bool? accessGranted,
  }) async {
    try {
      var query = _supabase
          .from('access_logs')
          .select('*, user_profiles(email, username)');

      if (countryCode != null) {
        query = query.eq('country_code', countryCode);
      }

      if (accessGranted != null) {
        query = query.eq('access_granted', accessGranted);
      }

      final response = await query
          .order('timestamp', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch access logs: $e');
      }
      return [];
    }
  }

  /// Get country restrictions list
  static Future<List<Map<String, dynamic>>> getCountryRestrictions() async {
    try {
      final response = await _supabase
          .from('country_restrictions')
          .select()
          .order('country_name', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch country restrictions: $e');
      }
      return [];
    }
  }

  /// Update country restriction status (admin only)
  static Future<bool> updateCountryRestriction({
    required String countryCode,
    required bool isEnabled,
    String? blockedReason,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      await _supabase
          .from('country_restrictions')
          .update({
            'is_enabled': isEnabled,
            'blocked_reason': blockedReason,
            'last_modified_by': userId,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('country_code', countryCode);

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to update country restriction: $e');
      }
      return false;
    }
  }

  /// Bulk update country restrictions
  static Future<bool> bulkUpdateCountryRestrictions({
    required List<String> countryCodes,
    required bool isEnabled,
    String? blockedReason,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      for (String countryCode in countryCodes) {
        await _supabase
            .from('country_restrictions')
            .update({
              'is_enabled': isEnabled,
              'blocked_reason': blockedReason,
              'last_modified_by': userId,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('country_code', countryCode);
      }

      return true;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to bulk update country restrictions: $e');
      }
      return false;
    }
  }

  /// Get access statistics by country
  static Future<Map<String, dynamic>> getAccessStatistics() async {
    try {
      final response = await _supabase
          .from('access_logs')
          .select('country_code, country_name, access_granted');

      final stats = <String, Map<String, dynamic>>{};

      for (var log in response) {
        final countryCode = log['country_code'] as String;
        if (!stats.containsKey(countryCode)) {
          stats[countryCode] = {
            'country_name': log['country_name'],
            'total_attempts': 0,
            'granted': 0,
            'blocked': 0,
          };
        }

        stats[countryCode]!['total_attempts'] =
            (stats[countryCode]!['total_attempts'] as int) + 1;

        if (log['access_granted'] == true) {
          stats[countryCode]!['granted'] =
              (stats[countryCode]!['granted'] as int) + 1;
        } else {
          stats[countryCode]!['blocked'] =
              (stats[countryCode]!['blocked'] as int) + 1;
        }
      }

      return stats;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch access statistics: $e');
      }
      return {};
    }
  }
}
