import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import './supabase_service.dart';
import './auth_service.dart';

class EnhancedRevenueAnalyticsService {
  static EnhancedRevenueAnalyticsService? _instance;
  static EnhancedRevenueAnalyticsService get instance =>
      _instance ??= EnhancedRevenueAnalyticsService._();

  EnhancedRevenueAnalyticsService._();

  SupabaseClient get _client => SupabaseService.instance.client;
  AuthService get _auth => AuthService.instance;

  /// Get revenue breakdown by source
  Future<Map<String, dynamic>> getRevenueBreakdown() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultBreakdown();

      final userId = _auth.currentUser!.id;
      final last30Days = DateTime.now().subtract(const Duration(days: 30));

      final snapshots = await _client
          .from('revenue_analytics_snapshots')
          .select()
          .eq('creator_user_id', userId)
          .gte('snapshot_date', last30Days.toIso8601String().split('T')[0])
          .order('snapshot_date', ascending: false);

      if ((snapshots as List).isEmpty) return _getDefaultBreakdown();

      double electionRevenue = 0;
      double marketplaceRevenue = 0;
      double adRevenue = 0;
      double referralRevenue = 0;
      int electionCount = 0;
      int marketplaceCount = 0;

      for (final snapshot in snapshots) {
        electionRevenue += (snapshot['election_revenue'] as num).toDouble();
        marketplaceRevenue += (snapshot['marketplace_revenue'] as num)
            .toDouble();
        adRevenue += (snapshot['ad_revenue'] as num).toDouble();
        referralRevenue += (snapshot['referral_revenue'] as num).toDouble();
      }

      final totalRevenue =
          electionRevenue + marketplaceRevenue + adRevenue + referralRevenue;

      return {
        'election_revenue': {
          'total': electionRevenue,
          'percentage': totalRevenue > 0
              ? (electionRevenue / totalRevenue * 100).toStringAsFixed(1)
              : '0',
          'transaction_count': electionCount,
          'avg_per_election': electionCount > 0
              ? electionRevenue / electionCount
              : 0,
          'trend': 'up',
        },
        'marketplace_revenue': {
          'total': marketplaceRevenue,
          'percentage': totalRevenue > 0
              ? (marketplaceRevenue / totalRevenue * 100).toStringAsFixed(1)
              : '0',
          'transaction_count': marketplaceCount,
          'avg_per_service': marketplaceCount > 0
              ? marketplaceRevenue / marketplaceCount
              : 0,
          'trend': 'up',
        },
        'ad_revenue': {
          'total': adRevenue,
          'percentage': totalRevenue > 0
              ? (adRevenue / totalRevenue * 100).toStringAsFixed(1)
              : '0',
          'impressions': 0,
          'cpm': 0,
          'trend': 'stable',
        },
        'referral_revenue': {
          'total': referralRevenue,
          'percentage': totalRevenue > 0
              ? (referralRevenue / totalRevenue * 100).toStringAsFixed(1)
              : '0',
          'referrals_count': 0,
          'conversion_rate': 0,
          'trend': 'up',
        },
        'total_revenue': totalRevenue,
      };
    } catch (e) {
      debugPrint('Get revenue breakdown error: $e');
      return _getDefaultBreakdown();
    }
  }

  /// Get historical trends (last 12 months)
  Future<List<Map<String, dynamic>>> getHistoricalTrends() async {
    try {
      if (!_auth.isAuthenticated) return [];

      final userId = _auth.currentUser!.id;
      final last12Months = DateTime.now().subtract(const Duration(days: 365));

      final snapshots = await _client
          .from('revenue_analytics_snapshots')
          .select()
          .eq('creator_user_id', userId)
          .gte('snapshot_date', last12Months.toIso8601String().split('T')[0])
          .order('snapshot_date', ascending: true);

      // Group by month
      final Map<String, Map<String, double>> monthlyData = {};

      for (final snapshot in snapshots as List) {
        final date = DateTime.parse(snapshot['snapshot_date'] as String);
        final monthKey =
            '${date.year}-${date.month.toString().padLeft(2, '0')}';

        monthlyData[monthKey] ??= {
          'election_revenue': 0,
          'marketplace_revenue': 0,
          'ad_revenue': 0,
          'referral_revenue': 0,
          'total_revenue': 0,
        };

        monthlyData[monthKey]!['election_revenue'] =
            (monthlyData[monthKey]!['election_revenue'] ?? 0) +
            (snapshot['election_revenue'] as num).toDouble();
        monthlyData[monthKey]!['marketplace_revenue'] =
            (monthlyData[monthKey]!['marketplace_revenue'] ?? 0) +
            (snapshot['marketplace_revenue'] as num).toDouble();
        monthlyData[monthKey]!['ad_revenue'] =
            (monthlyData[monthKey]!['ad_revenue'] ?? 0) +
            (snapshot['ad_revenue'] as num).toDouble();
        monthlyData[monthKey]!['referral_revenue'] =
            (monthlyData[monthKey]!['referral_revenue'] ?? 0) +
            (snapshot['referral_revenue'] as num).toDouble();
        monthlyData[monthKey]!['total_revenue'] =
            (monthlyData[monthKey]!['total_revenue'] ?? 0) +
            (snapshot['total_revenue'] as num).toDouble();
      }

      return monthlyData.entries
          .map((e) => {'month': e.key, ...e.value})
          .toList();
    } catch (e) {
      debugPrint('Get historical trends error: $e');
      return [];
    }
  }

  /// Get tax liability preview
  Future<Map<String, dynamic>> getTaxLiabilityPreview() async {
    try {
      if (!_auth.isAuthenticated) return _getDefaultTaxPreview();

      final userId = _auth.currentUser!.id;
      final currentYear = DateTime.now().year;

      final estimates = await _client
          .from('tax_estimates')
          .select()
          .eq('creator_user_id', userId)
          .eq('tax_year', currentYear)
          .order('quarter', ascending: true);

      final expenses = await _client
          .from('expense_records')
          .select()
          .eq('creator_user_id', userId)
          .eq('is_deductible', true)
          .gte('expense_date', '$currentYear-01-01')
          .lte('expense_date', '$currentYear-12-31');

      double totalGrossEarnings = 0;
      double totalEstimatedTax = 0;
      final quarterlyEstimates = <Map<String, dynamic>>[];

      for (final estimate in estimates as List) {
        totalGrossEarnings += (estimate['gross_earnings'] as num).toDouble();
        totalEstimatedTax += (estimate['estimated_tax'] as num).toDouble();
        quarterlyEstimates.add({
          'quarter': 'Q${estimate['quarter']}',
          'amount': estimate['estimated_tax'],
          'due_date': _getQuarterDueDate(
            currentYear,
            estimate['quarter'] as int,
          ),
        });
      }

      double totalDeductions = 0;
      for (final expense in expenses as List) {
        totalDeductions += (expense['amount'] as num).toDouble();
      }

      return {
        'gross_earnings': totalGrossEarnings,
        'total_deductions': totalDeductions,
        'net_taxable_income': totalGrossEarnings - totalDeductions,
        'estimated_total_tax': totalEstimatedTax,
        'quarterly_estimates': quarterlyEstimates,
        'self_employment_tax': totalGrossEarnings * 0.153,
        'federal_income_tax': totalEstimatedTax - (totalGrossEarnings * 0.153),
      };
    } catch (e) {
      debugPrint('Get tax liability preview error: $e');
      return _getDefaultTaxPreview();
    }
  }

  /// Add expense record
  Future<bool> addExpense({
    required String category,
    required double amount,
    required DateTime expenseDate,
    String? description,
    String? receiptUrl,
    bool isDeductible = true,
  }) async {
    try {
      if (!_auth.isAuthenticated) return false;

      await _client.from('expense_records').insert({
        'creator_user_id': _auth.currentUser!.id,
        'expense_category': category,
        'amount': amount,
        'expense_date': expenseDate.toIso8601String().split('T')[0],
        'description': description,
        'receipt_url': receiptUrl,
        'is_deductible': isDeductible,
      });

      return true;
    } catch (e) {
      debugPrint('Add expense error: $e');
      return false;
    }
  }

  /// Get performance metrics
  Future<Map<String, dynamic>> getPerformanceMetrics() async {
    try {
      if (!_auth.isAuthenticated) return {};

      final userId = _auth.currentUser!.id;

      // Get follower count (mock)
      final followerCount = 1250;

      // Get total revenue
      final snapshots = await _client
          .from('revenue_analytics_snapshots')
          .select('total_revenue, transaction_count')
          .eq('creator_user_id', userId)
          .gte(
            'snapshot_date',
            DateTime.now()
                .subtract(const Duration(days: 30))
                .toIso8601String()
                .split('T')[0],
          );

      double totalRevenue = 0;
      int totalTransactions = 0;

      for (final snapshot in snapshots as List) {
        totalRevenue += (snapshot['total_revenue'] as num).toDouble();
        totalTransactions += (snapshot['transaction_count'] as int);
      }

      return {
        'revenue_per_follower': followerCount > 0
            ? totalRevenue / followerCount
            : 0,
        'average_transaction_value': totalTransactions > 0
            ? totalRevenue / totalTransactions
            : 0,
        'customer_lifetime_value': 150.0, // Mock
        'earnings_velocity_daily': totalRevenue / 30,
        'weekly_run_rate': (totalRevenue / 30) * 7,
        'annual_projection': (totalRevenue / 30) * 365,
      };
    } catch (e) {
      debugPrint('Get performance metrics error: $e');
      return {};
    }
  }

  /// Export revenue report
  Future<String> exportRevenueReport({
    DateTime? startDate,
    DateTime? endDate,
    List<String>? metricsToInclude,
  }) async {
    try {
      if (!_auth.isAuthenticated) return '';

      final userId = _auth.currentUser!.id;
      final start =
          startDate ?? DateTime.now().subtract(const Duration(days: 30));
      final end = endDate ?? DateTime.now();

      final snapshots = await _client
          .from('revenue_analytics_snapshots')
          .select()
          .eq('creator_user_id', userId)
          .gte('snapshot_date', start.toIso8601String().split('T')[0])
          .lte('snapshot_date', end.toIso8601String().split('T')[0])
          .order('snapshot_date', ascending: true);

      final csvLines = <String>[
        'Date,Election Revenue,Marketplace Revenue,Ad Revenue,Referral Revenue,Total Revenue,Transaction Count',
      ];

      for (final snapshot in snapshots as List) {
        csvLines.add(
          '${snapshot['snapshot_date']},'
          '${snapshot['election_revenue']},'
          '${snapshot['marketplace_revenue']},'
          '${snapshot['ad_revenue']},'
          '${snapshot['referral_revenue']},'
          '${snapshot['total_revenue']},'
          '${snapshot['transaction_count']}',
        );
      }

      return csvLines.join('\n');
    } catch (e) {
      debugPrint('Export revenue report error: $e');
      return '';
    }
  }

  Map<String, dynamic> _getDefaultBreakdown() {
    return {
      'election_revenue': {
        'total': 0.0,
        'percentage': '0',
        'transaction_count': 0,
        'avg_per_election': 0.0,
        'trend': 'stable',
      },
      'marketplace_revenue': {
        'total': 0.0,
        'percentage': '0',
        'transaction_count': 0,
        'avg_per_service': 0.0,
        'trend': 'stable',
      },
      'ad_revenue': {
        'total': 0.0,
        'percentage': '0',
        'impressions': 0,
        'cpm': 0.0,
        'trend': 'stable',
      },
      'referral_revenue': {
        'total': 0.0,
        'percentage': '0',
        'referrals_count': 0,
        'conversion_rate': 0.0,
        'trend': 'stable',
      },
      'total_revenue': 0.0,
    };
  }

  Map<String, dynamic> _getDefaultTaxPreview() {
    return {
      'gross_earnings': 0.0,
      'total_deductions': 0.0,
      'net_taxable_income': 0.0,
      'estimated_total_tax': 0.0,
      'quarterly_estimates': [],
      'self_employment_tax': 0.0,
      'federal_income_tax': 0.0,
    };
  }

  String _getQuarterDueDate(int year, int quarter) {
    switch (quarter) {
      case 1:
        return '$year-04-15';
      case 2:
        return '$year-06-15';
      case 3:
        return '$year-09-15';
      case 4:
        return '$year-01-15';
      default:
        return '$year-04-15';
    }
  }
}
