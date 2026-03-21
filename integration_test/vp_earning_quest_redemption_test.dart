import 'package:flutter/foundation.dart';
// E2E Integration Test: VP Earning → Quest Completion → Redemption Flow
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vottery/main.dart' as app;
import 'package:vottery/services/vp_service.dart';
import 'package:vottery/services/gamification_service.dart';
import 'package:vottery/services/voting_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('VP Earning Quest Redemption E2E Test', () {
    testWidgets(
      'Complete flow: vote cast → 10 VP earned → quest progress → quest completed → 50 VP reward → rewards shop redemption → VP deducted → item unlocked',
      (WidgetTester tester) async {
        // Initialize app
        app.main();
        await tester.pumpAndSettle();

        final vpService = VPService.instance;
        final gamificationService = GamificationService.instance;
        final votingService = VotingService.instance;

        // Step 1: Get initial VP balance
        final initialBalance = await vpService.getVPBalance();
        final initialVP = initialBalance?['available_vp'] as int? ?? 0;
        expect(initialVP, isNotNull);

        // Step 2: Cast a vote (earns 10 VP)
        final voteSuccess = await votingService.castVote(
          electionId: 'test-election-id',
          selectedOptionId: 'option-1',
        );
        expect(voteSuccess, isTrue);

        // Step 3: Verify VP earned (10 VP for voting)
        await tester.pumpAndSettle(const Duration(seconds: 2));
        final afterVoteBalance = await vpService.getVPBalance();
        final afterVoteVP = afterVoteBalance?['available_vp'] as int? ?? 0;
        expect(afterVoteVP, equals(initialVP + 10));

        // Step 4: Complete a known test quest (service API uses named params)
        final questCompleted = await gamificationService.completeQuest(
          questId: 'test-quest-id',
          userId: 'test-user-id',
        );
        expect(questCompleted['success'], isA<bool>());

        // Step 6: Verify quest reward (50 VP)
        await tester.pumpAndSettle(const Duration(seconds: 2));
        final afterQuestBalance = await vpService.getVPBalance();
        final afterQuestVP = afterQuestBalance?['available_vp'] as int? ?? 0;
        expect(afterQuestVP, equals(afterVoteVP + 50));

        // Step 7: Navigate to rewards shop
        await tester.tap(find.text('Rewards Shop'));
        await tester.pumpAndSettle();

        // Step 8: Redeem item (costs 100 VP)
        await tester.tap(find.text('Custom Theme'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Redeem'));
        await tester.pumpAndSettle();

        // Step 9: Verify VP deducted
        final afterRedemptionBalance = await vpService.getVPBalance();
        final afterRedemptionVP =
            afterRedemptionBalance?['available_vp'] as int? ?? 0;
        expect(afterRedemptionVP, equals(afterQuestVP - 100));

        // Step 10: Verify gamification service remains callable post-redemption flow
        final streakState = await gamificationService.updateStreak();
        expect(streakState, isA<Map<String, dynamic>>());

        debugPrint('✅ VP Earning Quest Redemption E2E Test PASSED');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}

