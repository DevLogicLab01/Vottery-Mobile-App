import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/supabase_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/shimmer_skeleton_loader.dart';
import './insight_card_widget.dart';
import './insight_editor_dialog_widget.dart';

class InsightLibraryWidget extends StatefulWidget {
  final String workspaceId;

  const InsightLibraryWidget({super.key, required this.workspaceId});

  @override
  State<InsightLibraryWidget> createState() => _InsightLibraryWidgetState();
}

class _InsightLibraryWidgetState extends State<InsightLibraryWidget> {
  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _insights = [];
  String _selectedCategory = 'all';
  String _sortBy = 'recent';

  final List<String> _categories = [
    'all',
    'performance',
    'security',
    'revenue',
    'user_behavior',
    'engagement',
    'technical',
  ];

  @override
  void initState() {
    super.initState();
    _loadInsights();
  }

  Future<void> _loadInsights() async {
    setState(() => _isLoading = true);

    try {
      dynamic query = _client
          .from('insights_library')
          .select('*, author:user_profiles!author_id(*)')
          .eq('workspace_id', widget.workspaceId);

      if (_selectedCategory != 'all') {
        query = query.eq('category', _selectedCategory);
      }

      if (_sortBy == 'recent') {
        query = query.order('created_at', ascending: false);
      } else if (_sortBy == 'trending') {
        query = query.order('upvotes', ascending: false);
      }

      final response = await query;

      setState(() {
        _insights = List<Map<String, dynamic>>.from(response);
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load insights error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _showInsightEditor() {
    showDialog(
      context: context,
      builder: (context) => InsightEditorDialogWidget(
        workspaceId: widget.workspaceId,
        onSubmit: (data) async {
          await _createInsight(data);
          Navigator.pop(context);
        },
      ),
    );
  }

  Future<void> _createInsight(Map<String, dynamic> data) async {
    try {
      await _client.from('insights_library').insert({
        ...data,
        'workspace_id': widget.workspaceId,
        'author_id': _auth.currentUser!.id,
      });

      await _loadInsights();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Insight documented successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      debugPrint('Create insight error: $e');
    }
  }

  Future<void> _voteInsight(String insightId, bool isUpvote) async {
    try {
      await _client.from('insight_votes').upsert({
        'insight_id': insightId,
        'user_id': _auth.currentUser!.id,
        'vote_type': isUpvote ? 'upvote' : 'downvote',
      });

      await _loadInsights();
    } catch (e) {
      debugPrint('Vote insight error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        _buildFilters(theme),
        Expanded(
          child: _isLoading
              ? ListView.builder(
                  padding: EdgeInsets.all(4.w),
                  itemCount: 5,
                  itemBuilder: (context, index) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: 2.h),
                      child: SkeletonCard(height: 20.h, width: double.infinity),
                    );
                  },
                )
              : _insights.isEmpty
              ? _buildEmptyState(theme)
              : RefreshIndicator(
                  onRefresh: _loadInsights,
                  child: ListView.builder(
                    padding: EdgeInsets.all(4.w),
                    itemCount: _insights.length,
                    itemBuilder: (context, index) {
                      final insight = _insights[index];
                      return InsightCardWidget(
                        insight: insight,
                        onVote: (isUpvote) =>
                            _voteInsight(insight['id'], isUpvote),
                      );
                    },
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilters(ThemeData theme) {
    return Container(
      padding: EdgeInsets.all(4.w),
      color: theme.colorScheme.surface,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Insights Library',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              ElevatedButton.icon(
                onPressed: _showInsightEditor,
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Insight'),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                ..._categories.map((category) {
                  final isSelected = category == _selectedCategory;
                  return Padding(
                    padding: EdgeInsets.only(right: 2.w),
                    child: ChoiceChip(
                      label: Text(category.replaceAll('_', ' ').toUpperCase()),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          setState(() => _selectedCategory = category);
                          _loadInsights();
                        }
                      },
                    ),
                  );
                }),
              ],
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Text('Sort by:', style: theme.textTheme.bodySmall),
              SizedBox(width: 2.w),
              ChoiceChip(
                label: const Text('Recent'),
                selected: _sortBy == 'recent',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _sortBy = 'recent');
                    _loadInsights();
                  }
                },
              ),
              SizedBox(width: 2.w),
              ChoiceChip(
                label: const Text('Trending'),
                selected: _sortBy == 'trending',
                onSelected: (selected) {
                  if (selected) {
                    setState(() => _sortBy = 'trending');
                    _loadInsights();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lightbulb_outline,
            size: 64,
            color: theme.colorScheme.onSurfaceVariant,
          ),
          SizedBox(height: 2.h),
          Text('No Insights Yet', style: theme.textTheme.titleLarge),
          SizedBox(height: 1.h),
          Text(
            'Document your first insight',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
