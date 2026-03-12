import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/auth_service.dart';
import '../../services/claude_service.dart';
import '../../services/supabase_service.dart';
import './widgets/performance_metrics_widget.dart';
import './widgets/recommendation_card_widget.dart';
import './widgets/recommendation_history_widget.dart';

class ContextAwareRecommendationsOverlay extends StatefulWidget {
  final String screenContext;
  final Map<String, dynamic>? screenData;

  const ContextAwareRecommendationsOverlay({
    super.key,
    required this.screenContext,
    this.screenData,
  });

  @override
  State<ContextAwareRecommendationsOverlay> createState() =>
      _ContextAwareRecommendationsOverlayState();
}

class _ContextAwareRecommendationsOverlayState
    extends State<ContextAwareRecommendationsOverlay> {
  final ClaudeService _claude = ClaudeService.instance;
  final AuthService _auth = AuthService.instance;
  final _client = SupabaseService.instance.client;

  bool _isMinimized = false;
  bool _isLoading = false;
  Offset _position = const Offset(20, 100);
  List<Map<String, dynamic>> _recommendations = [];
  List<Map<String, dynamic>> _history = [];
  Map<String, dynamic>? _performanceMetrics;
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
    _loadHistory();
    _loadPerformanceMetrics();
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final recommendations = await _claude.getContextualRecommendations(
        screenContext: widget.screenContext,
        userData: widget.screenData ?? {},
      );

      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load recommendations error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadHistory() async {
    try {
      final response = await _client
          .from('recommendation_history')
          .select()
          .eq('user_id', _auth.currentUser!.id)
          .order('created_at', ascending: false)
          .limit(20);

      if (mounted) {
        setState(() => _history = List<Map<String, dynamic>>.from(response));
      }
    } catch (e) {
      debugPrint('Load history error: $e');
    }
  }

  Future<void> _loadPerformanceMetrics() async {
    try {
      final response = await _client.rpc(
        'get_recommendation_performance_metrics',
        params: {'user_id': _auth.currentUser!.id},
      );

      if (mounted) {
        setState(() => _performanceMetrics = response);
      }
    } catch (e) {
      debugPrint('Load performance metrics error: $e');
    }
  }

  Future<void> _approveRecommendation(
    Map<String, dynamic> recommendation,
  ) async {
    try {
      // Execute the recommendation action
      await _executeRecommendationAction(recommendation);

      // Log approval
      await _client.from('recommendation_history').insert({
        'user_id': _auth.currentUser!.id,
        'recommendation_id': recommendation['id'],
        'recommendation_type': recommendation['type'],
        'action': 'approved',
        'screen_context': widget.screenContext,
        'confidence_score': recommendation['confidence_score'],
        'created_at': DateTime.now().toIso8601String(),
      });

      // Reload recommendations and history
      await _loadRecommendations();
      await _loadHistory();
      await _loadPerformanceMetrics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ Recommendation applied successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Approve recommendation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to apply recommendation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _rejectRecommendation(
    Map<String, dynamic> recommendation,
  ) async {
    try {
      await _client.from('recommendation_history').insert({
        'user_id': _auth.currentUser!.id,
        'recommendation_id': recommendation['id'],
        'recommendation_type': recommendation['type'],
        'action': 'rejected',
        'screen_context': widget.screenContext,
        'confidence_score': recommendation['confidence_score'],
        'created_at': DateTime.now().toIso8601String(),
      });

      setState(() {
        _recommendations.remove(recommendation);
      });

      await _loadHistory();
    } catch (e) {
      debugPrint('Reject recommendation error: $e');
    }
  }

  Future<void> _executeRecommendationAction(
    Map<String, dynamic> recommendation,
  ) async {
    final actionType = recommendation['action_type'];
    final actionData = recommendation['action_data'];

    switch (actionType) {
      case 'budget_reallocation':
        await _client.rpc('reallocate_campaign_budget', params: actionData);
        break;
      case 'content_optimization':
        await _client.rpc('optimize_content', params: actionData);
        break;
      case 'fraud_prevention':
        await _client.rpc('apply_fraud_prevention', params: actionData);
        break;
      case 'revenue_optimization':
        await _client.rpc('optimize_revenue', params: actionData);
        break;
      case 'engagement_boost':
        await _client.rpc('boost_engagement', params: actionData);
        break;
      default:
        debugPrint('Unknown action type: $actionType');
    }
  }

  Future<void> _undoLastAction() async {
    try {
      final lastAction = _history.firstWhere(
        (h) => h['action'] == 'approved' && h['can_undo'] == true,
        orElse: () => {},
      );

      if (lastAction.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No recent actions to undo')),
          );
        }
        return;
      }

      await _client.rpc(
        'undo_recommendation_action',
        params: {'history_id': lastAction['id']},
      );

      await _loadHistory();
      await _loadPerformanceMetrics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Action undone successfully'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      debugPrint('Undo action error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _position.dx,
      top: _position.dy,
      child: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            _position = Offset(
              _position.dx + details.delta.dx,
              _position.dy + details.delta.dy,
            );
          });
        },
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16.0),
          child: Container(
            width: _isMinimized ? 60.w : 90.w,
            height: _isMinimized ? 8.h : 70.h,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.0),
              border: Border.all(color: Colors.blue.shade300, width: 2),
            ),
            child: _isMinimized ? _buildMinimizedView() : _buildExpandedView(),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimizedView() {
    return InkWell(
      onTap: () => setState(() => _isMinimized = false),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lightbulb, color: Colors.amber, size: 24.sp),
            SizedBox(height: 0.5.h),
            Text(
              '${_recommendations.length}',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandedView() {
    return Column(
      children: [
        _buildHeader(),
        _buildTabBar(),
        Expanded(child: _buildTabContent()),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16.0)),
      ),
      child: Row(
        children: [
          Icon(Icons.psychology, color: Colors.blue, size: 20.sp),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              'AI Recommendations',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.minimize),
            onPressed: () => setState(() => _isMinimized = true),
            iconSize: 18.sp,
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
            iconSize: 18.sp,
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
      ),
      child: Row(
        children: [
          _buildTab('Suggestions', 0),
          _buildTab('History', 1),
          _buildTab('Metrics', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isSelected = _selectedTab == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedTab = index),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 1.5.h),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: isSelected ? Colors.blue : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.blue : Colors.grey,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    switch (_selectedTab) {
      case 0:
        return _buildRecommendationsList();
      case 1:
        return RecommendationHistoryWidget(history: _history);
      case 2:
        return PerformanceMetricsWidget(metrics: _performanceMetrics);
      default:
        return const SizedBox();
    }
  }

  Widget _buildRecommendationsList() {
    if (_recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle, color: Colors.green, size: 48.sp),
            SizedBox(height: 2.h),
            Text(
              'All caught up!',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 1.h),
            Text(
              'No new recommendations at this time',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(2.w),
            itemCount: _recommendations.length,
            itemBuilder: (context, index) {
              return RecommendationCardWidget(
                recommendation: _recommendations[index],
                onApprove: () =>
                    _approveRecommendation(_recommendations[index]),
                onReject: () => _rejectRecommendation(_recommendations[index]),
              );
            },
          ),
        ),
        if (_history.any(
          (h) => h['action'] == 'approved' && h['can_undo'] == true,
        ))
          Container(
            padding: EdgeInsets.all(2.w),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade300)),
            ),
            child: ElevatedButton.icon(
              onPressed: _undoLastAction,
              icon: const Icon(Icons.undo),
              label: const Text('Undo Last Action'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                minimumSize: Size(double.infinity, 5.h),
              ),
            ),
          ),
      ],
    );
  }
}
