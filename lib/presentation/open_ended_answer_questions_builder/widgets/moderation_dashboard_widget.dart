import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/mcq_service.dart';

class ModerationDashboardWidget extends StatefulWidget {
  final String? electionId;

  const ModerationDashboardWidget({super.key, this.electionId});

  @override
  State<ModerationDashboardWidget> createState() =>
      _ModerationDashboardWidgetState();
}

class _ModerationDashboardWidgetState extends State<ModerationDashboardWidget> {
  final MCQService _mcqService = MCQService.instance;
  List<Map<String, dynamic>> _flaggedResponses = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadFlaggedResponses();
  }

  Future<void> _loadFlaggedResponses() async {
    if (widget.electionId == null) return;

    setState(() => _isLoading = true);
    try {
      final responses = await _mcqService.getFreeTextAnswers(
        electionId: widget.electionId!,
        limit: 100,
      );

      setState(() {
        _flaggedResponses = responses
            .where((r) => r['moderation_flag'] == true)
            .toList();
      });
    } catch (e) {
      debugPrint('Load flagged responses error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.electionId == null) {
      return Center(
        child: Text(
          'Please select an election first',
          style: TextStyle(fontSize: 13.sp, color: Colors.grey),
        ),
      );
    }

    return Column(
      children: [
        _buildModerationHeader(),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _flaggedResponses.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle_outline,
                        size: 15.w,
                        color: Colors.green,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No flagged responses',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.green,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'All responses passed content moderation',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _flaggedResponses.length,
                  itemBuilder: (context, index) {
                    return _buildFlaggedResponseCard(_flaggedResponses[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildModerationHeader() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        border: Border(bottom: BorderSide(color: Colors.red.shade200)),
      ),
      child: Row(
        children: [
          Icon(Icons.flag, color: Colors.red, size: 6.w),
          SizedBox(width: 2.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Content Moderation',
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.red.shade900,
                  ),
                ),
                Text(
                  '${_flaggedResponses.length} responses require review',
                  style: TextStyle(fontSize: 11.sp, color: Colors.red.shade700),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFlaggedResponseCard(Map<String, dynamic> response) {
    final answerText = response['answer_text'] ?? '';
    final moderationReason =
        response['moderation_reason'] ?? 'No reason provided';
    final createdAt = response['created_at'] ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.red.shade200),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning, size: 4.w, color: Colors.red),
                      SizedBox(width: 1.w),
                      Text(
                        'Flagged',
                        style: TextStyle(
                          fontSize: 10.sp,
                          color: Colors.red,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Spacer(),
                Text(
                  createdAt,
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Text(
                answerText,
                style: TextStyle(fontSize: 12.sp),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Reason: $moderationReason',
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.red.shade700,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Approve response
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Response approved')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                    child: Text('Approve'),
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      // Remove response
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Response removed')),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                    ),
                    child: Text('Remove'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
