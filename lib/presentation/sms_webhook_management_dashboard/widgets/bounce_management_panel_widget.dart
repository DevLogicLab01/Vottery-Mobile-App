import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/supabase_service.dart';
import 'package:intl/intl.dart';

class BounceManagementPanelWidget extends StatelessWidget {
  final List<Map<String, dynamic>> bounceList;
  final VoidCallback onRefresh;

  const BounceManagementPanelWidget({
    super.key,
    required this.bounceList,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (bounceList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.block, size: 48.sp, color: Colors.grey[400]),
            SizedBox(height: 2.h),
            Text(
              'No bounced numbers',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(3.w),
          color: theme.colorScheme.surface,
          child: Row(
            children: [
              Icon(Icons.info_outline, size: 16.sp, color: Colors.orange),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Suppressed numbers will not receive SMS messages',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.orange[700],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.all(4.w),
            itemCount: bounceList.length,
            separatorBuilder: (context, index) => SizedBox(height: 2.h),
            itemBuilder: (context, index) {
              final bounce = bounceList[index];
              return _buildBounceCard(context, theme, bounce);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildBounceCard(
    BuildContext context,
    ThemeData theme,
    Map<String, dynamic> bounce,
  ) {
    final phoneNumber = bounce['phone_number'] as String? ?? 'Unknown';
    final bounceType = bounce['bounce_type'] as String? ?? 'unknown';
    final bounceReason = bounce['bounce_reason'] as String? ?? 'No reason provided';
    final bounceCount = bounce['bounce_count'] as int? ?? 0;
    final firstBouncedAt = bounce['first_bounced_at'] as String?;

    final typeColor = _getBounceTypeColor(bounceType);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: typeColor.withAlpha(51)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_android, size: 16.sp, color: typeColor),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  phoneNumber,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                decoration: BoxDecoration(
                  color: typeColor.withAlpha(26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  bounceType.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    fontSize: 9.sp,
                    fontWeight: FontWeight.bold,
                    color: typeColor,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            bounceReason,
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.grey[700],
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Icon(Icons.repeat, size: 12.sp, color: Colors.grey[600]),
              SizedBox(width: 1.w),
              Text(
                '$bounceCount bounces',
                style: TextStyle(
                  fontSize: 10.sp,
                  color: Colors.grey[600],
                ),
              ),
              SizedBox(width: 3.w),
              if (firstBouncedAt != null) ...[
                Icon(Icons.access_time, size: 12.sp, color: Colors.grey[600]),
                SizedBox(width: 1.w),
                Text(
                  _formatTimestamp(firstBouncedAt),
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey[600],
                  ),
                ),
              ],
            ],
          ),
          SizedBox(height: 1.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => _removeSuppression(context, bounce['bounce_id'] as String?),
                icon: Icon(Icons.check_circle_outline, size: 14.sp),
                label: const Text('Remove Suppression'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getBounceTypeColor(String bounceType) {
    switch (bounceType) {
      case 'hard_bounce':
        return Colors.red;
      case 'soft_bounce':
        return Colors.orange;
      case 'carrier_blocked':
        return Colors.purple;
      case 'spam_detected':
        return Colors.deepOrange;
      case 'network_error':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _removeSuppression(BuildContext context, String? bounceId) async {
    if (bounceId == null) return;

    try {
      await SupabaseService.instance.client
          .from('sms_bounce_list')
          .update({'is_suppressed': false, 'updated_at': DateTime.now().toIso8601String()})
          .eq('bounce_id', bounceId);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Suppression removed successfully'),
            backgroundColor: Colors.green,
          ),
        );
        onRefresh();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error removing suppression: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatTimestamp(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('MMM d, yyyy').format(dateTime);
    } catch (e) {
      return timestamp;
    }
  }
}