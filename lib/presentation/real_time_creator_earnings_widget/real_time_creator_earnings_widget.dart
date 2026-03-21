import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../services/creator_earnings_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/animated_vp_counter_widget.dart';
import './widgets/daily_earnings_chart_widget.dart';
import './widgets/earnings_breakdown_widget.dart';
import './widgets/earnings_transaction_feed_widget.dart';
import './widgets/settlement_preview_widget.dart';

class RealTimeCreatorEarningsWidget extends StatefulWidget {
  const RealTimeCreatorEarningsWidget({super.key});

  @override
  State<RealTimeCreatorEarningsWidget> createState() =>
      _RealTimeCreatorEarningsWidgetState();
}

class _RealTimeCreatorEarningsWidgetState
    extends State<RealTimeCreatorEarningsWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CreatorEarningsService _earningsService =
      CreatorEarningsService.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'RealTimeCreatorEarningsWidget',
      onRetry: () => setState(() {}),
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          leading: Padding(
            padding: EdgeInsets.only(left: 4.w),
            child: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          title: 'Creator Earnings',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'download',
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              onPressed: _exportEarningsReport,
            ),
          ],
        ),
        body: StreamBuilder<Map<String, dynamic>>(
          stream: _earningsService.streamEarningsSummary(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SkeletonDashboard();
            }

            final summary = snapshot.data ?? {};

            return summary.isEmpty
                ? NoEarningsEmptyState(
                    onLearnMore: () {
                      // Navigate to monetization guide
                    },
                  )
                : SingleChildScrollView(
                    padding: EdgeInsets.all(4.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Live VP Balance Counter
                        AnimatedVpCounterWidget(
                          vpBalance: summary['available_balance_vp'] ?? 0,
                          usdBalance: summary['available_balance_usd'] ?? 0.0,
                        ),
                        SizedBox(height: 3.h),

                        // Real-time Transaction Feed
                        EarningsTransactionFeedWidget(),
                        SizedBox(height: 3.h),

                        // Earnings Breakdown Tabs
                        Container(
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceLight,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Column(
                            children: [
                              TabBar(
                                controller: _tabController,
                                labelColor: AppTheme.primaryLight,
                                unselectedLabelColor:
                                    AppTheme.textSecondaryLight,
                                indicatorColor: AppTheme.primaryLight,
                                tabs: [
                                  Tab(text: 'Daily'),
                                  Tab(text: 'Weekly'),
                                  Tab(text: 'Monthly'),
                                ],
                              ),
                              SizedBox(
                                height: 35.h,
                                child: TabBarView(
                                  controller: _tabController,
                                  children: [
                                    DailyEarningsChartWidget(),
                                    EarningsBreakdownWidget(period: 'weekly'),
                                    EarningsBreakdownWidget(period: 'monthly'),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: 3.h),

                        // Settlement Preview
                        SettlementPreviewWidget(),
                        SizedBox(height: 3.h),

                        // Top Performing Elections
                        _buildTopElectionsSection(),
                      ],
                    ),
                  );
          },
        ),
      ),
    );
  }

  Widget _buildTopElectionsSection() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Top Performing Elections',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.creatorAnalyticsDashboard);
                },
                child: Text('View All'),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: _earningsService.getTopElectionsByRevenue(limit: 5),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: EdgeInsets.all(2.h),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              final elections = snapshot.data ?? [];

              if (elections.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(2.h),
                  child: Text(
                    'No election earnings yet',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                  ),
                );
              }

              return Column(
                children: elections.map((election) {
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(
                      backgroundColor: AppTheme.primaryLight.withAlpha(26),
                      child: CustomIconWidget(
                        iconName: 'how_to_vote',
                        size: 5.w,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    title: Text(
                      election['election_title'] ?? 'Untitled Election',
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textPrimaryLight,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Text(
                      '${election['transaction_count']} transactions',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    trailing: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${(election['total_usd_earned'] ?? 0.0).toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentLight,
                          ),
                        ),
                        Text(
                          '${election['total_vp_earned']} VP',
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _exportEarningsReport() async {
    try {
      final summary = await _earningsService.getEarningsSummary();
      final byElection = await _earningsService.getEarningsByElection(limit: 10);

      final totalUsd = ((summary['total_earned_usd'] ?? 0.0) as num)
          .toDouble()
          .toStringAsFixed(2);
      final totalVp = ((summary['total_earned_vp'] ?? 0) as num).toString();
      final availableUsd = ((summary['available_balance_usd'] ?? 0.0) as num)
          .toDouble()
          .toStringAsFixed(2);
      final availableVp = ((summary['available_balance_vp'] ?? 0) as num).toString();

      final topLines = byElection
          .map((row) {
            final title = row['election_title']?.toString() ?? 'Untitled Election';
            final usd = ((row['total_usd_earned'] ?? 0.0) as num)
                .toDouble()
                .toStringAsFixed(2);
            final vp = ((row['total_vp_earned'] ?? 0) as num).toString();
            return '- $title: \$$usd | $vp VP';
          })
          .join('\n');

      final report = StringBuffer()
        ..writeln('Vottery Creator Earnings Report')
        ..writeln('Generated: ${DateTime.now().toIso8601String()}')
        ..writeln('')
        ..writeln('Totals')
        ..writeln('- Total earned: \$$totalUsd | $totalVp VP')
        ..writeln('- Available balance: \$$availableUsd | $availableVp VP')
        ..writeln('')
        ..writeln('Top elections')
        ..writeln(topLines.isEmpty ? '- No election earnings yet' : topLines);

      await Share.share(
        report.toString(),
        subject: 'Vottery creator earnings report',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not export report: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
