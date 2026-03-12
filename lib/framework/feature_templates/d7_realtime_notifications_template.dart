import '../shared_constants.dart';

/// D7 - Real-time Gamification Notifications Template
class RealtimeNotificationsTemplate {
  RealtimeNotificationsTemplate._();

  static List<String> getSubscriptionChannels() => [
    SharedConstants.userVpTransactions,
    SharedConstants.userQuests,
    SharedConstants.userAchievements,
    SharedConstants.userStreaks,
    SharedConstants.leaderboardPositions,
  ];

  static Map<String, String> getNotificationTypes() => {
    'vp_earned': '+X VP earned',
    'achievement_unlocked': 'Achievement unlocked: [name]',
    'streak_maintained': 'Streak: N days 🔥',
    'streak_broken': 'Streak broken 💔',
    'rank_changed': 'You moved to rank #K on [leaderboard]',
    'quest_completed': 'Quest completed: [name]',
  };

  static String getImplementationGuide() =>
      '''
D7 - Realtime Notifications Implementation Guide:
1. Service: lib/services/realtime_gamification_notification_service.dart
2. Channels: ${getSubscriptionChannels().join(', ')}
3. Notification types: ${getNotificationTypes().keys.join(', ')}
4. UI: Toast/Snackbar + optional confetti for achievements
''';
}
