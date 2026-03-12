import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/brand_partnership_service.dart';
import '../../services/creator_monetization_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/active_campaigns_widget.dart';
import './widgets/brand_discovery_feed_widget.dart';
import './widgets/partnership_proposals_widget.dart';
import './widgets/partnership_status_header_widget.dart';
import './widgets/portfolio_builder_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Creator Brand Partnership Hub - Comprehensive brand collaboration management
/// Portfolio showcasing, audience analytics sharing, and partnership workflow automation
class CreatorBrandPartnershipHub extends StatefulWidget {
  const CreatorBrandPartnershipHub({super.key});

  @override
  State<CreatorBrandPartnershipHub> createState() =>
      _CreatorBrandPartnershipHubState();
}

class _CreatorBrandPartnershipHubState extends State<CreatorBrandPartnershipHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final BrandPartnershipService _partnershipService =
      BrandPartnershipService.instance;
  final CreatorMonetizationService _monetizationService =
      CreatorMonetizationService.instance;
  final SupabaseService _supabaseService = SupabaseService.instance;

  bool _isLoading = true;
  bool _isVerifiedCreator = false;
  String? _creatorId;
  Map<String, dynamic> _partnershipStatus = {};
  List<Map<String, dynamic>> _portfolioItems = [];
  List<Map<String, dynamic>> _opportunities = [];
  List<Map<String, dynamic>> _proposals = [];
  List<Map<String, dynamic>> _activeCampaigns = [];

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
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      _creatorId = userId;

      // Check verified creator status
      final profileResponse = await _supabaseService.client
          .from('user_profiles')
          .select('creator_verification_status, follower_count')
          .eq('id', userId)
          .single();

      _isVerifiedCreator =
          profileResponse['creator_verification_status'] == 'approved' &&
          (profileResponse['follower_count'] ?? 0) > 1000;

      if (!_isVerifiedCreator) {
        setState(() => _isLoading = false);
        return;
      }

      // Load partnership status
      await _loadPartnershipStatus();

      // Load portfolio items
      await _loadPortfolioItems();

      // Load brand opportunities
      await _loadBrandOpportunities();

      // Load proposals
      await _loadProposals();

      // Load active campaigns
      await _loadActiveCampaigns();
    } catch (e) {
      debugPrint('Load data error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadPartnershipStatus() async {
    try {
      final response = await _supabaseService.client
          .from('brand_partnerships')
          .select('*')
          .eq('creator_id', _creatorId!)
          .eq('status', 'active');

      final activeCampaignsCount = response.length;

      final revenueResponse = await _supabaseService.client
          .from('partnership_history')
          .select('total_revenue')
          .eq('creator_id', _creatorId!);

      final totalRevenue = revenueResponse.fold<double>(
        0.0,
        (sum, item) => sum + ((item['total_revenue'] ?? 0.0) as num).toDouble(),
      );

      final portfolioResponse = await _supabaseService.client
          .from('creator_portfolio_items')
          .select('*')
          .eq('creator_id', _creatorId!);

      final portfolioCompletion = portfolioResponse.isEmpty
          ? 0
          : (portfolioResponse
                        .where((item) => item['is_featured'] == true)
                        .length /
                    portfolioResponse.length *
                    100)
                .round();

      setState(() {
        _partnershipStatus = {
          'active_campaigns': activeCampaignsCount,
          'total_revenue': totalRevenue,
          'portfolio_completion': portfolioCompletion,
        };
      });
    } catch (e) {
      debugPrint('Load partnership status error: $e');
    }
  }

  Future<void> _loadPortfolioItems() async {
    try {
      final response = await _supabaseService.client
          .from('creator_portfolio_items')
          .select('*')
          .eq('creator_id', _creatorId!)
          .order('created_at', ascending: false);

      setState(
        () => _portfolioItems = List<Map<String, dynamic>>.from(response),
      );
    } catch (e) {
      debugPrint('Load portfolio items error: $e');
    }
  }

  Future<void> _loadBrandOpportunities() async {
    try {
      final response = await _supabaseService.client
          .from('brand_partnerships')
          .select(
            '*, user_profiles!brand_partnerships_brand_id_fkey(username, avatar_url)',
          )
          .eq('status', 'open')
          .order('created_at', ascending: false)
          .limit(20);

      setState(
        () => _opportunities = List<Map<String, dynamic>>.from(response),
      );
    } catch (e) {
      debugPrint('Load brand opportunities error: $e');
    }
  }

  Future<void> _loadProposals() async {
    try {
      final response = await _supabaseService.client
          .from('proposal_submissions')
          .select('*, brand_partnerships(campaign_name, brand_id)')
          .eq('creator_id', _creatorId!)
          .order('created_at', ascending: false);

      setState(() => _proposals = List<Map<String, dynamic>>.from(response));
    } catch (e) {
      debugPrint('Load proposals error: $e');
    }
  }

  Future<void> _loadActiveCampaigns() async {
    try {
      final response = await _supabaseService.client
          .from('brand_partnerships')
          .select('*, partnership_performance_metrics(*)')
          .eq('creator_id', _creatorId!)
          .eq('status', 'active')
          .order('created_at', ascending: false);

      setState(
        () => _activeCampaigns = List<Map<String, dynamic>>.from(response),
      );
    } catch (e) {
      debugPrint('Load active campaigns error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CreatorBrandPartnershipHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Brand Partnerships',
          variant: CustomAppBarVariant.withBack,
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : !_isVerifiedCreator
            ? _buildVerificationRequiredView()
            : Column(
                children: [
                  PartnershipStatusHeaderWidget(
                    activeCampaigns:
                        _partnershipStatus['active_campaigns'] ?? 0,
                    totalRevenue: _partnershipStatus['total_revenue'] ?? 0.0,
                    portfolioCompletion:
                        _partnershipStatus['portfolio_completion'] ?? 0,
                  ),
                  SizedBox(height: 2.h),
                  TabBar(
                    controller: _tabController,
                    labelColor: Theme.of(context).primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: Theme.of(context).primaryColor,
                    labelStyle: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                    tabs: const [
                      Tab(text: 'Portfolio'),
                      Tab(text: 'Discover'),
                      Tab(text: 'Proposals'),
                      Tab(text: 'Active'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        PortfolioBuilderWidget(
                          portfolioItems: _portfolioItems,
                          onRefresh: _loadPortfolioItems,
                        ),
                        BrandDiscoveryFeedWidget(
                          opportunities: _opportunities,
                          onRefresh: _loadBrandOpportunities,
                        ),
                        PartnershipProposalsWidget(
                          proposals: _proposals,
                          onRefresh: _loadProposals,
                        ),
                        ActiveCampaignsWidget(
                          campaigns: _activeCampaigns,
                          onRefresh: _loadActiveCampaigns,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildVerificationRequiredView() {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.verified_user_outlined, size: 20.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'Verification Required',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'To access brand partnerships, you need:\n\n• Verified creator status (approved)\n• At least 1,000 followers',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey[600],
                height: 1.5,
              ),
            ),
            SizedBox(height: 3.h),
            ElevatedButton(
              onPressed: () {
                Navigator.pushNamed(
                  context,
                  '/creator-verification-kyc',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                'Start Verification',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}