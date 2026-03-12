import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/bundle_size_tracker_widget.dart';
import './widgets/code_splitting_analyzer_widget.dart';
import './widgets/deferred_imports_manager_widget.dart';
import './widgets/lazy_asset_loading_widget.dart';
import './widgets/progressive_image_loader_widget.dart';
import './widgets/tree_shaking_optimizer_widget.dart';

class CodeSplittingPerformanceOptimizationHub extends StatefulWidget {
  const CodeSplittingPerformanceOptimizationHub({super.key});

  @override
  State<CodeSplittingPerformanceOptimizationHub> createState() =>
      _CodeSplittingPerformanceOptimizationHubState();
}

class _CodeSplittingPerformanceOptimizationHubState
    extends State<CodeSplittingPerformanceOptimizationHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _bundleMetrics = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadBundleMetrics();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadBundleMetrics() async {
    setState(() => _isLoading = true);

    await Future.delayed(const Duration(milliseconds: 800));

    setState(() {
      _bundleMetrics = {
        'current_bundle_size': 35.2,
        'original_bundle_size': 85.0,
        'reduction_percentage': 58.6,
        'deferred_routes': 42,
        'lazy_loaded_assets': 156,
        'tree_shaking_savings': 12.3,
      };
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CodeSplittingPerformanceOptimizationHub',
      onRetry: _loadBundleMetrics,
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
          title: 'Code Splitting & Lazy Loading',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadBundleMetrics,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : Column(
                children: [
                  _buildMetricsHeader(),
                  _buildTabBar(),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: const [
                        BundleSizeTrackerWidget(),
                        DeferredImportsManagerWidget(),
                        LazyAssetLoadingWidget(),
                        ProgressiveImageLoaderWidget(),
                        TreeShakingOptimizerWidget(),
                        CodeSplittingAnalyzerWidget(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildMetricsHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Current Size',
                  '${_bundleMetrics['current_bundle_size']} MB',
                  AppTheme.accentLight,
                  Icons.check_circle,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  'Original Size',
                  '${_bundleMetrics['original_bundle_size']} MB',
                  AppTheme.textSecondaryLight,
                  Icons.storage,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _buildMetricCard(
                  'Reduction',
                  '${_bundleMetrics['reduction_percentage']}%',
                  AppTheme.primaryLight,
                  Icons.trending_down,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: _buildMetricCard(
                  'Deferred Routes',
                  '${_bundleMetrics['deferred_routes']}',
                  AppTheme.secondaryLight,
                  Icons.route,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 5.w, color: color),
              SizedBox(width: 2.w),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppTheme.primaryLight,
        unselectedLabelColor: AppTheme.textSecondaryLight,
        indicatorColor: AppTheme.primaryLight,
        labelStyle: TextStyle(fontSize: 10.sp, fontWeight: FontWeight.w600),
        isScrollable: true,
        tabs: const [
          Tab(text: 'Bundle Size'),
          Tab(text: 'Deferred Imports'),
          Tab(text: 'Lazy Assets'),
          Tab(text: 'Progressive Images'),
          Tab(text: 'Tree Shaking'),
          Tab(text: 'Analysis'),
        ],
      ),
    );
  }
}
