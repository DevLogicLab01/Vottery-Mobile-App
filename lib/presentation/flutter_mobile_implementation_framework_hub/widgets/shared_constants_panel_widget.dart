import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../framework/shared_constants.dart';

class SharedConstantsPanelWidget extends StatefulWidget {
  const SharedConstantsPanelWidget({super.key});

  @override
  State<SharedConstantsPanelWidget> createState() =>
      _SharedConstantsPanelWidgetState();
}

class _SharedConstantsPanelWidgetState
    extends State<SharedConstantsPanelWidget> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<String> _categories = [
    'All',
    'Tables',
    'Routes',
    'Stripe',
    'VP',
    'Errors',
    'Edge Functions',
    'Columns',
  ];

  final List<Map<String, String>> _allConstants = [
    // Tables
    {
      'name': 'sponsoredElections',
      'value': SharedConstants.sponsoredElections,
      'category': 'Tables',
      'usage': 'Ad campaigns',
    },
    {
      'name': 'platformGamificationCampaigns',
      'value': SharedConstants.platformGamificationCampaigns,
      'category': 'Tables',
      'usage': 'Monthly gamification',
    },
    {
      'name': 'userVpTransactions',
      'value': SharedConstants.userVpTransactions,
      'category': 'Tables',
      'usage': 'VP economy',
    },
    {
      'name': 'featureRequests',
      'value': SharedConstants.featureRequests,
      'category': 'Tables',
      'usage': 'Community feedback',
    },
    {
      'name': 'electionsTable',
      'value': SharedConstants.electionsTable,
      'category': 'Tables',
      'usage': 'Core elections',
    },
    {
      'name': 'payoutSettings',
      'value': SharedConstants.payoutSettings,
      'category': 'Tables',
      'usage': 'Creator payouts',
    },
    {
      'name': 'userSubscriptions',
      'value': SharedConstants.userSubscriptions,
      'category': 'Tables',
      'usage': 'Subscription state',
    },
    {
      'name': 'userPaymentMethods',
      'value': SharedConstants.userPaymentMethods,
      'category': 'Tables',
      'usage': 'Payment methods',
    },
    // Routes
    {
      'name': 'campaignManagementDashboard',
      'value': SharedConstants.campaignManagementDashboard,
      'category': 'Routes',
      'usage': 'Campaign screen',
    },
    {
      'name': 'participatoryAdsStudio',
      'value': SharedConstants.participatoryAdsStudio,
      'category': 'Routes',
      'usage': 'Ads wizard',
    },
    {
      'name': 'communityEngagementDashboard',
      'value': SharedConstants.communityEngagementDashboard,
      'category': 'Routes',
      'usage': 'Community screen',
    },
    {
      'name': 'incidentResponseAnalytics',
      'value': SharedConstants.incidentResponseAnalytics,
      'category': 'Routes',
      'usage': 'Incident screen',
    },
    {
      'name': 'subscriptionArchitecture',
      'value': SharedConstants.subscriptionArchitecture,
      'category': 'Routes',
      'usage': 'Subscription screen',
    },
    {
      'name': 'unifiedPaymentOrchestration',
      'value': SharedConstants.unifiedPaymentOrchestration,
      'category': 'Routes',
      'usage': 'Payment hub',
    },
    // Stripe
    {
      'name': 'stripeProductBasic',
      'value': SharedConstants.stripeProductBasic,
      'category': 'Stripe',
      'usage': 'Basic tier product',
    },
    {
      'name': 'stripeProductPro',
      'value': SharedConstants.stripeProductPro,
      'category': 'Stripe',
      'usage': 'Pro tier product',
    },
    {
      'name': 'stripeProductElite',
      'value': SharedConstants.stripeProductElite,
      'category': 'Stripe',
      'usage': 'Elite tier product',
    },
    // VP
    {
      'name': 'vpMultiplierBasic',
      'value': '${SharedConstants.vpMultiplierBasic}x',
      'category': 'VP',
      'usage': 'Basic VP multiplier',
    },
    {
      'name': 'vpMultiplierPro',
      'value': '${SharedConstants.vpMultiplierPro}x',
      'category': 'VP',
      'usage': 'Pro VP multiplier',
    },
    {
      'name': 'vpMultiplierElite',
      'value': '${SharedConstants.vpMultiplierElite}x',
      'category': 'VP',
      'usage': 'Elite VP multiplier',
    },
    // Errors
    {
      'name': 'paymentFailed',
      'value': SharedConstants.paymentFailed,
      'category': 'Errors',
      'usage': 'Payment error code',
    },
    {
      'name': 'subscriptionExpired',
      'value': SharedConstants.subscriptionExpired,
      'category': 'Errors',
      'usage': 'Subscription error',
    },
    {
      'name': 'insufficientVp',
      'value': SharedConstants.insufficientVp,
      'category': 'Errors',
      'usage': 'VP error code',
    },
    // Edge Functions
    {
      'name': 'stripeSecureProxy',
      'value': SharedConstants.stripeSecureProxy,
      'category': 'Edge Functions',
      'usage': 'Stripe payments',
    },
    {
      'name': 'sendComplianceReport',
      'value': SharedConstants.sendComplianceReport,
      'category': 'Edge Functions',
      'usage': 'Compliance reports',
    },
    {
      'name': 'predictionPoolWebhooks',
      'value': SharedConstants.predictionPoolWebhooks,
      'category': 'Edge Functions',
      'usage': 'Prediction pools',
    },
    {
      'name': 'userActivityAnalyzer',
      'value': SharedConstants.userActivityAnalyzer,
      'category': 'Edge Functions',
      'usage': 'Activity analysis',
    },
    // Columns
    {
      'name': 'allowComments',
      'value': SharedConstants.allowComments,
      'category': 'Columns',
      'usage': 'Election feature toggle',
    },
    {
      'name': 'isGamified',
      'value': SharedConstants.isGamified,
      'category': 'Columns',
      'usage': 'Gamification toggle',
    },
    {
      'name': 'prizeConfig',
      'value': SharedConstants.prizeConfig,
      'category': 'Columns',
      'usage': 'Prize configuration',
    },
  ];

  List<Map<String, String>> get _filteredConstants {
    return _allConstants.where((c) {
      final matchesCategory =
          _selectedCategory == 'All' || c['category'] == _selectedCategory;
      final matchesSearch =
          _searchQuery.isEmpty ||
          c['name']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          c['value']!.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Search bar
        TextField(
          onChanged: (v) => setState(() => _searchQuery = v),
          decoration: InputDecoration(
            hintText: 'Search constants...',
            prefixIcon: const Icon(Icons.search, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: 3.w,
              vertical: 1.h,
            ),
          ),
          style: GoogleFonts.inter(fontSize: 13.sp),
        ),
        SizedBox(height: 1.h),
        // Category filter chips
        SizedBox(
          height: 4.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            separatorBuilder: (_, __) => SizedBox(width: 2.w),
            itemBuilder: (context, i) {
              final cat = _categories[i];
              final selected = _selectedCategory == cat;
              return FilterChip(
                label: Text(
                  cat,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: selected ? Colors.white : theme.colorScheme.primary,
                  ),
                ),
                selected: selected,
                onSelected: (_) => setState(() => _selectedCategory = cat),
                backgroundColor: theme.colorScheme.surface,
                selectedColor: theme.colorScheme.primary,
                padding: EdgeInsets.symmetric(horizontal: 2.w),
              );
            },
          ),
        ),
        SizedBox(height: 1.h),
        // Count
        Text(
          '${_filteredConstants.length} constants',
          style: GoogleFonts.inter(
            fontSize: 11.sp,
            color: theme.colorScheme.onSurface.withAlpha(153),
          ),
        ),
        SizedBox(height: 1.h),
        // Constants list
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _filteredConstants.length,
          separatorBuilder: (_, __) =>
              Divider(height: 1, color: theme.dividerColor),
          itemBuilder: (context, i) {
            final c = _filteredConstants[i];
            return _ConstantRowWidget(
              name: c['name']!,
              value: c['value']!,
              category: c['category']!,
              usage: c['usage']!,
            );
          },
        ),
      ],
    );
  }
}

class _ConstantRowWidget extends StatelessWidget {
  final String name;
  final String value;
  final String category;
  final String usage;

  const _ConstantRowWidget({
    required this.name,
    required this.value,
    required this.category,
    required this.usage,
  });

  Color _categoryColor(BuildContext context) {
    switch (category) {
      case 'Tables':
        return Colors.blue;
      case 'Routes':
        return Colors.green;
      case 'Stripe':
        return Colors.purple;
      case 'VP':
        return Colors.orange;
      case 'Errors':
        return Colors.red;
      case 'Edge Functions':
        return Colors.teal;
      case 'Columns':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () {
        Clipboard.setData(ClipboardData(text: value));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Copied: $value'),
            duration: const Duration(seconds: 1),
          ),
        );
      },
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        child: Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: _categoryColor(context),
                shape: BoxShape.circle,
              ),
            ),
            SizedBox(width: 2.w),
            Expanded(
              flex: 3,
              child: Text(
                name,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 3,
              child: Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: theme.colorScheme.primary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                usage,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  color: theme.colorScheme.onSurface.withAlpha(128),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Icon(
              Icons.copy,
              size: 14,
              color: theme.colorScheme.onSurface.withAlpha(77),
            ),
          ],
        ),
      ),
    );
  }
}