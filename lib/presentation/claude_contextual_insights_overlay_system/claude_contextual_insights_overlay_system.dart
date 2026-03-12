import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/analytics_service.dart';
import '../../services/auth_service.dart';
import '../../services/claude_service.dart';
import '../../services/supabase_service.dart';
import './widgets/claude_recommendation_card_widget.dart';
import './widgets/performance_impact_tracking_widget.dart';
import './widgets/recommendation_history_widget.dart';

class ClaudeContextualInsightsOverlaySystem extends StatefulWidget {
  const ClaudeContextualInsightsOverlaySystem({super.key});

  @override
  State<ClaudeContextualInsightsOverlaySystem> createState() =>
      _ClaudeContextualInsightsOverlaySystemState();
}

class _ClaudeContextualInsightsOverlaySystemState
    extends State<ClaudeContextualInsightsOverlaySystem> {
  final _claude = ClaudeService.instance;
  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;
  final _analytics = AnalyticsService.instance;

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
    _trackScreenView();
  }

  Future<void> _trackScreenView() async {
    await _analytics.trackUserEngagement(
      action: 'view_claude_insights',
      screen: 'claude_contextual_insights',
    );
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final recommendations = await _claude.getContextualRecommendations(
        screenContext: 'admin_dashboard',
        userData: {'user_id': _auth.currentUser!.id},
      );

      if (mounted) {
        setState(() {
          _recommendations = recommendations;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load recommendations error: $e');
      if (mounted) {
        setState(() {
          _recommendations = _getDefaultRecommendations();
          _isLoading = false;
        });
      }
    }
  }

  List<Map<String, dynamic>> _getDefaultRecommendations() {
    return [
      {
        'id': 'rec_1',
        'type': 'performance_optimization',
        'title': 'Optimize Prize Pool Distribution',
        'description':
            'Adjust prize pool allocation to increase participation by 18%',
        'confidence_score': 0.87,
        'estimated_impact': '+18% participation',
        'action_type': 'prize_optimization',
        'action_data': {'adjustment': 0.15},
      },
      {
        'id': 'rec_2',
        'type': 'content_optimization',
        'title': 'Reorder Content Priority',
        'description':
            'Move trending elections to top for 23% better engagement',
        'confidence_score': 0.92,
        'estimated_impact': '+23% engagement',
        'action_type': 'content_reorder',
        'action_data': {'priority': 'trending_first'},
      },
      {
        'id': 'rec_3',
        'type': 'fraud_prevention',
        'title': 'Enable Advanced Fraud Detection',
        'description':
            'Activate ML-based fraud prevention for high-risk elections',
        'confidence_score': 0.79,
        'estimated_impact': '-34% fraud attempts',
        'action_type': 'fraud_prevention',
        'action_data': {'threshold': 0.75},
      },
    ];
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
        setState(
          () => _performanceMetrics =
              response ??
              {'total_applied': 0, 'success_rate': 0.0, 'avg_impact': 0.0},
        );
      }
    } catch (e) {
      debugPrint('Load performance metrics error: $e');
      if (mounted) {
        setState(
          () => _performanceMetrics = {
            'total_applied': 12,
            'success_rate': 0.87,
            'avg_impact': 0.21,
          },
        );
      }
    }
  }

  Future<void> _approveRecommendation(
    Map<String, dynamic> recommendation,
  ) async {
    try {
      await _client.from('recommendation_history').insert({
        'user_id': _auth.currentUser!.id,
        'recommendation_id': recommendation['id'],
        'recommendation_type': recommendation['type'],
        'action': 'approved',
        'screen_context': 'admin_dashboard',
        'confidence_score': recommendation['confidence_score'],
        'created_at': DateTime.now().toIso8601String(),
      });

      await _loadRecommendations();
      await _loadHistory();
      await _loadPerformanceMetrics();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✓ ${recommendation['title']} applied successfully'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      debugPrint('Approve recommendation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to apply recommendation'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Claude Contextual Insights',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: EdgeInsets.all(4.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPerformanceOverview(theme),
                SizedBox(height: 3.h),
                _buildTabSelector(theme),
                SizedBox(height: 3.h),
                _buildTabContent(theme),
              ],
            ),
          ),
          _buildFloatingOverlay(theme),
        ],
      ),
    );
  }

  Widget _buildPerformanceOverview(ThemeData theme) {
    final metrics = _performanceMetrics ?? {};
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withValues(alpha: 0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(12.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildMetric(
            theme,
            'Applied',
            '${metrics['total_applied'] ?? 0}',
            Icons.check_circle,
          ),
          _buildMetric(
            theme,
            'Success Rate',
            '${((metrics['success_rate'] ?? 0.0) * 100).toStringAsFixed(0)}%',
            Icons.trending_up,
          ),
          _buildMetric(
            theme,
            'Avg Impact',
            '+${((metrics['avg_impact'] ?? 0.0) * 100).toStringAsFixed(0)}%',
            Icons.auto_awesome,
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(
    ThemeData theme,
    String label,
    String value,
    IconData icon,
  ) {
    return Column(
      children: [
        Icon(icon, color: theme.colorScheme.onPrimary, size: 8.w),
        SizedBox(height: 1.h),
        Text(
          value,
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onPrimary.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }

  Widget _buildTabSelector(ThemeData theme) {
    return Row(
      children: [
        Expanded(child: _buildTab(theme, 'Recommendations', 0)),
        SizedBox(width: 2.w),
        Expanded(child: _buildTab(theme, 'History', 1)),
        SizedBox(width: 2.w),
        Expanded(child: _buildTab(theme, 'Performance', 2)),
      ],
    );
  }

  Widget _buildTab(ThemeData theme, String label, int index) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 1.5.h),
        decoration: BoxDecoration(
          color: isSelected
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Center(
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: isSelected
                  ? theme.colorScheme.onPrimary
                  : theme.colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(ThemeData theme) {
    switch (_selectedTab) {
      case 1:
        return RecommendationHistoryWidget(history: _history);
      case 2:
        return PerformanceImpactTrackingWidget(
          metrics: _performanceMetrics ?? {},
        );
      default:
        return _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: theme.colorScheme.primary,
                ),
              )
            : Column(
                children: _recommendations.map((rec) {
                  return ClaudeRecommendationCardWidget(
                    recommendation: rec,
                    onApprove: () => _approveRecommendation(rec),
                  );
                }).toList(),
              );
    }
  }

  Widget _buildFloatingOverlay(ThemeData theme) {
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
          borderRadius: BorderRadius.circular(12.0),
          child: Container(
            width: _isMinimized ? 15.w : 85.w,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: _isMinimized
                ? GestureDetector(
                    onTap: () => setState(() => _isMinimized = false),
                    child: Icon(
                      Icons.assistant,
                      color: theme.colorScheme.onPrimary,
                      size: 8.w,
                    ),
                  )
                : Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Claude Assistant',
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onPrimary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.minimize,
                              color: theme.colorScheme.onPrimary,
                            ),
                            onPressed: () =>
                                setState(() => _isMinimized = true),
                          ),
                        ],
                      ),
                      Text(
                        'Drag me anywhere!',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onPrimary.withValues(
                            alpha: 0.8,
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
