import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:flutter_svg/flutter_svg.dart';

class EnhancedEmptyStateWidget extends StatelessWidget {
  final String title;
  final String description;
  final String? illustrationUrl;
  final IconData? fallbackIcon;
  final String? primaryActionLabel;
  final VoidCallback? onPrimaryAction;
  final String? secondaryActionLabel;
  final VoidCallback? onSecondaryAction;

  const EnhancedEmptyStateWidget({
    super.key,
    required this.title,
    required this.description,
    this.illustrationUrl,
    this.fallbackIcon,
    this.primaryActionLabel,
    this.onPrimaryAction,
    this.secondaryActionLabel,
    this.onSecondaryAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(6.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Illustration or Icon
            if (illustrationUrl != null)
              illustrationUrl!.endsWith('.svg')
                  ? SvgPicture.network(
                      illustrationUrl!,
                      width: 60.w,
                      height: 30.h,
                      fit: BoxFit.contain,
                      placeholderBuilder: (context) => Icon(
                        fallbackIcon ?? Icons.inbox_outlined,
                        size: 80.0,
                        color: Colors.grey.shade400,
                      ),
                    )
                  : Image.network(
                      illustrationUrl!,
                      width: 60.w,
                      height: 30.h,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        fallbackIcon ?? Icons.inbox_outlined,
                        size: 80.0,
                        color: Colors.grey.shade400,
                      ),
                    )
            else
              Icon(
                fallbackIcon ?? Icons.inbox_outlined,
                size: 80.0,
                color: Colors.grey.shade400,
              ),
            SizedBox(height: 3.h),

            // Title
            Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 1.5.h),

            // Description
            Text(
              description,
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.grey.shade600,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),

            // Primary Action Button
            if (primaryActionLabel != null && onPrimaryAction != null)
              ElevatedButton(
                onPressed: onPrimaryAction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(
                    horizontal: 8.w,
                    vertical: 1.5.h,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  primaryActionLabel!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

            // Secondary Action Button
            if (secondaryActionLabel != null && onSecondaryAction != null)
              SizedBox(height: 1.5.h),
            if (secondaryActionLabel != null && onSecondaryAction != null)
              TextButton(
                onPressed: onSecondaryAction,
                child: Text(
                  secondaryActionLabel!,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// Predefined empty states for common scenarios
class NoActiveVotesEmptyState extends StatelessWidget {
  final VoidCallback? onCreateVote;
  final VoidCallback? onExploreVotes;

  const NoActiveVotesEmptyState({
    super.key,
    this.onCreateVote,
    this.onExploreVotes,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedEmptyStateWidget(
      title: 'No Active Votes',
      description:
          'You haven\'t participated in any votes yet. Start exploring elections or create your own!',
      illustrationUrl: 'https://illustrations.popsy.co/amber/voting.svg',
      fallbackIcon: Icons.how_to_vote_outlined,
      primaryActionLabel: 'Explore Elections',
      onPrimaryAction: onExploreVotes,
      secondaryActionLabel: 'Create Vote',
      onSecondaryAction: onCreateVote,
    );
  }
}

class NoEarningsEmptyState extends StatelessWidget {
  final VoidCallback? onLearnMore;

  const NoEarningsEmptyState({super.key, this.onLearnMore});

  @override
  Widget build(BuildContext context) {
    return EnhancedEmptyStateWidget(
      title: 'No Earnings Yet',
      description:
          'Start creating engaging content and participating in elections to earn rewards!',
      illustrationUrl: 'https://illustrations.popsy.co/amber/money-profits.svg',
      fallbackIcon: Icons.account_balance_wallet_outlined,
      primaryActionLabel: 'Learn How to Earn',
      onPrimaryAction: onLearnMore,
    );
  }
}

class NoTransactionsEmptyState extends StatelessWidget {
  const NoTransactionsEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    return EnhancedEmptyStateWidget(
      title: 'No Transactions',
      description:
          'Your transaction history will appear here once you start earning or making purchases.',
      illustrationUrl: 'https://illustrations.popsy.co/amber/receipt.svg',
      fallbackIcon: Icons.receipt_long_outlined,
    );
  }
}

class NoMarketplaceServicesEmptyState extends StatelessWidget {
  final VoidCallback? onCreateService;

  const NoMarketplaceServicesEmptyState({super.key, this.onCreateService});

  @override
  Widget build(BuildContext context) {
    return EnhancedEmptyStateWidget(
      title: 'No Services Listed',
      description:
          'Start monetizing your skills by listing services in the creator marketplace!',
      illustrationUrl:
          'https://illustrations.popsy.co/amber/online-shopping.svg',
      fallbackIcon: Icons.storefront_outlined,
      primaryActionLabel: 'Create Service',
      onPrimaryAction: onCreateService,
    );
  }
}

class NoDataEmptyState extends StatelessWidget {
  final String title;
  final String description;
  final VoidCallback? onRefresh;

  const NoDataEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedEmptyStateWidget(
      title: title,
      description: description,
      illustrationUrl: 'https://illustrations.popsy.co/amber/no-data.svg',
      fallbackIcon: Icons.data_usage_outlined,
      primaryActionLabel: onRefresh != null ? 'Refresh' : null,
      onPrimaryAction: onRefresh,
    );
  }
}
