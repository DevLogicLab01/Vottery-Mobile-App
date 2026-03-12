import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/community_service.dart';
import '../../widgets/custom_app_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/offline_status_badge.dart';

class CommunityElectionsHubScreen extends StatefulWidget {
  const CommunityElectionsHubScreen({super.key});

  @override
  State<CommunityElectionsHubScreen> createState() =>
      _CommunityElectionsHubScreenState();
}

class _CommunityElectionsHubScreenState
    extends State<CommunityElectionsHubScreen>
    with SingleTickerProviderStateMixin {
  final CommunityService _communityService = CommunityService.instance;

  late TabController _tabController;
  bool _isLoading = true;
  String _searchQuery = '';
  List<Map<String, dynamic>> _communities = [];
  List<Map<String, dynamic>> _myCommunities = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) return;
      _loadData();
    });
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final index = _tabController.index;
      if (index == 0) {
        _communities = await _communityService.getCommunities(limit: 50);
      } else {
        _myCommunities = await _communityService.getUserCommunities();
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'CommunityElectionsHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: CustomAppBar(
          title: 'Community Elections',
          variant: CustomAppBarVariant.withBack,
          actions: const [
            OfflineStatusBadge(),
          ],
        ),
        body: Column(
          children: [
            _buildHeader(theme),
            _buildTabBar(theme),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : RefreshIndicator(
                      onRefresh: _loadData,
                      child: _tabController.index == 0
                          ? _buildCommunityList(theme, _communities)
                          : _buildCommunityList(
                              theme,
                              _myCommunities
                                  .map((e) =>
                                      (e['community'] as Map?)?.cast<String, dynamic>() ??
                                      e.cast<String, dynamic>())
                                  .toList(),
                            ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Topic-based community spaces for collaborative elections',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.5.h),
          TextField(
            decoration: InputDecoration(
              hintText: 'Search communities...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              isDense: true,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value.trim());
            },
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(ThemeData theme) {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: theme.colorScheme.primary,
        unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
        indicatorColor: theme.colorScheme.primary,
        tabs: const [
          Tab(text: 'Discover'),
          Tab(text: 'My Communities'),
        ],
      ),
    );
  }

  Widget _buildCommunityList(
    ThemeData theme,
    List<Map<String, dynamic>> items,
  ) {
    final filtered = items.where((c) {
      final name = (c['name'] ?? '').toString().toLowerCase();
      final topic = (c['topic'] ?? '').toString().toLowerCase();
      final query = _searchQuery.toLowerCase();
      if (query.isEmpty) return true;
      return name.contains(query) || topic.contains(query);
    }).toList();

    if (filtered.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(height: 10.h),
          Center(
            child: Text(
              'No communities found.',
              style: theme.textTheme.bodyMedium,
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      itemCount: filtered.length,
      itemBuilder: (context, index) {
        final community = filtered[index];
        return _buildCommunityCard(theme, community);
      },
    );
  }

  Widget _buildCommunityCard(
    ThemeData theme,
    Map<String, dynamic> community,
  ) {
    final name = community['name'] as String? ?? 'Community';
    final topic = community['topic'] as String? ?? 'General';
    final description = community['description'] as String? ?? '';
    final memberCount = community['member_count'] as int? ?? 0;

    return Card(
      margin: EdgeInsets.only(bottom: 1.5.h),
      elevation: 1,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              name,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            SizedBox(height: 0.5.h),
            Text(
              topic,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.primary,
              ),
            ),
            if (description.isNotEmpty) ...[
              SizedBox(height: 0.8.h),
              Text(
                description,
                style: theme.textTheme.bodySmall,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            SizedBox(height: 1.h),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.group, size: 16),
                    SizedBox(width: 1.w),
                    Text('$memberCount members'),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    // For now, navigate to generic collaborative voting room
                    Navigator.pushNamed(
                      context,
                      AppRoutes.collaborativeVotingRoom,
                      arguments: community['id'],
                    );
                  },
                  child: const Text('View elections'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

