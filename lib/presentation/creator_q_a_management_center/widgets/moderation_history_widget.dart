import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/audience_questions_service.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/shimmer_skeleton_loader.dart';

class ModerationHistoryWidget extends StatefulWidget {
  final String electionId;

  const ModerationHistoryWidget({super.key, required this.electionId});

  @override
  State<ModerationHistoryWidget> createState() =>
      _ModerationHistoryWidgetState();
}

class _ModerationHistoryWidgetState extends State<ModerationHistoryWidget> {
  final AudienceQuestionsService _questionsService =
      AudienceQuestionsService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _moderationHistory = [];
  String _filterStatus = 'all';

  @override
  void initState() {
    super.initState();
    _loadModerationHistory();
  }

  Future<void> _loadModerationHistory() async {
    setState(() => _isLoading = true);

    final history = await _questionsService.getQuestions(
      electionId: widget.electionId,
      statusFilter: _filterStatus == 'all' ? null : _filterStatus,
    );

    setState(() {
      _moderationHistory = history;
      _isLoading = false;
    });
  }

  void _showModerationDetails(Map<String, dynamic> record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Moderation Details'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Question', record['question_text'] ?? 'N/A'),
              SizedBox(height: 1.h),
              _buildDetailRow(
                'Action',
                (record['moderation_status'] ?? 'N/A').toUpperCase(),
              ),
              SizedBox(height: 1.h),
              _buildDetailRow(
                'Moderator',
                record['moderator_name'] ?? 'Unknown',
              ),
              SizedBox(height: 1.h),
              _buildDetailRow('Date', _formatTimestamp(record['moderated_at'])),
              if (record['moderator_notes'] != null &&
                  record['moderator_notes'].toString().isNotEmpty) ...[
                SizedBox(height: 1.h),
                const Divider(),
                SizedBox(height: 1.h),
                Text(
                  'Moderator Notes:',
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  record['moderator_notes'],
                  style: TextStyle(fontSize: 13.sp),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 30.w,
          child: Text(
            '$label:',
            style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.bold),
          ),
        ),
        Expanded(
          child: Text(value, style: TextStyle(fontSize: 13.sp)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          color: Colors.grey[100],
          child: Row(
            children: [
              Text(
                'Filter:',
                style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Approved', 'approved'),
                      _buildFilterChip('Rejected', 'rejected'),
                      _buildFilterChip('Flagged', 'flagged'),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoading
              ? ListView.builder(
                  itemCount: 5,
                  itemBuilder: (context, index) => Padding(
                    padding: EdgeInsets.all(2.w),
                    child: ShimmerSkeletonLoader(
                      child: Container(
                        height: 12.h,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                      ),
                    ),
                  ),
                )
              : _moderationHistory.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.history, size: 64, color: Colors.grey[400]),
                      SizedBox(height: 2.h),
                      Text(
                        'No moderation history',
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadModerationHistory,
                  child: ListView.builder(
                    itemCount: _moderationHistory.length,
                    itemBuilder: (context, index) {
                      final record = _moderationHistory[index];
                      final status = record['moderation_status'] ?? '';

                      return Card(
                        margin: EdgeInsets.symmetric(
                          horizontal: 3.w,
                          vertical: 1.h,
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: _getStatusColor(
                              status,
                            ).withAlpha(26),
                            child: Icon(
                              _getStatusIcon(status),
                              color: _getStatusColor(status),
                            ),
                          ),
                          title: Text(
                            record['question_text'] ?? '',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 0.5.h),
                              Row(
                                children: [
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 2.w,
                                      vertical: 0.5.h,
                                    ),
                                    decoration: BoxDecoration(
                                      color: _getStatusColor(
                                        status,
                                      ).withAlpha(26),
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    child: Text(
                                      status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11.sp,
                                        fontWeight: FontWeight.bold,
                                        color: _getStatusColor(status),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 2.w),
                                  Icon(
                                    Icons.access_time,
                                    size: 14,
                                    color: Colors.grey[600],
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    _formatTimestamp(record['moderated_at']),
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.info_outline),
                            onPressed: () => _showModerationDetails(record),
                          ),
                        ),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filterStatus == value;

    return Padding(
      padding: EdgeInsets.only(right: 2.w),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          setState(() {
            _filterStatus = value;
          });
          _loadModerationHistory();
        },
        selectedColor: AppTheme.primaryLight.withAlpha(51),
        checkmarkColor: AppTheme.primaryLight,
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'flagged':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      case 'flagged':
        return Icons.flag;
      default:
        return Icons.help_outline;
    }
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      final DateTime dateTime = DateTime.parse(timestamp.toString());
      final Duration difference = DateTime.now().difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
