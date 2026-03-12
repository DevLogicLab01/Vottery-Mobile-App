import 'dart:async';

import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/intelligence_overview_header_widget.dart';
import './widgets/transcript_analysis_widget.dart';
import './widgets/trending_engine_widget.dart';
import './widgets/semantic_similarity_widget.dart';
import './widgets/content_optimization_widget.dart';
import './widgets/trending_themes_heatmap_widget.dart';
import './widgets/duplicate_detection_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

class AnthropicContentIntelligenceHub extends StatefulWidget {
  const AnthropicContentIntelligenceHub({super.key});

  @override
  State<AnthropicContentIntelligenceHub> createState() =>
      _AnthropicContentIntelligenceHubState();
}

class _AnthropicContentIntelligenceHubState
    extends State<AnthropicContentIntelligenceHub> {
  bool _isLoading = true;
  bool _autoRefreshEnabled = true;
  Timer? _refreshTimer;

  Map<String, dynamic> _intelligenceOverview = {};
  List<Map<String, dynamic>> _transcriptAnalyses = [];
  List<Map<String, dynamic>> _trendingElections = [];
  List<Map<String, dynamic>> _semanticSimilarities = [];
  List<Map<String, dynamic>> _optimizationSuggestions = [];
  List<Map<String, dynamic>> _trendingThemes = [];
  List<Map<String, dynamic>> _duplicateContent = [];

  @override
  void initState() {
    super.initState();
    _loadIntelligenceData();
    _setupAutoRefresh();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  void _setupAutoRefresh() {
    if (_autoRefreshEnabled) {
      _refreshTimer = Timer.periodic(Duration(minutes: 5), (_) {
        if (mounted) {
          _loadIntelligenceData(silent: true);
        }
      });
    }
  }

  Future<void> _loadIntelligenceData({bool silent = false}) async {
    if (!silent) {
      setState(() => _isLoading = true);
    }

    try {
      final results = await Future.wait([
        _loadIntelligenceOverview(),
        _loadTranscriptAnalyses(),
        _loadTrendingElections(),
        _loadSemanticSimilarities(),
        _loadOptimizationSuggestions(),
        _loadTrendingThemes(),
        _loadDuplicateContent(),
      ]);

      if (mounted) {
        setState(() {
          _intelligenceOverview = results[0] as Map<String, dynamic>;
          _transcriptAnalyses = results[1] as List<Map<String, dynamic>>;
          _trendingElections = results[2] as List<Map<String, dynamic>>;
          _semanticSimilarities = results[3] as List<Map<String, dynamic>>;
          _optimizationSuggestions = results[4] as List<Map<String, dynamic>>;
          _trendingThemes = results[5] as List<Map<String, dynamic>>;
          _duplicateContent = results[6] as List<Map<String, dynamic>>;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load intelligence data error: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<Map<String, dynamic>> _loadIntelligenceOverview() async {
    try {
      final supabase = SupabaseService.instance.client;

      final transcriptCount = await supabase
          .from('transcript_analysis')
          .select('analysis_id')
          .count();

      final trendingCount = await supabase
          .from('trending_elections')
          .select('trending_id')
          .gte('trending_score', 50)
          .count();

      final avgQuality = await supabase
          .from('transcript_analysis')
          .select('content_quality_score')
          .limit(100);

      double qualityScore = 0.0;
      if (avgQuality.isNotEmpty) {
        final scores = avgQuality
            .map((e) => (e['content_quality_score'] as num?)?.toDouble() ?? 0.0)
            .toList();
        qualityScore = scores.reduce((a, b) => a + b) / scores.length;
      }

      return {
        'total_analyses': transcriptCount.count ?? 0,
        'trending_elections': trendingCount.count ?? 0,
        'avg_content_quality': qualityScore,
        'analysis_status': 'active',
      };
    } catch (e) {
      debugPrint('Load intelligence overview error: $e');
      return {
        'total_analyses': 0,
        'trending_elections': 0,
        'avg_content_quality': 0.0,
        'analysis_status': 'error',
      };
    }
  }

  Future<List<Map<String, dynamic>>> _loadTranscriptAnalyses() async {
    try {
      final supabase = SupabaseService.instance.client;
      final response = await supabase
          .from('transcript_analysis')
          .select('*, elections!inner(id, title, description)')
          .order('analyzed_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Load transcript analyses error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadTrendingElections() async {
    try {
      final supabase = SupabaseService.instance.client;
      final response = await supabase.rpc(
        'get_trending_elections',
        params: {'p_limit': 15},
      );

      return List<Map<String, dynamic>>.from(response ?? []);
    } catch (e) {
      debugPrint('Load trending elections error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadSemanticSimilarities() async {
    try {
      final supabase = SupabaseService.instance.client;
      final response = await supabase
          .from('semantic_similarity_cache')
          .select(
            '*, election_a:elections!election_a_id(id, title), election_b:elections!election_b_id(id, title)',
          )
          .gte('similarity_score', 0.8)
          .order('similarity_score', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Load semantic similarities error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadOptimizationSuggestions() async {
    try {
      final supabase = SupabaseService.instance.client;
      final response = await supabase
          .from('transcript_analysis')
          .select('*, elections!inner(id, title)')
          .lt('content_quality_score', 60)
          .order('content_quality_score', ascending: true)
          .limit(8);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Load optimization suggestions error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadTrendingThemes() async {
    try {
      final supabase = SupabaseService.instance.client;
      final response = await supabase
          .from('transcript_analysis')
          .select('key_themes')
          .not('key_themes', 'is', null)
          .limit(50);

      final Map<String, int> themeCount = {};
      for (final item in response) {
        final themes = item['key_themes'] as List<dynamic>?;
        if (themes != null) {
          for (final theme in themes) {
            final themeStr = theme.toString();
            themeCount[themeStr] = (themeCount[themeStr] ?? 0) + 1;
          }
        }
      }

      final sortedThemes = themeCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedThemes
          .take(15)
          .map((e) => {'theme': e.key, 'count': e.value})
          .toList();
    } catch (e) {
      debugPrint('Load trending themes error: $e');
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> _loadDuplicateContent() async {
    try {
      final supabase = SupabaseService.instance.client;
      final response = await supabase
          .from('semantic_similarity_cache')
          .select(
            '*, election_a:elections!election_a_id(id, title), election_b:elections!election_b_id(id, title)',
          )
          .gte('similarity_score', 0.9)
          .order('similarity_score', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      debugPrint('Load duplicate content error: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'AnthropicContentIntelligenceHub',
      onRetry: () => _loadIntelligenceData(),
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: CustomAppBar(
          title: 'Content Intelligence Hub',
          actions: [
            IconButton(
              icon: Icon(
                _autoRefreshEnabled ? Icons.refresh : Icons.refresh_outlined,
                color: _autoRefreshEnabled ? Colors.blue : Colors.grey,
              ),
              onPressed: () {
                setState(() => _autoRefreshEnabled = !_autoRefreshEnabled);
                if (_autoRefreshEnabled) {
                  _setupAutoRefresh();
                } else {
                  _refreshTimer?.cancel();
                }
              },
            ),
            IconButton(
              icon: const Icon(Icons.sync),
              onPressed: () => _loadIntelligenceData(),
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonDashboard()
            : RefreshIndicator(
                onRefresh: () => _loadIntelligenceData(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.all(3.w),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      IntelligenceOverviewHeaderWidget(
                        overview: _intelligenceOverview,
                      ),
                      SizedBox(height: 2.h),
                      TranscriptAnalysisWidget(analyses: _transcriptAnalyses),
                      SizedBox(height: 2.h),
                      TrendingEngineWidget(
                        trendingElections: _trendingElections,
                      ),
                      SizedBox(height: 2.h),
                      SemanticSimilarityWidget(
                        similarities: _semanticSimilarities,
                      ),
                      SizedBox(height: 2.h),
                      ContentOptimizationWidget(
                        suggestions: _optimizationSuggestions,
                      ),
                      SizedBox(height: 2.h),
                      TrendingThemesHeatmapWidget(themes: _trendingThemes),
                      SizedBox(height: 2.h),
                      DuplicateDetectionWidget(duplicates: _duplicateContent),
                      SizedBox(height: 2.h),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
