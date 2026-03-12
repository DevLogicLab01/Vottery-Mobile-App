import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class GoogleAnalyticsIntegrationService {
  final SupabaseClient _supabase = Supabase.instance.client;

  static const String _measurementId = String.fromEnvironment(
    'GA4_MEASUREMENT_ID',
  );
  static const String _apiSecret = String.fromEnvironment('GA4_API_SECRET');

  // Track custom events
  Future<void> trackEvent({
    required String eventName,
    required Map<String, dynamic> parameters,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;

      // Store event locally
      await _supabase.from('google_analytics_events').insert({
        'user_id': userId,
        'event_name': eventName,
        'event_parameters': parameters,
        'timestamp': DateTime.now().toIso8601String(),
        'synced_to_ga4': false,
      });

      // Send to GA4 via Measurement Protocol
      if (_measurementId.isNotEmpty && _apiSecret.isNotEmpty) {
        await _sendToGA4(eventName, parameters, userId);
      }
    } catch (e) {
      if (kDebugMode) print('Error tracking event: $e');
    }
  }

  Future<void> _sendToGA4(
    String eventName,
    Map<String, dynamic> params,
    String? userId,
  ) async {
    // GA4 Measurement Protocol implementation
    // This would send events to GA4 in production
  }

  // Track screen views
  Future<void> trackScreenView(String screenName) async {
    await trackEvent(
      eventName: 'screen_view',
      parameters: {'screen_name': screenName},
    );
  }

  // Set user properties
  Future<void> setUserProperty(String propertyName, String value) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return;

      await _supabase
          .from('user_profiles')
          .update({
            'analytics_properties': {propertyName: value},
          })
          .eq('id', userId);
    } catch (e) {
      if (kDebugMode) print('Error setting user property: $e');
    }
  }

  // Track conversions
  Future<void> trackConversion(String conversionName, {double? value}) async {
    await trackEvent(
      eventName: conversionName,
      parameters: {
        'conversion_name': conversionName,
        if (value != null) 'value': value,
      },
    );
  }

  // Track ecommerce events
  Future<void> trackPurchase({
    required String transactionId,
    required double value,
    required String currency,
    required List<Map<String, dynamic>> items,
  }) async {
    await trackEvent(
      eventName: 'purchase',
      parameters: {
        'transaction_id': transactionId,
        'value': value,
        'currency': currency,
        'items': items,
      },
    );
  }

  // Get analytics data
  Future<Map<String, dynamic>> getAnalyticsOverview() async {
    try {
      final response = await _supabase
          .from('google_analytics_events')
          .select('event_name, event_parameters, timestamp')
          .order('timestamp', ascending: false)
          .limit(100);

      return {
        'total_events': response.length,
        'recent_events': response,
        'synced_count': response
            .where((e) => e['synced_to_ga4'] == true)
            .length,
      };
    } catch (e) {
      if (kDebugMode) print('Error getting analytics: $e');
      return {};
    }
  }

  // Get real-time metrics
  Stream<List<Map<String, dynamic>>> getRealTimeEvents() {
    return _supabase
        .from('google_analytics_events')
        .stream(primaryKey: ['event_id'])
        .order('timestamp', ascending: false)
        .limit(50);
  }
}
