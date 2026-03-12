import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../services/sms_rate_limiter_service.dart';
import '../../services/openai_sms_optimizer_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';

/// SMS Rate Limiting & Queue Control Center
class SmsRateLimitingQueueControlCenter extends StatefulWidget {
  const SmsRateLimitingQueueControlCenter({super.key});

  @override
  State<SmsRateLimitingQueueControlCenter> createState() =>
      _SmsRateLimitingQueueControlCenterState();
}

class _SmsRateLimitingQueueControlCenterState
    extends State<SmsRateLimitingQueueControlCenter>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _rateLimiter = SMSRateLimiterService.instance;
  final _queueManager = SMSQueueManagerService.instance;
  final _optimizer = OpenAISMSOptimizerService.instance;

  Map<String, dynamic>? _userRateLimit;
  Map<String, dynamic> _queueStats = {};
  List<Map<String, dynamic>> _queueMessages = [];
  Map<String, dynamic> _optimizationAnalytics = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _rateLimiter.getUserRateLimit(),
        _queueManager.getQueueStats(),
        _queueManager.getQueueMessages(limit: 50),
        _optimizer.getOptimizationAnalytics(),
      ]);

      if (mounted) {
        setState(() {
          _userRateLimit = results[0] as Map<String, dynamic>?;
          _queueStats = results[1] as Map<String, dynamic>;
          _queueMessages = results[2] as List<Map<String, dynamic>>;
          _optimizationAnalytics = results[3] as Map<String, dynamic>;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'SMS Rate Limiting & Queue',
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'SMS Rate Limiting & Queue',
          actions: [
            IconButton(icon: const Icon(Icons.refresh), onPressed: _loadData),
          ],
        ),
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.all(2.w),
              color: Colors.purple.shade50,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStatCard(
                          'Queue',
                          _queueStats['queue_depth']?.toString() ?? '0',
                          Icons.queue,
                          Colors.purple,
                        ),
                        _buildStatCard(
                          'Sent',
                          _userRateLimit?['messages_sent']?.toString() ?? '0',
                          Icons.send,
                          Colors.green,
                        ),
                        _buildStatCard(
                          'Limit',
                          _userRateLimit?['limit_amount']?.toString() ?? '0',
                          Icons.speed,
                          Colors.orange,
                        ),
                      ],
                    ),
            ),
            TabBar(
              controller: _tabController,
              labelColor: Colors.purple,
              tabs: const [
                Tab(text: 'Queue'),
                Tab(text: 'Limits'),
                Tab(text: 'AI'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildQueueTab(),
                  _buildRateLimitsTab(),
                  _buildOptimizationTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Card(
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Column(
          children: [
            Icon(icon, color: color, size: 8.w),
            SizedBox(height: 1.h),
            Text(
              value,
              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
            ),
            Text(label, style: TextStyle(fontSize: 10.sp)),
          ],
        ),
      ),
    );
  }

  Widget _buildQueueTab() {
    return ListView.builder(
      padding: EdgeInsets.all(2.w),
      itemCount: _queueMessages.length,
      itemBuilder: (context, index) {
        final message = _queueMessages[index];
        return Card(
          child: ListTile(
            leading: Icon(
              message['priority'] == 'critical'
                  ? Icons.priority_high
                  : Icons.message,
              color: message['priority'] == 'critical'
                  ? Colors.red
                  : Colors.blue,
            ),
            title: Text(
              message['message_body'] ?? 'No message',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text('Status: ${message['status']}'),
          ),
        );
      },
    );
  }

  Widget _buildRateLimitsTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Card(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Rate Limit',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Tier: ${_userRateLimit?['tier']?.toString().toUpperCase() ?? 'FREE'}',
                  ),
                  SizedBox(height: 1.h),
                  LinearProgressIndicator(
                    value: _userRateLimit != null
                        ? (_userRateLimit!['messages_sent'] /
                              _userRateLimit!['limit_amount'])
                        : 0,
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    '${_userRateLimit?['messages_sent'] ?? 0} / ${_userRateLimit?['limit_amount'] ?? 0} messages',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptimizationTab() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'OpenAI SMS Optimization',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 2.h),
          Card(
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                children: [
                  _buildAnalyticRow(
                    'Total Optimizations',
                    _optimizationAnalytics['total_optimizations']?.toString() ??
                        '0',
                  ),
                  _buildAnalyticRow(
                    'Avg Character Reduction',
                    _optimizationAnalytics['avg_character_reduction']
                            ?.toString() ??
                        '0',
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          ElevatedButton.icon(
            onPressed: _testOptimization,
            icon: const Icon(Icons.auto_fix_high),
            label: const Text('Test SMS Optimization'),
          ),
        ],
      ),
    );
  }

  Widget _buildAnalyticRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 1.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _testOptimization() async {
    final messageController = TextEditingController(
      text:
          'Hello! We are excited to announce our new product launch this weekend!',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Test SMS Optimization'),
        content: TextField(
          controller: messageController,
          decoration: const InputDecoration(labelText: 'Original Message'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final result = await _optimizer.optimizeLength(
                messageController.text,
              );
              if (mounted) {
                Navigator.pop(context);
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Result'),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Original: ${result.originalMessage}'),
                        SizedBox(height: 2.h),
                        Text(
                          'Optimized: ${result.optimizedMessage}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 2.h),
                        Text('Saved: ${result.characterSavings ?? 0} chars'),
                      ],
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
            },
            child: const Text('Optimize'),
          ),
        ],
      ),
    );
  }
}