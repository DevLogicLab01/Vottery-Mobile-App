import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/creator_community_service.dart';
import '../../services/supabase_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/dual_header_bottom_bar.dart';
import '../../widgets/dual_header_top_bar.dart';
import '../../widgets/error_boundary_wrapper.dart';
import 'creator_community_post_detail_screen.dart';

/// Creator Community Hub - Strategy sharing, partnership matching, peer mentorship
class CreatorCommunityHub extends StatefulWidget {
  const CreatorCommunityHub({super.key});

  @override
  State<CreatorCommunityHub> createState() => _CreatorCommunityHubState();
}

class _CreatorCommunityHubState extends State<CreatorCommunityHub>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final CreatorCommunityService _service = CreatorCommunityService.instance;

  bool _loading = true;
  List<Map<String, dynamic>> _strategyPosts = [];
  List<Map<String, dynamic>> _partnerships = [];
  List<Map<String, dynamic>> _mentorship = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      final results = await Future.wait([
        _service.getStrategyPosts(),
        _service.getPartnershipOpportunities(),
        _service.getMentorshipThreads(),
      ]);
      if (mounted) {
        setState(() {
          _strategyPosts = results[0];
          _partnerships = results[1];
          _mentorship = results[2];
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'CreatorCommunityHub',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: AppTheme.backgroundLight,
        appBar: DualHeaderTopBar(
          currentRoute: AppRoutes.creatorCommunityHub,
          friendRequestsCount: 0,
          messagesCount: 0,
          notificationsCount: 0,
        ),
        body: Column(
          children: [
            Container(
              color: Colors.white,
              child: Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(4.w),
                    child: Text(
                      'Creator Community Hub',
                      style: GoogleFonts.inter(
                        fontSize: 20.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                  TabBar(
                    controller: _tabController,
                    labelColor: AppTheme.vibrantYellow,
                    unselectedLabelColor: AppTheme.textSecondaryLight,
                    indicatorColor: AppTheme.vibrantYellow,
                    tabs: const [
                      Tab(text: 'Strategy'),
                      Tab(text: 'Partnerships'),
                      Tab(text: 'Mentorship'),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildStrategyTab(),
                        _buildPartnershipsTab(),
                        _buildMentorshipTab(),
                      ],
                    ),
            ),
          ],
        ),
        floatingActionButton: _buildCreatePostFAB(),
        bottomNavigationBar: DualHeaderBottomBar(
          currentRoute: AppRoutes.creatorCommunityHub,
          onNavigate: (route) => Navigator.pushNamed(context, route),
        ),
      ),
    );
  }

  Widget? _buildCreatePostFAB() {
    final isLoggedIn = SupabaseService.instance.client.auth.currentUser != null;
    if (!isLoggedIn) return null;
    return FloatingActionButton.extended(
      onPressed: _showCreatePostDialog,
      backgroundColor: AppTheme.vibrantYellow,
      icon: const Icon(Icons.add, color: Colors.black87),
      label: Text(
        'Create Post',
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
      ),
    );
  }

  void _showCreatePostDialog() {
    final postType = _tabController.index == 0
        ? 'strategy'
        : _tabController.index == 1
            ? 'partnership'
            : 'mentorship';
    final postTypeLabel = ['Strategy', 'Partnership', 'Mentorship'][_tabController.index];
    final titleController = TextEditingController();
    final bodyController = TextEditingController();
    final tagsController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: EdgeInsets.only(bottom: 2.h),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(
                  'Create $postTypeLabel Post',
                  style: GoogleFonts.inter(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 2.h),
                TextField(
                  controller: titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 1,
                ),
                SizedBox(height: 1.5.h),
                TextField(
                  controller: bodyController,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 4,
                ),
                SizedBox(height: 1.5.h),
                TextField(
                  controller: tagsController,
                  decoration: InputDecoration(
                    labelText: 'Tags (comma-separated)',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  maxLines: 1,
                ),
                SizedBox(height: 2.h),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Cancel'),
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: FilledButton(
                        onPressed: () async {
                          final title = titleController.text.trim();
                          final body = bodyController.text.trim();
                          if (title.isEmpty || body.isEmpty) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Title and content required')),
                              );
                            }
                            return;
                          }
                          final tags = tagsController.text
                              .split(',')
                              .map((s) => s.trim())
                              .where((s) => s.isNotEmpty)
                              .toList();
                          final post = await _service.createPost(
                            postType: postType,
                            title: title,
                            body: body,
                            tags: tags.isEmpty ? null : tags,
                          );
                          if (mounted) {
                            Navigator.pop(ctx);
                            if (post != null) {
                              _loadData();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Post created!')),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Failed to create post')),
                              );
                            }
                          }
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.vibrantYellow,
                          foregroundColor: Colors.black87,
                        ),
                        child: const Text('Post'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStrategyTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _strategyPosts.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Text(
                'Carousel best practices & strategy sharing',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            );
          }
          final post = _strategyPosts[index - 1];
          return _buildPostCard(
            post,
            (post['tags'] as List?)?.join(', ') ?? '',
            Icons.lightbulb_outline,
          );
        },
      ),
    );
  }

  Widget _buildPartnershipsTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _partnerships.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Text(
                'Find collaboration opportunities',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            );
          }
          final post = _partnerships[index - 1];
          return _buildPostCard(
            post,
            'Partnership',
            Icons.handshake_outlined,
          );
        },
      ),
    );
  }

  Widget _buildMentorshipTab() {
    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView.builder(
        padding: EdgeInsets.all(4.w),
        itemCount: _mentorship.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: EdgeInsets.only(bottom: 2.h),
              child: Text(
                'Learn from top creators',
                style: GoogleFonts.inter(
                  fontSize: 13.sp,
                  color: AppTheme.textSecondaryLight,
                ),
              ),
            );
          }
          final post = _mentorship[index - 1];
          return _buildPostCard(
            post,
            'Mentorship',
            Icons.school_outlined,
          );
        },
      ),
    );
  }

  Widget _buildPostCard(
    Map<String, dynamic> post,
    String subtitle,
    IconData icon,
  ) {
    final author = post['author'] as Map<String, dynamic>?;
    final username = author?['username'] as String? ?? 'Creator';

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.vibrantYellow.withAlpha(80),
          child: Icon(icon, color: AppTheme.primaryLight, size: 22),
        ),
        title: Text(
          post['title'] as String? ?? 'Untitled',
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w600,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 0.5.h),
            Text(
              '@$username · $subtitle',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            if (post['likes_count'] != null)
              Padding(
                padding: EdgeInsets.only(top: 0.5.h),
                child: Text(
                  '${post['likes_count']} likes',
                  style: GoogleFonts.inter(
                    fontSize: 10.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ),
          ],
        ),
        isThreeLine: true,
        onTap: () {
          final postTypeLabel = icon == Icons.lightbulb_outline
              ? 'Strategy'
              : icon == Icons.handshake_outlined
                  ? 'Partnership'
                  : 'Mentorship';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreatorCommunityPostDetailScreen(
                post: post,
                postTypeLabel: postTypeLabel,
                icon: icon,
              ),
            ),
          );
        },
      ),
    );
  }
}
