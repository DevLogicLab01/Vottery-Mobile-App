import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/claude_carousel_coach_service.dart';

/// Real-Time Claude Coaching API Hub
/// Streaming Claude API integration with conversation history and action item automation
class RealTimeClaudeCoachingApiHub extends StatefulWidget {
  const RealTimeClaudeCoachingApiHub({super.key});

  @override
  State<RealTimeClaudeCoachingApiHub> createState() =>
      _RealTimeClaudeCoachingApiHubState();
}

class _RealTimeClaudeCoachingApiHubState
    extends State<RealTimeClaudeCoachingApiHub> {
  final ClaudeCarouselCoachService _coachService =
      ClaudeCarouselCoachService.instance;
  final TextEditingController _questionController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _conversationHistory = [];
  List<Map<String, dynamic>> _actionItems = [];
  String _streamingResponse = '';
  bool _isStreaming = false;
  bool _isLoadingHistory = true;
  String _connectionStatus = 'Connected';
  int _responseLatency = 0;

  @override
  void initState() {
    super.initState();
    _loadConversationHistory();
    _loadActionItems();
  }

  Future<void> _loadConversationHistory() async {
    setState(() => _isLoadingHistory = true);
    final history = await _coachService.getConversationHistory(limit: 10);
    setState(() {
      _conversationHistory = history;
      _isLoadingHistory = false;
    });
  }

  Future<void> _loadActionItems() async {
    final items = await _coachService.getActionItems();
    setState(() => _actionItems = items);
  }

  void _sendQuestion() async {
    final question = _questionController.text.trim();
    if (question.isEmpty || _isStreaming) return;

    setState(() {
      _isStreaming = true;
      _streamingResponse = '';
      _connectionStatus = 'Streaming...';
    });

    _questionController.clear();

    // Add user message to UI
    setState(() {
      _conversationHistory.insert(0, {
        'question': question,
        'claude_response': '',
        'asked_at': DateTime.now().toIso8601String(),
      });
    });

    final startTime = DateTime.now();

    try {
      await for (final chunk in _coachService.streamCoachResponse(
        question: question,
        conversationHistory: _conversationHistory.skip(1).take(5).toList(),
      )) {
        setState(() {
          _streamingResponse = chunk;
          _conversationHistory[0]['claude_response'] = chunk;
        });

        // Auto-scroll to bottom
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      }

      final endTime = DateTime.now();
      setState(() {
        _responseLatency = endTime.difference(startTime).inMilliseconds;
        _connectionStatus = 'Connected';
      });

      // Reload action items after streaming completes
      await _loadActionItems();
    } catch (e) {
      setState(() {
        _connectionStatus = 'Error';
        _conversationHistory[0]['claude_response'] =
            'Error: Unable to get response. Please try again.';
      });
    } finally {
      setState(() {
        _isStreaming = false;
        _streamingResponse = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Claude Coaching Hub'),
        backgroundColor: Colors.purple.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => _showActionItemsDialog(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildStreamingStatusHeader(),
          Expanded(
            child: _isLoadingHistory
                ? const Center(child: CircularProgressIndicator())
                : _buildConversationInterface(),
          ),
          _buildInputField(),
        ],
      ),
    );
  }

  Widget _buildStreamingStatusHeader() {
    Color statusColor;
    IconData statusIcon;

    switch (_connectionStatus) {
      case 'Streaming...':
        statusColor = Colors.blue;
        statusIcon = Icons.sync;
        break;
      case 'Error':
        statusColor = Colors.red;
        statusIcon = Icons.error;
        break;
      default:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(26),
        border: Border(bottom: BorderSide(color: statusColor.withAlpha(77))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 16.0),
              SizedBox(width: 1.w),
              Text(
                _connectionStatus,
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ],
          ),
          if (_responseLatency > 0)
            Row(
              children: [
                Icon(Icons.speed, color: Colors.grey.shade600, size: 16.0),
                SizedBox(width: 1.w),
                Text(
                  '${_responseLatency}ms',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          Row(
            children: [
              Icon(Icons.assignment, color: Colors.purple, size: 16.0),
              SizedBox(width: 1.w),
              Text(
                '${_actionItems.length} Actions',
                style: TextStyle(fontSize: 12.sp, color: Colors.purple),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConversationInterface() {
    if (_conversationHistory.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.psychology, size: 64.0, color: Colors.purple.shade200),
            SizedBox(height: 2.h),
            Text(
              'Ask your carousel coach anything!',
              style: TextStyle(fontSize: 16.sp, color: Colors.grey.shade600),
            ),
            SizedBox(height: 1.h),
            Text(
              'Get personalized recommendations',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: EdgeInsets.all(3.w),
      itemCount: _conversationHistory.length,
      itemBuilder: (context, index) {
        final message = _conversationHistory[index];
        return _buildMessageBubbles(message);
      },
    );
  }

  Widget _buildMessageBubbles(Map<String, dynamic> message) {
    final question = message['question'] as String? ?? '';
    final response = message['claude_response'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // User question
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            margin: EdgeInsets.only(bottom: 1.h, left: 15.w),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Text(
              question,
              style: TextStyle(fontSize: 13.sp, color: Colors.blue.shade900),
            ),
          ),
        ),

        // Coach response
        if (response.isNotEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.only(bottom: 2.h, right: 15.w),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.purple.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 12.0,
                        backgroundColor: Colors.purple.shade700,
                        child: const Icon(
                          Icons.psychology,
                          size: 16.0,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'Coach',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple.shade700,
                        ),
                      ),
                      if (_isStreaming &&
                          _conversationHistory.indexOf(message) == 0)
                        Padding(
                          padding: EdgeInsets.only(left: 2.w),
                          child: SizedBox(
                            width: 12.0,
                            height: 12.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.purple.shade700,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    response,
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.purple.shade900,
                    ),
                  ),
                ],
              ),
            ),
          ),

        // Typing indicator for streaming
        if (_isStreaming &&
            _conversationHistory.indexOf(message) == 0 &&
            response.isEmpty)
          Align(
            alignment: Alignment.centerLeft,
            child: Container(
              margin: EdgeInsets.only(bottom: 2.h, right: 15.w),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Coach is thinking',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontStyle: FontStyle.italic,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  SizedBox(
                    width: 16.0,
                    height: 16.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.purple.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildInputField() {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            blurRadius: 4.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _questionController,
              decoration: InputDecoration(
                hintText: 'Ask anything...',
                hintStyle: TextStyle(fontSize: 13.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide(color: Colors.purple.shade200),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide(color: Colors.purple.shade200),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24.0),
                  borderSide: BorderSide(
                    color: Colors.purple.shade700,
                    width: 2.0,
                  ),
                ),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 4.w,
                  vertical: 1.5.h,
                ),
              ),
              maxLines: null,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => _sendQuestion(),
              enabled: !_isStreaming,
            ),
          ),
          SizedBox(width: 2.w),
          FloatingActionButton(
            onPressed: _isStreaming ? null : _sendQuestion,
            backgroundColor: _isStreaming
                ? Colors.grey
                : Colors.purple.shade700,
            mini: true,
            child: _isStreaming
                ? SizedBox(
                    width: 20.0,
                    height: 20.0,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Icon(Icons.send, color: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showActionItemsDialog() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.purple.shade50,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(20.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Action Items',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.purple.shade700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _actionItems.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.assignment_turned_in,
                            size: 64.0,
                            color: Colors.grey.shade300,
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            'No action items yet',
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: EdgeInsets.all(3.w),
                      itemCount: _actionItems.length,
                      itemBuilder: (context, index) {
                        final item = _actionItems[index];
                        return _buildActionItemCard(item);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItemCard(Map<String, dynamic> item) {
    final description = item['action_description'] as String? ?? '';
    final expectedOutcome = item['expected_outcome'] as String? ?? '';
    final priority = item['priority'] as String? ?? 'medium';
    final status = item['status'] as String? ?? 'pending';
    final actionId = item['action_id'] as String;

    Color priorityColor;
    switch (priority) {
      case 'high':
        priorityColor = Colors.red;
        break;
      case 'medium':
        priorityColor = Colors.orange;
        break;
      default:
        priorityColor = Colors.blue;
    }

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
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
                    color: priorityColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: Text(
                    priority.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: priorityColor,
                    ),
                  ),
                ),
                const Spacer(),
                if (status == 'completed')
                  Icon(Icons.check_circle, color: Colors.green, size: 20.0),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              description,
              style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w600),
            ),
            if (expectedOutcome.isNotEmpty) ...[
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(
                    Icons.trending_up,
                    size: 16.0,
                    color: Colors.green.shade600,
                  ),
                  SizedBox(width: 1.w),
                  Expanded(
                    child: Text(
                      expectedOutcome,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.green.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ],
            if (status != 'completed') ...[
              SizedBox(height: 1.h),
              ElevatedButton(
                onPressed: () async {
                  await _coachService.updateActionItemStatus(
                    actionId,
                    'completed',
                  );
                  await _loadActionItems();
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Action item marked as completed'),
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                child: const Text('Mark Complete'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _questionController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
