import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './supabase_service.dart';

enum BlockchainErrorType {
  rsaDecryptionFailure,
  blockchainTimeout,
  invalidHash,
  networkError,
  verificationFailed,
  expiredCertificate,
  unknown,
}

class BlockchainErrorService {
  static BlockchainErrorService? _instance;
  static BlockchainErrorService get instance =>
      _instance ??= BlockchainErrorService._();

  BlockchainErrorService._();

  SupabaseClient get _client => SupabaseService.instance.client;

  static const int timeoutSeconds = 30;
  static const List<int> retryDelaysSeconds = [5, 15, 30];

  /// Verify vote with timeout and retry mechanism
  Future<Map<String, dynamic>> verifyVoteWithErrorHandling(
    String receiptCode,
  ) async {
    int retryCount = 0;

    while (retryCount <= retryDelaysSeconds.length) {
      try {
        final result = await _verifyVoteWithTimeout(receiptCode);
        return {'success': true, 'data': result, 'retryCount': retryCount};
      } on TimeoutException {
        if (retryCount < retryDelaysSeconds.length) {
          await Future.delayed(
            Duration(seconds: retryDelaysSeconds[retryCount]),
          );
          retryCount++;
        } else {
          await _logError(
            errorType: BlockchainErrorType.blockchainTimeout,
            errorMessage:
                'Blockchain verification timeout after $retryCount retries',
            receiptCode: receiptCode,
          );
          return {
            'success': false,
            'errorType': BlockchainErrorType.blockchainTimeout,
            'errorMessage':
                'Unable to connect to verification service. Please try again later.',
            'retryCount': retryCount,
          };
        }
      } catch (e) {
        return await _handleVerificationError(e, receiptCode);
      }
    }

    return {
      'success': false,
      'errorType': BlockchainErrorType.unknown,
      'errorMessage': 'Verification failed after maximum retries',
    };
  }

  /// Verify vote with timeout
  Future<Map<String, dynamic>> _verifyVoteWithTimeout(
    String receiptCode,
  ) async {
    return await _client
        .rpc('verify_vote_integrity', params: {'p_receipt_code': receiptCode})
        .timeout(
          Duration(seconds: timeoutSeconds),
          onTimeout: () =>
              throw TimeoutException('Blockchain verification timeout'),
        );
  }

  /// Handle verification errors
  Future<Map<String, dynamic>> _handleVerificationError(
    dynamic error,
    String receiptCode,
  ) async {
    debugPrint('Blockchain verification error: $error');

    BlockchainErrorType errorType = BlockchainErrorType.unknown;
    String errorMessage = 'An unexpected error occurred';

    final errorString = error.toString().toLowerCase();

    if (errorString.contains('rsa') ||
        errorString.contains('decrypt') ||
        errorString.contains('encryption')) {
      errorType = BlockchainErrorType.rsaDecryptionFailure;
      errorMessage =
          '🔐 Decryption Error - Verify election encryption keys. The vote data could not be decrypted.';
    } else if (errorString.contains('timeout')) {
      errorType = BlockchainErrorType.blockchainTimeout;
      errorMessage =
          'Unable to connect to verification service. Please check your internet connection and try again.';
    } else if (errorString.contains('hash') ||
        errorString.contains('integrity') ||
        errorString.contains('tamper')) {
      errorType = BlockchainErrorType.invalidHash;
      errorMessage =
          '⚠️ Vote Integrity Compromised - The vote record has been tampered with or is invalid.';
    } else if (errorString.contains('network') ||
        errorString.contains('connection')) {
      errorType = BlockchainErrorType.networkError;
      errorMessage =
          'Network Error: Unable to connect to verification service. Please check your internet connection.';
    } else if (errorString.contains('not found') ||
        errorString.contains('does not exist')) {
      errorType = BlockchainErrorType.verificationFailed;
      errorMessage =
          'Verification Failed: Vote record not found in blockchain. The receipt code may be invalid.';
    } else if (errorString.contains('expired') ||
        errorString.contains('certificate')) {
      errorType = BlockchainErrorType.expiredCertificate;
      errorMessage =
          'Expired Certificate: Verification period ended. This vote can no longer be verified.';
    }

    await _logError(
      errorType: errorType,
      errorMessage: error.toString(),
      receiptCode: receiptCode,
    );

    return {
      'success': false,
      'errorType': errorType,
      'errorMessage': errorMessage,
      'technicalDetails': error.toString(),
    };
  }

  /// Detect RSA decryption failures
  bool isRSADecryptionError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('rsa') ||
        errorString.contains('decrypt') ||
        errorString.contains('encryption') ||
        errorString.contains('key');
  }

  /// Detect invalid hash errors
  bool isInvalidHashError(dynamic error) {
    final errorString = error.toString().toLowerCase();
    return errorString.contains('hash') ||
        errorString.contains('integrity') ||
        errorString.contains('tamper') ||
        errorString.contains('mismatch');
  }

  /// Log error to database for analytics
  Future<void> _logError({
    required BlockchainErrorType errorType,
    required String errorMessage,
    String? receiptCode,
  }) async {
    try {
      await _client.from('blockchain_audit_logs').insert({
        'event_type': 'verification_error',
        'error_type': errorType.toString().split('.').last,
        'error_message': errorMessage,
        'receipt_code': receiptCode,
        'timestamp': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Error logging blockchain error: $e');
    }
  }

  /// Get error analytics
  Future<Map<String, dynamic>> getErrorAnalytics() async {
    try {
      final response = await _client
          .from('blockchain_audit_logs')
          .select('error_type')
          .eq('event_type', 'verification_error')
          .gte(
            'timestamp',
            DateTime.now().subtract(Duration(days: 30)).toIso8601String(),
          );

      final errors = List<Map<String, dynamic>>.from(response);

      final errorCounts = <String, int>{};
      for (var error in errors) {
        final type = error['error_type'] as String? ?? 'unknown';
        errorCounts[type] = (errorCounts[type] ?? 0) + 1;
      }

      final totalErrors = errors.length;
      final errorRates = errorCounts.map(
        (type, count) => MapEntry(type, (count / totalErrors * 100).round()),
      );

      return {
        'totalErrors': totalErrors,
        'errorCounts': errorCounts,
        'errorRates': errorRates,
        'period': '30 days',
      };
    } catch (e) {
      debugPrint('Get error analytics error: $e');
      return {'totalErrors': 0, 'errorCounts': {}, 'errorRates': {}};
    }
  }

  /// Get user-friendly error message
  String getUserFriendlyErrorMessage(BlockchainErrorType errorType) {
    switch (errorType) {
      case BlockchainErrorType.rsaDecryptionFailure:
        return '🔐 Decryption Error - Verify election encryption keys';
      case BlockchainErrorType.blockchainTimeout:
        return 'Unable to connect to verification service';
      case BlockchainErrorType.invalidHash:
        return '⚠️ Vote Integrity Compromised';
      case BlockchainErrorType.networkError:
        return 'Network Error: Unable to connect to verification service';
      case BlockchainErrorType.verificationFailed:
        return 'Verification Failed: Vote record not found in blockchain';
      case BlockchainErrorType.expiredCertificate:
        return 'Expired Certificate: Verification period ended';
      default:
        return 'An unexpected error occurred during verification';
    }
  }

  /// Get recovery suggestions
  List<String> getRecoverySuggestions(BlockchainErrorType errorType) {
    switch (errorType) {
      case BlockchainErrorType.rsaDecryptionFailure:
        return [
          'Contact the election creator to verify encryption keys',
          'Ensure the election is properly configured',
          'Try verifying a different vote to test the system',
        ];
      case BlockchainErrorType.blockchainTimeout:
        return [
          'Check your internet connection',
          'Try again in a few moments',
          'Contact support if the issue persists',
        ];
      case BlockchainErrorType.invalidHash:
        return [
          'Report this issue to administrators immediately',
          'Do not attempt to vote again',
          'Save your receipt code for investigation',
        ];
      case BlockchainErrorType.networkError:
        return [
          'Check your internet connection',
          'Disable VPN if enabled',
          'Try switching to a different network',
        ];
      case BlockchainErrorType.verificationFailed:
        return [
          'Double-check your receipt code for typos',
          'Ensure you are verifying the correct election',
          'Contact support with your receipt code',
        ];
      case BlockchainErrorType.expiredCertificate:
        return [
          'This election verification period has ended',
          'Contact the election creator for archived records',
          'Save your receipt for future reference',
        ];
      default:
        return [
          'Try again in a few moments',
          'Contact support if the issue persists',
        ];
    }
  }
}
