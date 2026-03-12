import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// E2E tests for NFT achievement unlock: navigate to achievements/NFT hub,
/// verify achievement grid or unlock flow. Used by CI for critical user flow validation.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('NFT Achievement Unlock E2E', () {
    testWidgets('Achievement system is accessible', (tester) async {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      final achievementsButton = find.byKey(const Key('achievements_nav'));
      if (achievementsButton.evaluate().isNotEmpty) {
        await tester.tap(achievementsButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      final nftHub = find.byKey(const Key('nft_achievement_hub'));
      final achievementGrid = find.byKey(const Key('achievement_grid'));
      expect(
        nftHub.evaluate().isNotEmpty || achievementGrid.evaluate().isNotEmpty,
        isTrue,
        reason: 'NFT achievement system should be accessible',
      );
    });
  });
}
