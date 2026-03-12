import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class FeatureToggleCardWidget extends StatelessWidget {
  final Map<String, dynamic> feature;
  final Function({
    required String featureId,
    required String featureName,
    required bool currentStatus,
    List<dynamic>? dependencies,
  })
  onToggle;

  const FeatureToggleCardWidget({
    super.key,
    required this.feature,
    required this.onToggle,
  });

  String _getFeatureDisplayName() {
    return (feature['feature_name'] as String)
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _escapeSpecialChars(String text) {
    return text.replaceAll('\$', '\\\$');
  }

  @override
  Widget build(BuildContext context) {
    final isEnabled = feature['is_enabled'] as bool;
    final featureName = feature['feature_name'] as String;
    final description = feature['description'] as String?;
    final dependencies = feature['dependencies'] as List<dynamic>?;
    final usageCount = feature['usage_count'] as int? ?? 0;
    final rolloutPercentage = feature['rollout_percentage'] as int? ?? 100;

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            _getFeatureDisplayName(),
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 2.w,
                            vertical: 0.5.h,
                          ),
                          decoration: BoxDecoration(
                            color: isEnabled
                                ? Colors.green.shade100
                                : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          child: Text(
                            isEnabled ? 'Enabled' : 'Disabled',
                            style: TextStyle(
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              color: isEnabled
                                  ? Colors.green.shade700
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (description != null) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        description,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 3.w),
              Switch(
                value: isEnabled,
                onChanged: (_) => onToggle(
                  featureId: feature['id'] as String,
                  featureName: featureName,
                  currentStatus: isEnabled,
                  dependencies: dependencies,
                ),
                activeThumbColor: Colors.green,
              ),
            ],
          ),
          if (dependencies != null && dependencies.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.link, size: 14.sp, color: Colors.blue.shade700),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'Depends on: ${dependencies.join(", ").replaceAll("_", " ")}',
                      style: TextStyle(
                        fontSize: 10.sp,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (usageCount > 0 || rolloutPercentage < 100) ...[
            SizedBox(height: 1.h),
            Row(
              children: [
                if (usageCount > 0) ...[
                  Icon(Icons.people, size: 12.sp, color: Colors.grey[600]),
                  SizedBox(width: 1.w),
                  Text(
                    '$usageCount users',
                    style: TextStyle(fontSize: 10.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(width: 3.w),
                ],
                if (rolloutPercentage < 100) ...[
                  Icon(Icons.pie_chart, size: 12.sp, color: Colors.orange),
                  SizedBox(width: 1.w),
                  Text(
                    '$rolloutPercentage% rollout',
                    style: TextStyle(fontSize: 10.sp, color: Colors.orange),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
