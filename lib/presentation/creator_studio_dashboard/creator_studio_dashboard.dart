import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../routes/app_routes.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/creator_tier_widget.dart';

/// Creator Studio Dashboard - Comprehensive analytics and content management
/// Empowers creators with revenue tracking, audience insights, and creation tools
class CreatorStudioDashboard extends StatefulWidget {
  const CreatorStudioDashboard({super.key});

  @override
  State<CreatorStudioDashboard> createState() => _CreatorStudioDashboardState();
}

class _CreatorStudioDashboardState extends State<CreatorStudioDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;

  // Mock creator data
  final Map<String, dynamic> _creatorData = {
    'tier': 'Gold Creator',
    'tier_level': 3,
    'total_earnings': 2450.75,
    'monthly_earnings': 850.50,
    'revenue_share_percentage': 70,
    'vp_earnings': 15420,
    'ad_revenue': 1200.25,
    'subscription_income': 1250.50,
    'follower_count': 12450,
    'total_views': 89500,
    'engagement_rate': 8.5,
    'content_count': 45,
    'vote_engagement_rate': 12.3,
    'jolt_view_count': 45200,
    'prediction_accuracy': 0.85,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadCreatorData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadCreatorData() async {
    setState(() => _isLoading = true);
    // Simulate API call
    await Future.delayed(Duration(seconds: 1));
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CreatorStudioDashboard',
      onRetry: _loadCreatorData,
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
          title: 'Creator Studio',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'monetization_on',
                size: 6.w,
                color: AppTheme.vibrantYellow,
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.realTimeCreatorEarningsWidget,
                );
              },
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: 'account_balance',
                size: 6.w,
                color: Colors.green,
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.creatorRevenueTransparencyHub,
                );
              },
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: 'verified_user',
                size: 6.w,
                color: AppTheme.primaryLight,
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.creatorVerificationKycScreen,
                );
              },
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: 'school',
                size: 6.w,
                color: Colors.orange,
              ),
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  AppRoutes.creatorOnboardingWizard,
                );
              },
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: 'military_tech',
                size: 6.w,
                color: Color(0xFFFFD700),
              ),
              onPressed: () {
                Navigator.pushNamed(context, AppRoutes.creatorTierDashboardScreen);
              },
            ),
            IconButton(
              icon: CustomIconWidget(
                iconName: 'settings',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: () {
                // Navigate to creator settings
              },
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Creator tier status header
                    CreatorTierWidget(
                      tier: _creatorData['tier'] as String,
                      tierLevel: _creatorData['tier_level'] as int,
                      totalEarnings: _creatorData['total_earnings'] as double,
                      monthlyEarnings:
                          _creatorData['monthly_earnings'] as double,
                      revenueSharePercentage:
                          _creatorData['revenue_share_percentage'] as int,
                    ),

                    // Tab bar
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        controller: _tabController,
                        labelColor: AppTheme.primaryLight,
                        unselectedLabelColor: AppTheme.textSecondaryLight,
                        indicatorColor: AppTheme.primaryLight,
                        labelStyle: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        tabs: [
                          Tab(text: 'Performance'),
                          Tab(text: 'Revenue'),
                          Tab(text: 'Audience'),
                          Tab(text: 'Create'),
                        ],
                      ),
                    ),

                    // Tab views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Performance tab
                          Center(child: Text('Content Performance Widget')),

                          // Revenue tab
                          Center(child: Text('Revenue Chart Widget')),

                          // Audience tab
                          Center(child: Text('Audience Insights Widget')),

                          // Create tab
                          Center(child: Text('Creation Tools Widget')),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
