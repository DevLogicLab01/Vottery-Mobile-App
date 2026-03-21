import 'package:flutter/material.dart';

import '../../routes/app_routes.dart';
import '../../widgets/custom_app_bar.dart';

/// Guided creator onboarding: registration → first monetization.
/// Steps: Identity verification → Tax setup → Banking → First earnings.
class CreatorOnboardingWizardScreen extends StatelessWidget {
  const CreatorOnboardingWizardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final steps = [
      _Step(
        title: 'Identity verification',
        subtitle: 'Verify your identity and country',
        icon: Icons.badge_outlined,
        route: AppRoutes.creatorVerificationKycScreen,
      ),
      _Step(
        title: 'Tax setup',
        subtitle: 'Add tax ID and jurisdiction details',
        icon: Icons.receipt_long_outlined,
        route: AppRoutes.taxComplianceDashboard,
      ),
      _Step(
        title: 'Banking method',
        subtitle: 'Connect payout account',
        icon: Icons.account_balance_outlined,
        route: AppRoutes.bankAccountLinkingScreen,
      ),
      _Step(
        title: 'First earnings',
        subtitle: 'Track revenue and request payouts',
        icon: Icons.trending_up,
        route: AppRoutes.creatorEarningsCommandCenter,
      ),
    ];

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: 'Creator onboarding',
          variant: CustomAppBarVariant.withBack,
          onBackPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              'Get set up for monetization',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            ...steps.asMap().entries.map((e) {
              final i = e.key + 1;
              final step = e.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primaryContainer,
                      child: Icon(step.icon, color: theme.colorScheme.onPrimaryContainer),
                    ),
                    title: Text('Step $i: ${step.title}'),
                    subtitle: Text(step.subtitle),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () => Navigator.pushNamed(context, step.route),
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}

class _Step {
  final String title;
  final String subtitle;
  final IconData icon;
  final String route;

  _Step({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
}
