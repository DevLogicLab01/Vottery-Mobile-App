import '../shared_constants.dart';

/// D3 - Ad Slot Manager Template
class AdSlotManagerTemplate {
  AdSlotManagerTemplate._();

  static List<String> getAllSlotIds() => [
    SharedConstants.homeFeed1,
    SharedConstants.homeFeed2,
    SharedConstants.profileTop,
    SharedConstants.electionDetailBottom,
  ];

  static String getInternalAdTable() => SharedConstants.sponsoredElections;

  /// Fallback logic: internal first, AdSense if unfilled
  static String getFallbackStrategy() => 'internal_first_adsense_fallback';

  static int getMaxImpressionsPerDay() => 3;

  static String getImplementationGuide() =>
      '''
D3 - Ad Slot Manager Implementation Guide:
1. Service: lib/services/ad_slot_orchestration_service.dart
2. Widget: AdSlotWidget (lib/presentation/social_media_home_feed/widgets/ad_slot_widget.dart)
3. Slot IDs: ${getAllSlotIds().join(', ')}
4. Strategy: ${getFallbackStrategy()}
5. Max impressions/day: ${getMaxImpressionsPerDay()}
6. Internal table: ${getInternalAdTable()}
''';
}
