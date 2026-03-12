import '../shared_constants.dart';

/// D8 - Subscription Tiers with VP Multipliers Template
class SubscriptionTiersTemplate {
  SubscriptionTiersTemplate._();

  static String getRoutePath() => SharedConstants.subscriptionArchitecture;
  static String getTableName() => SharedConstants.userSubscriptions;

  static Map<String, dynamic> getTierConfig() => {
    SharedConstants.tierBasic: {
      'product_id': SharedConstants.stripeProductBasic,
      'vp_multiplier': SharedConstants.vpMultiplierBasic,
      'label': '${SharedConstants.vpMultiplierBasic}x VP',
    },
    SharedConstants.tierPro: {
      'product_id': SharedConstants.stripeProductPro,
      'vp_multiplier': SharedConstants.vpMultiplierPro,
      'label': '${SharedConstants.vpMultiplierPro}x VP',
    },
    SharedConstants.tierElite: {
      'product_id': SharedConstants.stripeProductElite,
      'vp_multiplier': SharedConstants.vpMultiplierElite,
      'label': '${SharedConstants.vpMultiplierElite}x VP',
    },
  };

  static String getImplementationGuide() =>
      '''
D8 - Subscription Tiers Implementation Guide:
1. Route: ${getRoutePath()}
2. Table: ${getTableName()}
3. Tiers: Basic (${SharedConstants.vpMultiplierBasic}x), Pro (${SharedConstants.vpMultiplierPro}x), Elite (${SharedConstants.vpMultiplierElite}x)
4. Stripe products: ${SharedConstants.stripeProductBasic}, ${SharedConstants.stripeProductPro}, ${SharedConstants.stripeProductElite}
5. Show: current plan, billing date, upgrade/downgrade flow
''';
}
