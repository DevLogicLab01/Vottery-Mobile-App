import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

/// Telnyx HTTP Client
/// Direct REST API implementation for SMS operations
class TelnyxHttpClient {
  final String apiKey;
  final String messagingProfileId;
  final String fromNumber;

  static const String baseUrl = 'https://api.telnyx.com/v2';
  static const String apiVersion = 'v2';
  static const Duration timeout = Duration(seconds: 10);

  TelnyxHttpClient({
    required this.apiKey,
    required this.messagingProfileId,
    required this.fromNumber,
  });

  /// Send SMS message
  Future<TelnyxSendResult> sendMessage({
    required String toNumber,
    required String messageBody,
    required String messageType,
    String? webhookUrl,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl/messages');
      final headers = {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

      final body = jsonEncode({
        'from': fromNumber,
        'to': toNumber,
        'text': messageBody,
        'messaging_profile_id': messagingProfileId,
        if (webhookUrl != null) 'webhook_url': webhookUrl,
      });

      final response = await http
          .post(uri, headers: headers, body: body)
          .timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messageData = data['data'] as Map<String, dynamic>;

        return TelnyxSendResult(
          success: true,
          messageId: messageData['id'] as String,
          to: messageData['to']?[0]?['phone_number'] as String?,
          from: messageData['from']?['phone_number'] as String?,
          text: messageData['text'] as String?,
          deliveryStatus: 'queued',
          timestamp: DateTime.now(),
        );
      } else if (response.statusCode >= 400) {
        final errorData = jsonDecode(response.body);
        final errors = errorData['errors'] as List?;
        final errorDetail = errors?.isNotEmpty == true
            ? errors!.first['detail'] as String?
            : 'Unknown error';
        final errorCode = errors?.isNotEmpty == true
            ? errors!.first['code'] as String?
            : null;

        return TelnyxSendResult(
          success: false,
          error: '$errorDetail (Code: $errorCode)',
          timestamp: DateTime.now(),
        );
      } else {
        return TelnyxSendResult(
          success: false,
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
          timestamp: DateTime.now(),
        );
      }
    } on SocketException catch (e) {
      return TelnyxSendResult(
        success: false,
        error: 'Network error: ${e.message}',
        timestamp: DateTime.now(),
      );
    } on TimeoutException catch (_) {
      return TelnyxSendResult(
        success: false,
        error: 'Request timeout after ${timeout.inSeconds}s',
        timestamp: DateTime.now(),
      );
    } catch (e) {
      return TelnyxSendResult(
        success: false,
        error: 'Unknown error: $e',
        timestamp: DateTime.now(),
      );
    }
  }

  /// Check service health
  Future<TelnyxHealthResult> checkHealth() async {
    final stopwatch = Stopwatch()..start();

    try {
      final uri = Uri.parse('$baseUrl/phone_numbers');
      final headers = {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

      final response = await http
          .get(uri, headers: headers)
          .timeout(const Duration(seconds: 5));

      stopwatch.stop();

      if (response.statusCode == 200) {
        return TelnyxHealthResult(
          isHealthy: true,
          latencyMs: stopwatch.elapsedMilliseconds,
          checkedAt: DateTime.now(),
        );
      } else {
        return TelnyxHealthResult(
          isHealthy: false,
          latencyMs: stopwatch.elapsedMilliseconds,
          checkedAt: DateTime.now(),
          error: 'HTTP ${response.statusCode}: ${response.reasonPhrase}',
        );
      }
    } on SocketException catch (e) {
      stopwatch.stop();
      return TelnyxHealthResult(
        isHealthy: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        checkedAt: DateTime.now(),
        error: 'Network error: ${e.message}',
      );
    } on TimeoutException catch (_) {
      stopwatch.stop();
      return TelnyxHealthResult(
        isHealthy: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        checkedAt: DateTime.now(),
        error: 'Health check timeout',
      );
    } catch (e) {
      stopwatch.stop();
      return TelnyxHealthResult(
        isHealthy: false,
        latencyMs: stopwatch.elapsedMilliseconds,
        checkedAt: DateTime.now(),
        error: 'Unknown error: $e',
      );
    }
  }

  /// Get message status
  Future<TelnyxMessageStatus> getMessageStatus(String messageId) async {
    try {
      final uri = Uri.parse('$baseUrl/messages/$messageId');
      final headers = {
        'Authorization': 'Bearer $apiKey',
        'Content-Type': 'application/json',
      };

      final response = await http.get(uri, headers: headers).timeout(timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final messageData = data['data'] as Map<String, dynamic>;

        return TelnyxMessageStatus(
          messageId: messageData['id'] as String,
          status: messageData['status'] as String?,
          deliveredAt: messageData['completed_at'] != null
              ? DateTime.parse(messageData['completed_at'] as String)
              : null,
          errorCode: messageData['errors']?[0]?['code'] as String?,
          errorMessage: messageData['errors']?[0]?['detail'] as String?,
        );
      } else {
        return TelnyxMessageStatus(
          messageId: messageId,
          status: 'unknown',
          errorMessage: 'Failed to fetch status: HTTP ${response.statusCode}',
        );
      }
    } catch (e) {
      return TelnyxMessageStatus(
        messageId: messageId,
        status: 'unknown',
        errorMessage: 'Error fetching status: $e',
      );
    }
  }
}

/// Telnyx Send Result
class TelnyxSendResult {
  final bool success;
  final String? messageId;
  final String? to;
  final String? from;
  final String? text;
  final String? deliveryStatus;
  final String? error;
  final DateTime timestamp;

  TelnyxSendResult({
    required this.success,
    this.messageId,
    this.to,
    this.from,
    this.text,
    this.deliveryStatus,
    this.error,
    required this.timestamp,
  });

  factory TelnyxSendResult.fromJson(Map<String, dynamic> json) {
    return TelnyxSendResult(
      success: json['success'] as bool,
      messageId: json['message_id'] as String?,
      to: json['to'] as String?,
      from: json['from'] as String?,
      text: json['text'] as String?,
      deliveryStatus: json['delivery_status'] as String?,
      error: json['error'] as String?,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message_id': messageId,
      'to': to,
      'from': from,
      'text': text,
      'delivery_status': deliveryStatus,
      'error': error,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}

/// Telnyx Health Result
class TelnyxHealthResult {
  final bool isHealthy;
  final int latencyMs;
  final DateTime checkedAt;
  final String? error;

  TelnyxHealthResult({
    required this.isHealthy,
    required this.latencyMs,
    required this.checkedAt,
    this.error,
  });
}

/// Telnyx Message Status
class TelnyxMessageStatus {
  final String messageId;
  final String? status;
  final DateTime? deliveredAt;
  final String? errorCode;
  final String? errorMessage;

  TelnyxMessageStatus({
    required this.messageId,
    this.status,
    this.deliveredAt,
    this.errorCode,
    this.errorMessage,
  });
}
