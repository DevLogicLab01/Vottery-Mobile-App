import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/brand_partnership_service.dart';
import '../../services/creator_monetization_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/active_campaign_card_widget.dart';
import './widgets/brand_directory_card_widget.dart';
import './widgets/opportunity_card_widget.dart';
import './widgets/partnership_history_card_widget.dart';
import './widgets/revenue_tracking_header_widget.dart';

/// Brand Partnership Hub - Facilitates advertiser relationships and campaign management
/// Connects creators with brand opportunities and tracks partnership performance
class BrandPartnershipHub extends StatefulWidget {
  const BrandPartnershipHub({super.key});

  @override
  State<BrandPartnershipHub> createState() => _BrandPartnershipHubState();
}

class _BrandPartnershipHubState extends State<BrandPartnershipHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BrandPartnershipService _partnershipService =
      BrandPartnershipService.instance;
  final CreatorMonetizationService _monetizationService =
      CreatorMonetizationService.instance;

  bool _isLoading = true;
  String? _creatorId;
  Map<String, dynamic> _revenueData = {};
  List<Map<String, dynamic>> _activeCampaigns = [];
  List<Map<String, dynamic>> _opportunities = [];
  List<Map<String, dynamic>> _history = [];
  List<Map<String, dynamic>> _brands = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      // Get creator profile
      final creatorProfile = await _monetizationService.getCreatorTier();
      _creatorId = creatorProfile['id'] as String?;

      if (_creatorId != null) {
        // Load all data in parallel
        final results = await Future.wait([
          _partnershipService.getRevenueTracking(creatorId: _creatorId!),
          _partnershipService.getCreatorApplications(creatorId: _creatorId!),
          _partnershipService.getAvailableOpportunities(creatorId: _creatorId!),
          _partnershipService.getPartnershipHistory(creatorId: _creatorId!),
          _partnershipService.getBrandDirectory(),
        ]);

        setState(() {
          _revenueData = results[0] as Map<String, dynamic>;
          _activeCampaigns = results[1] as List<Map<String, dynamic>>;
          _opportunities = results[2] as List<Map<String, dynamic>>;
          _history = results[3] as List<Map<String, dynamic>>;
          _brands = results[4] as List<Map<String, dynamic>>;
        });
      }
    } catch (e) {
      debugPrint('Load partnership data error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'BrandPartnershipHub',
      onRetry: _loadData,
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
          title: 'Brand Partnerships',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadData,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : (_activeCampaigns.isEmpty &&
                  _opportunities.isEmpty &&
                  _history.isEmpty &&
                  _brands.isEmpty)
            ? NoDataEmptyState(
                title: 'No Brand Partnerships',
                description:
                    'Connect with brands to monetize your content and grow your audience.',
                onRefresh: _loadData,
              )
            : SingleChildScrollView(
                child: Column(
                  children: [
                    // Revenue tracking header
                    RevenueTrackingHeaderWidget(
                      totalEarnings: _revenueData['total_earnings'] ?? 0.0,
                      thisMonthEarnings:
                          _revenueData['this_month_earnings'] ?? 0.0,
                      activeCampaigns: _revenueData['active_campaigns'] ?? 0,
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
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                        ),
                        isScrollable: true,
                        tabs: [
                          Tab(text: 'Active'),
                          Tab(text: 'Opportunities'),
                          Tab(text: 'History'),
                          Tab(text: 'Brands'),
                        ],
                      ),
                    ),

                    // Tab views
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          // Active Campaigns
                          _buildActiveCampaignsTab(),

                          // Available Opportunities
                          _buildOpportunitiesTab(),

                          // Partnership History
                          _buildHistoryTab(),

                          // Brand Directory
                          _buildBrandDirectoryTab(),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildActiveCampaignsTab() {
    if (_activeCampaigns.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'campaign',
              size: 15.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No Active Campaigns',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Apply to opportunities to start earning',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _activeCampaigns.length,
        itemBuilder: (context, index) {
          return ActiveCampaignCardWidget(
            campaign: _activeCampaigns[index],
            onTap: () {
              // Navigate to campaign details
            },
          );
        },
      ),
    );
  }

  Widget _buildOpportunitiesTab() {
    if (_opportunities.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'search',
              size: 15.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No Opportunities Available',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Check back soon for new campaigns',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _opportunities.length,
        itemBuilder: (context, index) {
          return OpportunityCardWidget(
            opportunity: _opportunities[index],
            onApply: () async {
              // Show application dialog
              await _showApplicationDialog(_opportunities[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildHistoryTab() {
    if (_history.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'history',
              size: 15.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No Partnership History',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Complete campaigns to build your history',
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _history.length,
        itemBuilder: (context, index) {
          return PartnershipHistoryCardWidget(partnership: _history[index]);
        },
      ),
    );
  }

  Widget _buildBrandDirectoryTab() {
    if (_brands.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CustomIconWidget(
              iconName: 'business',
              size: 15.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No Verified Brands',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _brands.length,
        itemBuilder: (context, index) {
          return BrandDirectoryCardWidget(brand: _brands[index]);
        },
      ),
    );
  }

  Future<void> _showApplicationDialog(Map<String, dynamic> opportunity) async {
    // Show application form dialog
    // This would be a full-screen form in production
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apply to Campaign'),
        content: Text(
          'Application form would go here with portfolio submission, audience demographics, and collaboration proposal.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              // Submit application
              if (_creatorId != null) {
                final success = await _partnershipService.applyToCampaign(
                  campaignId: opportunity['id'],
                  creatorId: _creatorId!,
                  applicationData: {
                    'portfolio': [],
                    'demographics': {},
                    'proposal': 'Sample proposal',
                    'expected_reach': 10000,
                    'expected_engagement_rate': 5.0,
                    'content_plan': [],
                  },
                );

                if (success && mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Application submitted successfully'),
                      backgroundColor: AppTheme.accentLight,
                    ),
                  );
                  _loadData();
                }
              }
            },
            child: Text('Submit'),
          ),
        ],
      ),
    );
  }
}
