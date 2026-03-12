import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/marketplace_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/marketplace_analytics_widget.dart';
import './widgets/marketplace_discovery_widget.dart';
import './widgets/marketplace_transactions_widget.dart';
import './widgets/my_services_widget.dart';

/// Creator Marketplace Screen
/// Service monetization through listings, transactions, and revenue tracking
class CreatorMarketplace extends StatefulWidget {
  const CreatorMarketplace({super.key});

  @override
  State<CreatorMarketplace> createState() => _CreatorMarketplaceState();
}

class _CreatorMarketplaceState extends State<CreatorMarketplace>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MarketplaceService _marketplaceService = MarketplaceService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _allServices = [];
  List<Map<String, dynamic>> _myServices = [];
  List<Map<String, dynamic>> _myTransactions = [];
  Map<String, dynamic> _analytics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMarketplaceData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadMarketplaceData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _marketplaceService.getMarketplaceServices(),
        _marketplaceService.getMyServices(),
        _marketplaceService.getTransactions(asBuyer: false),
        _marketplaceService.getMarketplaceAnalytics(),
      ]);

      if (mounted) {
        setState(() {
          _allServices = results[0] as List<Map<String, dynamic>>;
          _myServices = results[1] as List<Map<String, dynamic>>;
          _myTransactions = results[2] as List<Map<String, dynamic>>;
          _analytics = results[3] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load marketplace data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _refreshData() async {
    await _loadMarketplaceData();
  }

  void _showCreateServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Create Service'),
        content: Text('Service creation form will be implemented here'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _refreshData();
            },
            child: Text('Create'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
        title: 'Creator Marketplace',
        actions: [
          IconButton(
            icon: CustomIconWidget(
              iconName: 'add_circle',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
            onPressed: _showCreateServiceDialog,
          ),
          IconButton(
            icon: CustomIconWidget(
              iconName: 'refresh',
              size: 6.w,
              color: AppTheme.textPrimaryLight,
            ),
            onPressed: _refreshData,
          ),
        ],
      ),
      body: _isLoading
          ? _buildSkeletonLoader()
          : _allServices.isEmpty && _myServices.isEmpty
          ? _buildEmptyState()
          : RefreshIndicator(
              onRefresh: _refreshData,
              child: Column(
                children: [
                  Container(
                    color: AppTheme.surfaceLight,
                    child: TabBar(
                      controller: _tabController,
                      labelColor: AppTheme.primaryLight,
                      unselectedLabelColor: AppTheme.textSecondaryLight,
                      indicatorColor: AppTheme.primaryLight,
                      isScrollable: true,
                      tabs: [
                        Tab(text: 'Discover'),
                        Tab(text: 'My Services'),
                        Tab(text: 'Transactions'),
                        Tab(text: 'Analytics'),
                      ],
                    ),
                  ),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        MarketplaceDiscoveryWidget(
                          services: _allServices,
                          onRefresh: _refreshData,
                        ),
                        MyServicesWidget(
                          services: _myServices,
                          onRefresh: _refreshData,
                        ),
                        MarketplaceTransactionsWidget(
                          transactions: _myTransactions,
                          onRefresh: _refreshData,
                        ),
                        MarketplaceAnalyticsWidget(analytics: _analytics),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildSkeletonLoader() {
    final theme = Theme.of(context);
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: 6,
      itemBuilder: (context, index) {
        return _buildSkeletonServiceCard(theme);
      },
    );
  }

  Widget _buildSkeletonServiceCard(ThemeData theme) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 15.w,
                height: 15.w,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50.w,
                      height: 2.5.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      width: 30.w,
                      height: 2.h,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.onSurface.withValues(
                          alpha: 0.1,
                        ),
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            width: double.infinity,
            height: 2.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
          SizedBox(height: 1.h),
          Container(
            width: 70.w,
            height: 2.h,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(4.0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'storefront',
                  color: theme.colorScheme.primary,
                  size: 60,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'No Services Available',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Start monetizing your skills by creating your first service listing.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            ElevatedButton.icon(
              onPressed: _showCreateServiceDialog,
              icon: CustomIconWidget(
                iconName: 'add_business',
                color: theme.colorScheme.onPrimary,
                size: 20,
              ),
              label: Text(
                'Create Service',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 1.8.h),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
