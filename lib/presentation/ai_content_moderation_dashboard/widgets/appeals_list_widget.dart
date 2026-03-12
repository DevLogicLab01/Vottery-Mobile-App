import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/supabase_service.dart';
import '../../../widgets/custom_icon_widget.dart';

class AppealsListWidget extends StatelessWidget {
  const AppealsListWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final client = SupabaseService.instance.client;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: client
          .from('content_appeals')
          .stream(primaryKey: ['appeal_id'])
          .eq('status', 'pending')
          .order('submitted_at', ascending: false),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CustomIconWidget(
                  iconName: 'gavel',
                  color: theme.disabledColor,
                  size: 64,
                ),
                SizedBox(height: 2.h),
                Text(
                  'No pending appeals',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: theme.disabledColor,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(4.w),
          itemCount: snapshot.data!.length,
          itemBuilder: (context, index) {
            final appeal = snapshot.data![index];
            return _buildAppealCard(context, appeal);
          },
        );
      },
    );
  }

  Widget _buildAppealCard(BuildContext context, Map<String, dynamic> appeal) {
    final theme = Theme.of(context);

    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Appeal Reason',
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            appeal['appeal_reason'] ?? 'No reason provided',
            style: theme.textTheme.bodyMedium,
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _handleApproveAppeal(context, appeal),
                  icon: CustomIconWidget(
                    iconName: 'check_circle',
                    color: Colors.white,
                    size: 18,
                  ),
                  label: const Text('Approve'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _handleRejectAppeal(context, appeal),
                  icon: CustomIconWidget(
                    iconName: 'cancel',
                    color: const Color(0xFFEF4444),
                    size: 18,
                  ),
                  label: Text(
                    'Reject',
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Color(0xFFEF4444)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _handleApproveAppeal(
    BuildContext context,
    Map<String, dynamic> appeal,
  ) async {
    try {
      await SupabaseService.instance.client
          .from('content_appeals')
          .update({'status': 'approved'})
          .eq('appeal_id', appeal['appeal_id']);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Appeal approved')));
      }
    } catch (e) {
      debugPrint('Approve appeal error: $e');
    }
  }

  Future<void> _handleRejectAppeal(
    BuildContext context,
    Map<String, dynamic> appeal,
  ) async {
    try {
      await SupabaseService.instance.client
          .from('content_appeals')
          .update({'status': 'denied'})
          .eq('appeal_id', appeal['appeal_id']);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Appeal rejected')));
      }
    } catch (e) {
      debugPrint('Reject appeal error: $e');
    }
  }
}
