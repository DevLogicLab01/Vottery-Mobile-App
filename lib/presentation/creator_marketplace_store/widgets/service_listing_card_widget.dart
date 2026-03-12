import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ServiceListingCardWidget extends StatelessWidget {
  final Map<String, dynamic> service;
  final VoidCallback onTap;

  const ServiceListingCardWidget({
    super.key,
    required this.service,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final priceTiers = service['price_tiers'] as List;
    final basePrice = priceTiers.first['price'] as num;
    final rating = (service['rating'] ?? 4.8) as num;
    final reviewCount = (service['review_count'] ?? 0) as int;
    final deliveryDays = service['delivery_time_days'] as int;
    final isFeatured = (service['is_featured'] ?? false) as bool;
    final category = service['category'] as String?;
    final creatorProfile = service['user_profiles'] as Map<String, dynamic>?;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.surfaceLight,
          borderRadius: BorderRadius.circular(12.0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8.0,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Creator Profile Picture
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(12.0),
                  ),
                  child: CachedNetworkImage(
                    imageUrl:
                        creatorProfile?['avatar_url'] ??
                        'https://images.unsplash.com/photo-1535713875002-d1d0cf377fde?w=400',
                    height: 15.h,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppTheme.textSecondaryLight.withValues(alpha: 0.1),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppTheme.textSecondaryLight.withValues(alpha: 0.1),
                      child: Icon(Icons.person, size: 10.w),
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
                        color: Colors.amber,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, size: 3.w, color: Colors.white),
                          SizedBox(width: 1.w),
                          Text(
                            'Featured',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
            Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Service Title
                  Text(
                    service['title'] as String,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),
                  // Creator Name
                  Text(
                    creatorProfile?['full_name'] ?? 'Creator',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppTheme.textSecondaryLight,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: 1.h),
                  // Rating
                  Row(
                    children: [
                      Icon(Icons.star, color: Colors.amber, size: 4.w),
                      SizedBox(width: 1.w),
                      Text(
                        '${rating.toStringAsFixed(1)}/5.0',
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimaryLight,
                        ),
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '($reviewCount)',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  // Delivery Time
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        color: AppTheme.textSecondaryLight,
                        size: 4.w,
                      ),
                      SizedBox(width: 1.w),
                      Text(
                        '$deliveryDays days delivery',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  // Category Tag
                  if (category != null)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Text(
                        category,
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  SizedBox(height: 1.h),
                  // Starting Price
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Starting at',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: AppTheme.textSecondaryLight,
                        ),
                      ),
                      Text(
                        '\$${basePrice.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
