import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';
import '../../../services/mcq_service.dart';

class TextResponseViewerWidget extends StatefulWidget {
  final String? electionId;

  const TextResponseViewerWidget({super.key, this.electionId});

  @override
  State<TextResponseViewerWidget> createState() =>
      _TextResponseViewerWidgetState();
}

class _TextResponseViewerWidgetState extends State<TextResponseViewerWidget> {
  final MCQService _mcqService = MCQService.instance;
  final TextEditingController _searchController = TextEditingController();

  List<Map<String, dynamic>> _responses = [];
  bool _isLoading = false;
  int _currentPage = 0;
  final int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _loadResponses();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadResponses() async {
    if (widget.electionId == null) return;

    setState(() => _isLoading = true);
    try {
      final responses = await _mcqService.getFreeTextAnswers(
        electionId: widget.electionId!,
        limit: _pageSize,
        offset: _currentPage * _pageSize,
      );
      setState(() => _responses = responses);
    } catch (e) {
      debugPrint('Load responses error: $e');
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
        _buildSearchBar(),
        Expanded(
          child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _responses.isEmpty
              ? Center(
                  child: Text(
                    'No responses yet',
                    style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: _responses.length,
                  itemBuilder: (context, index) {
                    return _buildResponseCard(_responses[index]);
                  },
                ),
        ),
        _buildPaginationControls(),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Search responses...',
          prefixIcon: Icon(Icons.search),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          contentPadding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        ),
        onChanged: (value) {
          // Implement search filtering
        },
      ),
    );
  }

  Widget _buildResponseCard(Map<String, dynamic> response) {
    final answerText = response['answer_text'] ?? '';
    final characterCount = response['character_count'] ?? 0;
    final sentiment = response['sentiment_label'] ?? 'neutral';
    final createdAt = response['created_at'] ?? '';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _buildSentimentBadge(sentiment),
                Spacer(),
                Text(
                  '$characterCount chars',
                  style: TextStyle(fontSize: 10.sp, color: Colors.grey),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              answerText,
              style: TextStyle(fontSize: 12.sp),
              maxLines: 5,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Text(
              createdAt,
              style: TextStyle(fontSize: 10.sp, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentimentBadge(String sentiment) {
    Color color;
    IconData icon;

    switch (sentiment.toLowerCase()) {
      case 'positive':
        color = Colors.green;
        icon = Icons.sentiment_satisfied;
        break;
      case 'negative':
        color = Colors.red;
        icon = Icons.sentiment_dissatisfied;
        break;
      default:
        color = Colors.grey;
        icon = Icons.sentiment_neutral;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(51),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 4.w, color: color),
          SizedBox(width: 1.w),
          Text(
            sentiment,
            style: TextStyle(
              fontSize: 10.sp,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 4,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _currentPage > 0
                ? () {
                    setState(() => _currentPage--);
                    _loadResponses();
                  }
                : null,
            icon: Icon(Icons.chevron_left, size: 5.w),
            label: Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentLight,
            ),
          ),
          Text(
            'Page ${_currentPage + 1}',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
          ElevatedButton.icon(
            onPressed: _responses.length == _pageSize
                ? () {
                    setState(() => _currentPage++);
                    _loadResponses();
                  }
                : null,
            icon: Icon(Icons.chevron_right, size: 5.w),
            label: Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentLight,
            ),
          ),
        ],
      ),
    );
  }
}
