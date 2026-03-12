import '../shared_constants.dart';

/// D1 - Campaign Management Dashboard Template
/// Provides all constants and configuration for the Campaign Management feature.
class CampaignManagementTemplate {
  CampaignManagementTemplate._();

  static String getTableName() => SharedConstants.sponsoredElections;
  static String getRoutePath() => SharedConstants.campaignManagementDashboard;
  static Duration getAutoRefreshInterval() =>
      SharedConstants.campaignRefreshInterval;

  static List<String> getRequiredColumns() => [
    'id',
    'campaign_name',
    'status',
    'engagement_metrics',
    'zone_breakdown',
    'votes',
    'reach',
    'cpe',
  ];

  static String getRealtimeChannel(String userId) =>
      '${SharedConstants.campaignsChannelPrefix}$userId';

  static Map<String, String> getSupabaseFilters() => {
    'status': 'active',
    'created_by': 'auth.uid()',
  };

  static String getImplementationGuide() =>
      '''
D1 - Campaign Management Dashboard Implementation Guide:
1. Screen path: lib/presentation/campaign_management_dashboard/
2. Table: ${getTableName()} (SharedConstants.sponsoredElections)
3. Route: ${getRoutePath()} → AppRoutes.campaignManagementDashboard
4. Auto-refresh: every ${getAutoRefreshInterval().inSeconds}s
5. Realtime channel: ${getRealtimeChannel('USER_ID')}
6. Required columns: ${getRequiredColumns().join(', ')}
7. Supabase filters: ${getSupabaseFilters()}
8. Navigation: Advertising section → Campaign Management
''';
}
