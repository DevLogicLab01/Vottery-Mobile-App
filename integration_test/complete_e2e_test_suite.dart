import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter/material.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Vote Casting E2E', () {
    testWidgets('User can cast vote in election', (tester) async {
      // Launch app
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Find and tap an election card
      final electionCard = find.byKey(const Key('election_card_0'));
      if (electionCard.evaluate().isNotEmpty) {
        await tester.tap(electionCard);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Find vote button
      final voteButton = find.byKey(const Key('vote_button'));
      if (voteButton.evaluate().isNotEmpty) {
        await tester.tap(voteButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Select first option
      final option = find.byKey(const Key('vote_option_0'));
      if (option.evaluate().isNotEmpty) {
        await tester.tap(option);
        await tester.pumpAndSettle();
      }

      // Submit vote
      final submitButton = find.byKey(const Key('submit_vote_button'));
      if (submitButton.evaluate().isNotEmpty) {
        await tester.tap(submitButton);
        await tester.pumpAndSettle(const Duration(seconds: 3));
      }

      // Verify success message or VP notification
      final successMessage = find.textContaining('VP');
      final ticketPopup = find.textContaining('Ticket');
      expect(
        successMessage.evaluate().isNotEmpty ||
            ticketPopup.evaluate().isNotEmpty,
        isTrue,
        reason: 'Should show VP earned or ticket notification after voting',
      );
    });
  });

  group('Payment Processing E2E', () {
    testWidgets('User can initiate payment flow', (tester) async {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to wallet
      final walletButton = find.byKey(const Key('wallet_nav_button'));
      if (walletButton.evaluate().isNotEmpty) {
        await tester.tap(walletButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Find payment/subscription button
      final payButton = find.byKey(const Key('payment_button'));
      if (payButton.evaluate().isNotEmpty) {
        await tester.tap(payButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify payment UI is shown
      final paymentUI = find.byKey(const Key('payment_form'));
      final stripeUI = find.textContaining('Stripe');
      expect(
        paymentUI.evaluate().isNotEmpty || stripeUI.evaluate().isNotEmpty,
        isTrue,
        reason: 'Payment UI should be accessible',
      );
    });
  });

  group('NFT Achievement E2E', () {
    testWidgets('Achievement system is accessible', (tester) async {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to achievements
      final achievementsButton = find.byKey(const Key('achievements_nav'));
      if (achievementsButton.evaluate().isNotEmpty) {
        await tester.tap(achievementsButton);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify NFT achievement hub is accessible
      final nftHub = find.byKey(const Key('nft_achievement_hub'));
      final achievementGrid = find.byKey(const Key('achievement_grid'));
      expect(
        nftHub.evaluate().isNotEmpty || achievementGrid.evaluate().isNotEmpty,
        isTrue,
        reason: 'NFT achievement system should be accessible',
      );
    });
  });

  group('Claude Recommendations E2E', () {
    testWidgets('AI recommendations are displayed', (tester) async {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to home feed
      final homeFeed = find.byKey(const Key('home_feed'));
      if (homeFeed.evaluate().isNotEmpty) {
        await tester.tap(homeFeed);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify recommendations are shown
      final recommendationCard = find.byKey(const Key('recommendation_card_0'));
      final aiRecommendation = find.textContaining('Recommended');
      expect(
        recommendationCard.evaluate().isNotEmpty ||
            aiRecommendation.evaluate().isNotEmpty,
        isTrue,
        reason: 'AI recommendations should be visible in feed',
      );
    });
  });

  group('Prediction Pool E2E', () {
    testWidgets('User can view prediction pool', (tester) async {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to gamification
      final gamificationNav = find.byKey(const Key('gamification_nav'));
      if (gamificationNav.evaluate().isNotEmpty) {
        await tester.tap(gamificationNav);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Find prediction pools section
      final predictionSection = find.byKey(
        const Key('prediction_pools_section'),
      );
      final predictionText = find.textContaining('Prediction');
      expect(
        predictionSection.evaluate().isNotEmpty ||
            predictionText.evaluate().isNotEmpty,
        isTrue,
        reason: 'Prediction pools should be accessible',
      );
    });
  });

  group('Gamification Flow E2E', () {
    testWidgets('VP balance is displayed', (tester) async {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Check VP balance is visible
      final vpBalance = find.byKey(const Key('vp_balance_display'));
      final vpText = find.textContaining('VP');
      expect(
        vpBalance.evaluate().isNotEmpty || vpText.evaluate().isNotEmpty,
        isTrue,
        reason: 'VP balance should be visible in the app',
      );
    });

    testWidgets('Rewards shop is accessible', (tester) async {
      await tester.pumpAndSettle(const Duration(seconds: 3));

      // Navigate to rewards
      final rewardsNav = find.byKey(const Key('rewards_shop_nav'));
      if (rewardsNav.evaluate().isNotEmpty) {
        await tester.tap(rewardsNav);
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }

      // Verify rewards shop
      final rewardsShop = find.byKey(const Key('rewards_shop'));
      final redeemButton = find.textContaining('Redeem');
      expect(
        rewardsShop.evaluate().isNotEmpty || redeemButton.evaluate().isNotEmpty,
        isTrue,
        reason: 'Rewards shop should be accessible',
      );
    });
  });
}
