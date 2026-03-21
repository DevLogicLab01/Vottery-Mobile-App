import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/perplexity_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';

class CreatorRevenueForecastingDashboard extends StatefulWidget {
  const CreatorRevenueForecastingDashboard({super.key});

  @override
  State<CreatorRevenueForecastingDashboard> createState() =>
      _CreatorRevenueForecastingDashboardState();
}

class _CreatorRevenueForecastingDashboardState
    extends State<CreatorRevenueForecastingDashboard> {
  bool _loading = false;
  bool _loadingContext = false;
  Map<String, dynamic>? _forecast;
  String? _error;
  String? _creatorUserId;
  Map<String, dynamic> _creatorContext = const {};

  Future<void> _loadCreatorContext() async {
    setState(() {
      _loadingContext = true;
      _error = null;
    });
    try {
      final userId = AuthService.instance.currentUser?.id;
      if (userId == null) {
        setState(() {
          _error = 'Sign in required to generate creator forecast.';
          _creatorUserId = null;
          _creatorContext = const {};
        });
        return;
      }

      final profile = await SupabaseService.instance.client
          .from('user_profiles')
          .select('display_name, full_name, tier, country')
          .eq('id', userId)
          .maybeSingle();

      final elections = await SupabaseService.instance.client
          .from('elections')
          .select('id, category, vote_count')
          .eq('creator_id', userId);

      final wallet = await SupabaseService.instance.client
          .from('wallet_transactions')
          .select('amount')
          .eq('user_id', userId)
          .inFilter('transaction_type', ['creator_payout', 'carousel_revenue']);

      final electionList = List<Map<String, dynamic>>.from(elections);
      final walletList = List<Map<String, dynamic>>.from(wallet);
      final totalVotes = electionList.fold<int>(
        0,
        (sum, e) => sum + ((e['vote_count'] as num?)?.toInt() ?? 0),
      );
      final totalElections = electionList.length;
      final avgParticipation =
          totalElections == 0 ? 0 : (totalVotes / totalElections).round();
      final revenue = walletList.fold<double>(
        0.0,
        (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0.0),
      );
      final categories = <String, int>{};
      for (final e in electionList) {
        final category = (e['category'] ?? 'General').toString();
        categories[category] = (categories[category] ?? 0) + 1;
      }
      final topCategories = categories.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      setState(() {
        _creatorUserId = userId;
        _creatorContext = {
          'creator_name':
              (profile?['display_name'] ?? profile?['full_name'] ?? 'Creator')
                  .toString(),
          'creator_tier': (profile?['tier'] ?? 'Starter').toString(),
          'monthly_revenue': revenue,
          'growth_rate': 0.0,
          'audience_size': avgParticipation,
          'historical': [
            {
              'period': 'last_30_days',
              'revenue': revenue,
              'engagement': avgParticipation,
            },
            {
              'period': 'last_60_days',
              'revenue': revenue,
              'engagement': avgParticipation,
            },
            {
              'period': 'last_90_days',
              'revenue': revenue,
              'engagement': avgParticipation,
            },
          ],
          'top_categories': topCategories.take(3).map((e) => e.key).toList(),
          'zones': [_resolveZone(profile?['country']?.toString())],
        };
      });
    } catch (_) {
      setState(() {
        _error = 'Unable to load creator metrics for forecasting.';
        _creatorUserId = null;
        _creatorContext = const {};
      });
    } finally {
      if (mounted) {
        setState(() {
          _loadingContext = false;
        });
      }
    }
  }

  String _resolveZone(String? countryCode) {
    switch ((countryCode ?? '').toUpperCase()) {
      case 'US':
      case 'CA':
        return 'USA';
      case 'GB':
      case 'DE':
      case 'FR':
        return 'Western Europe';
      case 'PL':
      case 'RO':
        return 'Eastern Europe';
      case 'IN':
        return 'India';
      case 'BR':
      case 'MX':
        return 'Latin America';
      case 'NG':
      case 'ZA':
        return 'Africa';
      case 'AE':
      case 'SA':
        return 'Middle East/Asia';
      case 'AU':
      case 'NZ':
        return 'Australasia';
      default:
        return 'USA';
    }
  }

  Future<void> _generateForecast() async {
    if (_creatorUserId == null) {
      setState(() {
        _error = 'Sign in required to generate creator forecast.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final data = await PerplexityService.instance
          .generateStrategicPlanWithForecasting(businessData: {
        'feature': 'creator_revenue_forecasting_dashboard',
        'creator_user_id': _creatorUserId,
        ..._creatorContext,
      });

      setState(() {
        _forecast = data;
      });
    } catch (e) {
      setState(() {
        _error = 'Unable to generate forecast right now.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCreatorContext().then((_) => _generateForecast());
  }

  @override
  Widget build(BuildContext context) {
    final forecast60 = _forecast?['forecast_60d'] as Map<String, dynamic>?;
    final forecast90 = _forecast?['forecast_90d'] as Map<String, dynamic>?;
    final recommendations =
        (_forecast?['strategic_recommendations'] as List?) ?? const [];

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        title: 'Creator Revenue Forecasting',
        leading: Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
          ),
        ),
        actions: [
          IconButton(
            onPressed: (_loading || _loadingContext) ? null : _generateForecast,
            icon: (_loading || _loadingContext)
                ? SizedBox(
                    width: 5.w,
                    height: 5.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : CustomIconWidget(
                    iconName: 'refresh',
                    size: 5.w,
                    color: AppTheme.textPrimaryLight,
                  ),
          ),
        ],
      ),
      body: ListView(
        padding: EdgeInsets.all(4.w),
        children: [
          if (_loadingContext) const LinearProgressIndicator(minHeight: 2),
          _buildForecastCard(
            title: '60-Day Revenue Forecast',
            forecast: forecast60,
            color: Colors.blue,
          ),
          SizedBox(height: 2.h),
          _buildForecastCard(
            title: '90-Day Revenue Forecast',
            forecast: forecast90,
            color: Colors.purple,
          ),
          SizedBox(height: 2.h),
          _buildScenarioCard(forecast90),
          SizedBox(height: 2.h),
          _buildRecommendationsCard(recommendations),
          if (_error != null) ...[
            SizedBox(height: 2.h),
            Text(
              _error!,
              style: TextStyle(
                color: Colors.red,
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_creatorUserId == null && !_loadingContext) ...[
            SizedBox(height: 1.h),
            Text(
              'Sign in to continue with creator revenue forecasting.',
              style: TextStyle(
                color: AppTheme.textSecondaryLight,
                fontSize: 9.5.sp,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildForecastCard({
    required String title,
    required Map<String, dynamic>? forecast,
    required Color color,
  }) {
    final growth = (forecast?['revenue_growth'] as Map?)?['predicted'];
    final confidence = (forecast?['revenue_growth'] as Map?)?['confidence'];
    final engagement = (forecast?['engagement_rate'] as Map?)?['predicted'];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Projected Revenue Growth: ${growth ?? 0}%',
            style: TextStyle(
              fontSize: 11.sp,
              color: color,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 0.6.h),
          Text(
            'Confidence: ${((confidence ?? 0.0) * 100).toStringAsFixed(0)}%',
            style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondaryLight),
          ),
          SizedBox(height: 0.6.h),
          Text(
            'Engagement Estimate: ${engagement ?? 0}%',
            style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondaryLight),
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(Map<String, dynamic>? forecast90) {
    final base = ((forecast90?['revenue_growth'] as Map?)?['predicted'] ?? 0)
        .toDouble();
    final conservative = (base * 0.72).toStringAsFixed(1);
    final optimistic = (base * 1.35).toStringAsFixed(1);

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Scenario Comparison',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text('Conservative: +$conservative%'),
          Text('Base: +${base.toStringAsFixed(1)}%'),
          Text('Optimistic: +$optimistic%'),
        ],
      ),
    );
  }

  Widget _buildRecommendationsCard(List recommendations) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue Recommendations',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          if (recommendations.isEmpty)
            Text(
              'No recommendations available yet.',
              style: TextStyle(fontSize: 10.sp, color: AppTheme.textSecondaryLight),
            )
          else
            ...recommendations.take(5).map((item) {
              final rec = item as Map<String, dynamic>;
              return Padding(
                padding: EdgeInsets.only(bottom: 1.h),
                child: Text(
                  '- ${rec['recommendation'] ?? rec['action'] ?? 'Recommendation'}',
                  style: TextStyle(fontSize: 10.5.sp),
                ),
              );
            }),
        ],
      ),
    );
  }
}
