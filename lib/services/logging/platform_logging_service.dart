import 'dart:convert';
import 'dart:io';

import 'package:battery_plus/battery_plus.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PlatformLoggingService {
  static final SupabaseClient _supabase = Supabase.instance.client;
  static final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  static final Battery _battery = Battery();

  /// Universal logging method - stores directly in platform_logs table
  static Future<void> logEvent({
    required String eventType,
    required String message,
    String logLevel = 'info',
    String logCategory = 'user_activity',
    Map<String, dynamic>? metadata,
    bool sensitiveData = false,
  }) async {
    try {
      // Add mobile device context
      final deviceContext = await _getDeviceContext();

      final logData = {
        'event_type': eventType,
        'message': message,
        'log_level': logLevel,
        'log_category': logCategory,
        'log_source': 'client',
        'sensitive_data': sensitiveData,
        'metadata': {
          ...?metadata,
          'platform': 'mobile',
          'device_context': deviceContext,
        },
      };

      // Insert directly into platform_logs table
      await _supabase.from('platform_logs').insert(logData);
    } catch (e) {
      debugPrint('Logging error: $e');
      // Fallback: Store locally and sync later
      await _storeOfflineLog(eventType, message, logLevel, metadata);
    }
  }

  /// Mobile device context
  static Future<Map<String, dynamic>> _getDeviceContext() async {
    try {
      final packageInfo = await PackageInfo.fromPlatform();
      final connectivityResults = await Connectivity().checkConnectivity();
      final batteryLevel = await _battery.batteryLevel;

      Map<String, dynamic> deviceData = {
        'app_version': packageInfo.version,
        'build_number': packageInfo.buildNumber,
        'network_type': connectivityResults.map((e) => e.name).join(','),
        'battery_level': batteryLevel,
        'timestamp': DateTime.now().toIso8601String(),
      };

      // Get platform-specific device info
      if (!kIsWeb && Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceData.addAll({
          'device_model': androidInfo.model,
          'android_version': androidInfo.version.release,
          'manufacturer': androidInfo.manufacturer,
        });
      } else if (!kIsWeb && Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceData.addAll({
          'device_model': iosInfo.model,
          'ios_version': iosInfo.systemVersion,
          'device_name': iosInfo.name,
        });
      } else if (kIsWeb) {
        final webInfo = await _deviceInfo.webBrowserInfo;
        deviceData.addAll({
          'browser': webInfo.browserName.name,
          'platform': webInfo.platform ?? 'unknown',
        });
      }

      return deviceData;
    } catch (e) {
      debugPrint('Device context error: $e');
      return {'error': 'Failed to get device context'};
    }
  }

  /// Convenience methods for common log types
  static Future<void> logVoteAction({
    required String electionId,
    required String optionId,
    int? vpEarned,
  }) async {
    await logEvent(
      eventType: 'vote_cast',
      message: 'User cast vote in election',
      logCategory: 'voting',
      metadata: {
        'election_id': electionId,
        'option_id': optionId,
        'vp_earned': vpEarned,
      },
    );
  }

  static Future<void> logSecurityAlert({
    required String alertType,
    required String description,
    Map<String, dynamic>? alertData,
  }) async {
    await logEvent(
      eventType: 'security_alert',
      message: 'Security alert: $alertType',
      logLevel: 'critical',
      logCategory: 'security',
      sensitiveData: true,
      metadata: {
        'alert_type': alertType,
        'description': description,
        ...?alertData,
      },
    );
  }

  static Future<void> logPaymentTransaction({
    required String transactionId,
    required String transactionType,
    required double amount,
  }) async {
    await logEvent(
      eventType: 'payment_transaction',
      message: 'Payment transaction processed',
      logCategory: 'payment',
      sensitiveData: true,
      metadata: {
        'transaction_id': transactionId,
        'transaction_type': transactionType,
        'amount': amount,
      },
    );
  }

  static Future<void> logAIAnalysis({
    required String analysisType,
    required String aiProvider,
    required Map<String, dynamic> analysisResult,
  }) async {
    await logEvent(
      eventType: 'ai_analysis',
      message: 'AI analysis completed: $analysisType',
      logCategory: 'ai_analysis',
      metadata: {
        'analysis_type': analysisType,
        'ai_provider': aiProvider,
        'result': analysisResult,
      },
    );
  }

  /// Offline logging support
  static Future<void> _storeOfflineLog(
    String eventType,
    String message,
    String logLevel,
    Map<String, dynamic>? metadata,
  ) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineLogs = prefs.getStringList('offline_logs') ?? [];

      final logEntry = jsonEncode({
        'event_type': eventType,
        'message': message,
        'log_level': logLevel,
        'metadata': metadata,
        'created_at': DateTime.now().toIso8601String(),
      });

      offlineLogs.add(logEntry);
      await prefs.setStringList('offline_logs', offlineLogs);
    } catch (e) {
      debugPrint('Offline log storage error: $e');
    }
  }

  /// Sync offline logs when connection restored
  static Future<void> syncOfflineLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineLogs = prefs.getStringList('offline_logs') ?? [];

      if (offlineLogs.isEmpty) return;

      final successfulLogs = <String>[];

      for (final logString in offlineLogs) {
        try {
          final logData = jsonDecode(logString);
          await _supabase.from('platform_logs').insert(logData);
          successfulLogs.add(logString);
        } catch (e) {
          debugPrint('Failed to sync log: $e');
          // Keep in offline queue for next sync attempt
          continue;
        }
      }

      // Remove successfully synced logs
      if (successfulLogs.isNotEmpty) {
        final remainingLogs = offlineLogs
            .where((log) => !successfulLogs.contains(log))
            .toList();
        await prefs.setStringList('offline_logs', remainingLogs);
      }
    } catch (e) {
      debugPrint('Sync offline logs error: $e');
    }
  }

  /// Diagnostics: get offline log count
  static Future<int> getOfflineLogCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final offlineLogs = prefs.getStringList('offline_logs') ?? [];
      return offlineLogs.length;
    } catch (e) {
      debugPrint('Get offline log count error: $e');
      return 0;
    }
  }
}
