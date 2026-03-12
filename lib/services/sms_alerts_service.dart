import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';
import './twilio_notification_service.dart';

class SmsAlertsService {
  static SmsAlertsService? _instance;
  static SmsAlertsService get instance => _instance ??= SmsAlertsService._();

  SmsAlertsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;
  TwilioNotificationService get _twilio => TwilioNotificationService.instance;

  // =====================================================
  // EMERGENCY CONTACTS MANAGEMENT
  // =====================================================

  Future<List<Map<String, dynamic>>> getEmergencyContacts() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('sms_emergency_contacts')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .order('priority', ascending: true)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get emergency contacts error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createEmergencyContact({
    required String contactName,
    required String phoneNumber,
    required String countryCode,
    required String priority,
    String coverageHours = '24/7',
    Map<String, dynamic>? notificationPreferences,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final response = await _client
          .from('sms_emergency_contacts')
          .insert({
            'user_id': _auth.currentUser!.id,
            'contact_name': contactName,
            'phone_number': phoneNumber,
            'country_code': countryCode,
            'priority': priority,
            'coverage_hours': coverageHours,
            'notification_preferences': notificationPreferences ?? {},
          })
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('Create emergency contact error: $e');
      rethrow;
    }
  }

  Future<bool> updateEmergencyContact({
    required String contactId,
    String? contactName,
    String? phoneNumber,
    String? countryCode,
    String? priority,
    String? coverageHours,
    bool? isActive,
  }) async {
    try {
      final updates = <String, dynamic>{};

      if (contactName != null) updates['contact_name'] = contactName;
      if (phoneNumber != null) updates['phone_number'] = phoneNumber;
      if (countryCode != null) updates['country_code'] = countryCode;
      if (priority != null) updates['priority'] = priority;
      if (coverageHours != null) updates['coverage_hours'] = coverageHours;
      if (isActive != null) updates['is_active'] = isActive;

      if (updates.isEmpty) return false;

      updates['updated_at'] = DateTime.now().toIso8601String();

      await _client
          .from('sms_emergency_contacts')
          .update(updates)
          .eq('id', contactId);

      return true;
    } catch (e) {
      debugPrint('Update emergency contact error: $e');
      return false;
    }
  }

  Future<bool> deleteEmergencyContact(String contactId) async {
    try {
      await _client.from('sms_emergency_contacts').delete().eq('id', contactId);
      return true;
    } catch (e) {
      debugPrint('Delete emergency contact error: $e');
      return false;
    }
  }

  // =====================================================
  // MESSAGE TEMPLATES MANAGEMENT
  // =====================================================

  Future<List<Map<String, dynamic>>> getMessageTemplates({
    String? alertType,
  }) async {
    try {
      var query = _client.from('sms_message_templates').select();

      if (alertType != null) {
        query = query.eq('alert_type', alertType);
      }

      final response = await query
          .eq('is_active', true)
          .order('usage_count', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get message templates error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> createMessageTemplate({
    required String templateName,
    required String alertType,
    required String messageTemplate,
    List<String>? variables,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final response = await _client
          .from('sms_message_templates')
          .insert({
            'template_name': templateName,
            'alert_type': alertType,
            'message_template': messageTemplate,
            'variables': variables ?? [],
            'created_by': _auth.currentUser!.id,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('Create message template error: $e');
      rethrow;
    }
  }

  // =====================================================
  // SMS DELIVERY TRACKING
  // =====================================================

  Future<List<Map<String, dynamic>>> getDeliveryHistory({
    String? alertType,
    String? deliveryStatus,
    int limit = 50,
  }) async {
    try {
      var query = _client.from('sms_delivery_tracking').select();

      if (alertType != null) {
        query = query.eq('alert_type', alertType);
      }

      if (deliveryStatus != null) {
        query = query.eq('delivery_status', deliveryStatus);
      }

      final response = await query
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get delivery history error: $e');
      return [];
    }
  }

  // =====================================================
  // SMS DELIVERY ANALYTICS
  // =====================================================

  /// Get comprehensive delivery analytics
  Future<Map<String, dynamic>> getDeliveryAnalytics({
    String? provider,
    int days = 7,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      var query = _client
          .from('sms_delivery_log')
          .select('provider_used, delivery_status, sent_at, delivered_at')
          .gte('sent_at', startDate.toIso8601String());

      if (provider != null) {
        query = query.eq('provider_used', provider);
      }

      final response = await query;
      final logs = List<Map<String, dynamic>>.from(response);

      // Calculate metrics
      final totalSent = logs.length;
      final delivered = logs
          .where((l) => l['delivery_status'] == 'delivered')
          .length;
      final failed = logs.where((l) => l['delivery_status'] == 'failed').length;
      final bounced = logs
          .where((l) => l['delivery_status'] == 'bounced')
          .length;

      final deliveryRate = totalSent > 0 ? (delivered / totalSent * 100) : 0.0;
      final bounceRate = totalSent > 0 ? (bounced / totalSent * 100) : 0.0;

      // Calculate average latency
      final deliveredLogs = logs.where(
        (l) =>
            l['delivery_status'] == 'delivered' &&
            l['sent_at'] != null &&
            l['delivered_at'] != null,
      );

      int totalLatency = 0;
      for (final log in deliveredLogs) {
        final sentAt = DateTime.parse(log['sent_at'] as String);
        final deliveredAt = DateTime.parse(log['delivered_at'] as String);
        totalLatency += deliveredAt.difference(sentAt).inMilliseconds;
      }

      final avgLatency = deliveredLogs.isNotEmpty
          ? (totalLatency / deliveredLogs.length).round()
          : 0;

      return {
        'total_sent': totalSent,
        'delivered': delivered,
        'failed': failed,
        'bounced': bounced,
        'delivery_rate': deliveryRate.toStringAsFixed(2),
        'bounce_rate': bounceRate.toStringAsFixed(2),
        'avg_latency_ms': avgLatency,
      };
    } catch (e) {
      debugPrint('Get delivery analytics error: $e');
      return {};
    }
  }

  /// Get provider comparison analytics
  Future<Map<String, dynamic>> getProviderComparison({int days = 7}) async {
    try {
      final telnyxStats = await getDeliveryAnalytics(
        provider: 'telnyx',
        days: days,
      );
      final twilioStats = await getDeliveryAnalytics(
        provider: 'twilio',
        days: days,
      );

      return {'telnyx': telnyxStats, 'twilio': twilioStats};
    } catch (e) {
      debugPrint('Get provider comparison error: $e');
      return {};
    }
  }

  /// Get bounce analysis
  Future<Map<String, dynamic>> getBounceAnalysis() async {
    try {
      final response = await _client
          .from('sms_bounce_list')
          .select('bounce_type')
          .eq('is_suppressed', true);

      final bounces = List<Map<String, dynamic>>.from(response);

      final bounceBreakdown = <String, int>{};
      for (final bounce in bounces) {
        final type = bounce['bounce_type'] as String? ?? 'unknown';
        bounceBreakdown[type] = (bounceBreakdown[type] ?? 0) + 1;
      }

      return {'total_bounced': bounces.length, 'breakdown': bounceBreakdown};
    } catch (e) {
      debugPrint('Get bounce analysis error: $e');
      return {};
    }
  }

  /// Get failover frequency
  Future<Map<String, dynamic>> getFailoverFrequency({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _client
          .from('provider_failover_log')
          .select('from_provider, to_provider, failed_at')
          .gte('failed_at', startDate.toIso8601String())
          .order('failed_at', ascending: false);

      final failovers = List<Map<String, dynamic>>.from(response);

      return {
        'total_failovers': failovers.length,
        'failover_events': failovers,
      };
    } catch (e) {
      debugPrint('Get failover frequency error: $e');
      return {};
    }
  }

  /// Get delivery trends over time
  Future<List<Map<String, dynamic>>> getDeliveryTrends({
    String? provider,
    int days = 7,
  }) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      var query = _client
          .from('sms_delivery_log')
          .select('sent_at, delivery_status')
          .gte('sent_at', startDate.toIso8601String());

      if (provider != null) {
        query = query.eq('provider_used', provider);
      }

      final response = await query.order('sent_at', ascending: true);
      final logs = List<Map<String, dynamic>>.from(response);

      // Group by day
      final trendsByDay = <String, Map<String, int>>{};

      for (final log in logs) {
        final sentAt = DateTime.parse(log['sent_at'] as String);
        final dayKey =
            '${sentAt.year}-${sentAt.month.toString().padLeft(2, '0')}-${sentAt.day.toString().padLeft(2, '0')}';

        if (!trendsByDay.containsKey(dayKey)) {
          trendsByDay[dayKey] = {'sent': 0, 'delivered': 0, 'failed': 0};
        }

        trendsByDay[dayKey]!['sent'] = (trendsByDay[dayKey]!['sent'] ?? 0) + 1;

        if (log['delivery_status'] == 'delivered') {
          trendsByDay[dayKey]!['delivered'] =
              (trendsByDay[dayKey]!['delivered'] ?? 0) + 1;
        } else if (log['delivery_status'] == 'failed') {
          trendsByDay[dayKey]!['failed'] =
              (trendsByDay[dayKey]!['failed'] ?? 0) + 1;
        }
      }

      return trendsByDay.entries
          .map(
            (e) => {
              'date': e.key,
              'sent': e.value['sent'],
              'delivered': e.value['delivered'],
              'failed': e.value['failed'],
              'delivery_rate': e.value['sent']! > 0
                  ? ((e.value['delivered']! / e.value['sent']!) * 100)
                        .toStringAsFixed(1)
                  : '0.0',
            },
          )
          .toList();
    } catch (e) {
      debugPrint('Get delivery trends error: $e');
      return [];
    }
  }

  /// Get latency distribution
  Future<Map<String, int>> getLatencyDistribution({int days = 7}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _client
          .from('sms_delivery_log')
          .select('sent_at, delivered_at')
          .eq('delivery_status', 'delivered')
          .gte('sent_at', startDate.toIso8601String())
          .not('delivered_at', 'is', null);

      final logs = List<Map<String, dynamic>>.from(response);

      final distribution = <String, int>{
        '0-5s': 0,
        '5-10s': 0,
        '10-30s': 0,
        '>30s': 0,
      };

      for (final log in logs) {
        final sentAt = DateTime.parse(log['sent_at'] as String);
        final deliveredAt = DateTime.parse(log['delivered_at'] as String);
        final latencySeconds = deliveredAt.difference(sentAt).inSeconds;

        if (latencySeconds <= 5) {
          distribution['0-5s'] = distribution['0-5s']! + 1;
        } else if (latencySeconds <= 10) {
          distribution['5-10s'] = distribution['5-10s']! + 1;
        } else if (latencySeconds <= 30) {
          distribution['10-30s'] = distribution['10-30s']! + 1;
        } else {
          distribution['>30s'] = distribution['>30s']! + 1;
        }
      }

      return distribution;
    } catch (e) {
      debugPrint('Get latency distribution error: $e');
      return {};
    }
  }

  /// Export delivery data to CSV format
  Future<String> exportDeliveryDataCSV({int days = 30}) async {
    try {
      final startDate = DateTime.now().subtract(Duration(days: days));

      final response = await _client
          .from('sms_delivery_log')
          .select()
          .gte('sent_at', startDate.toIso8601String())
          .order('sent_at', ascending: false);

      final logs = List<Map<String, dynamic>>.from(response);

      // Build CSV
      final csv = StringBuffer();
      csv.writeln(
        'Provider,Category,Recipient,Status,Sent At,Delivered At,Error',
      );

      for (final log in logs) {
        csv.writeln(
          '${log['provider_used']},'
          '${log['message_category']},'
          '${log['recipient_phone']},'
          '${log['delivery_status']},'
          '${log['sent_at']},'
          '${log['delivered_at'] ?? ''},'
          '${log['error_message'] ?? ''}',
        );
      }

      return csv.toString();
    } catch (e) {
      debugPrint('Export delivery data CSV error: $e');
      return '';
    }
  }

  // =====================================================
  // SMS COST TRACKING
  // =====================================================

  Future<List<Map<String, dynamic>>> getCostTracking() async {
    try {
      final response = await _client
          .from('sms_cost_tracking')
          .select()
          .order('current_spend', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get cost tracking error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> getTotalCostAnalytics() async {
    try {
      final response = await _client.from('sms_cost_tracking').select();

      double totalBudget = 0;
      double totalSpend = 0;
      int totalMessages = 0;

      for (final zone in response) {
        totalBudget += (zone['monthly_budget'] ?? 0).toDouble();
        totalSpend += (zone['current_spend'] ?? 0).toDouble();
        totalMessages += (zone['message_count'] ?? 0) as int;
      }

      final budgetUsed = totalBudget > 0
          ? (totalSpend / totalBudget * 100).toStringAsFixed(1)
          : '0.0';

      return {
        'total_budget': totalBudget.toStringAsFixed(2),
        'total_spend': totalSpend.toStringAsFixed(2),
        'total_messages': totalMessages,
        'budget_used_percentage': budgetUsed,
        'zones_count': response.length,
      };
    } catch (e) {
      debugPrint('Get total cost analytics error: $e');
      return {
        'total_budget': '0.00',
        'total_spend': '0.00',
        'total_messages': 0,
        'budget_used_percentage': '0.0',
        'zones_count': 0,
      };
    }
  }

  // =====================================================
  // SEND EMERGENCY SMS
  // =====================================================

  Future<bool> sendEmergencySms({
    required String alertType,
    required String message,
    String? templateId,
    List<String>? contactIds,
  }) async {
    try {
      // Get contacts to send to
      List<Map<String, dynamic>> contacts;
      if (contactIds != null && contactIds.isNotEmpty) {
        contacts = await _client
            .from('sms_emergency_contacts')
            .select()
            .inFilter('id', contactIds)
            .eq('is_active', true);
      } else {
        contacts = await _client
            .from('sms_emergency_contacts')
            .select()
            .eq('is_active', true)
            .order('priority', ascending: true)
            .limit(5);
      }

      if (contacts.isEmpty) {
        debugPrint('No active emergency contacts found');
        return false;
      }

      // Send SMS to each contact
      for (final contact in contacts) {
        final phoneNumber = contact['phone_number'] as String;

        // Track delivery
        await _client.from('sms_delivery_tracking').insert({
          'contact_id': contact['id'],
          'template_id': templateId,
          'phone_number': phoneNumber,
          'message_content': message,
          'alert_type': alertType,
          'delivery_status': 'pending',
          'sent_at': DateTime.now().toIso8601String(),
        });

        // Send via Twilio
        await _twilio.sendUserActivityNotification(
          phoneNumber: phoneNumber,
          activityType: 'Emergency Alert',
          details: message,
        );
      }

      return true;
    } catch (e) {
      debugPrint('Send emergency SMS error: $e');
      return false;
    }
  }

  // =====================================================
  // SCHEDULED MESSAGES
  // =====================================================

  Future<List<Map<String, dynamic>>> getScheduledMessages() async {
    try {
      final response = await _client
          .from('sms_scheduled_messages')
          .select()
          .eq('is_sent', false)
          .order('scheduled_for', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get scheduled messages error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>?> scheduleMessage({
    required String contactId,
    required String messageContent,
    required String alertType,
    required DateTime scheduledFor,
    String? templateId,
  }) async {
    try {
      if (!_auth.isAuthenticated) {
        throw Exception('User must be authenticated');
      }

      final response = await _client
          .from('sms_scheduled_messages')
          .insert({
            'contact_id': contactId,
            'template_id': templateId,
            'message_content': messageContent,
            'alert_type': alertType,
            'scheduled_for': scheduledFor.toIso8601String(),
            'created_by': _auth.currentUser!.id,
          })
          .select()
          .single();

      return response;
    } catch (e) {
      debugPrint('Schedule message error: $e');
      rethrow;
    }
  }
}
