import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../theme/app_theme.dart';
import '../../../services/stripe_connect_service.dart';

class StripeConnectOnboardingWidget extends StatefulWidget {
  final Map<String, dynamic> creatorAccount;
  final VoidCallback onOnboardingComplete;

  const StripeConnectOnboardingWidget({
    super.key,
    required this.creatorAccount,
    required this.onOnboardingComplete,
  });

  @override
  State<StripeConnectOnboardingWidget> createState() =>
      _StripeConnectOnboardingWidgetState();
}

class _StripeConnectOnboardingWidgetState
    extends State<StripeConnectOnboardingWidget> {
  final StripeConnectService _stripeService = StripeConnectService.instance;
  bool _isLoading = false;

  Future<void> _startOnboarding() async {
    setState(() => _isLoading = true);

    try {
      final onboardingLink = await _stripeService.getAccountOnboardingLink();

      if (onboardingLink != null && mounted) {
        // Open onboarding link in webview or browser
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Opening Stripe Connect onboarding...'),
            backgroundColor: AppTheme.accentLight,
          ),
        );

        // TODO: Implement webview navigation
        // For now, just show success message
        await Future.delayed(const Duration(seconds: 2));
        widget.onOnboardingComplete();
      }
    } catch (e) {
      debugPrint('Onboarding error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to start onboarding'),
            backgroundColor: AppTheme.errorLight,
          ),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final stripeAccountId = widget.creatorAccount['stripe_account_id'];
    final stripeStatus =
        widget.creatorAccount['stripe_account_status'] ?? 'pending';

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(
          color: stripeAccountId != null ? Colors.green : Colors.orange,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withAlpha(51),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                stripeAccountId != null ? Icons.check_circle : Icons.warning,
                color: stripeAccountId != null ? Colors.green : Colors.orange,
                size: 6.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Stripe Connect',
                  style: GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
              _buildStatusChip(stripeStatus),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            stripeAccountId != null
                ? 'Your Stripe account is connected. You can now request payouts.'
                : 'Connect your Stripe account to receive payouts directly to your bank account.',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade700),
          ),
          if (stripeAccountId == null) ...[
            SizedBox(height: 2.h),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _startOnboarding,
              icon: _isLoading
                  ? SizedBox(
                      width: 4.w,
                      height: 4.w,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(Icons.link, size: 5.w),
              label: Text(
                _isLoading ? 'Connecting...' : 'Connect Stripe',
                style: TextStyle(fontSize: 12.sp),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.accentLight,
                foregroundColor: Colors.white,
                minimumSize: Size(double.infinity, 6.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color backgroundColor;
    Color textColor;
    String displayText;

    switch (status) {
      case 'verified':
        backgroundColor = Colors.green.withAlpha(51);
        textColor = Colors.green;
        displayText = 'Verified';
        break;
      case 'pending':
        backgroundColor = Colors.orange.withAlpha(51);
        textColor = Colors.orange;
        displayText = 'Pending';
        break;
      case 'restricted':
        backgroundColor = Colors.red.withAlpha(51);
        textColor = Colors.red;
        displayText = 'Restricted';
        break;
      default:
        backgroundColor = Colors.grey.withAlpha(51);
        textColor = Colors.grey;
        displayText = status;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Text(
        displayText,
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}
