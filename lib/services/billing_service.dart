import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:universal_html/html.dart' as universal_html;

import './auth_service.dart';
import './supabase_service.dart';

/// Comprehensive billing service for payment methods, invoices, alerts, and compliance
class BillingService {
  static BillingService? _instance;
  static BillingService get instance => _instance ??= BillingService._();

  BillingService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get user's payment methods
  Future<List<Map<String, dynamic>>> getPaymentMethods() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('payment_methods')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .eq('is_active', true)
          .order('is_default', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get payment methods error: $e');
      return [];
    }
  }

  /// Add payment method
  Future<bool> addPaymentMethod({
    required String stripePaymentMethodId,
    required String paymentType,
    required String billingName,
    String? cardBrand,
    String? cardLast4,
    int? cardExpMonth,
    int? cardExpYear,
    Map<String, dynamic>? billingAddress,
    bool setAsDefault = false,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('payment_methods').insert({
        'user_id': _auth.currentUser!.id,
        'payment_type': paymentType,
        'stripe_payment_method_id': stripePaymentMethodId,
        'card_brand': cardBrand,
        'card_last4': cardLast4,
        'card_exp_month': cardExpMonth,
        'card_exp_year': cardExpYear,
        'billing_name': billingName,
        'billing_address': billingAddress ?? {},
        'is_default': setAsDefault,
      });

      return true;
    } catch (e) {
      debugPrint('Add payment method error: $e');
      return false;
    }
  }

  /// Remove payment method
  Future<bool> removePaymentMethod(String paymentMethodId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('payment_methods')
          .update({'is_active': false})
          .eq('id', paymentMethodId)
          .eq('user_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Remove payment method error: $e');
      return false;
    }
  }

  /// Set default payment method
  Future<bool> setDefaultPaymentMethod(String paymentMethodId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      // Remove default from all methods
      await _client
          .from('payment_methods')
          .update({'is_default': false})
          .eq('user_id', _auth.currentUser!.id);

      // Set new default
      await _client
          .from('payment_methods')
          .update({'is_default': true})
          .eq('id', paymentMethodId)
          .eq('user_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Set default payment method error: $e');
      return false;
    }
  }

  /// Get invoices
  Future<List<Map<String, dynamic>>> getInvoices({int limit = 50}) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('invoices')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(limit);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get invoices error: $e');
      return [];
    }
  }

  /// Generate invoice PDF
  Future<String?> generateInvoicePDF(Map<String, dynamic> invoice) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'INVOICE',
                style: pw.TextStyle(
                  fontSize: 24,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 20),
              pw.Text('Invoice #: ${invoice['invoice_number']}'),
              pw.Text(
                'Date: ${DateTime.parse(invoice['created_at'].toString()).toString().split(' ')[0]}',
              ),
              pw.Text('Amount: \$${invoice['amount']}'),
              pw.Text('Status: ${invoice['status']}'),
              pw.SizedBox(height: 20),
              pw.Divider(),
              pw.SizedBox(height: 20),
              pw.Text(
                'Line Items:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              ...((invoice['line_items'] as List?) ?? []).map(
                (item) =>
                    pw.Text('${item['description']}: \$${item['amount']}'),
              ),
            ],
          ),
        ),
      );

      final bytes = await pdf.save();

      // Web: Trigger download
      final blob = universal_html.Blob([bytes]);
      final url = universal_html.Url.createObjectUrlFromBlob(blob);
      universal_html.AnchorElement(href: url)
        ..setAttribute('download', 'invoice_${invoice['invoice_number']}.pdf')
        ..click();
      universal_html.Url.revokeObjectUrl(url);
      return 'Invoice downloaded successfully';
    } catch (e) {
      debugPrint('Generate invoice PDF error: $e');
      return null;
    }
  }

  /// Get billing alerts
  Future<List<Map<String, dynamic>>> getBillingAlerts({
    bool unreadOnly = false,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      var query = _client
          .from('billing_alerts')
          .select()
          .eq('user_id', _auth.currentUser!.id);

      if (unreadOnly) {
        query = query.eq('is_read', false);
      }

      final response = await query.order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get billing alerts error: $e');
      return [];
    }
  }

  /// Mark alert as read
  Future<bool> markAlertAsRead(String alertId) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client
          .from('billing_alerts')
          .update({'is_read': true})
          .eq('id', alertId)
          .eq('user_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Mark alert as read error: $e');
      return false;
    }
  }

  /// Get billing preferences
  Future<Map<String, dynamic>?> getBillingPreferences() async {
    try {
      if (!_auth.isAuthenticated) return null;

      final response = await _client
          .from('billing_preferences')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .maybeSingle();

      return response;
    } catch (e) {
      debugPrint('Get billing preferences error: $e');
      return null;
    }
  }

  /// Update billing preferences
  Future<bool> updateBillingPreferences({
    bool? emailAlertsEnabled,
    bool? failedPaymentAlerts,
    bool? renewalReminders,
    bool? autoRenewalEnabled,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      final updates = <String, dynamic>{};
      if (emailAlertsEnabled != null) {
        updates['email_alerts_enabled'] = emailAlertsEnabled;
      }
      if (failedPaymentAlerts != null) {
        updates['failed_payment_alerts'] = failedPaymentAlerts;
      }
      if (renewalReminders != null) {
        updates['renewal_reminders'] = renewalReminders;
      }
      if (autoRenewalEnabled != null) {
        updates['auto_renewal_enabled'] = autoRenewalEnabled;
      }

      await _client
          .from('billing_preferences')
          .upsert({'user_id': _auth.currentUser!.id, ...updates})
          .eq('user_id', _auth.currentUser!.id);

      return true;
    } catch (e) {
      debugPrint('Update billing preferences error: $e');
      return false;
    }
  }

  /// Submit payment dispute
  Future<bool> submitPaymentDispute({
    required String invoiceId,
    required String reason,
    required String description,
    double? amount,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('payment_disputes').insert({
        'user_id': _auth.currentUser!.id,
        'invoice_id': invoiceId,
        'reason': reason,
        'description': description,
        'amount': amount,
        'status': 'submitted',
      });

      return true;
    } catch (e) {
      debugPrint('Submit payment dispute error: $e');
      return false;
    }
  }

  /// Get payment disputes
  Future<List<Map<String, dynamic>>> getPaymentDisputes() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('payment_disputes')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get payment disputes error: $e');
      return [];
    }
  }

  /// Get billing history for charts (monthly aggregation)
  Future<List<Map<String, dynamic>>> getBillingHistoryForCharts({
    int months = 12,
  }) async {
    try {
      if (!_auth.isAuthenticated) return [];

      final startDate = DateTime.now().subtract(Duration(days: months * 30));

      final response = await _client
          .from('invoices')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .eq('status', 'paid')
          .gte('created_at', startDate.toIso8601String())
          .order('created_at', ascending: true);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get billing history for charts error: $e');
      return [];
    }
  }
}

class SubscriptionEvent {
  final String id;
  final String subscriptionId;
  final String userId;
  final String eventType;
  final String? oldTier;
  final String? newTier;
  final String? cancellationReason;
  final String? cancellationFeedback;
  final double? prorationAmount;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;

  SubscriptionEvent({
    required this.id,
    required this.subscriptionId,
    required this.userId,
    required this.eventType,
    this.oldTier,
    this.newTier,
    this.cancellationReason,
    this.cancellationFeedback,
    this.prorationAmount,
    this.metadata,
    required this.createdAt,
  });

  factory SubscriptionEvent.fromJson(Map<String, dynamic> json) {
    return SubscriptionEvent(
      id: json['id'] as String,
      subscriptionId: json['subscription_id'] as String,
      userId: json['user_id'] as String,
      eventType: json['event_type'] as String,
      oldTier: json['old_tier'] as String?,
      newTier: json['new_tier'] as String?,
      cancellationReason: json['cancellation_reason'] as String?,
      cancellationFeedback: json['cancellation_feedback'] as String?,
      prorationAmount: json['proration_amount'] != null
          ? (json['proration_amount'] as num).toDouble()
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'subscription_id': subscriptionId,
      'user_id': userId,
      'event_type': eventType,
      'old_tier': oldTier,
      'new_tier': newTier,
      'cancellation_reason': cancellationReason,
      'cancellation_feedback': cancellationFeedback,
      'proration_amount': prorationAmount,
      'metadata': metadata,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
