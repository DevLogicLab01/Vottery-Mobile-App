import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:vottery/constants/vottery_ads_constants.dart';
import 'package:vottery/presentation/participatory_ads_studio/participatory_ads_studio.dart';
import 'package:vottery/presentation/vottery_ads_studio/vottery_ads_studio.dart';

/// Parity with Web `BATCH1_*` strings in `votteryAdsConstants.js` (certification / Cypress).
void main() {
  test('VotteryAdsConstants Batch-1 strings match Web export names', () {
    expect(
      VotteryAdsConstants.batch1InternalAdsDisabledTitle,
      'Internal Ads Disabled for Batch 1',
    );
    expect(
      VotteryAdsConstants.batch1ParticipatoryAdsDisabledTitle,
      'Participatory Ads Disabled for Batch 1',
    );
    expect(VotteryAdsConstants.internalAdsBatch1Disabled, isTrue);
  });

  testWidgets('VotteryAdsStudio shows Batch-1 policy when internal ads disabled', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: VotteryAdsStudio()));
    await tester.pumpAndSettle();
    expect(
      find.text(VotteryAdsConstants.batch1InternalAdsDisabledTitle),
      findsOneWidget,
    );
    expect(
      find.text(VotteryAdsConstants.batch1InternalAdsDisabledBody),
      findsOneWidget,
    );
  });

  testWidgets('ParticipatoryAdsStudio shows Batch-1 policy when internal ads disabled', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: ParticipatoryAdsStudio()));
    await tester.pumpAndSettle();
    expect(
      find.text(VotteryAdsConstants.batch1ParticipatoryAdsDisabledTitle),
      findsOneWidget,
    );
    expect(
      find.text(VotteryAdsConstants.batch1ParticipatoryAdsDisabledBody),
      findsOneWidget,
    );
  });
}
