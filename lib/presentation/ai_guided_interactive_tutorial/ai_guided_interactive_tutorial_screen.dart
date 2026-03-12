import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// Entry point for role-based AI-guided interactive tutorial (parity with Web /ai-guided-interactive-tutorial-system).
/// Offers paths for Voter, Creator, and Admin; launches existing onboarding/tutorial flows.
class AiGuidedInteractiveTutorialScreen extends StatelessWidget {
  const AiGuidedInteractiveTutorialScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ErrorBoundaryWrapper(
      screenName: 'AiGuidedInteractiveTutorial',
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'AI-Guided Tutorial',
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.maybePop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 3.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Choose your role to start a guided walkthrough',
                style: theme.textTheme.titleMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 3.h),
              _RoleCard(
                title: 'Voter',
                subtitle: 'Vote, discover elections, and earn VP',
                icon: Icons.how_to_vote,
                color: AppTheme.primaryLight,
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.interactiveOnboardingTutorialSystem,
                ),
              ),
              SizedBox(height: 2.h),
              _RoleCard(
                title: 'Creator',
                subtitle: 'Create elections, set fees, and manage payouts',
                icon: Icons.create,
                color: Colors.purple,
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.interactiveOnboardingToursHub,
                ),
              ),
              SizedBox(height: 2.h),
              _RoleCard(
                title: 'Admin',
                subtitle: 'Platform controls and analytics',
                icon: Icons.admin_panel_settings,
                color: Colors.teal,
                onTap: () => Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.interactiveOnboardingToursHub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RoleCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: theme.colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}
