import '../shared_constants.dart';

/// D4 - Platform-wide Gamification Template
class PlatformGamificationTemplate {
  PlatformGamificationTemplate._();

  static String getTableName() => SharedConstants.platformGamificationCampaigns;

  static List<String> getAllocationCategories() => [
    'country',
    'continent',
    'gender',
    'mau',
    'dau',
    'premium',
    'subscribers',
    'advertisers',
    'creators',
    'others',
  ];

  static List<String> getRealtimeChannels() => [
    SharedConstants.userVpTransactions,
    SharedConstants.userQuests,
    SharedConstants.userAchievements,
    SharedConstants.userStreaks,
    SharedConstants.leaderboardPositions,
  ];

  static String getImplementationGuide() =>
      '''
D4 - Platform Gamification Implementation Guide:
1. Table: ${getTableName()}
2. Allocation categories: ${getAllocationCategories().join(', ')}
3. Realtime channels: ${getRealtimeChannels().join(', ')}
4. Display: Home + Profile screens (prize pool, winners, countdown)
5. Service: lib/services/realtime_gamification_notification_service.dart
''';
}
