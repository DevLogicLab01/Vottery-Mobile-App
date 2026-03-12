import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class SearchResultsWidget extends StatelessWidget {
  final Map<String, dynamic> results;
  final String domain;

  const SearchResultsWidget({
    super.key,
    required this.results,
    required this.domain,
  });

  @override
  Widget build(BuildContext context) {
    final allResults = results['results'] as List? ?? [];
    final filteredResults = domain == 'all'
        ? allResults
        : allResults.where((r) => r['domain'] == domain).toList();

    if (filteredResults.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 15.w, color: Colors.grey),
            SizedBox(height: 2.h),
            Text(
              'No ${domain == 'all' ? '' : domain} results found',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(2.w),
      itemCount: filteredResults.length,
      itemBuilder: (context, index) {
        final result = filteredResults[index];
        return _buildResultCard(context, result);
      },
    );
  }

  Widget _buildResultCard(BuildContext context, Map<String, dynamic> result) {
    final domain = result['domain'] as String? ?? 'unknown';
    final confidenceScore = result['confidence_score'] as int? ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => _navigateToDetail(context, result),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(3.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with domain badge and confidence score
              Row(
                children: [
                  _buildDomainBadge(context, domain),
                  const Spacer(),
                  if (confidenceScore > 0)
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 2.w,
                        vertical: 0.5.h,
                      ),
                      decoration: BoxDecoration(
                        color: _getConfidenceColor(
                          confidenceScore,
                        ).withAlpha(51),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.psychology,
                            size: 12.sp,
                            color: _getConfidenceColor(confidenceScore),
                          ),
                          SizedBox(width: 1.w),
                          Text(
                            '$confidenceScore%',
                            style: TextStyle(
                              fontSize: 11.sp,
                              fontWeight: FontWeight.bold,
                              color: _getConfidenceColor(confidenceScore),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
              SizedBox(height: 1.h),

              // Title/Name
              Text(
                result['title'] ??
                    result['name'] ??
                    result['content'] ??
                    'Untitled',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.5.h),

              // Description/Content
              if (result['description'] != null || result['content'] != null)
                Text(
                  result['description'] ?? result['content'] ?? '',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),

              // Metadata
              SizedBox(height: 1.h),
              _buildMetadata(context, result, domain),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDomainBadge(BuildContext context, String domain) {
    final icons = {
      'posts': Icons.article,
      'users': Icons.person,
      'groups': Icons.group,
      'elections': Icons.how_to_vote,
    };

    final colors = {
      'posts': Colors.blue,
      'users': Colors.green,
      'groups': Colors.orange,
      'elections': Colors.purple,
    };

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: (colors[domain] ?? Colors.grey).withAlpha(51),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icons[domain] ?? Icons.help_outline,
            size: 12.sp,
            color: colors[domain] ?? Colors.grey,
          ),
          SizedBox(width: 1.w),
          Text(
            domain.toUpperCase(),
            style: TextStyle(
              fontSize: 10.sp,
              fontWeight: FontWeight.bold,
              color: colors[domain] ?? Colors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetadata(
    BuildContext context,
    Map<String, dynamic> result,
    String domain,
  ) {
    return Row(
      children: [
        if (result['created_at'] != null) ...[
          Icon(Icons.access_time, size: 10.sp, color: Colors.grey),
          SizedBox(width: 1.w),
          Text(
            _formatDate(result['created_at']),
            style: TextStyle(fontSize: 10.sp, color: Colors.grey),
          ),
        ],
        if (result['author'] != null || result['creator'] != null) ...[
          SizedBox(width: 3.w),
          Icon(Icons.person_outline, size: 10.sp, color: Colors.grey),
          SizedBox(width: 1.w),
          Text(
            result['author'] ?? result['creator'] ?? '',
            style: TextStyle(fontSize: 10.sp, color: Colors.grey),
          ),
        ],
      ],
    );
  }

  Color _getConfidenceColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  String _formatDate(dynamic date) {
    try {
      final dateTime = DateTime.parse(date.toString());
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inDays > 7) {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inMinutes}m ago';
      }
    } catch (e) {
      return '';
    }
  }

  void _navigateToDetail(BuildContext context, Map<String, dynamic> result) {
    // Navigate to appropriate detail screen based on domain
    final domain = result['domain'] as String?;
    // TODO: Implement navigation logic
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Navigate to $domain detail')));
  }
}
