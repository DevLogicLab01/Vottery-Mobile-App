import '../shared_constants.dart';

/// D5 - Community Engagement Dashboard Template
class CommunityEngagementTemplate {
  CommunityEngagementTemplate._();

  static String getRoutePath() => SharedConstants.communityEngagementDashboard;

  static List<String> getLeaderboardTypes() => [
    'feedback_contributions',
    'voting_participation',
    'feature_adoption',
  ];

  static List<String> getRequiredTables() => [
    SharedConstants.featureRequests,
    'votes',
    'implementation_tracking',
  ];

  static List<String> getBadgeTypes() => [
    'Top Contributor',
    'Most Votes',
    'Early Adopter',
    'Power User',
  ];

  static String getImplementationGuide() =>
      '''
D5 - Community Engagement Dashboard Implementation Guide:
1. Route: ${getRoutePath()}
2. Leaderboard types: ${getLeaderboardTypes().join(', ')}
3. Tables: ${getRequiredTables().join(', ')}
4. Badges: ${getBadgeTypes().join(', ')}
5. Extend: User Feedback Portal with Leaderboards tab
''';
}
