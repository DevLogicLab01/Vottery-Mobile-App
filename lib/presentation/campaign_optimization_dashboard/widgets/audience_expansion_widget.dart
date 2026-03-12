import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AudienceExpansionWidget extends StatelessWidget {
  final List<Map<String, dynamic>> suggestions;
  final Function(String) onApply;

  const AudienceExpansionWidget({
    super.key,
    required this.suggestions,
    required this.onApply,
  });

  @override
  Widget build(BuildContext context) {
    if (suggestions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.people_outline, size: 60.sp, color: Colors.blue),
            SizedBox(height: 2.h),
            Text(
              'No Audience Suggestions',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 1.h),
            Text(
              'Audience expansion opportunities will appear here',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(3.w),
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final suggestion = suggestions[index];
        return _buildSuggestionCard(context, suggestion);
      },
    );
  }

  Widget _buildSuggestionCard(
    BuildContext context,
    Map<String, dynamic> suggestion,
  ) {
    final suggestedSegment = suggestion['suggested_segment'] ?? {};
    final similarityScore = (suggestion['similarity_score'] ?? 0.0).toDouble();
    final estimatedReach = suggestion['estimated_reach'] ?? 0;
    final estimatedCpm = (suggestion['estimated_cpm'] ?? 0.0).toDouble();
    final lookalikeType = suggestion['lookalike_type'] ?? 'hybrid';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: Colors.blue.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(Icons.group_add, color: Colors.blue, size: 20.sp),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Lookalike Audience',
                        style: TextStyle(
                          fontSize: 15.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        lookalikeType.toUpperCase(),
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.green.withAlpha(26),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    '${similarityScore.toStringAsFixed(0)}% Match',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.green,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: _buildMetricBox(
                    'Estimated Reach',
                    _formatNumber(estimatedReach),
                    Icons.visibility,
                    Colors.purple,
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: _buildMetricBox(
                    'Est. CPM',
                    '\$${estimatedCpm.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Suggested Segment:',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: [
                if (suggestedSegment['age_range'] != null)
                  _buildChip(
                    'Age: ${suggestedSegment['age_range']}',
                    Colors.blue,
                  ),
                if (suggestedSegment['gender'] != null)
                  _buildChip(
                    'Gender: ${suggestedSegment['gender']}',
                    Colors.pink,
                  ),
                if (suggestedSegment['location'] != null)
                  _buildChip(
                    'Location: ${suggestedSegment['location']}',
                    Colors.green,
                  ),
                if (suggestedSegment['interests'] != null)
                  _buildChip(
                    'Interests: ${suggestedSegment['interests']}',
                    Colors.purple,
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => onApply(suggestion['id']),
                icon: const Icon(Icons.add_circle_outline, color: Colors.white),
                label: Text(
                  'Test This Audience',
                  style: TextStyle(fontSize: 14.sp, color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricBox(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 18.sp),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildChip(String label, Color color) {
    return Chip(
      label: Text(
        label,
        style: TextStyle(fontSize: 11.sp, color: color),
      ),
      backgroundColor: color.withAlpha(26),
      side: BorderSide.none,
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
