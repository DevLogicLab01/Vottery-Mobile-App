import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/config/batch1_route_allowlist.dart';

void main() {
  group('Batch1RouteAllowlist default policy', () {
    test('allows a known Batch-1 route', () {
      expect(Batch1RouteAllowlist.isAllowed('/votteryAdsStudio'), isTrue);
    });

    test('allows participatory ads studio routes (Web-canonical parity)', () {
      expect(Batch1RouteAllowlist.isAllowed('/participatoryAdsStudio'), isTrue);
      expect(
        Batch1RouteAllowlist.isAllowed('/participatory-ads-studio'),
        isTrue,
      );
    });

    test('blocks a non-allowlisted route when full-cert mode is off', () {
      expect(Batch1RouteAllowlist.isAllowed('/this-route-does-not-exist'), isFalse);
    });
  });
}
