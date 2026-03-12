import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './resend_email_service.dart';

class PayoutNotificationService {
  static PayoutNotificationService? _instance;
  static PayoutNotificationService get instance =>
      _instance ??= PayoutNotificationService._();

  PayoutNotificationService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  ResendEmailService get _emailService => ResendEmailService.instance;

  /// Send payout scheduled notification
  Future<void> sendPayoutScheduledNotification({
    required String recipientEmail,
    required double amount,
    required String currency,
    required DateTime expectedDate,
  }) async {
    try {
      await _emailService.sendEmail(
        to: recipientEmail,
        subject: 'Payout Scheduled',
        html:
            '''
          <h2>Your payout has been scheduled</h2>
          <p>Amount: $currency ${amount.toStringAsFixed(2)}</p>
          <p>Expected arrival: ${expectedDate.toString().split(' ')[0]}</p>
          <p>You will receive another notification when the payout is processed.</p>
        ''',
      );
    } catch (e) {
      debugPrint('Send payout scheduled notification error: $e');
    }
  }

  /// Send payout processing notification
  Future<void> sendPayoutProcessingNotification({
    required String recipientEmail,
    required double amount,
    required String currency,
  }) async {
    try {
      await _emailService.sendEmail(
        to: recipientEmail,
        subject: 'Payout Processing',
        html:
            '''
          <h2>Your payout is being processed</h2>
          <p>Amount: $currency ${amount.toStringAsFixed(2)}</p>
          <p>This usually takes 2-5 business days to arrive in your account.</p>
        ''',
      );
    } catch (e) {
      debugPrint('Send payout processing notification error: $e');
    }
  }

  /// Send payout completed notification
  Future<void> sendPayoutCompletedNotification({
    required String recipientEmail,
    required double amount,
    required String currency,
    required DateTime arrivalDate,
  }) async {
    try {
      await _emailService.sendEmail(
        to: recipientEmail,
        subject: 'Payout Completed',
        html:
            '''
          <h2>Your payout has been completed!</h2>
          <p>Amount: $currency ${amount.toStringAsFixed(2)}</p>
          <p>Expected arrival: ${arrivalDate.toString().split(' ')[0]}</p>
          <p>Thank you for being a valued creator!</p>
        ''',
      );
    } catch (e) {
      debugPrint('Send payout completed notification error: $e');
    }
  }

  /// Send payout failed notification
  Future<void> sendPayoutFailedNotification({
    required String recipientEmail,
    required double amount,
    required String errorMessage,
  }) async {
    try {
      await _emailService.sendEmail(
        to: recipientEmail,
        subject: 'Payout Failed - Action Required',
        html:
            '''
          <h2>Your payout could not be processed</h2>
          <p>Amount: \${amount.toStringAsFixed(2)}</p>
          <p>Reason: $errorMessage</p>
          <p>Please update your bank account information or contact support.</p>
        ''',
      );
    } catch (e) {
      debugPrint('Send payout failed notification error: $e');
    }
  }

  /// Send tier upgrade notification
  Future<void> sendTierUpgradeNotification({
    required String recipientEmail,
    required String oldTier,
    required String newTier,
    required double vpMultiplier,
    required List<String> newFeatures,
  }) async {
    try {
      final featuresHtml = newFeatures.map((f) => '<li>$f</li>').join('');

      await _emailService.sendEmail(
        to: recipientEmail,
        subject:
            'Congratulations! You\'ve Reached ${newTier.toUpperCase()} Tier',
        html:
            '''
          <h2>🎉 Tier Upgrade!</h2>
          <p>You've been upgraded from <strong>${oldTier.toUpperCase()}</strong> to <strong>${newTier.toUpperCase()}</strong> tier!</p>
          <h3>New Benefits:</h3>
          <ul>
            <li>VP Multiplier: ${vpMultiplier.toStringAsFixed(1)}x</li>
            $featuresHtml
          </ul>
          <p>Keep up the great work!</p>
        ''',
      );
    } catch (e) {
      debugPrint('Send tier upgrade notification error: $e');
    }
  }

  /// Send suspension notification
  Future<void> sendSuspensionNotification({
    required String recipientEmail,
    required String reason,
    required String evidence,
    DateTime? expiresAt,
  }) async {
    try {
      final durationText = expiresAt != null
          ? 'until ${expiresAt.toString().split(' ')[0]}'
          : 'permanently';

      await _emailService.sendEmail(
        to: recipientEmail,
        subject: 'Account Suspended',
        html:
            '''
          <h2>Your account has been suspended</h2>
          <p><strong>Reason:</strong> $reason</p>
          <p><strong>Evidence:</strong> $evidence</p>
          <p><strong>Duration:</strong> $durationText</p>
          <h3>Appeal Process:</h3>
          <p>If you believe this suspension is unfair, you can submit an appeal through the app.</p>
          <p>Go to Settings > Security > View Suspension Details > Submit Appeal</p>
        ''',
      );
    } catch (e) {
      debugPrint('Send suspension notification error: $e');
    }
  }
}
