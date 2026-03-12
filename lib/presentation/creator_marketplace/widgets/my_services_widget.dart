import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

/// My Services Widget
/// Manage creator's own marketplace service listings
class MyServicesWidget extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final VoidCallback onRefresh;

  const MyServicesWidget({
    super.key,
    required this.services,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.store_outlined,
              size: 15.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No services listed yet',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            ElevatedButton(
              onPressed: onRefresh,
              child: Text('Create Your First Service'),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(services[index]);
      },
    );
  }

  Widget _buildServiceCard(Map<String, dynamic> service) {
    final title = service['title'] ?? 'Untitled Service';
    final serviceType = service['service_type'] ?? 'unknown';
    final isActive = service['is_active'] ?? false;
    final priceTiers = service['price_tiers'] as List? ?? [];

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: isActive
              ? AppTheme.primaryLight.withAlpha(26)
              : Colors.grey.withAlpha(26),
          child: Icon(
            _getServiceIcon(serviceType),
            color: isActive ? AppTheme.primaryLight : Colors.grey,
            size: 6.w,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          _formatServiceType(serviceType),
          style: TextStyle(fontSize: 12.sp),
        ),
        trailing: Container(
          padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.green.withAlpha(26)
                : Colors.grey.withAlpha(26),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Text(
            isActive ? 'Active' : 'Inactive',
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
              color: isActive ? Colors.green : Colors.grey,
            ),
          ),
        ),
        children: [
          Padding(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service['description'] ?? 'No description',
                  style: TextStyle(fontSize: 12.sp),
                ),
                SizedBox(height: 2.h),
                Text(
                  'Pricing Tiers',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                ...priceTiers.map(
                  (tier) => ListTile(
                    dense: true,
                    title: Text(
                      tier['tier_name'] ?? 'Tier',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    trailing: Text(
                      '\$${tier['price']}',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {},
                        child: Text('Edit'),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        child: Text(isActive ? 'Deactivate' : 'Activate'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getServiceIcon(String type) {
    switch (type) {
      case 'consultation':
        return Icons.video_call;
      case 'sponsored_content':
        return Icons.campaign;
      case 'exclusive_access':
        return Icons.lock_open;
      case 'collaboration_bundle':
        return Icons.handshake;
      case 'shoutout':
        return Icons.record_voice_over;
      default:
        return Icons.star;
    }
  }

  String _formatServiceType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}
