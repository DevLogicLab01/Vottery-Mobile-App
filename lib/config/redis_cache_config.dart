class CacheTTL {
  CacheTTL._();
  static const int leaderboardGlobal = 300;
  static const int leaderboardZone = 300;
  static const int creatorAnalytics = 300;
  static const int electionStats = 300;
  static const int userDashboard = 180;
  static const int electionFeed = 120;
  static const int voteCount = 60;
  static const int electionsWithVoteCounts = 300;
}

class CacheKeys {
  CacheKeys._();
  static const String leaderboardGlobalPrefix = 'leaderboard:global';
  static const String leaderboardZonePrefix = 'leaderboard:zone';
  static const String creatorAnalyticsPrefix = 'creator:analytics';
  static const String electionStatsPrefix = 'election:stats';
  static const String userDashboardPrefix = 'user:dashboard';
  static const String electionsVotesPrefix = 'elections:votes';

  static String leaderboardGlobal(int timeBucket) =>
      '$leaderboardGlobalPrefix:$timeBucket';
  static String leaderboardZone(String zoneId, int timeBucket) =>
      '$leaderboardZonePrefix:$zoneId:$timeBucket';
  static String creatorAnalytics(String userId, int timeBucket) =>
      '$creatorAnalyticsPrefix:$userId:$timeBucket';
  static String electionStats(String electionId, int timeBucket) =>
      '$electionStatsPrefix:$electionId:$timeBucket';
  static String userDashboard(String userId, int timeBucket) =>
      '$userDashboardPrefix:$userId:$timeBucket';
  static String electionsWithVotes(String electionIds, int timeBucket) =>
      '$electionsVotesPrefix:$electionIds:$timeBucket';

  static int get fiveMinBucket =>
      DateTime.now().millisecondsSinceEpoch ~/ 300000;
  static int get threeMinBucket =>
      DateTime.now().millisecondsSinceEpoch ~/ 180000;
  static int get oneMinBucket => DateTime.now().millisecondsSinceEpoch ~/ 60000;
}

class CacheLimits {
  CacheLimits._();
  static const int maxMemoryMb = 100;
  static const int maxKeys = 10000;
  static const String evictionPolicy = 'allkeys-lru';
}
