import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/app_export.dart';
import '../../theme/app_theme.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';

class ComprehensiveLoadingStatesErrorHandlingHub extends StatefulWidget {
  const ComprehensiveLoadingStatesErrorHandlingHub({super.key});

  @override
  State<ComprehensiveLoadingStatesErrorHandlingHub> createState() =>
      _ComprehensiveLoadingStatesErrorHandlingHubState();
}

class _ComprehensiveLoadingStatesErrorHandlingHubState
    extends State<ComprehensiveLoadingStatesErrorHandlingHub> {
  String _selectedDemo = 'Skeleton Loaders';
  bool _isLoading = false;
  bool _showError = false;
  bool _showEmpty = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundLight,
      appBar: CustomAppBar(title: 'Loading & Error States Demo'),
      body: Column(
        children: [
          _buildDemoSelector(),
          Expanded(child: _buildDemoContent()),
        ],
      ),
    );
  }

  Widget _buildDemoSelector() {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: AppTheme.surfaceLight,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildSelectorChip('Skeleton Loaders'),
            SizedBox(width: 2.w),
            _buildSelectorChip('Empty States'),
            SizedBox(width: 2.w),
            _buildSelectorChip('Error Fallbacks'),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectorChip(String label) {
    final isSelected = _selectedDemo == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          _selectedDemo = label;
          _isLoading = false;
          _showError = false;
          _showEmpty = false;
        });
      },
      selectedColor: AppTheme.primaryLight,
      labelStyle: GoogleFonts.inter(
        fontSize: 12.sp,
        fontWeight: FontWeight.w600,
        color: isSelected ? Colors.white : AppTheme.textPrimaryLight,
      ),
    );
  }

  Widget _buildDemoContent() {
    switch (_selectedDemo) {
      case 'Skeleton Loaders':
        return _buildSkeletonLoadersDemo();
      case 'Empty States':
        return _buildEmptyStatesDemo();
      case 'Error Fallbacks':
        return _buildErrorFallbacksDemo();
      default:
        return Container();
    }
  }

  Widget _buildSkeletonLoadersDemo() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Skeleton Loaders',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Shimmer effect placeholders for async data loading',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: () {
              setState(() => _isLoading = !_isLoading);
            },
            child: Text(_isLoading ? 'Hide Skeleton' : 'Show Skeleton'),
          ),
          SizedBox(height: 2.h),
          if (_isLoading) ...[
            Text(
              'Composer Skeleton',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            _buildComposerSkeleton(),
            SizedBox(height: 3.h),
            Text(
              'Tutorial Skeleton',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            _buildTutorialSkeleton(),
            SizedBox(height: 3.h),
            Text(
              'Payout Skeleton',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            _buildPayoutSkeleton(),
          ] else ...[
            Center(
              child: Text(
                'Click button to see skeleton loaders',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildComposerSkeleton() {
    return Column(
      children: [
        SkeletonCard(height: 6.h),
        SizedBox(height: 1.h),
        SkeletonCard(height: 15.h),
        SizedBox(height: 1.h),
        SkeletonCard(height: 8.h),
        SizedBox(height: 1.h),
        SkeletonCard(height: 10.h),
      ],
    );
  }

  Widget _buildTutorialSkeleton() {
    return Column(
      children: [
        SkeletonCard(height: 20.h),
        SizedBox(height: 1.h),
        SkeletonCard(height: 5.h),
        SizedBox(height: 1.h),
        SkeletonCard(height: 8.h),
      ],
    );
  }

  Widget _buildPayoutSkeleton() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: SkeletonCard(height: 12.h)),
            SizedBox(width: 2.w),
            Expanded(child: SkeletonCard(height: 12.h)),
          ],
        ),
        SizedBox(height: 2.h),
        SkeletonList(itemCount: 3),
      ],
    );
  }

  Widget _buildEmptyStatesDemo() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Empty States',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Contextual CTAs when no data is available',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 3.h),
          ElevatedButton(
            onPressed: () {
              setState(() => _showEmpty = !_showEmpty);
            },
            child: Text(_showEmpty ? 'Hide Empty States' : 'Show Empty States'),
          ),
          SizedBox(height: 2.h),
          if (_showEmpty) ...[
            Text(
              'Composer Empty State',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            EnhancedEmptyStateWidget(
              title: 'Start Your First Post',
              description:
                  'Create engaging content to share with your audience',
              illustrationUrl:
                  'https://illustrations.popsy.co/amber/writing.svg',
              fallbackIcon: Icons.edit_note,
              primaryActionLabel: 'Create Post',
              onPrimaryAction: () {},
            ),
            SizedBox(height: 3.h),
            Text(
              'Tutorial Completed State',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            EnhancedEmptyStateWidget(
              title: "You've Completed Onboarding!",
              description: 'You\'re all set to start using the platform',
              illustrationUrl:
                  'https://illustrations.popsy.co/amber/success.svg',
              fallbackIcon: Icons.check_circle_outline,
              primaryActionLabel: 'Replay Tutorial',
              onPrimaryAction: () {},
              secondaryActionLabel: 'Go to Dashboard',
              onSecondaryAction: () {},
            ),
            SizedBox(height: 3.h),
            Text(
              'Wallet Empty State',
              style: GoogleFonts.inter(
                fontSize: 14.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            EnhancedEmptyStateWidget(
              title: 'Your Wallet is Empty',
              description:
                  'Start earning VP by participating in elections and completing quests',
              illustrationUrl:
                  'https://illustrations.popsy.co/amber/wallet.svg',
              fallbackIcon: Icons.account_balance_wallet_outlined,
              primaryActionLabel: 'Start Earning VP',
              onPrimaryAction: () {},
              secondaryActionLabel: 'Learn More',
              onSecondaryAction: () {},
            ),
          ] else ...[
            Center(
              child: Text(
                'Click button to see empty states',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildErrorFallbacksDemo() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Error Fallbacks',
            style: GoogleFonts.inter(
              fontSize: 18.sp,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Retry mechanisms and error handling for API failures',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
          SizedBox(height: 3.h),
          _buildErrorCard(
            'Network Error',
            'Check your internet connection',
            Icons.wifi_off,
            AppTheme.errorLight,
            'Retry',
          ),
          SizedBox(height: 2.h),
          _buildErrorCard(
            'Server Error',
            'Try again in 5 seconds...',
            Icons.cloud_off,
            AppTheme.warningLight,
            'Auto-retry',
          ),
          SizedBox(height: 2.h),
          _buildErrorCard(
            'Authentication Error',
            'Your session has expired',
            Icons.lock_outline,
            Colors.orange,
            'Re-login',
          ),
          SizedBox(height: 2.h),
          _buildErrorCard(
            'Request Timeout',
            'The request took too long',
            Icons.timer_off,
            AppTheme.errorLight,
            'Retry',
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: AppTheme.warningLight.withAlpha(26),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: AppTheme.warningLight, width: 2.0),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_off,
                  color: AppTheme.warningLight,
                  size: 24.sp,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "You're offline",
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Some features may be limited. Cached data available.',
                        style: GoogleFonts.inter(
                          fontSize: 12.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorCard(
    String title,
    String message,
    IconData icon,
    Color color,
    String actionLabel,
  ) {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: color, width: 2.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 24.sp),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$actionLabel triggered')),
                );
              },
              icon: Icon(Icons.refresh),
              label: Text(actionLabel),
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
