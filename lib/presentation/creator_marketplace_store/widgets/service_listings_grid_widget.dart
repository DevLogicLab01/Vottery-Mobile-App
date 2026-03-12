import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ServiceListingsGridWidget extends StatelessWidget {
  final List<Map<String, dynamic>> services;
  final Function(Map<String, dynamic>) onServiceTap;

  const ServiceListingsGridWidget({
    super.key,
    required this.services,
    required this.onServiceTap,
  });

  @override
  Widget build(BuildContext context) {
    if (services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.storefront_outlined,
              size: 15.w,
              color: AppTheme.textSecondaryLight,
            ),
            SizedBox(height: 2.h),
            Text(
              'No services available',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(4.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 0.75,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        return _buildServiceCard(context, services[index]);
      },
    );
  }

  Widget _buildServiceCard(BuildContext context, Map<String, dynamic> service) {
    final title = service['title'] ?? 'Untitled Service';
    final priceTiers = service['price_tiers'] as List? ?? [];
    final startingPrice = priceTiers.isNotEmpty ? priceTiers.first['price'] : 0;
    final rating = service['rating'] ?? 4.8;
    final reviewCount = service['review_count'] ?? 0;
    final deliveryDays = service['delivery_time_days'] ?? 3;
    final isFeatured = service['is_featured'] ?? false;
    final category = service['category'] ?? 'General';
    final creatorName = service['user_profiles']?['full_name'] ?? 'Creator';
    final creatorAvatar = service['user_profiles']?['avatar_url'];

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: () => onServiceTap(service),
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Container(
                  height: 12.h,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withAlpha(26),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12.0),
                      topRight: Radius.circular(12.0),
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      _getCategoryIcon(category),
                      size: 10.w,
                      color: AppTheme.primaryLight,
                    ),
                  ),
                ),
                if (isFeatured)
                  Positioned(
                    top: 1.h,
                    right: 2.w,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.vibrantYellow,
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 3.w, color: Colors.white),
                          SizedBox(width: 1.w),
                          Text(
                            'Featured',
                            style: TextStyle(
                              fontSize: 9.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 3.w,
                          backgroundImage: creatorAvatar != null
                              ? NetworkImage(creatorAvatar)
                              : null,
                          child: creatorAvatar == null
                              ? Text(
                                  creatorName[0].toUpperCase(),
                                  style: TextStyle(fontSize: 10.sp),
                                )
                              : null,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Text(
                            creatorName,
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 3.5.w,
                          color: AppTheme.vibrantYellow,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '$rating',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          ' ($reviewCount)',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 0.5.h),
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 3.5.w,
                          color: AppTheme.textSecondaryLight,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          '$deliveryDays days',
                          style: TextStyle(
                            fontSize: 10.sp,
                            color: AppTheme.textSecondaryLight,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryLight.withAlpha(26),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 9.sp,
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          '\$$startingPrice',
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category.toLowerCase()) {
      case 'design':
        return Icons.palette;
      case 'content':
        return Icons.article;
      case 'strategy':
        return Icons.lightbulb;
      case 'management':
        return Icons.business_center;
      default:
        return Icons.category;
    }
  }
}
