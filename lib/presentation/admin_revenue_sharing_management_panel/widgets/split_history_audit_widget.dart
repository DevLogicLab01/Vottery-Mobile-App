import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/revenue_share_service.dart';

class SplitHistoryAuditWidget extends StatefulWidget {
  const SplitHistoryAuditWidget({super.key});

  @override
  State<SplitHistoryAuditWidget> createState() =>
      _SplitHistoryAuditWidgetState();
}

class _SplitHistoryAuditWidgetState extends State<SplitHistoryAuditWidget> {
  final RevenueShareService _revenueService = RevenueShareService.instance;
  String? _selectedCountryCode;
  List<Map<String, dynamic>> _history = [];
  bool _isLoading = false;

  Future<void> _loadHistory(String countryCode) async {
    setState(() => _isLoading = true);

    final history = await _revenueService.getRevenueSplitHistory(
      countryCode: countryCode,
    );

    if (mounted) {
      setState(() {
        _history = history;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(4.w),
          child: Text(
            'Select a country to view split change history',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
        ),
        if (_isLoading)
          Expanded(child: Center(child: CircularProgressIndicator()))
        else if (_history.isEmpty)
          Expanded(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 48.sp, color: Colors.grey[400]),
                  SizedBox(height: 2.h),
                  Text(
                    'No history available',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          )
        else
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              itemCount: _history.length,
              itemBuilder: (context, index) {
                final entry = _history[index];
                return _buildHistoryCard(entry);
              },
            ),
          ),
      ],
    );
  }

  Widget _buildHistoryCard(Map<String, dynamic> entry) {
    final countryName = entry['country_name'] as String;
    final previousPlatform =
        (entry['previous_platform_percentage'] as num? ?? 0).toDouble();
    final previousCreator = (entry['previous_creator_percentage'] as num? ?? 0)
        .toDouble();
    final newPlatform = (entry['new_platform_percentage'] as num).toDouble();
    final newCreator = (entry['new_creator_percentage'] as num).toDouble();
    final updatedBy = entry['user_profiles']?['full_name'] ?? 'System';
    final createdAt = DateTime.parse(entry['created_at'] as String);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  countryName,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  _formatDate(createdAt),
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Previous Split',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${previousPlatform.toStringAsFixed(1)}% / ${previousCreator.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, size: 20.sp, color: Colors.grey[400]),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New Split',
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                      Text(
                        '${newPlatform.toStringAsFixed(1)}% / ${newCreator.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.person, size: 14.sp, color: Colors.grey[600]),
                SizedBox(width: 1.w),
                Text(
                  'Updated by: $updatedBy',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}
