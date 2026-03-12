import '../shared_constants.dart';

/// D2 - Participatory Ads Studio Template
class ParticipatoryAdsTemplate {
  ParticipatoryAdsTemplate._();

  static String getTableName() => SharedConstants.sponsoredElections;
  static String getRoutePath() => SharedConstants.participatoryAdsStudio;

  static List<String> getWizardSteps() => [
    'basic_info',
    'ad_format',
    'audience_targeting',
    'budget_configuration',
    'review_submit',
  ];

  static List<String> getAdFormats() => [
    'Market Research',
    'Hype Prediction',
    'CSR Vote',
  ];

  static List<String> getRequiredTables() => [
    SharedConstants.sponsoredElections,
    SharedConstants.adFrequencyCaps,
    SharedConstants.cpePricingZones,
  ];

  static String getImplementationGuide() =>
      '''
D2 - Participatory Ads Studio Implementation Guide:
1. Screen path: lib/presentation/participatory_ads_studio/
2. Table: ${getTableName()}
3. Route: ${getRoutePath()}
4. Wizard steps: ${getWizardSteps().join(' → ')}
5. Ad formats: ${getAdFormats().join(', ')}
6. Related tables: ${getRequiredTables().join(', ')}
''';
}
