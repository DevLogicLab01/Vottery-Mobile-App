import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class StrategicRecommendationsWidget extends StatelessWidget {
  final List<Map<String, dynamic>> recommendations;
  final VoidCallback onGenerate;
  final bool isGenerating;

  const StrategicRecommendationsWidget({
    super.key,
    required this.recommendations,
    required this.onGenerate,
    required this.isGenerating,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.lightbulb, color: Colors.amber),
                SizedBox(width: 2.w),
                Text(
                  'Strategic Recommendations',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                if (isGenerating)
                  SizedBox(
                    width: 5.w,
                    height: 5.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    icon: const Icon(Icons.refresh),
                    onPressed: onGenerate,
                    tooltip: 'Generate Recommendations',
                  ),
              ],
            ),
            SizedBox(height: 2.h),

            if (recommendations.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.tips_and_updates_outlined,
                      size: 10.w,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 1.h),
                    Text(
                      'No recommendations yet',
                      style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                    ),
                    SizedBox(height: 1.h),
                    ElevatedButton.icon(
                      onPressed: isGenerating ? null : onGenerate,
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate with AI'),
                    ),
                  ],
                ),
              )
            else
              ...recommendations.map((rec) {
                final type = rec['recommendation_type'] as String;
                final text = rec['recommendation_text'] as String;
                final confidence =
                    (rec['confidence_score'] as num?)?.toDouble() ?? 0.0;

                return Card(
                  margin: EdgeInsets.only(bottom: 2.h),
                  color: _getColorForType(type).withAlpha(26),
                  child: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              _getIconForType(type),
                              color: _getColorForType(type),
                              size: 5.w,
                            ),
                            SizedBox(width: 2.w),
                            Expanded(
                              child: Text(
                                _formatType(type),
                                style: TextStyle(
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.bold,
                                  color: _getColorForType(type),
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.3.h,
                              ),
                              decoration: BoxDecoration(
                                color: _getColorForType(type),
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              child: Text(
                                '${confidence.toStringAsFixed(0)}%',
                                style: TextStyle(
                                  fontSize: 10.sp,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 1.h),
                        Text(
                          text,
                          style: TextStyle(
                            fontSize: 12.sp,
                            color: Colors.grey[800],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'posting_time':
        return Icons.schedule;
      case 'target_demographics':
        return Icons.people;
      case 'engagement_tactics':
        return Icons.thumb_up;
      case 'content_strategy':
        return Icons.article;
      default:
        return Icons.lightbulb;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'posting_time':
        return Colors.blue;
      case 'target_demographics':
        return Colors.green;
      case 'engagement_tactics':
        return Colors.orange;
      case 'content_strategy':
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  String _formatType(String type) {
    return type
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) {
          return word[0].toUpperCase() + word.substring(1);
        })
        .join(' ');
  }
}
