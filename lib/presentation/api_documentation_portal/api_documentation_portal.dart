import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/custom_icon_widget.dart';
import '../res_tful_api_management_hub/widgets/swagger_documentation_widget.dart';

class ApiDocumentationPortalScreen extends StatelessWidget {
  const ApiDocumentationPortalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(
        leading: Padding(
          padding: EdgeInsets.only(left: 4.w),
          child: IconButton(
            icon: CustomIconWidget(
              iconName: 'arrow_back',
              size: 6.w,
              color: theme.appBarTheme.foregroundColor ??
                  AppTheme.textPrimaryLight,
            ),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        title: 'API Documentation',
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(theme),
              SizedBox(height: 3.h),
              _buildQuickInfoCard(theme),
              SizedBox(height: 3.h),
              const SwaggerDocumentationWidget(),
              SizedBox(height: 3.h),
              _buildWebhookSection(theme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Developer API Portal',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 0.8.h),
        Text(
          'Explore REST endpoints for elections, embeds, and webhooks. '
          'Use this screen as a companion while integrating Vottery with your apps.',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: AppTheme.textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickInfoCard(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_outline, color: Colors.green),
              SizedBox(width: 2.w),
              Text(
                'Security Reminder',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Never paste production API keys or secrets on shared screens. '
            'Use environment variables and secure storage for all credentials.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Key resources:',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 0.5.h),
          _buildBullet(theme, 'Elections: /rest/v1/elections'),
          _buildBullet(theme, 'Votes: /rest/v1/votes'),
          _buildBullet(
            theme,
            'Campaigns: /rest/v1/brand_partnerships',
          ),
          _buildBullet(theme, 'Webhooks: /rest/v1/webhooks'),
        ],
      ),
    );
  }

  Widget _buildBullet(ThemeData theme, String text) {
    return Padding(
      padding: EdgeInsets.only(top: 0.4.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(
            child: Text(
              text,
              style: theme.textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWebhookSection(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.webhook_outlined, color: Colors.blue),
              SizedBox(width: 2.w),
              Text(
                'Webhook Management',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Configure webhooks to receive real-time notifications for election events, '
            'fraud alerts, payouts, and advertiser campaigns.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 1.5.h),
          _buildBullet(
            theme,
            'Use secret tokens and HMAC signatures to verify incoming webhook calls.',
          ),
          _buildBullet(
            theme,
            'Store signing keys and shared secrets in Supabase config, not in client apps.',
          ),
        ],
      ),
    );
  }
}

