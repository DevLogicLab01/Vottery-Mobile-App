class AdNetworkConfig {
  AdNetworkConfig._();

  /// Global flag to enable or disable internal Vottery ads (primary).
  /// When false, all slots go to external partners (AppLovin MAX, AdMob).
  /// Build-time: use --dart-define=INTERNAL_ADS_ENABLED=false to ship with fallbacks only at launch.
  static bool get internalAdsEnabled {
    const env = String.fromEnvironment(
      'INTERNAL_ADS_ENABLED',
      defaultValue: 'true',
    );
    return env.toLowerCase() == 'true' || env == '1';
  }

  /// Web-style naming kept for clarity, but used on mobile for partner IDs.
  /// Replace placeholder values with real IDs/keys when you integrate SDKs.

  // AppLovin MAX (Mobile)
  static const bool appLovinEnabled = false;
  static const String appLovinSdkKey = 'YOUR_APPLOVIN_SDK_KEY';
  static const String appLovinHomeFeed1UnitId = 'applovin_home_feed_1';
  static const String appLovinHomeFeed2UnitId = 'applovin_home_feed_2';
  static const String appLovinProfileTopUnitId = 'applovin_profile_top';
  static const String appLovinElectionDetailBottomUnitId =
      'applovin_election_detail_bottom';

  // AdMob (Mobile)
  static const bool adMobEnabled = false;
  static const String adMobAppId = 'ca-app-pub-xxx~your_app_id';
  static const String adMobHomeFeed1UnitId = 'ca-app-pub-xxx/home_feed_1';
  static const String adMobHomeFeed2UnitId = 'ca-app-pub-xxx/home_feed_2';
  static const String adMobProfileTopUnitId = 'ca-app-pub-xxx/profile_top';
  static const String adMobElectionDetailBottomUnitId =
      'ca-app-pub-xxx/election_detail_bottom';
}

