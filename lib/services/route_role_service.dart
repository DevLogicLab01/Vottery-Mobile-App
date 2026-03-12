import '../constants/roles.dart';
import '../routes/app_routes.dart';

/// Centralized route-to-role mapping for RBAC.
/// Keep in sync with Web: src/services/navigationService.js
class RouteRoleService {
  RouteRoleService._();

  /// Routes that require admin roles (admin, super_admin, manager, moderator)
  static const Set<String> _adminRoutes = {
    AppRoutes.unifiedProductionMonitoringHub,
    AppRoutes.performanceOptimizationRecommendationsEngineDashboard,
    AppRoutes.flutterMobileImplementationFrameworkHub,
    AppRoutes.incidentResponseAnalytics,
    AppRoutes.subscriptionArchitecture,
    AppRoutes.realtimeGamificationErrorRecoveryHub,
    AppRoutes.automatedDatadogResponseCommandCenter,
    AppRoutes.predictivePerformanceTuningDashboard,
    AppRoutes.costAnalyticsRoiDashboard,
    AppRoutes.claudeDecisionReasoningHub,
    AppRoutes.claudeRevenueOptimizationCoach,
    AppRoutes.adminAutomationControlPanel,
    AppRoutes.multiRegionFailoverDashboard,
    AppRoutes.securityComplianceAudit,
    AppRoutes.securityAuditDashboard,
    AppRoutes.creatorRevenueShareScreen,
    AppRoutes.realTimeRevenueOptimization,
    AppRoutes.analyticsExportReportingHub,
    AppRoutes.performanceTestingDashboard,
    AppRoutes.apiRateLimitingDashboard,
    AppRoutes.ga4EnhancedAnalyticsDashboard,
    AppRoutes.offlineSyncDiagnostics,
    AppRoutes.userFeedbackPortal,
    AppRoutes.featureImplementationTracking,
  };

  /// Routes that require creator roles (creator or admin)
  static const Set<String> _creatorRoutes = {
    AppRoutes.creatorCommunityHub,
    AppRoutes.communityEngagementDashboard,
  };

  /// Get required roles for a route name. Returns null if public.
  static List<String>? getRequiredRolesForRoute(String? routeName) {
    if (routeName == null || routeName.isEmpty) return null;
    if (_adminRoutes.contains(routeName)) return AppRoles.adminRoles;
    if (_creatorRoutes.contains(routeName)) return AppRoles.creatorRoles;
    return null;
  }

  /// Check if a route requires role protection
  static bool requiresRoleGuard(String? routeName) {
    return getRequiredRolesForRoute(routeName) != null;
  }
}
