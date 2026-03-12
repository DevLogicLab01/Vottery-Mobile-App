import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/carousel_creator_tiers_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Carousel Creator Tiers Management Hub providing 4-tier subscription system
/// with VIP sponsorship priority, premium analytics, and exclusive creator tools
class CarouselCreatorTiersManagementHub extends StatefulWidget {
  const CarouselCreatorTiersManagementHub({super.key});

  @override
  State<CarouselCreatorTiersManagementHub> createState() =>
      _CarouselCreatorTiersManagementHubState();
}

class _CarouselCreatorTiersManagementHubState
    extends State<CarouselCreatorTiersManagementHub>
    with SingleTickerProviderStateMixin {
  final CarouselCreatorTiersService _tiersService =
      CarouselCreatorTiersService.instance;

  late TabController _tabController;
  StreamSubscription? _subscriptionStream;

  List<Map<String, dynamic>> _allTiers = [];
  Map<String, dynamic>? _currentSubscription;
  List<Map<String, dynamic>> _featureFlags = [];
  Map<String, dynamic> _tierAnalytics = {};
  bool _isLoading = true;
  int _currentTierLevel = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
    _setupSubscriptionStream();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _subscriptionStream?.cancel();
    super.dispose();
  }

  void _setupSubscriptionStream() {
    // Remove this line - streamUserSubscription() method doesn't exist
    // Use polling or other mechanism if real-time updates are needed
    /*
    _subscriptionStream = _tiersService.streamUserSubscription().listen((
      subscription,
    ) {
      if (mounted) {
        setState(() {
          _currentSubscription = subscription;
          if (subscription != null) {
            final tier =
                subscription['carousel_creator_tiers'] as Map<String, dynamic>?;
            _currentTierLevel = tier?['tier_level'] as int? ?? 1;
          }
        });
      }
    });
    */
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final results = await Future.wait([
      _tiersService.getAllTiers(),
      _tiersService.getUserSubscription(),
      _tiersService.getAllFeatureFlags(),
      _tiersService.getTierAnalytics(),
    ]);

    if (mounted) {
      setState(() {
        _allTiers = results[0] as List<Map<String, dynamic>>;
        _currentSubscription = results[1] as Map<String, dynamic>?;
        _featureFlags = results[2] as List<Map<String, dynamic>>;
        _tierAnalytics = results[3] as Map<String, dynamic>;

        if (_currentSubscription != null) {
          final tier =
              _currentSubscription!['carousel_creator_tiers']
                  as Map<String, dynamic>?;
          _currentTierLevel = tier?['tier_level'] as int? ?? 1;
        }

        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CarouselCreatorTiersManagementHub',
      child: Scaffold(
        appBar: CustomAppBar(title: 'Creator Tiers'),
        body: _isLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildCurrentTierHeader(),
                  TabBar(
                    controller: _tabController,
                    tabs: [
                      Tab(text: 'Tiers'),
                      Tab(text: 'Features'),
                      Tab(text: 'Analytics'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        _buildTiersTab(),
                        _buildFeaturesTab(),
                        _buildAnalyticsTab(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCurrentTierHeader() {
    final currentTier = _allTiers.firstWhere(
      (t) => t['tier_level'] == _currentTierLevel,
      orElse: () => _allTiers.isNotEmpty ? _allTiers.first : {},
    );

    if (currentTier.isEmpty) return SizedBox.shrink();

    final tierName = currentTier['tier_name'] as String? ?? 'Starter';
    final tierLevel = currentTier['tier_level'] as int? ?? 1;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: _getTierGradient(tierLevel),
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Current Tier',
            style: TextStyle(color: Colors.white, fontSize: 12.sp),
          ),
          SizedBox(height: 1.h),
          Text(
            tierName.toUpperCase(),
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (_currentSubscription != null) ...[
            SizedBox(height: 1.h),
            Text(
              'Renews: ${_formatDate(_currentSubscription!["current_period_end"])}',
              style: TextStyle(color: Colors.white70, fontSize: 11.sp),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTiersTab() {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        Text(
          'Choose Your Tier',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        ..._allTiers.map((tier) => _buildTierCard(tier)),
      ],
    );
  }

  Widget _buildTierCard(Map<String, dynamic> tier) {
    final tierName = tier['tier_name'] as String? ?? '';
    final tierLevel = tier['tier_level'] as int? ?? 1;
    final monthlyPrice = (tier['monthly_price'] as num?)?.toDouble() ?? 0.0;
    final annualPrice = (tier['annual_price'] as num?)?.toDouble();
    final benefits = tier['benefits'] as Map<String, dynamic>? ?? {};
    final benefitsList = benefits['benefits'] as List? ?? [];

    final isCurrentTier = tierLevel == _currentTierLevel;
    final canUpgrade = tierLevel > _currentTierLevel;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: isCurrentTier ? 4.0 : 2.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: isCurrentTier
            ? BorderSide(color: Theme.of(context).primaryColor, width: 2.0)
            : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tierName.toUpperCase(),
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      monthlyPrice == 0
                          ? 'FREE'
                          : '\$${monthlyPrice.toStringAsFixed(2)}/month',
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                if (isCurrentTier)
                  Chip(
                    label: Text('Current'),
                    backgroundColor: Colors.green,
                    labelStyle: TextStyle(color: Colors.white),
                  ),
              ],
            ),
            if (annualPrice != null && annualPrice > 0) ...[
              SizedBox(height: 1.h),
              Text(
                'Annual: \$${annualPrice.toStringAsFixed(2)} (Save ${((monthlyPrice * 12 - annualPrice) / (monthlyPrice * 12) * 100).toStringAsFixed(0)}%)',
                style: TextStyle(fontSize: 11.sp, color: Colors.green),
              ),
            ],
            SizedBox(height: 2.h),
            Text(
              'Benefits:',
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            ...benefitsList.map(
              (benefit) => Padding(
                padding: EdgeInsets.only(bottom: 0.5.h),
                child: Row(
                  children: [
                    Icon(Icons.check_circle, color: Colors.green, size: 16.sp),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        benefit.toString(),
                        style: TextStyle(fontSize: 12.sp),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (canUpgrade) ...[
              SizedBox(height: 2.h),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _handleUpgrade(tier),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: 1.5.h),
                  ),
                  child: Text('Upgrade to ${tierName.toUpperCase()}'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturesTab() {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        Text(
          'Available Features',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        ..._featureFlags.map((flag) => _buildFeatureCard(flag)),
      ],
    );
  }

  Widget _buildFeatureCard(Map<String, dynamic> flag) {
    final featureName = flag['feature_name'] as String? ?? '';
    final description = flag['feature_description'] as String? ?? '';
    final enabledGlobally = flag['enabled_globally'] as bool? ?? false;
    final requiredTier = flag['requires_minimum_tier'] as int? ?? 1;

    final isAvailable = _currentTierLevel >= requiredTier && enabledGlobally;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isAvailable ? Icons.check_circle : Icons.lock,
                  color: isAvailable ? Colors.green : Colors.grey,
                  size: 18.sp,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    featureName.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              description,
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 1.h),
            Text(
              'Required: Tier $requiredTier+',
              style: TextStyle(
                fontSize: 11.sp,
                color: isAvailable ? Colors.green : Colors.orange,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyticsTab() {
    final totalSubscribers = _tierAnalytics['total_subscribers'] as int? ?? 0;
    final mrr =
        (_tierAnalytics['monthly_recurring_revenue'] as num?)?.toDouble() ??
        0.0;
    final tierCounts =
        _tierAnalytics['subscribers_by_tier'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        Text(
          'Tier Analytics',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        _buildAnalyticsCard(
          'Total Subscribers',
          totalSubscribers.toString(),
          Icons.people,
          Colors.blue,
        ),
        _buildAnalyticsCard(
          'Monthly Recurring Revenue',
          '\$${mrr.toStringAsFixed(2)}',
          Icons.attach_money,
          Colors.green,
        ),
        SizedBox(height: 2.h),
        Text(
          'Subscribers by Tier',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 1.h),
        ...tierCounts.entries.map(
          (entry) => Card(
            margin: EdgeInsets.only(bottom: 1.h),
            child: ListTile(
              title: Text(entry.key.toUpperCase()),
              trailing: Text(
                entry.value.toString(),
                style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnalyticsCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
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

  List<Color> _getTierGradient(int tierLevel) {
    switch (tierLevel) {
      case 1:
        return [Colors.grey[700]!, Colors.grey[900]!];
      case 2:
        return [Colors.blue[600]!, Colors.blue[900]!];
      case 3:
        return [Colors.purple[600]!, Colors.purple[900]!];
      case 4:
        return [Colors.amber[700]!, Colors.orange[900]!];
      default:
        return [Colors.grey[700]!, Colors.grey[900]!];
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'N/A';
    try {
      final dt = DateTime.parse(date.toString());
      return '${dt.month}/${dt.day}/${dt.year}';
    } catch (e) {
      return 'N/A';
    }
  }

  void _handleUpgrade(Map<String, dynamic> tier) {
    final tierName = tier['tier_name'] as String? ?? '';
    final monthlyPrice = (tier['monthly_price'] as num?)?.toDouble() ?? 0.0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Upgrade to ${tierName.toUpperCase()}'),
        content: Text(
          'You are about to upgrade to ${tierName.toUpperCase()} tier for \$${monthlyPrice.toStringAsFixed(2)}/month.\n\nThis will unlock premium features and benefits.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _processUpgrade(tier);
            },
            child: Text('Confirm Upgrade'),
          ),
        ],
      ),
    );
  }

  void _processUpgrade(Map<String, dynamic> tier) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Stripe checkout integration required. Contact support to complete upgrade.',
        ),
        duration: Duration(seconds: 3),
      ),
    );
  }
}
