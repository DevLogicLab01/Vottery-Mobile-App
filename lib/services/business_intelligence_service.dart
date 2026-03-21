import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './resend_email_service.dart';
import './supabase_query_cache_service.dart';

class BusinessIntelligenceService {
  static BusinessIntelligenceService? _instance;
  static BusinessIntelligenceService get instance =>
      _instance ??= BusinessIntelligenceService._();

  BusinessIntelligenceService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  ResendEmailService get _resendEmailService => ResendEmailService.instance;

  /// Get executive dashboard metrics
  Future<Map<String, dynamic>> getExecutiveDashboard() async {
    try {
      final response = await _client.rpc('get_executive_dashboard');
      return response ?? _getDefaultDashboard();
    } catch (e) {
      debugPrint('Get executive dashboard error: $e');
      return _getDefaultDashboard();
    }
  }

  /// Get revenue analytics
  Future<Map<String, dynamic>> getRevenueAnalytics({
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _client.rpc(
        'get_revenue_analytics',
        params: {
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
      );

      return response ?? _getDefaultRevenueAnalytics();
    } catch (e) {
      debugPrint('Get revenue analytics error: $e');
      return _getDefaultRevenueAnalytics();
    }
  }

  /// Get user intelligence metrics
  Future<Map<String, dynamic>> getUserIntelligence() async {
    try {
      final response = await _client.rpc('get_user_intelligence');
      return response ?? _getDefaultUserIntelligence();
    } catch (e) {
      debugPrint('Get user intelligence error: $e');
      return _getDefaultUserIntelligence();
    }
  }

  /// Get content performance metrics
  Future<Map<String, dynamic>> getContentPerformance() async {
    try {
      final response = await _client.rpc('get_content_performance_metrics');
      return response ?? _getDefaultContentPerformance();
    } catch (e) {
      debugPrint('Get content performance error: $e');
      return _getDefaultContentPerformance();
    }
  }

  /// Get predictive insights
  Future<Map<String, dynamic>> getPredictiveInsights() async {
    try {
      final response = await _client.rpc('get_predictive_insights');
      return response ?? _getDefaultPredictiveInsights();
    } catch (e) {
      debugPrint('Get predictive insights error: $e');
      return _getDefaultPredictiveInsights();
    }
  }

  /// Get growth forecasting
  Future<Map<String, dynamic>> getGrowthForecast({
    int forecastDays = 30,
  }) async {
    try {
      final response = await _client.rpc(
        'get_growth_forecast',
        params: {'forecast_days': forecastDays},
      );

      return response ?? _getDefaultGrowthForecast();
    } catch (e) {
      debugPrint('Get growth forecast error: $e');
      return _getDefaultGrowthForecast();
    }
  }

  /// Get market opportunity analysis
  Future<Map<String, dynamic>> getMarketOpportunities() async {
    try {
      final response = await _client.rpc('get_market_opportunities');
      return response ?? _getDefaultMarketOpportunities();
    } catch (e) {
      debugPrint('Get market opportunities error: $e');
      return _getDefaultMarketOpportunities();
    }
  }

  /// Get competitive intelligence
  Future<Map<String, dynamic>> getCompetitiveIntelligence() async {
    try {
      final response = await _client.rpc('get_competitive_intelligence');
      return response ?? _getDefaultCompetitiveIntelligence();
    } catch (e) {
      debugPrint('Get competitive intelligence error: $e');
      return _getDefaultCompetitiveIntelligence();
    }
  }

  /// Generate executive report
  Future<Map<String, dynamic>> generateExecutiveReport({
    required String reportType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final response = await _client.rpc(
        'generate_executive_report',
        params: {
          'report_type': reportType,
          'start_date': startDate?.toIso8601String(),
          'end_date': endDate?.toIso8601String(),
        },
      );

      return response ?? _getDefaultReport();
    } catch (e) {
      debugPrint('Generate executive report error: $e');
      return _getDefaultReport();
    }
  }

  /// Get active stakeholder groups used for report delivery
  Future<List<Map<String, dynamic>>> getStakeholderGroups() async {
    try {
      final response = await _client
          .from('stakeholder_groups')
          .select()
          .eq('is_active', true)
          .order('group_name', ascending: true);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get stakeholder groups error: $e');
      return [];
    }
  }

  /// Generate + deliver executive report through edge function
  Future<Map<String, dynamic>> sendExecutiveReport({
    required String reportType,
    required String stakeholderGroupId,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      final generated = await generateExecutiveReport(
        reportType: reportType,
        startDate: startDate,
        endDate: endDate,
      );

      // Persist report record first for delivery/audit parity with Web.
      final inserted = await _client
          .from('executive_reports')
          .insert({
            'report_type': reportType,
            'title': '$reportType executive report',
            'report_data': generated,
            'status': 'pending',
          })
          .select()
          .single();
      final reportId = inserted['id'];

      final stakeholderGroup = await _client
          .from('stakeholder_groups')
          .select()
          .eq('id', stakeholderGroupId)
          .single();

      final edgeResponse = await _client.functions.invoke(
        'send-executive-report',
        body: {
          'reportId': reportId,
          'reportType': reportType,
          'title': inserted['title'],
          'reportData': generated,
          'recipients': stakeholderGroup['recipients'],
          'stakeholderGroupId': stakeholderGroupId,
        },
      );

      final recipientEmails = _extractEmails(stakeholderGroup['recipients']);

      if (edgeResponse.status < 200 || edgeResponse.status >= 300) {
        // Fallback to direct email delivery to keep mobile parity with web delivery workflows.
        int deliveredCount = 0;
        for (final email in recipientEmails) {
          final emailResponse = await _resendEmailService.sendEmail(
            to: email,
            subject: '[Vottery] ${inserted['title']}',
            html: _buildExecutiveReportHtml(
              reportType: reportType,
              reportData: generated,
            ),
          );
          final delivered = emailResponse['success'] == true;
          if (delivered) deliveredCount++;
          await _logReportDelivery(
            reportId: reportId.toString(),
            recipientEmail: email,
            deliveryStatus: delivered ? 'delivered' : 'failed',
            errorMessage: delivered ? null : (emailResponse['error']?.toString()),
          );
        }

        final fallbackSuccess = deliveredCount > 0;
        await _client
            .from('executive_reports')
            .update({
              'status': fallbackSuccess ? 'sent' : 'failed',
              if (fallbackSuccess)
                'sent_at': DateTime.now().toIso8601String(),
            })
            .eq('id', reportId);
        if (fallbackSuccess) {
          SupabaseQueryCacheService.instance
              .onExecutiveReportSent(reportType: reportType);
        }

        return {
          'success': fallbackSuccess,
          'report_id': reportId,
          'fallback_delivery': true,
          'delivered_count': deliveredCount,
          'total_recipients': recipientEmails.length,
          if (!fallbackSuccess) 'error': 'Failed to deliver report',
        };
      }

      await _client
          .from('executive_reports')
          .update({
            'status': 'sent',
            'sent_at': DateTime.now().toIso8601String(),
          })
          .eq('id', reportId);
      SupabaseQueryCacheService.instance
          .onExecutiveReportSent(reportType: reportType);

      for (final email in recipientEmails) {
        await _logReportDelivery(
          reportId: reportId.toString(),
          recipientEmail: email,
          deliveryStatus: 'delivered',
        );
      }

      return {
        'success': true,
        'report_id': reportId,
        'delivery': edgeResponse.data,
        'delivered_count': recipientEmails.length,
      };
    } catch (e) {
      debugPrint('Send executive report error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  /// Delivery logs for report-level QA checks
  Future<List<Map<String, dynamic>>> getReportDeliveryLogs(String reportId) async {
    try {
      final response = await _client
          .from('report_delivery_logs')
          .select()
          .eq('report_id', reportId)
          .order('created_at', ascending: false);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get report delivery logs error: $e');
      return [];
    }
  }

  /// Delivery statistics parity with Web executiveReportingService.getDeliveryStatistics
  Future<Map<String, dynamic>> getDeliveryStatistics({String timeRange = '30d'}) async {
    try {
      final now = DateTime.now();
      DateTime startDate;
      switch (timeRange) {
        case '7d':
          startDate = now.subtract(const Duration(days: 7));
          break;
        case '30d':
        default:
          startDate = now.subtract(const Duration(days: 30));
      }

      final response = await _client
          .from('report_delivery_logs')
          .select('delivery_status, created_at')
          .gte('created_at', startDate.toIso8601String());
      final logs = List<Map<String, dynamic>>.from(response);

      final totalDeliveries = logs.length;
      final successfulDeliveries = logs
          .where((d) => d['delivery_status'] == 'delivered')
          .length;
      final failedDeliveries = logs
          .where((d) => d['delivery_status'] == 'failed')
          .length;
      final pendingDeliveries = logs
          .where((d) => d['delivery_status'] == 'pending')
          .length;

      final deliveryRate = totalDeliveries > 0
          ? ((successfulDeliveries / totalDeliveries) * 100)
          : 0.0;

      return {
        'totalDeliveries': totalDeliveries,
        'successfulDeliveries': successfulDeliveries,
        'failedDeliveries': failedDeliveries,
        'pendingDeliveries': pendingDeliveries,
        'deliveryRate': deliveryRate.toStringAsFixed(2),
      };
    } catch (e) {
      debugPrint('Get delivery statistics error: $e');
      return {
        'totalDeliveries': 0,
        'successfulDeliveries': 0,
        'failedDeliveries': 0,
        'pendingDeliveries': 0,
        'deliveryRate': '0.00',
      };
    }
  }

  /// Get KPI tracking
  Future<List<Map<String, dynamic>>> getKPITracking() async {
    try {
      final response = await _client
          .from('kpi_tracking')
          .select()
          .order('created_at', ascending: false)
          .limit(30);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Get KPI tracking error: $e');
      return [];
    }
  }

  Map<String, dynamic> _getDefaultDashboard() {
    return {
      'total_revenue': 0.0,
      'monthly_revenue': 0.0,
      'revenue_growth': 0.0,
      'active_users': 0,
      'user_growth': 0.0,
      'engagement_rate': 0.0,
      'churn_rate': 0.0,
    };
  }

  Map<String, dynamic> _getDefaultRevenueAnalytics() {
    return {
      'subscription_revenue': 0.0,
      'ad_revenue': 0.0,
      'creator_payouts': 0.0,
      'vp_purchases': 0.0,
      'revenue_by_tier': {},
    };
  }

  Map<String, dynamic> _getDefaultUserIntelligence() {
    return {
      'total_users': 0,
      'active_users': 0,
      'engagement_patterns': {},
      'churn_prediction': 0.0,
      'lifetime_value': 0.0,
    };
  }

  Map<String, dynamic> _getDefaultContentPerformance() {
    return {
      'total_content': 0,
      'viral_content': 0,
      'voting_trends': {},
      'creator_success_metrics': {},
    };
  }

  Map<String, dynamic> _getDefaultPredictiveInsights() {
    return {
      'growth_forecast': 0.0,
      'churn_risk': 0.0,
      'revenue_forecast': 0.0,
      'market_opportunities': [],
    };
  }

  Map<String, dynamic> _getDefaultGrowthForecast() {
    return {
      'user_growth_forecast': [],
      'revenue_growth_forecast': [],
      'confidence_interval': 0.85,
    };
  }

  Map<String, dynamic> _getDefaultMarketOpportunities() {
    return {'opportunities': [], 'market_size': 0.0, 'addressable_market': 0.0};
  }

  Map<String, dynamic> _getDefaultCompetitiveIntelligence() {
    return {
      'market_position': 'unknown',
      'competitive_advantages': [],
      'threats': [],
    };
  }

  Map<String, dynamic> _getDefaultReport() {
    return {
      'report_type': 'executive_summary',
      'generated_at': DateTime.now().toIso8601String(),
      'summary': 'No data available',
      'metrics': {},
    };
  }

  List<String> _extractEmails(dynamic recipients) {
    if (recipients is! List) return const [];
    final emails = <String>[];
    for (final recipient in recipients) {
      if (recipient is String && recipient.contains('@')) {
        emails.add(recipient);
      } else if (recipient is Map && recipient['email'] != null) {
        emails.add(recipient['email'].toString());
      }
    }
    return emails.toSet().toList();
  }

  Future<void> _logReportDelivery({
    required String reportId,
    required String recipientEmail,
    required String deliveryStatus,
    String? errorMessage,
  }) async {
    try {
      await _client.from('report_delivery_logs').insert({
        'report_id': reportId,
        'recipient_email': recipientEmail,
        'delivery_status': deliveryStatus,
        if (errorMessage != null) 'error_message': errorMessage,
      });
    } catch (e) {
      debugPrint('Log report delivery error: $e');
    }
  }

  String _buildExecutiveReportHtml({
    required String reportType,
    required Map<String, dynamic> reportData,
  }) {
    final generatedAt = reportData['generated_at']?.toString() ??
        DateTime.now().toIso8601String();
    return '''
<!DOCTYPE html>
<html>
<body style="font-family: Arial, sans-serif; max-width: 720px; margin: 0 auto; padding: 20px;">
  <h2 style="color: #4F46E5;">Executive Report: $reportType</h2>
  <p><strong>Generated:</strong> $generatedAt</p>
  <hr />
  <pre style="white-space: pre-wrap; background: #F8FAFC; padding: 12px; border-radius: 8px;">${reportData.toString()}</pre>
  <p style="color:#6B7280; font-size:12px;">Automated delivery from Vottery Mobile BI suite.</p>
</body>
</html>''';
  }
}
