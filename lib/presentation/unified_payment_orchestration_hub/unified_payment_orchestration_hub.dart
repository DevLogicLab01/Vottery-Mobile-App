import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../routes/app_routes.dart';
import '../../services/auth_service.dart';
import '../../services/stripe_connect_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/payout_method_card_widget.dart';
import './widgets/routing_logic_panel_widget.dart';
import './widgets/subscription_payment_card_widget.dart';

class UnifiedPaymentOrchestrationHub extends StatefulWidget {
  const UnifiedPaymentOrchestrationHub({super.key});

  @override
  State<UnifiedPaymentOrchestrationHub> createState() =>
      _UnifiedPaymentOrchestrationHubState();
}

class _UnifiedPaymentOrchestrationHubState
    extends State<UnifiedPaymentOrchestrationHub> {
  final AuthService _auth = AuthService.instance;
  final StripeConnectService _stripeConnect = StripeConnectService.instance;

  bool _isLoading = true;
  Map<String, dynamic>? _subscriptionPaymentMethod;
  Map<String, dynamic>? _participationPaymentMethod;
  Map<String, dynamic>? _payoutSettings;
  Map<String, dynamic>? _paymentPreferences;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPaymentData();
  }

  Future<void> _loadPaymentData() async {
    setState(() => _isLoading = true);
    try {
      final userId = _auth.currentUser?.id;
      if (userId == null) {
        setState(() {
          _isLoading = false;
          _error = 'Please log in to manage payment methods';
        });
        return;
      }

      // Load payout settings
      final payoutResponse = await Supabase.instance.client
          .from('payout_settings')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      // Load payment preferences
      final prefsResponse = await Supabase.instance.client
          .from('user_payment_preferences')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      // Load Stripe Connect status
      Map<String, dynamic>? stripeStatus;
      try {
        final stripeResponse = await Supabase.instance.client
            .from('stripe_connect_accounts')
            .select()
            .eq('user_id', userId)
            .maybeSingle();
        stripeStatus = stripeResponse;
      } catch (_) {}

      // Load subscription payment method from user_subscriptions
      Map<String, dynamic>? subPayment;
      try {
        final subResponse = await Supabase.instance.client
            .from('user_subscriptions')
            .select('payment_method_id, plan_type, status')
            .eq('user_id', userId)
            .eq('status', 'active')
            .maybeSingle();
        subPayment = subResponse;
      } catch (_) {}

      if (mounted) {
        setState(() {
          _payoutSettings = payoutResponse != null
              ? {
                  ...payoutResponse,
                  'stripe_connect_status':
                      stripeStatus?['status'] ?? 'inactive',
                }
              : null;
          _paymentPreferences = prefsResponse;
          _subscriptionPaymentMethod = subPayment;
          _isLoading = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handleUpdatePreference(String flow, String method) async {
    final userId = _auth.currentUser?.id;
    if (userId == null) return;
    try {
      await Supabase.instance.client.from('user_payment_preferences').upsert({
        'user_id': userId,
        '${flow}_method': method,
        'updated_at': DateTime.now().toIso8601String(),
      });
      _loadPaymentData();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$flow method updated to $method'),
            backgroundColor: const Color(0xFF22C55E),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Update failed: $e')));
      }
    }
  }

  void _navigateToStripePortal() {
    Navigator.pushNamed(context, AppRoutes.stripeConnectPayoutManagementHub);
  }

  void _navigateToPayoutSettings() {
    Navigator.pushNamed(context, AppRoutes.creatorPayoutDashboard);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ErrorBoundaryWrapper(
      screenName: 'UnifiedPaymentOrchestrationHub',
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Payment Hub',
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadPaymentData,
              tooltip: 'Refresh',
            ),
          ],
        ),
        body: RefreshIndicator(
          onRefresh: _loadPaymentData,
          child: _isLoading
              ? _buildSkeleton()
              : _error != null
              ? _buildError()
              : _buildContent(),
        ),
      ),
    );
  }

  Widget _buildSkeleton() {
    return ListView.builder(
      itemCount: 4,
      padding: EdgeInsets.symmetric(vertical: 2.h),
      itemBuilder: (_, __) => Padding(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
        child: ShimmerSkeletonLoader(
          child: Container(
            width: double.infinity,
            height: 15.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 48),
          SizedBox(height: 2.h),
          Text(
            _error ?? 'Unknown error',
            style: GoogleFonts.inter(fontSize: 13.sp),
          ),
          SizedBox(height: 1.h),
          ElevatedButton(
            onPressed: _loadPaymentData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    return ListView(
      padding: EdgeInsets.symmetric(vertical: 2.h),
      children: [
        // Overview Header
        _buildOverviewHeader(),
        SizedBox(height: 1.h),

        // Section: Subscription Payments
        _SectionHeader(
          title: 'Subscription Payments',
          icon: Icons.subscriptions,
          color: const Color(0xFF6366F1),
        ),
        SubscriptionPaymentCardWidget(
          paymentMethod: _subscriptionPaymentMethod,
          onAddMethod: _navigateToStripePortal,
          onManage: _navigateToStripePortal,
        ),

        SizedBox(height: 1.h),

        // Section: Participation Fees
        _SectionHeader(
          title: 'Participation Fee Methods',
          icon: Icons.how_to_vote,
          color: const Color(0xFF0EA5E9),
        ),
        _ParticipationPaymentCard(
          method: _participationPaymentMethod,
          onManage: _navigateToStripePortal,
        ),

        SizedBox(height: 1.h),

        // Section: Creator Payouts
        _SectionHeader(
          title: 'Creator Payout Methods',
          icon: Icons.account_balance,
          color: const Color(0xFF10B981),
        ),
        PayoutMethodCardWidget(
          payoutSettings: _payoutSettings,
          onAddPayout: _navigateToPayoutSettings,
          onManage: _navigateToPayoutSettings,
        ),

        SizedBox(height: 1.h),

        // Smart Routing Panel
        _SectionHeader(
          title: 'Smart Routing',
          icon: Icons.route,
          color: const Color(0xFF8B5CF6),
        ),
        RoutingLogicPanelWidget(
          preferences: _paymentPreferences,
          onUpdatePreference: _handleUpdatePreference,
        ),

        SizedBox(height: 3.h),
      ],
    );
  }

  Widget _buildOverviewHeader() {
    final activeCount = [
      _subscriptionPaymentMethod,
      _participationPaymentMethod,
      _payoutSettings,
    ].where((m) => m != null).length;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payment Orchestration',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  '$activeCount of 3 methods configured',
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: Colors.white.withAlpha(200),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.white.withAlpha(30),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              '$activeCount/3',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 0.5.h),
      child: Row(
        children: [
          Icon(icon, color: color, size: 4.5.w),
          SizedBox(width: 2.w),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ParticipationPaymentCard extends StatelessWidget {
  final Map<String, dynamic>? method;
  final VoidCallback onManage;

  const _ParticipationPaymentCard({this.method, required this.onManage});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
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
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: const Color(0xFF0EA5E9).withAlpha(20),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: const Icon(
                  Icons.how_to_vote,
                  color: Color(0xFF0EA5E9),
                  size: 20,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                'Participation Fee Payment',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          Row(
            children: [
              _MethodBadge(
                label: 'Stripe',
                isActive: true,
                color: const Color(0xFF6366F1),
              ),
              SizedBox(width: 2.w),
              _MethodBadge(
                label: 'Bank Transfer',
                isActive: false,
                color: const Color(0xFF22C55E),
              ),
            ],
          ),
          SizedBox(height: 1.5.h),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onManage,
              icon: const Icon(Icons.manage_accounts, size: 16),
              label: const Text('Manage Methods'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF0EA5E9),
                side: const BorderSide(color: Color(0xFF0EA5E9)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MethodBadge extends StatelessWidget {
  final String label;
  final bool isActive;
  final Color color;

  const _MethodBadge({
    required this.label,
    required this.isActive,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 0.8.h),
      decoration: BoxDecoration(
        color: isActive ? color.withAlpha(20) : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: isActive ? color : Colors.grey.shade300),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isActive ? Icons.check_circle : Icons.circle_outlined,
            size: 3.5.w,
            color: isActive ? color : Colors.grey.shade400,
          ),
          SizedBox(width: 1.w),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: isActive ? color : Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}