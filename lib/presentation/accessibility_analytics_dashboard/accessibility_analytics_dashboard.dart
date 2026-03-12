import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/accessibility_preferences_service.dart';
import '../../services/ga4_analytics_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class AccessibilityAnalyticsDashboard extends StatefulWidget {
  const AccessibilityAnalyticsDashboard({super.key});

  @override
  State<AccessibilityAnalyticsDashboard> createState() =>
      _AccessibilityAnalyticsDashboardState();
}

class _AccessibilityAnalyticsDashboardState
    extends State<AccessibilityAnalyticsDashboard> {
  final AccessibilityPreferencesService _accessibilityService =
      AccessibilityPreferencesService.instance;
  final GA4AnalyticsService _analyticsService = GA4AnalyticsService.instance;

  bool _isLoading = true;
  Map<String, dynamic> _adoptionRates = {};
  Map<String, dynamic> _optimizationReports = {};

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _accessibilityService.getAccessibilityAdoptionRates(),
        _accessibilityService.getAccessibilityOptimizationReports(),
      ]);

      if (mounted) {
        setState(() {
          _adoptionRates = results[0];
          _optimizationReports = results[1];
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load accessibility analytics error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AccessibilityAnalyticsDashboard',
      onRetry: _loadAnalytics,
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
          title: 'Accessibility Analytics',
          actions: [
            IconButton(
              icon: CustomIconWidget(
                iconName: 'refresh',
                size: 6.w,
                color: AppTheme.textPrimaryLight,
              ),
              onPressed: _loadAnalytics,
            ),
            SizedBox(width: 2.w),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : SingleChildScrollView(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildAdoptionRatesSection(),
                    SizedBox(height: 3.h),
                    _buildOptimizationReportsSection(),
                    SizedBox(height: 3.h),
                    _buildFeatureUsageSection(),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildAdoptionRatesSection() {
    final fontScalingAdoption = _adoptionRates['font_scaling_adoption'] ?? 0.0;
    final themePreferenceAdoption =
        _adoptionRates['theme_preference_adoption'] ?? 0.0;
    final totalUsers = _adoptionRates['total_accessibility_users'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Accessibility Adoption Rates',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        _buildAdoptionCard(
          'Font Scaling',
          fontScalingAdoption,
          Icons.text_fields,
          Colors.blue,
        ),
        SizedBox(height: 2.h),
        _buildAdoptionCard(
          'Theme Preferences',
          themePreferenceAdoption,
          Icons.palette,
          Colors.purple,
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.people, color: Colors.green, size: 8.w),
              SizedBox(width: 2.w),
              Text(
                '$totalUsers users with accessibility preferences',
                style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAdoptionCard(
    String label,
    double adoptionRate,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 8.w),
              SizedBox(width: 2.w),
              Text(
                label,
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          LinearProgressIndicator(
            value: adoptionRate / 100,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 1.h,
          ),
          SizedBox(height: 1.h),
          Text(
            '${adoptionRate.toStringAsFixed(1)}% adoption rate',
            style: TextStyle(
              fontSize: 12.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationReportsSection() {
    final highUsageSettings = _optimizationReports['high_usage_settings'] ?? [];
    final recommendations = _optimizationReports['recommendations'] ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Optimization Reports',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        if (recommendations.isNotEmpty)
          ...recommendations.map((rec) => _buildRecommendationCard(rec))
        else
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green, size: 8.w),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'No optimization recommendations at this time',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.green.shade700,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildRecommendationCard(Map<String, dynamic> recommendation) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Colors.orange, size: 6.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  recommendation['title'] ?? 'Recommendation',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            recommendation['description'] ?? '',
            style: TextStyle(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureUsageSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Feature Usage Heatmap',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        _buildFeatureUsageCard('Font Size Adjustment', 68.5, Colors.blue),
        SizedBox(height: 2.h),
        _buildFeatureUsageCard('Theme Preference', 45.2, Colors.purple),
        SizedBox(height: 2.h),
        _buildFeatureUsageCard('High Contrast Mode', 12.8, Colors.orange),
        SizedBox(height: 2.h),
        _buildFeatureUsageCard('Reduced Motion', 8.3, Colors.green),
      ],
    );
  }

  Widget _buildFeatureUsageCard(
    String feature,
    double usagePercentage,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              feature,
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
          ),
          Text(
            '${usagePercentage.toStringAsFixed(1)}%',
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
