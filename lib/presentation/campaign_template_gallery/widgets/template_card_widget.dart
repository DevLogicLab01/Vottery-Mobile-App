import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class TemplateCardWidget extends StatelessWidget {
  final Map<String, dynamic> template;
  final VoidCallback onTap;
  final bool isFeatured;

  const TemplateCardWidget({
    super.key,
    required this.template,
    required this.onTap,
    this.isFeatured = false,
  });

  @override
  Widget build(BuildContext context) {
    final name = template['name'] as String? ?? 'Untitled Template';
    final description = template['description'] as String? ?? '';
    final successRate = (template['success_rate'] as num?)?.toDouble() ?? 0.0;
    final usageCount = template['usage_count'] as int? ?? 0;
    final industryTags =
        (template['industry_tags'] as List?)?.cast<String>() ?? [];
    final thumbnailUrl = template['thumbnail_url'] as String?;

    return Card(
      elevation: isFeatured ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            Stack(
              children: [
                Container(
                  height: 15.h,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(12.0),
                    ),
                    color: Colors.grey[200],
                    image: thumbnailUrl != null
                        ? DecorationImage(
                            image: NetworkImage(thumbnailUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: thumbnailUrl == null
                      ? Center(
                          child: Icon(
                            Icons.campaign,
                            size: 40.sp,
                            color: Colors.grey,
                          ),
                        )
                      : null,
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
                          Icon(Icons.star, size: 12.sp, color: Colors.white),
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

            // Content
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(3.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Template Name
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 0.5.h),

                    // Description
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const Spacer(),

                    // Industry Tags
                    if (industryTags.isNotEmpty)
                      Wrap(
                        spacing: 1.w,
                        runSpacing: 0.5.h,
                        children: industryTags.take(2).map((tag) {
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: 2.w,
                              vertical: 0.3.h,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.accentLight.withAlpha(26),
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Text(
                              tag.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9.sp,
                                color: AppTheme.accentLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          );
                        }).toList(),
                      ),

                    SizedBox(height: 1.h),

                    // Stats Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Success Rate
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 12.sp,
                              color: Colors.green,
                            ),
                            SizedBox(width: 1.w),
                            Text(
                              '${successRate.toStringAsFixed(0)}%',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),

                        // Usage Count
                        Row(
                          children: [
                            Icon(Icons.people, size: 12.sp, color: Colors.grey),
                            SizedBox(width: 1.w),
                            Text(
                              '$usageCount',
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey,
                              ),
                            ),
                          ],
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
}
