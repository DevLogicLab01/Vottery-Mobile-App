import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/platform_analytics_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Personal Analytics: voting performance, earnings, achievement progress.
class PersonalAnalyticsDashboardScreen extends StatefulWidget {
  const PersonalAnalyticsDashboardScreen({super.key});

  @override
  State<PersonalAnalyticsDashboardScreen> createState() =>
      _PersonalAnalyticsDashboardScreenState();
}

class _PersonalAnalyticsDashboardScreenState
    extends State<PersonalAnalyticsDashboardScreen> {
  final PlatformAnalyticsService _analytics =
      PlatformAnalyticsService.instance;
  final AuthService _auth = AuthService.instance;
  final SupabaseService _supabase = SupabaseService.instance;

  bool _loading = true;
  Map<String, dynamic> _data = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final userId = _supabase.client.auth.currentUser?.id;
      final data = await _analytics.getPersonalAnalytics(userId);
      if (mounted) {
        setState(() {
          _data = data;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ErrorBoundaryWrapper(
      screenName: 'PersonalAnalyticsDashboard',
      onRetry: _load,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Personal Analytics',
          variant: CustomAppBarVariant.withBack,
        ),
        body: _loading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _load,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Your performance',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      _card(
                        theme,
                        Icons.how_to_vote,
                        'Votes cast',
                        '${_data['votesCast'] ?? 0}',
                        'Total votes in elections',
                      ),
                      SizedBox(height: 2.h),
                      _card(
                        theme,
                        Icons.account_balance_wallet,
                        'Current balance',
                        '\$${(_data['balance'] ?? 0).toStringAsFixed(2)}',
                        'Available earnings',
                      ),
                      SizedBox(height: 2.h),
                      _card(
                        theme,
                        Icons.trending_up,
                        'Total earned',
                        '\$${(_data['totalEarned'] ?? 0).toStringAsFixed(2)}',
                        'All-time earnings',
                      ),
                      SizedBox(height: 2.h),
                      _card(
                        theme,
                        Icons.emoji_events,
                        'Achievements',
                        '${_data['achievementsUnlocked'] ?? 0}',
                        'Badges unlocked',
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _card(ThemeData theme, IconData icon, String title, String value,
      String subtitle) {
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Icon(icon, size: 28.sp, color: AppTheme.primaryLight),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
