import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/subscription_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/subscription_analytics_dashboard_widget.dart';

class PremiumSubscriptionCenter extends StatefulWidget {
  const PremiumSubscriptionCenter({super.key});

  @override
  State<PremiumSubscriptionCenter> createState() =>
      _PremiumSubscriptionCenterState();
}

class _PremiumSubscriptionCenterState extends State<PremiumSubscriptionCenter> {
  bool _isLoading = true;
  bool _isAnnual = false;
  Map<String, dynamic>? _currentSubscription;

  @override
  void initState() {
    super.initState();
    _loadSubscriptionData();
  }

  Future<void> _loadSubscriptionData() async {
    setState(() => _isLoading = true);

    final subscription = await SubscriptionService.instance
        .getCurrentSubscription();

    setState(() {
      _currentSubscription = subscription;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'PremiumSubscriptionCenter',
      onRetry: _loadSubscriptionData,
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
          title: 'Premium Subscription',
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                child: Column(
                  children: [
                    _buildCurrentSubscriptionBanner(),
                    _buildBillingToggle(),
                    _buildSubscriptionTiers(),
                    SizedBox(height: 4.h),
                    // Add Subscription Analytics Dashboard
                    const SubscriptionAnalyticsDashboardWidget(),
                    SizedBox(height: 4.h),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildCurrentSubscriptionBanner() {
    if (_currentSubscription == null) {
      return Container(
        margin: EdgeInsets.all(4.w),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [AppTheme.primaryLight, Colors.purple],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          children: [
            CustomIconWidget(
              iconName: 'workspace_premium',
              size: 15.w,
              color: Colors.white,
            ),
            SizedBox(height: 2.h),
            Text(
              'Unlock Premium Features',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Get up to 5x VP multiplier and exclusive benefits',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white.withAlpha(230),
              ),
            ),
          ],
        ),
      );
    }

    final tierKey = (_currentSubscription?['tier'] ?? _currentSubscription?['plan_type'] ?? 'basic').toString().toLowerCase();
    final tierData = SubscriptionService.tiers[tierKey] ?? SubscriptionService.tiers['basic'];
    final vpMultiplier = (tierData?['vp_multiplier'] as num?)?.toDouble() ?? 2.0;
    final planName = tierData?['name'] ?? 'Basic';

    return Container(
      margin: EdgeInsets.all(4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green, width: 2),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'check_circle',
            size: 10.w,
            color: Colors.green,
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Active Subscription',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[900],
                  ),
                ),
                Text(
                  '$planName • ${vpMultiplier.toInt()}x VP multiplier',
                  style: TextStyle(fontSize: 12.sp, color: Colors.green[700]),
                ),
                if (_currentSubscription?['current_period_end'] != null)
                  Text(
                    'Next billing: ${DateTime.tryParse(_currentSubscription!['current_period_end'].toString())?.toString().split(' ').first ?? '—'}',
                    style: TextStyle(fontSize: 11.sp, color: Colors.green[600]),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBillingToggle() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(1.w),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAnnual = false),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: !_isAnnual ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  'Monthly',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: !_isAnnual
                        ? FontWeight.bold
                        : FontWeight.normal,
                    color: !_isAnnual
                        ? AppTheme.primaryLight
                        : AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _isAnnual = true),
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: _isAnnual ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Column(
                  children: [
                    Text(
                      'Annual',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: _isAnnual
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: _isAnnual
                            ? AppTheme.primaryLight
                            : AppTheme.textSecondaryLight,
                      ),
                    ),
                    Text(
                      'Save 17%',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubscriptionTiers() {
    return Column(
      children: [
        SizedBox(height: 3.h),
        _buildTierCard('basic', SubscriptionService.tiers['basic']!),
        _buildTierCard('pro', SubscriptionService.tiers['pro']!),
        _buildTierCard('elite', SubscriptionService.tiers['elite']!),
      ],
    );
  }

  Widget _buildTierCard(String tierId, Map<String, dynamic> tierData) {
    final isCurrentTier = _currentSubscription?['tier'] == tierId;
    final price = _isAnnual
        ? tierData['price_yearly']
        : tierData['price_monthly'];

    Color tierColor;
    switch (tierId) {
      case 'basic':
        tierColor = Colors.blue;
        break;
      case 'pro':
        tierColor = Colors.purple;
        break;
      case 'elite':
        tierColor = Colors.amber[700]!;
        break;
      default:
        tierColor = AppTheme.primaryLight;
    }

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: isCurrentTier ? tierColor : Colors.grey[300]!,
          width: isCurrentTier ? 3 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                decoration: BoxDecoration(
                  color: tierColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Text(
                  tierData['name'],
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: tierColor,
                  ),
                ),
              ),
              Spacer(),
              Text(
                '${tierData['vp_multiplier']}x',
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.bold,
                  color: tierColor,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            '\$${price.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          Text(
            _isAnnual ? 'per year' : 'per month',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          ...((tierData['features'] as List).map(
            (feature) => Padding(
              padding: EdgeInsets.only(bottom: 1.h),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'check',
                    size: 5.w,
                    color: tierColor,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      feature,
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          )),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: isCurrentTier
                  ? null
                  : () => _subscribe(tierId, _isAnnual ? 'yearly' : 'monthly'),
              style: ElevatedButton.styleFrom(
                backgroundColor: isCurrentTier ? Colors.grey : tierColor,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                isCurrentTier ? 'Current Plan' : 'Subscribe',
                style: TextStyle(fontSize: 14.sp, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _subscribe(String tier, String billingPeriod) async {
    final success = await SubscriptionService.instance.subscribe(
      tier: tier,
      billingPeriod: billingPeriod,
    );

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscription activated successfully!')),
      );
      _loadSubscriptionData();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Subscription failed. Please try again.')),
      );
    }
  }
}
