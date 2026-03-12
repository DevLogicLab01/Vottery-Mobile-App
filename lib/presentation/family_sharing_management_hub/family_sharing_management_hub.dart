import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/resend_email_service.dart';
import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import './widgets/add_family_member_dialog_widget.dart';
import './widgets/family_member_card_widget.dart';
import './widgets/family_status_header_widget.dart';
import './widgets/quota_management_widget.dart';
import './widgets/usage_analytics_widget.dart';

class FamilySharingManagementHub extends StatefulWidget {
  const FamilySharingManagementHub({super.key});

  @override
  State<FamilySharingManagementHub> createState() =>
      _FamilySharingManagementHubState();
}

class _FamilySharingManagementHubState
    extends State<FamilySharingManagementHub> {
  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;
  final _resend = ResendEmailService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _familyMembers = [];
  Map<String, dynamic>? _currentSubscription;
  Map<String, dynamic> _usageAnalytics = {};
  String _selectedTab = 'members';

  @override
  void initState() {
    super.initState();
    _loadFamilyData();
  }

  Future<void> _loadFamilyData() async {
    setState(() => _isLoading = true);

    try {
      if (!_auth.isAuthenticated) {
        setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait([
        _loadFamilyMembers(),
        _loadCurrentSubscription(),
        _loadUsageAnalytics(),
      ]);

      setState(() => _isLoading = false);
    } catch (e) {
      debugPrint('Load family data error: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadFamilyMembers() async {
    try {
      final response = await _client
          .from('family_members')
          .select()
          .eq('primary_account_id', _auth.currentUser!.id)
          .order('created_at', ascending: false);

      setState(() {
        _familyMembers = List<Map<String, dynamic>>.from(response);
      });
    } catch (e) {
      debugPrint('Load family members error: $e');
    }
  }

  Future<void> _loadCurrentSubscription() async {
    try {
      final response = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .eq('status', 'active')
          .maybeSingle();

      setState(() {
        _currentSubscription = response;
      });
    } catch (e) {
      debugPrint('Load subscription error: $e');
    }
  }

  Future<void> _loadUsageAnalytics() async {
    try {
      if (_currentSubscription == null) return;

      final response = await _client
          .from('family_usage_analytics')
          .select()
          .eq('subscription_id', _currentSubscription!['id'])
          .gte(
            'date',
            DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
          );

      final analytics = List<Map<String, dynamic>>.from(response);

      // Calculate aggregate metrics
      int totalApiCalls = 0;
      double totalStorage = 0;
      int totalUsageTime = 0;
      Set<String> allFeatures = {};

      for (var record in analytics) {
        totalApiCalls += (record['api_calls_count'] as int?) ?? 0;
        totalStorage += (record['storage_used_mb'] as num?)?.toDouble() ?? 0.0;
        totalUsageTime += (record['usage_time_minutes'] as int?) ?? 0;

        final features = record['active_features'] as List?;
        if (features != null) {
          allFeatures.addAll(features.cast<String>());
        }
      }

      setState(() {
        _usageAnalytics = {
          'total_api_calls': totalApiCalls,
          'total_storage_mb': totalStorage,
          'total_usage_time_minutes': totalUsageTime,
          'active_features_count': allFeatures.length,
          'detailed_analytics': analytics,
        };
      });
    } catch (e) {
      debugPrint('Load usage analytics error: $e');
    }
  }

  Future<void> _showAddMemberDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => const AddFamilyMemberDialogWidget(),
    );

    if (result != null) {
      await _addFamilyMember(result);
    }
  }

  Future<void> _addFamilyMember(Map<String, dynamic> memberData) async {
    try {
      // Generate invitation token
      final token =
          DateTime.now().millisecondsSinceEpoch.toString() +
          _auth.currentUser!.id.substring(0, 8);

      // Insert family member
      await _client.from('family_members').insert({
        'primary_account_id': _auth.currentUser!.id,
        'email': memberData['email'],
        'relationship': memberData['relationship'],
        'permissions': memberData['permissions'],
        'invitation_token': token,
        'invitation_expires_at': DateTime.now()
            .add(const Duration(days: 7))
            .toIso8601String(),
        'status': 'pending',
      });

      // Send invitation email
      await _sendInvitationEmail(
        memberData['email'],
        token,
        memberData['relationship'],
      );

      await _loadFamilyMembers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation sent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Add family member error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendInvitationEmail(
    String email,
    String token,
    String relationship,
  ) async {
    try {
      final invitationLink =
          'https://vottery2205.builtwithrocket.new/accept-family-invitation?token=$token';

      await _resend.sendComplianceReport(
        recipientEmail: email,
        reportType: 'Family Invitation',
        reportData: {
          'primary_account_holder': _auth.currentUser!.email ?? 'User',
          'relationship': relationship,
          'invitation_link': invitationLink,
          'expiry_days': 7,
        },
      );
    } catch (e) {
      debugPrint('Send invitation email error: $e');
    }
  }

  Future<void> _removeFamilyMember(String memberId) async {
    try {
      await _client.from('family_members').delete().eq('id', memberId);

      await _loadFamilyMembers();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Family member removed'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Remove family member error: $e');
    }
  }

  Future<void> _resendInvitation(String memberId, String email) async {
    try {
      final token =
          DateTime.now().millisecondsSinceEpoch.toString() +
          _auth.currentUser!.id.substring(0, 8);

      await _client
          .from('family_members')
          .update({
            'invitation_token': token,
            'invitation_expires_at': DateTime.now()
                .add(const Duration(days: 7))
                .toIso8601String(),
          })
          .eq('id', memberId);

      final member = _familyMembers.firstWhere((m) => m['id'] == memberId);
      await _sendInvitationEmail(email, token, member['relationship']);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Invitation resent successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Resend invitation error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'FamilySharingManagementHub',
      onRetry: _loadFamilyData,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: CustomAppBar(
          title: 'Family Sharing',
          variant: CustomAppBarVariant.withBack,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadFamilyData,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: _loadFamilyData,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    children: [
                      FamilyStatusHeaderWidget(
                        activeMembersCount: _familyMembers
                            .where((m) => m['status'] == 'active')
                            .length,
                        totalMembers: _familyMembers.length,
                        subscription: _currentSubscription,
                      ),
                      SizedBox(height: 2.h),
                      _buildShareYourPremiumCard(theme),
                      SizedBox(height: 2.h),
                      _buildTabSelector(theme),
                      SizedBox(height: 2.h),
                      _buildTabContent(theme),
                    ],
                  ),
                ),
              ),
        floatingActionButton: _selectedTab == 'members'
            ? FloatingActionButton.extended(
                onPressed: _showAddMemberDialog,
                icon: const Icon(Icons.person_add),
                label: const Text('Add Member'),
              )
            : null,
      ),
    );
  }

  Widget _buildShareYourPremiumCard(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryLight, Colors.purple],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'family_restroom',
                size: 8.w,
                color: Colors.white,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Share Your Premium',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildBenefitRow('Up to 5 family members', Icons.people),
          _buildBenefitRow('Shared premium features', Icons.star),
          _buildBenefitRow('Individual profiles', Icons.person),
          _buildBenefitRow('Separate usage tracking', Icons.analytics),
        ],
      ),
    );
  }

  Widget _buildBenefitRow(String text, IconData icon) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 5.w),
          SizedBox(width: 2.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 13.sp,
              color: Colors.white.withAlpha(230),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSelector(ThemeData theme) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      child: Row(
        children: [
          Expanded(child: _buildTab('members', 'Members', Icons.people, theme)),
          SizedBox(width: 2.w),
          Expanded(
            child: _buildTab('analytics', 'Analytics', Icons.analytics, theme),
          ),
          SizedBox(width: 2.w),
          Expanded(child: _buildTab('quota', 'Quota', Icons.pie_chart, theme)),
        ],
      ),
    );
  }

  Widget _buildTab(String tabId, String label, IconData icon, ThemeData theme) {
    final isSelected = _selectedTab == tabId;

    return GestureDetector(
      onTap: () => setState(() => _selectedTab = tabId),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryLight : Colors.grey[200],
          borderRadius: BorderRadius.circular(12.0),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondaryLight,
              size: 6.w,
            ),
            SizedBox(height: 0.5.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected ? Colors.white : AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTabContent(ThemeData theme) {
    switch (_selectedTab) {
      case 'members':
        return _buildMembersTab(theme);
      case 'analytics':
        return UsageAnalyticsWidget(
          analytics: _usageAnalytics,
          familyMembers: _familyMembers,
        );
      case 'quota':
        return QuotaManagementWidget(
          subscription: _currentSubscription,
          usageAnalytics: _usageAnalytics,
          familyMembers: _familyMembers,
        );
      default:
        return Container();
    }
  }

  Widget _buildMembersTab(ThemeData theme) {
    if (_familyMembers.isEmpty) {
      return Container(
        padding: EdgeInsets.all(8.w),
        child: Column(
          children: [
            Icon(Icons.people_outline, size: 20.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No Family Members Yet',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Add family members to share your premium subscription',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: _familyMembers.map((member) {
        return FamilyMemberCardWidget(
          member: member,
          onRemove: () => _removeFamilyMember(member['id']),
          onResendInvitation: () =>
              _resendInvitation(member['id'], member['email']),
        );
      }).toList(),
    );
  }
}
