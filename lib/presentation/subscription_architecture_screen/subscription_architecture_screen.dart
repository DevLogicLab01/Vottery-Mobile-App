import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/supabase_service.dart';
import '../../services/auth_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../framework/shared_constants.dart';
import './widgets/current_plan_card_widget.dart';
import './widgets/subscription_tiers_comparison_widget.dart';
import './widgets/billing_analytics_panel_widget.dart';
import './widgets/upgrade_downgrade_controls_widget.dart';

class SubscriptionArchitectureScreen extends StatefulWidget {
  const SubscriptionArchitectureScreen({super.key});

  @override
  State<SubscriptionArchitectureScreen> createState() =>
      _SubscriptionArchitectureScreenState();
}

class _SubscriptionArchitectureScreenState
    extends State<SubscriptionArchitectureScreen> {
  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;
  Map<String, dynamic>? _subscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubscription();
  }

  Future<void> _loadSubscription() async {
    setState(() => _isLoading = true);
    try {
      if (!_auth.isAuthenticated) {
        setState(() => _isLoading = false);
        return;
      }
      final response = await _client
          .from(SharedConstants.userSubscriptions)
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .inFilter('status', ['active', 'past_due'])
          .maybeSingle();

      if (mounted) {
        setState(() {
          _subscription = response;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load subscription error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String get _currentPlan {
    return _subscription?['plan_type'] as String? ?? 'Basic';
  }

  int get _vpMultiplier {
    switch (_currentPlan.toLowerCase()) {
      case 'elite':
        return SharedConstants.vpMultiplierElite;
      case 'pro':
        return SharedConstants.vpMultiplierPro;
      default:
        return SharedConstants.vpMultiplierBasic;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'SubscriptionArchitecture',
      onRetry: _loadSubscription,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Subscription',
          variant: CustomAppBarVariant.withBack,
          onBackPressed: () => Navigator.pop(context),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadSubscription,
            ),
          ],
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadSubscription,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CurrentPlanCardWidget(
                        subscription: _subscription,
                        currentPlan: _currentPlan,
                        vpMultiplier: _vpMultiplier,
                      ),
                      SizedBox(height: 3.h),
                      SubscriptionTiersComparisonWidget(
                        currentPlan: _currentPlan,
                      ),
                      SizedBox(height: 3.h),
                      BillingAnalyticsPanelWidget(subscription: _subscription),
                      SizedBox(height: 3.h),
                      UpgradeDowngradeControlsWidget(
                        currentPlan: _currentPlan,
                        onPlanChanged: _loadSubscription,
                      ),
                      SizedBox(height: 4.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
