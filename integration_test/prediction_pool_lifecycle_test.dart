import 'package:flutter/foundation.dart';
// E2E Integration Test: Prediction Pool Lifecycle
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:vottery/main.dart' as app;
import 'package:vottery/services/prediction_service.dart';
import 'package:vottery/services/vp_service.dart';
import 'package:vottery/services/leaderboard_service.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Prediction Pool Lifecycle E2E Test', () {
    testWidgets(
      'Complete flow: pool creation → user prediction → election resolution → Brier score → VP reward → leaderboard update',
      (WidgetTester tester) async {
        // Initialize app
        app.main();
        await tester.pumpAndSettle();

        final predictionService = PredictionService.instance;
        final vpService = VPService.instance;
        final leaderboardService = LeaderboardService.instance;

        // Step 1: Create prediction pool
        final poolId = await predictionService.createPredictionPool(
          electionId: 'test-election-id',
          question: 'Who will win the election?',
          options: ['Candidate A', 'Candidate B'],
          entryFee: 100,
        );
        expect(poolId, isNotNull);

        // Step 2: Get initial VP balance
        final initialBalance = await vpService.getVPBalance();
        final initialVP = initialBalance?['available_vp'] as int? ?? 0;

        // Step 3: Submit user prediction (costs 100 VP entry fee)
        final predictionSuccess = await predictionService.submitPrediction(
          poolId: poolId!,
          predictions: {'Candidate A': 0.7, 'Candidate B': 0.3},
        );
        expect(predictionSuccess, isTrue);

        // Step 4: Verify VP deducted for entry fee
        await tester.pumpAndSettle(const Duration(seconds: 2));
        final afterEntryBalance = await vpService.getVPBalance();
        final afterEntryVP = afterEntryBalance?['available_vp'] as int? ?? 0;
        expect(afterEntryVP, equals(initialVP - 100));

        // Step 5: Resolve election (Candidate A wins)
        final resolutionSuccess = await predictionService.resolveElection(
          electionId: 'test-election-id',
          winnerId: 'candidate-a-id',
        );
        expect(resolutionSuccess, isTrue);

        // Step 6: Calculate Brier score
        await tester.pumpAndSettle(const Duration(seconds: 3));
        final brierScore = await predictionService.getUserBrierScore(
          poolId: poolId,
        );
        expect(brierScore, isNotNull);
        expect(brierScore, lessThan(1.0)); // Lower is better

        // Step 7: Verify VP reward distribution
        final afterRewardBalance = await vpService.getVPBalance();
        final afterRewardVP = afterRewardBalance?['available_vp'] as int? ?? 0;
        expect(afterRewardVP, greaterThan(afterEntryVP)); // Should earn VP

        // Step 8: Verify leaderboard update
        final leaderboard = await leaderboardService.getGlobalLeaderboard(
          leaderboardType: 'prediction_accuracy',
          timePeriod: 'all_time',
        );
        expect(leaderboard, isNotEmpty);

        // Step 9: Verify user rank updated
        final userRank = await leaderboardService.getUserRank(
          leaderboardType: 'prediction_accuracy',
          timePeriod: 'all_time',
        );
        expect(userRank, isNotNull);
        expect(userRank?['rank_position'], greaterThan(0));

        debugPrint('✅ Prediction Pool Lifecycle E2E Test PASSED');
      },
      timeout: const Timeout(Duration(minutes: 2)),
    );
  });
}

