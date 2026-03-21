import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/services/revenue_intelligence_service.dart';

void main() {
  group('RevenueIntelligenceService defaults', () {
    test('getDefaultZoneRecommendations returns 8 zones', () {
      final zones = RevenueIntelligenceService.instance.getDefaultZoneRecommendations();
      expect(zones, hasLength(8));
      for (var i = 0; i < zones.length; i++) {
        expect(zones[i]['name'], isNotNull);
        expect(zones[i]['revenue'], isA<num>());
        expect(zones[i]['growth_rate'], isA<num>());
      }
    });

    test('defaultGrowthRecommendations is non-empty', () {
      final recs = RevenueIntelligenceService.instance.defaultGrowthRecommendations();
      expect(recs, isNotEmpty);
      expect(recs.first['recommendation'], isNotEmpty);
    });
  });
}
