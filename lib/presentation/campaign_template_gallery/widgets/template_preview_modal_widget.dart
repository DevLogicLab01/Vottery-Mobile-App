import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class TemplatePreviewModalWidget extends StatelessWidget {
  final Map<String, dynamic> template;
  final VoidCallback onApply;

  const TemplatePreviewModalWidget({
    super.key,
    required this.template,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    final name = template['name'] as String? ?? 'Untitled Template';
    final description = template['description'] as String? ?? '';
    final successRate = (template['success_rate'] as num?)?.toDouble() ?? 0.0;
    final avgRoi = (template['avg_roi'] as num?)?.toDouble() ?? 0.0;
    final avgEngagement =
        (template['avg_engagement'] as num?)?.toDouble() ?? 0.0;
    final usageCount = template['usage_count'] as int? ?? 0;
    final communityRating =
        (template['community_rating'] as num?)?.toDouble() ?? 0.0;
    final industryTags =
        (template['industry_tags'] as List?)?.cast<String>() ?? [];
    final sampleQuestions =
        (template['sample_questions'] as List?)?.cast<String>() ?? [];
    final targetingParams =
        template['targeting_parameters'] as Map<String, dynamic>? ?? {};

    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
          ),
          child: Column(
            children: [
              // Handle Bar
              Container(
                margin: EdgeInsets.symmetric(vertical: 1.h),
                width: 12.w,
                height: 0.5.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.all(4.w),
                  children: [
                    // Template Name
                    Text(
                      name,
                      style: TextStyle(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),

                    // Industry Tags
                    Wrap(
                      spacing: 2.w,
                      runSpacing: 1.h,
                      children: industryTags.map((tag) {
                        return Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 3.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.accentLight.withAlpha(26),
                            borderRadius: BorderRadius.circular(8.0),
                          ),
                          child: Text(
                            tag.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: AppTheme.accentLight,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 2.h),

                    // Description
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: 2.h),

                    // Performance Metrics
                    _buildMetricsRow([
                      _MetricData(
                        'Success Rate',
                        '$successRate%',
                        Icons.trending_up,
                        Colors.green,
                      ),
                      _MetricData(
                        'Avg ROI',
                        '${avgRoi.toStringAsFixed(1)}%',
                        Icons.attach_money,
                        Colors.blue,
                      ),
                      _MetricData(
                        'Engagement',
                        '${avgEngagement.toStringAsFixed(1)}%',
                        Icons.favorite,
                        Colors.red,
                      ),
                    ]),
                    SizedBox(height: 2.h),

                    // Community Stats
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatItem(
                          Icons.people,
                          '$usageCount uses',
                          Colors.grey,
                        ),
                        _buildStatItem(
                          Icons.star,
                          '${communityRating.toStringAsFixed(1)}/5.0',
                          Colors.amber,
                        ),
                      ],
                    ),
                    SizedBox(height: 3.h),

                    // Sample Questions
                    if (sampleQuestions.isNotEmpty) ...[
                      Text(
                        'Sample Questions',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      ...sampleQuestions.map((question) {
                        return Padding(
                          padding: EdgeInsets.only(bottom: 1.h),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.check_circle,
                                size: 4.w,
                                color: AppTheme.accentLight,
                              ),
                              SizedBox(width: 2.w),
                              Expanded(
                                child: Text(
                                  question,
                                  style: TextStyle(fontSize: 13.sp),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      SizedBox(height: 2.h),
                    ],

                    // Targeting Parameters
                    if (targetingParams.isNotEmpty) ...[
                      Text(
                        'Targeting Parameters',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Container(
                        padding: EdgeInsets.all(3.w),
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildTargetingItem(
                              'Age Range',
                              '${targetingParams['age_min'] ?? 18}-${targetingParams['age_max'] ?? 65}',
                            ),
                            _buildTargetingItem(
                              'Target Zones',
                              (targetingParams['zones'] as List?)?.join(', ') ??
                                  'All zones',
                            ),
                            _buildTargetingItem(
                              'Estimated Reach',
                              '${targetingParams['estimated_reach'] ?? 'N/A'}',
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 3.h),
                    ],

                    // Expected Results
                    Text(
                      'Expected Results',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Container(
                      padding: EdgeInsets.all(3.w),
                      decoration: BoxDecoration(
                        color: Colors.blue[50],
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        children: [
                          _buildResultItem(
                            Icons.visibility,
                            'Engagement Rate',
                            '${avgEngagement.toStringAsFixed(1)}%',
                          ),
                          _buildResultItem(
                            Icons.trending_up,
                            'Expected ROI',
                            '${avgRoi.toStringAsFixed(1)}%',
                          ),
                          _buildResultItem(
                            Icons.people,
                            'Projected Reach',
                            '${targetingParams['estimated_reach'] ?? 'N/A'}',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Apply Button
              Container(
                padding: EdgeInsets.all(4.w),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withAlpha(13),
                      blurRadius: 10.0,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.accentLight,
                    padding: EdgeInsets.symmetric(vertical: 1.8.h),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.rocket_launch, size: 5.w, color: Colors.white),
                      SizedBox(width: 2.w),
                      Text(
                        'Apply Template',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricsRow(List<_MetricData> metrics) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: metrics.map((metric) {
        return Column(
          children: [
            Icon(metric.icon, size: 8.w, color: metric.color),
            SizedBox(height: 0.5.h),
            Text(
              metric.value,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: metric.color,
              ),
            ),
            Text(
              metric.label,
              style: TextStyle(fontSize: 11.sp, color: Colors.grey),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildStatItem(IconData icon, String label, Color color) {
    return Row(
      children: [
        Icon(icon, size: 5.w, color: color),
        SizedBox(width: 2.w),
        Text(
          label,
          style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }

  Widget _buildTargetingItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 13.sp, color: Colors.grey[700]),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildResultItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        children: [
          Icon(icon, size: 5.w, color: Colors.blue),
          SizedBox(width: 3.w),
          Expanded(
            child: Text(label, style: TextStyle(fontSize: 13.sp)),
          ),
          Text(
            value,
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

class _MetricData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  _MetricData(this.label, this.value, this.icon, this.color);
}
