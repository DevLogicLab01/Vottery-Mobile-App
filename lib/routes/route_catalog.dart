import 'app_routes.dart';

class RouteCatalogEntry {
  const RouteCatalogEntry({
    required this.path,
    this.featureKey,
  });

  final String path;
  final String? featureKey;
}

class RouteCatalog {
  static final Map<String, RouteCatalogEntry> _entries = {
    AppRoutes.unifiedProductionMonitoringHub: const RouteCatalogEntry(
      path: AppRoutes.unifiedProductionMonitoringHub,
      featureKey: 'unified-production-monitoring-hub',
    ),
    AppRoutes.performanceOptimizationRecommendationsEngineDashboard:
        const RouteCatalogEntry(
      path: AppRoutes.performanceOptimizationRecommendationsEngineDashboard,
      featureKey: 'performance-optimization-recommendations-engine-dashboard',
    ),
    AppRoutes.apiDocumentationPortal: const RouteCatalogEntry(
      path: AppRoutes.apiDocumentationPortal,
      featureKey: 'api-documentation-portal',
    ),
    AppRoutes.analyticsExportReportingHub: const RouteCatalogEntry(
      path: AppRoutes.analyticsExportReportingHub,
      featureKey: 'analytics-export-reporting-hub',
    ),
    AppRoutes.securityComplianceAudit: const RouteCatalogEntry(
      path: AppRoutes.securityComplianceAudit,
      featureKey: 'security-compliance-audit-screen',
    ),
  };

  static RouteCatalogEntry? lookup(String routeName) => _entries[routeName];
}
