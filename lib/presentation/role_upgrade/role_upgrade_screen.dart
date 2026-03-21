import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../constants/roles.dart';
import '../../routes/app_routes.dart';
import '../../services/auth_service_new.dart';
import '../../services/supabase_service.dart';

class _RoleInfo {
  const _RoleInfo(this.label, this.icon, this.color, this.benefits, this.ctaRoute);
  final String label;
  final IconData icon;
  final Color color;
  final List<String> benefits;
  final String ctaRoute;
}

/// Role upgrade request screen. Users can request creator or advertiser access.
class RoleUpgradeScreen extends StatefulWidget {
  const RoleUpgradeScreen({super.key, this.initialRole = 'creator'});

  final String initialRole;

  @override
  State<RoleUpgradeScreen> createState() => _RoleUpgradeScreenState();
}

class _RoleUpgradeScreenState extends State<RoleUpgradeScreen> {
  late String _requestedRole;
  final _messageController = TextEditingController();
  bool _submitting = false;

  static const _roleInfo = {
    'creator': _RoleInfo('Creator', Icons.add_circle_outline, Color(0xFF7C3AED), [
      'Create elections and polls',
      'Monetize with participation fees',
      'Access creator analytics',
      'Stripe payouts',
    ], AppRoutes.electionCreationStudio),
    'advertiser': _RoleInfo('Advertiser', Icons.campaign, Color(0xFF059669), [
      'Run participatory ad campaigns',
      'Target engaged audiences',
      'Real-time ROI dashboards',
      'Brand registration',
    ], AppRoutes.participatoryAdsStudio),
  };

  @override
  void initState() {
    super.initState();
    _requestedRole = widget.initialRole;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final args = ModalRoute.of(context)?.settings.arguments;
    if (args is Map<String, dynamic> && args['role'] != null) {
      _requestedRole = args['role'] as String;
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _handleRequestUpgrade() async {
    final user = AuthService.instance.currentUser;
    if (user == null) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        AppRoutes.initial,
        (route) => false,
      );
      return;
    }
    setState(() => _submitting = true);
    try {
      await SupabaseService.instance.client.from('role_upgrade_requests').insert({
        'user_id': user.id,
        'requested_role': _requestedRole,
        'message': _messageController.text.isEmpty ? null : _messageController.text,
        'status': 'pending',
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Upgrade request submitted. We\'ll review it shortly.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pushNamedAndRemoveUntil(context, AppRoutes.initial, (route) => false);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final info = _roleInfo[_requestedRole] ?? _roleInfo['creator']!;
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthService.instance.getUserProfile(),
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final role = profile?['role'] as String?;
        final alreadyHasRole = role == _requestedRole || AppRoles.adminRoles.contains(role);

        if (alreadyHasRole) {
          return Scaffold(
            body: SafeArea(
              child: Padding(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(info.icon, size: 64, color: info.color),
                    SizedBox(height: 2.h),
                    Text(
                      'You already have ${info.label} access',
                      style: Theme.of(context).textTheme.titleLarge,
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'Go to your ${info.label.toLowerCase()} dashboard to get started.',
                      textAlign: TextAlign.center,
                    ),
                    SizedBox(height: 4.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushReplacementNamed(context, info.ctaRoute),
                        child: Text('Go to ${info.label} Dashboard'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          appBar: AppBar(title: const Text('Upgrade')),
          body: SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: BoxDecoration(
                    color: info.color.withAlpha(230),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(info.icon, size: 48, color: Colors.white),
                      SizedBox(height: 2.h),
                      Text(
                        'Upgrade to ${info.label}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Unlock powerful tools to grow and monetize on Vottery.',
                        style: TextStyle(color: Colors.white.withAlpha(230)),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 3.h),
                Text('What you get', style: Theme.of(context).textTheme.titleMedium),
                SizedBox(height: 2.h),
                ...info.benefits.map((b) => Padding(
                  padding: EdgeInsets.only(bottom: 1.h),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.check, color: Colors.green, size: 20),
                      SizedBox(width: 2.w),
                      Expanded(child: Text(b)),
                    ],
                  ),
                )),
                SizedBox(height: 3.h),
                TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(
                    labelText: 'Tell us why you want to upgrade (optional)',
                    hintText: 'e.g. I run a community and want to create polls...',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Back'),
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _submitting ? null : _handleRequestUpgrade,
                        child: _submitting ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Request Upgrade'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
