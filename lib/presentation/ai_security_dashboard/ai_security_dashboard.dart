import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/claude_service.dart';
import '../../services/multi_ai_orchestration_service.dart';
import '../../services/openai_fraud_detection_service.dart';
import '../../services/perplexity_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/content_moderation_panel_widget.dart';
import './widgets/fraud_detection_panel_widget.dart';
import './widgets/security_metrics_card_widget.dart';
import './widgets/threat_intelligence_panel_widget.dart';

/// AI Security Dashboard Screen
/// Provides comprehensive fraud detection and content moderation oversight
class AISecurityDashboard extends StatefulWidget {
  const AISecurityDashboard({super.key});

  @override
  State<AISecurityDashboard> createState() => _AISecurityDashboardState();
}

class _AISecurityDashboardState extends State<AISecurityDashboard> {
  final MultiAIOrchestrationService _orchestration =
      MultiAIOrchestrationService.instance;
  final OpenAIFraudDetectionService _fraudService =
      OpenAIFraudDetectionService.instance;
  final ClaudeService _claudeService = ClaudeService.instance;
  final PerplexityService _perplexityService = PerplexityService.instance;

  bool _isRefreshing = false;
  final bool _isLoading = false;
  final int _alertCount = 3;
  bool _emergencyMode = false;

  final List<Map<String, dynamic>> _securityMetrics = [
    {
      'title': 'Fraud Detection Rate',
      'value': '97.8%',
      'subtitle': '+2.3% this week',
      'iconName': 'shield',
      'color': const Color(0xFF10B981),
    },
    {
      'title': 'Content Moderation',
      'value': '24',
      'subtitle': 'Items in queue',
      'iconName': 'verified_user',
      'color': const Color(0xFF3B82F6),
    },
    {
      'title': 'Threat Intelligence',
      'value': 'Medium',
      'subtitle': 'Current threat level',
      'iconName': 'security',
      'color': const Color(0xFFF59E0B),
    },
    {
      'title': 'System Confidence',
      'value': '92%',
      'subtitle': 'AI consensus score',
      'iconName': 'psychology',
      'color': const Color(0xFF8B5CF6),
    },
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'AISecurityDashboard',
      onRetry: _handleRefresh,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'AI Security Dashboard',
            variant: CustomAppBarVariant.standard,
            leading: IconButton(
              icon: CustomIconWidget(
                iconName: 'arrow_back',
                color: theme.appBarTheme.foregroundColor!,
                size: 24,
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: CustomIconWidget(
                      iconName: 'notifications',
                      color: theme.appBarTheme.foregroundColor!,
                      size: 24,
                    ),
                    onPressed: () => _showAlerts(context),
                  ),
                  if (_alertCount > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEF4444),
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          _alertCount.toString(),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              IconButton(
                icon: CustomIconWidget(
                  iconName: _emergencyMode ? 'emergency' : 'emergency_home',
                  color: _emergencyMode
                      ? const Color(0xFFEF4444)
                      : theme.appBarTheme.foregroundColor!,
                  size: 24,
                ),
                onPressed: () {
                  setState(() => _emergencyMode = !_emergencyMode);
                  _showEmergencyToggle(context);
                },
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _handleRefresh,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(context),
                      SizedBox(height: 2.h),
                      _buildSecurityMetrics(context),
                      SizedBox(height: 3.h),
                      FraudDetectionPanelWidget(),
                      SizedBox(height: 2.h),
                      ContentModerationPanelWidget(),
                      SizedBox(height: 2.h),
                      ThreatIntelligencePanelWidget(),
                      SizedBox(height: 3.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              color: _emergencyMode
                  ? const Color(0xFFEF4444).withValues(alpha: 0.1)
                  : const Color(0xFF10B981).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: CustomIconWidget(
              iconName: 'security',
              color: _emergencyMode
                  ? const Color(0xFFEF4444)
                  : const Color(0xFF10B981),
              size: 28,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Security Status',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  _emergencyMode
                      ? 'Emergency Mode Active'
                      : 'All Systems Operational',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: _emergencyMode
                        ? const Color(0xFFEF4444)
                        : const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityMetrics(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 2.w,
          mainAxisSpacing: 1.h,
          childAspectRatio: 1.5,
        ),
        itemCount: _securityMetrics.length,
        itemBuilder: (context, index) {
          return SecurityMetricsCardWidget(metric: _securityMetrics[index]);
        },
      ),
    );
  }

  Future<void> _handleRefresh() async {
    setState(() => _isRefreshing = true);
    await Future.delayed(const Duration(seconds: 2));
    setState(() => _isRefreshing = false);
  }

  void _showAlerts(BuildContext context) {
    final theme = Theme.of(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                margin: EdgeInsets.only(bottom: 2.h),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.3,
                  ),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Security Alerts ($_alertCount)',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            _buildAlertItem(
              context,
              'High Fraud Score Detected',
              'Vote ID: #12345 - Score: 78',
              'error',
              const Color(0xFFEF4444),
            ),
            _buildAlertItem(
              context,
              'Content Flagged for Review',
              'Potential policy violation detected',
              'flag',
              const Color(0xFFF59E0B),
            ),
            _buildAlertItem(
              context,
              'Unusual Voting Pattern',
              'User ID: #67890 - Velocity spike',
              'warning',
              const Color(0xFFF59E0B),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildAlertItem(
    BuildContext context,
    String title,
    String description,
    String iconName,
    Color color,
  ) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          CustomIconWidget(iconName: iconName, color: color, size: 24),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyToggle(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _emergencyMode
              ? 'Emergency mode activated - Enhanced monitoring enabled'
              : 'Emergency mode deactivated',
        ),
        backgroundColor: _emergencyMode
            ? const Color(0xFFEF4444)
            : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
