import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import './supabase_service.dart';
import './auth_service.dart';

class ResendEmailService {
  static ResendEmailService? _instance;
  static ResendEmailService get instance =>
      _instance ??= ResendEmailService._();

  ResendEmailService._();

  static const String apiKey = String.fromEnvironment('RESEND_API_KEY');
  static const String apiUrl = 'https://api.resend.com/emails';
  static const String fromEmail = 'noreply@vottery.com';

  AuthService get _auth => AuthService.instance;
  dynamic get _client => SupabaseService.instance.client;

  /// Send scheduled compliance report
  Future<Map<String, dynamic>> sendComplianceReport({
    required String recipientEmail,
    required String reportType,
    required Map<String, dynamic> reportData,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-resend-api-key-here') {
        return _getDefaultEmailResponse();
      }

      final emailContent = _buildComplianceReportEmail(reportType, reportData);
      final response = await _sendEmail(
        to: recipientEmail,
        subject: 'Vottery Compliance Report - $reportType',
        html: emailContent,
      );

      await _logEmailDelivery(
        recipientEmail: recipientEmail,
        emailType: 'compliance_report',
        reportType: reportType,
        deliveryStatus: response['success'] ? 'delivered' : 'failed',
      );

      return response;
    } catch (e) {
      debugPrint('Send compliance report error: $e');
      return _getDefaultEmailResponse();
    }
  }

  /// Send settlement confirmation email
  Future<Map<String, dynamic>> sendSettlementConfirmation({
    required String recipientEmail,
    required Map<String, dynamic> settlementData,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-resend-api-key-here') {
        return _getDefaultEmailResponse();
      }

      final emailContent = _buildSettlementConfirmationEmail(settlementData);
      final response = await _sendEmail(
        to: recipientEmail,
        subject:
            'Vottery Settlement Confirmation - \$${settlementData['amount']}',
        html: emailContent,
      );

      await _logEmailDelivery(
        recipientEmail: recipientEmail,
        emailType: 'settlement_confirmation',
        deliveryStatus: response['success'] ? 'delivered' : 'failed',
      );

      return response;
    } catch (e) {
      debugPrint('Send settlement confirmation error: $e');
      return _getDefaultEmailResponse();
    }
  }

  /// Send campaign analytics report
  Future<Map<String, dynamic>> sendCampaignAnalyticsReport({
    required String recipientEmail,
    required String campaignId,
    required Map<String, dynamic> analyticsData,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-resend-api-key-here') {
        return _getDefaultEmailResponse();
      }

      final emailContent = _buildCampaignAnalyticsEmail(
        campaignId,
        analyticsData,
      );
      final response = await _sendEmail(
        to: recipientEmail,
        subject:
            'Vottery Campaign Analytics Report - ${analyticsData['campaign_name']}',
        html: emailContent,
      );

      await _logEmailDelivery(
        recipientEmail: recipientEmail,
        emailType: 'campaign_analytics',
        campaignId: campaignId,
        deliveryStatus: response['success'] ? 'delivered' : 'failed',
      );

      return response;
    } catch (e) {
      debugPrint('Send campaign analytics error: $e');
      return _getDefaultEmailResponse();
    }
  }

  /// Send billing summary email
  Future<Map<String, dynamic>> sendBillingSummary({
    required String recipientEmail,
    required Map<String, dynamic> billingData,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-resend-api-key-here') {
        return _getDefaultEmailResponse();
      }

      final emailContent = _buildBillingSummaryEmail(billingData);
      final response = await _sendEmail(
        to: recipientEmail,
        subject: 'Vottery Billing Summary - ${billingData['period']}',
        html: emailContent,
      );

      await _logEmailDelivery(
        recipientEmail: recipientEmail,
        emailType: 'billing_summary',
        deliveryStatus: response['success'] ? 'delivered' : 'failed',
      );

      return response;
    } catch (e) {
      debugPrint('Send billing summary error: $e');
      return _getDefaultEmailResponse();
    }
  }

  /// Schedule automated email report
  Future<Map<String, dynamic>> scheduleEmailReport({
    required String recipientEmail,
    required String reportType,
    required String frequency, // daily, weekly, monthly
    required Map<String, dynamic> reportConfig,
  }) async {
    try {
      await _client.from('scheduled_email_reports').insert({
        'recipient_email': recipientEmail,
        'report_type': reportType,
        'frequency': frequency,
        'report_config': reportConfig,
        'next_delivery': _calculateNextDeliveryDate(frequency),
        'is_active': true,
      });

      return {
        'success': true,
        'message': 'Email report scheduled successfully',
      };
    } catch (e) {
      debugPrint('Schedule email report error: $e');
      return {'success': false, 'message': 'Failed to schedule email report'};
    }
  }

  /// Get scheduled email reports
  Future<List<Map<String, dynamic>>> getScheduledReports() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final response = await _client
          .from('scheduled_email_reports')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get scheduled reports error: $e');
      return [];
    }
  }

  /// Cancel scheduled email report
  Future<bool> cancelScheduledReport(String reportId) async {
    try {
      await _client
          .from('scheduled_email_reports')
          .update({'is_active': false})
          .eq('id', reportId);

      return true;
    } catch (e) {
      debugPrint('Cancel scheduled report error: $e');
      return false;
    }
  }

  /// Core email sending function
  Future<Map<String, dynamic>> _sendEmail({
    required String to,
    required String subject,
    required String html,
  }) async {
    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'from': fromEmail,
          'to': [to],
          'subject': subject,
          'html': html,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {'success': true, 'email_id': data['id']};
      } else {
        debugPrint('Resend API error: ${response.statusCode} ${response.body}');
        return {'success': false, 'error': response.body};
      }
    } catch (e) {
      debugPrint('Send email error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Public email sending method
  Future<Map<String, dynamic>> sendEmail({
    required String to,
    required String subject,
    required String html,
  }) async {
    return _sendEmail(to: to, subject: subject, html: html);
  }

  /// Build compliance report email HTML
  String _buildComplianceReportEmail(
    String reportType,
    Map<String, dynamic> reportData,
  ) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
    .metric { background: white; padding: 15px; margin: 10px 0; border-radius: 6px; border-left: 4px solid #667eea; }
    .footer { text-align: center; padding: 20px; color: #666; font-size: 12px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Compliance Report</h1>
      <p>$reportType</p>
    </div>
    <div class="content">
      <h2>Report Summary</h2>
      <div class="metric">
        <strong>Total Transactions:</strong> ${reportData['total_transactions'] ?? 0}
      </div>
      <div class="metric">
        <strong>Compliance Score:</strong> ${reportData['compliance_score'] ?? 0}%
      </div>
      <div class="metric">
        <strong>Flagged Items:</strong> ${reportData['flagged_items'] ?? 0}
      </div>
      <div class="metric">
        <strong>Report Period:</strong> ${reportData['period'] ?? 'N/A'}
      </div>
    </div>
    <div class="footer">
      <p>This is an automated report from Vottery. Do not reply to this email.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Build settlement confirmation email HTML
  String _buildSettlementConfirmationEmail(
    Map<String, dynamic> settlementData,
  ) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
    .amount { font-size: 36px; font-weight: bold; color: #11998e; text-align: center; margin: 20px 0; }
    .detail { background: white; padding: 15px; margin: 10px 0; border-radius: 6px; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>✅ Settlement Confirmed</h1>
    </div>
    <div class="content">
      <div class="amount">\$${settlementData['amount']}</div>
      <div class="detail">
        <strong>Settlement ID:</strong> ${settlementData['settlement_id']}
      </div>
      <div class="detail">
        <strong>Payment Method:</strong> ${settlementData['payment_method']}
      </div>
      <div class="detail">
        <strong>Estimated Arrival:</strong> ${settlementData['estimated_arrival']}
      </div>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Build campaign analytics email HTML
  String _buildCampaignAnalyticsEmail(
    String campaignId,
    Map<String, dynamic> analyticsData,
  ) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #f093fb 0%, #f5576c 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
    .metric { background: white; padding: 15px; margin: 10px 0; border-radius: 6px; display: flex; justify-content: space-between; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Campaign Analytics</h1>
      <p>${analyticsData['campaign_name']}</p>
    </div>
    <div class="content">
      <div class="metric">
        <span>Total Reach:</span>
        <strong>${analyticsData['total_reach'] ?? 0}</strong>
      </div>
      <div class="metric">
        <span>Engagement Rate:</span>
        <strong>${analyticsData['engagement_rate'] ?? 0}%</strong>
      </div>
      <div class="metric">
        <span>ROI:</span>
        <strong>${analyticsData['roi'] ?? 0}%</strong>
      </div>
      <div class="metric">
        <span>Budget Spent:</span>
        <strong>\$${analyticsData['budget_spent'] ?? 0}</strong>
      </div>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Build billing summary email HTML
  String _buildBillingSummaryEmail(Map<String, dynamic> billingData) {
    return '''
<!DOCTYPE html>
<html>
<head>
  <style>
    body { font-family: Arial, sans-serif; line-height: 1.6; color: #333; }
    .container { max-width: 600px; margin: 0 auto; padding: 20px; }
    .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 30px; text-align: center; border-radius: 8px 8px 0 0; }
    .content { background: #f9f9f9; padding: 30px; border-radius: 0 0 8px 8px; }
    .total { font-size: 32px; font-weight: bold; text-align: center; margin: 20px 0; }
  </style>
</head>
<body>
  <div class="container">
    <div class="header">
      <h1>Billing Summary</h1>
      <p>${billingData['period']}</p>
    </div>
    <div class="content">
      <div class="total">\$${billingData['total_amount']}</div>
      <p>Your billing summary for ${billingData['period']} is ready.</p>
    </div>
  </div>
</body>
</html>
''';
  }

  /// Send retention email to at-risk creator
  Future<Map<String, dynamic>> sendRetentionEmail({
    required String recipientEmail,
    required String creatorName,
    required int daysSincePost,
  }) async {
    try {
      if (apiKey.isEmpty || apiKey == 'your-resend-api-key-here') {
        return _getDefaultEmailResponse();
      }

      final emailContent = _buildRetentionEmailHtml(
        creatorName: creatorName,
        daysSincePost: daysSincePost,
      );

      final response = await _sendEmail(
        to: recipientEmail,
        subject: 'We\'re here to help, $creatorName',
        html: emailContent,
      );

      await _logEmailDelivery(
        recipientEmail: recipientEmail,
        emailType: 'retention_campaign',
        deliveryStatus: response['success'] ? 'delivered' : 'failed',
      );

      return response;
    } catch (e) {
      debugPrint('Send retention email error: $e');
      return _getDefaultEmailResponse();
    }
  }

  String _buildRetentionEmailHtml({
    required String creatorName,
    required int daysSincePost,
  }) {
    return '''
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto; padding: 20px;">
  <h2 style="color: #6366f1;">We're here to help, $creatorName!</h2>
  <p>We noticed you haven't posted in $daysSincePost days. We miss your content!</p>
  <div style="background: #f0fdf4; padding: 16px; border-radius: 8px; margin: 16px 0;">
    <h3 style="color: #16a34a;">Your Earnings Snapshot</h3>
    <p>Check your latest earnings and see how your content is performing.</p>
  </div>
  <div style="background: #fef3c7; padding: 16px; border-radius: 8px; margin: 16px 0;">
    <h3 style="color: #d97706;">Your Tier Benefits</h3>
    <p>You're close to unlocking the next tier! Keep creating to unlock exclusive perks.</p>
  </div>
  <div style="background: #ede9fe; padding: 16px; border-radius: 8px; margin: 16px 0;">
    <h3 style="color: #7c3aed;">Creator Success Stories</h3>
    <p>Creators like you bounced back and doubled their earnings. You can too!</p>
  </div>
  <a href="https://vottery2205.builtwithrocket.new/creator-analytics-dashboard"
     style="display: inline-block; background: #6366f1; color: white; padding: 12px 24px;
            border-radius: 8px; text-decoration: none; margin-top: 16px;">
    View Your Analytics Dashboard
  </a>
  <p style="color: #6b7280; font-size: 12px; margin-top: 24px;">Vottery Creator Team</p>
</body>
</html>''';
  }

  /// Calculate next delivery date based on frequency
  String _calculateNextDeliveryDate(String frequency) {
    final now = DateTime.now();
    DateTime nextDelivery;

    switch (frequency) {
      case 'daily':
        nextDelivery = now.add(Duration(days: 1));
        break;
      case 'weekly':
        nextDelivery = now.add(Duration(days: 7));
        break;
      case 'monthly':
        nextDelivery = DateTime(now.year, now.month + 1, now.day);
        break;
      default:
        nextDelivery = now.add(Duration(days: 7));
    }

    return nextDelivery.toIso8601String();
  }

  /// Log email delivery
  Future<void> _logEmailDelivery({
    required String recipientEmail,
    required String emailType,
    required String deliveryStatus,
    String? reportType,
    String? campaignId,
  }) async {
    try {
      await _client.from('email_delivery_logs').insert({
        'recipient_email': recipientEmail,
        'email_type': emailType,
        'delivery_status': deliveryStatus,
        'report_type': reportType,
        'campaign_id': campaignId,
        'sent_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint('Log email delivery error: $e');
    }
  }

  Map<String, dynamic> _getDefaultEmailResponse() {
    return {'success': false, 'message': 'Email service not configured'};
  }
}
