import 'package:flutter/material.dart';

import '../../services/ai_recommendations_service.dart';
import '../../services/feed_ranking_service.dart';
import '../../services/supabase_service.dart';

class GeminiRecommendationSyncHub extends StatefulWidget {
  const GeminiRecommendationSyncHub({super.key});

  @override
  State<GeminiRecommendationSyncHub> createState() =>
      _GeminiRecommendationSyncHubState();
}

class _GeminiRecommendationSyncHubState extends State<GeminiRecommendationSyncHub> {
  final AIRecommendationsService _recommendations = AIRecommendationsService.instance;
  final FeedRankingService _feedRanking = FeedRankingService.instance;
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _recommendedElections = <Map<String, dynamic>>[];
  List<Map<String, dynamic>> _recommendedContent = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final userId = SupabaseService.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await _feedRanking.updateSimilarUsers();
      }

      final elections = await _recommendations.getElectionRecommendations();
      final content = await _recommendations.getContentRecommendations(
        screenContext: 'gemini_recommendation_sync_hub',
        limit: 10,
      );

      if (!mounted) return;
      setState(() {
        _recommendedElections = elections;
        _recommendedContent = content;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-Time Recommendation Sync Hub'),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadRecommendations,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Failed to load recommendations: $_error'))
              : ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    const Text(
                      'Personalized Election Recommendations',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    if (_recommendedElections.isEmpty)
                      const Text('No election recommendations available.')
                    else
                      ..._recommendedElections.map((item) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.how_to_vote),
                              title: Text(item['title']?.toString() ?? 'Untitled election'),
                              subtitle: Text(item['description']?.toString() ?? 'Recommended for you'),
                            ),
                          )),
                    const SizedBox(height: 20),
                    const Text(
                      'Context-Aware Content Recommendations',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),
                    if (_recommendedContent.isEmpty)
                      const Text('No content recommendations available.')
                    else
                      ..._recommendedContent.map((item) => Card(
                            child: ListTile(
                              leading: const Icon(Icons.recommend),
                              title: Text(item['title']?.toString() ?? 'Recommended content'),
                              subtitle: Text(item['description']?.toString() ?? 'AI-ranked for your activity'),
                              trailing: Text(
                                ((item['relevance_score'] ?? 0) as num).toString(),
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          )),
                  ],
                ),
    );
  }
}
