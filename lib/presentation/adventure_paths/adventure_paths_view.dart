import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../services/auth_service.dart';
import '../../services/openai_service.dart';
import '../../services/supabase_service.dart';
import '../../services/vp_service.dart';
import '../../widgets/custom_app_bar.dart';

class AdventurePath {
  final String id;
  final String pathName;
  final String themeDescription;
  final String pathIcon;
  final List<Map<String, dynamic>> contentItems;
  final int completedItems;
  final bool isStarted;

  const AdventurePath({
    required this.id,
    required this.pathName,
    required this.themeDescription,
    required this.pathIcon,
    required this.contentItems,
    required this.completedItems,
    required this.isStarted,
  });

  int get totalItems => contentItems.length;
  double get progress => totalItems > 0 ? completedItems / totalItems : 0.0;
  bool get isCompleted => completedItems >= totalItems && totalItems > 0;
}

class AdventurePathsView extends StatefulWidget {
  const AdventurePathsView({super.key});

  @override
  State<AdventurePathsView> createState() => _AdventurePathsViewState();
}

class _AdventurePathsViewState extends State<AdventurePathsView> {
  bool _isLoading = true;
  bool _isGenerating = false;
  List<AdventurePath> _paths = [];
  AdventurePath? _activePath;
  int _activeItemIndex = 0;

  final AuthService _auth = AuthService.instance;
  final VPService _vpService = VPService.instance;
  SupabaseClient get _client => SupabaseService.instance.client;

  @override
  void initState() {
    super.initState();
    _loadPaths();
  }

  Future<void> _loadPaths() async {
    try {
      if (_auth.isAuthenticated) {
        final data = await _client
            .from('user_adventure_paths')
            .select()
            .eq('user_id', _auth.currentUser!.id)
            .order('created_at', ascending: false)
            .limit(10);

        if (data.isNotEmpty) {
          final paths = data
              .map(
                (p) => AdventurePath(
                  id: p['id']?.toString() ?? '',
                  pathName: p['path_name']?.toString() ?? 'Adventure Path',
                  themeDescription: p['theme_description']?.toString() ?? '',
                  pathIcon: p['path_icon']?.toString() ?? '\\u{1F5FA}',
                  contentItems: List<Map<String, dynamic>>.from(
                    p['content_items'] as List? ?? [],
                  ),
                  completedItems: (p['completed_items'] as num?)?.toInt() ?? 0,
                  isStarted: (p['is_started'] as bool?) ?? false,
                ),
              )
              .toList();
          if (mounted) setState(() => _paths = paths);
          if (mounted) setState(() => _isLoading = false);
          return;
        }
      }
      await _generatePaths();
    } catch (_) {
      _loadMockPaths();
    }
    if (mounted) setState(() => _isLoading = false);
  }

  void _loadMockPaths() {
    _paths = [
      AdventurePath(
        id: '1',
        pathName: 'Election Explorer',
        themeDescription:
            'Discover the world of democratic elections through voting and predictions',
        pathIcon: '\\u{1F5F3}',
        contentItems: [
          {
            'type': 'election',
            'title': 'Vote in your first election',
            'narrative_connector': 'Your journey begins with a single vote...',
          },
          {
            'type': 'prediction',
            'title': 'Make a prediction',
            'narrative_connector': 'Now test your political instincts...',
          },
          {
            'type': 'post',
            'title': 'Share your thoughts',
            'narrative_connector': 'Tell the community what you think...',
          },
          {
            'type': 'election',
            'title': 'Vote in a gamified election',
            'narrative_connector': 'Level up with a gamified experience...',
          },
          {
            'type': 'jolt',
            'title': 'Watch a political Jolt',
            'narrative_connector': 'Stay informed with short video content...',
          },
        ],
        completedItems: 2,
        isStarted: true,
      ),
      AdventurePath(
        id: '2',
        pathName: 'VP Millionaire',
        themeDescription:
            'Earn massive VP through strategic voting and predictions',
        pathIcon: '\\u{1F4B0}',
        contentItems: [
          {
            'type': 'election',
            'title': 'Vote in 3 elections',
            'narrative_connector': 'Start earning VP with every vote...',
          },
          {
            'type': 'prediction',
            'title': 'Win a prediction pool',
            'narrative_connector': 'Multiply your earnings with accuracy...',
          },
          {
            'type': 'ad',
            'title': 'Complete an ad quest',
            'narrative_connector': 'Brands reward your engagement...',
          },
          {
            'type': 'election',
            'title': 'Vote in a premium election',
            'narrative_connector': 'Premium elections = premium rewards...',
          },
          {
            'type': 'prediction',
            'title': 'Achieve 80%+ accuracy',
            'narrative_connector': 'Master the art of prediction...',
          },
        ],
        completedItems: 0,
        isStarted: false,
      ),
      AdventurePath(
        id: '3',
        pathName: 'Social Butterfly',
        themeDescription:
            'Build connections and engage with the Vottery community',
        pathIcon: '\\u{1F98B}',
        contentItems: [
          {
            'type': 'post',
            'title': 'Create your first post',
            'narrative_connector': 'Share your voice with the world...',
          },
          {
            'type': 'jolt',
            'title': 'Like 5 Jolts',
            'narrative_connector': 'Support creators you love...',
          },
          {
            'type': 'post',
            'title': 'Comment on 3 posts',
            'narrative_connector': 'Join the conversation...',
          },
          {
            'type': 'election',
            'title': 'Vote in a group election',
            'narrative_connector': 'Democracy is better together...',
          },
          {
            'type': 'post',
            'title': 'Get 10 likes on a post',
            'narrative_connector': 'Your voice is being heard!',
          },
        ],
        completedItems: 1,
        isStarted: true,
      ),
    ];
  }

  Future<void> _generatePaths() async {
    if (!_auth.isAuthenticated) {
      _loadMockPaths();
      return;
    }
    if (mounted) setState(() => _isGenerating = true);
    try {
      // Get user interests from profile
      final profile = await _client
          .from('profiles')
          .select('interests')
          .eq('id', _auth.currentUser!.id)
          .maybeSingle();

      final interests =
          profile?['interests']?.toString() ?? 'politics, technology, sports';

      final prompt =
          'Generate 3 adventure paths for a user with interests: $interests. '
          'Each path: 5-7 content items (elections, jolts, posts, ads, predictions) forming a coherent narrative. '
          'Return JSON array: [{"path_name":"string","theme_description":"string","path_icon":"emoji","content_items":[{"type":"election|jolt|post|ad|prediction","title":"string","narrative_connector":"string"}]}]. '
          'Return only valid JSON.';

      final response = await OpenAIService.instance.generateResponse(prompt);

      final parsed = _parsePathsJson(response.trim());
      if (parsed.isNotEmpty) {
        for (final path in parsed) {
          await _client.from('user_adventure_paths').insert({
            'user_id': _auth.currentUser!.id,
            'path_name': path['path_name'],
            'theme_description': path['theme_description'],
            'path_icon': path['path_icon'] ?? '\\u{1F5FA}',
            'content_items': path['content_items'],
            'completed_items': 0,
            'is_started': false,
            'created_at': DateTime.now().toIso8601String(),
          });
        }
        await _loadPaths();
        return;
      }
    } catch (_) {}
    _loadMockPaths();
    if (mounted) setState(() => _isGenerating = false);
  }

  List<Map<String, dynamic>> _parsePathsJson(String json) {
    try {
      // Simple JSON array extraction
      final start = json.indexOf('[');
      final end = json.lastIndexOf(']');
      if (start == -1 || end == -1) return [];
      final decoded = jsonDecode(json.substring(start, end + 1)) as List;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  Future<void> _completeItem(AdventurePath path, int itemIndex) async {
    try {
      // Remove this block - awardVP method doesn't exist
      // await _vpService.awardVP(
      //   amount: 5,
      //   source: 'adventure_path_item',
      //   description: 'Completed adventure path item',
      // );
    } catch (_) {}

    try {
      await _client
          .from('user_adventure_paths')
          .update({
            'completed_items': itemIndex + 1,
            'is_started': true,
            'updated_at': DateTime.now().toIso8601String(),
          })
          .eq('id', path.id);
    } catch (_) {}

    if (itemIndex + 1 >= path.totalItems) {
      await _onPathCompleted(path);
    } else {
      if (mounted) setState(() => _activeItemIndex = itemIndex + 1);
    }
    await _loadPaths();
  }

  Future<void> _onPathCompleted(AdventurePath path) async {
    try {
      // Remove this block - awardVP method doesn't exist
      // await _vpService.awardVP(
      //   amount: 100,
      //   source: 'adventure_path_completion',
      //   description: 'Completed adventure path: ${path.pathName}',
      // );
      await _client.from('adventure_path_analytics').insert({
        'user_id': _auth.currentUser!.id,
        'path_id': path.id,
        'path_name': path.pathName,
        'completed_at': DateTime.now().toIso8601String(),
        'total_items': path.totalItems,
      });
    } catch (_) {}
    if (mounted) _showCompletionCelebration(path);
  }

  void _showCompletionCelebration(AdventurePath path) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: const Color(0xFF1E1E2E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('\\u{1F3C6}', style: TextStyle(fontSize: 24.sp)),
              SizedBox(height: 2.h),
              Text(
                'Adventure Complete!',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'You completed "${path.pathName}"!',
                style: GoogleFonts.inter(
                  color: Colors.white70,
                  fontSize: 12.sp,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 1.5.h),
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFD700).withAlpha(20),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
                    SizedBox(width: 2.w),
                    Text(
                      '+100 VP Bonus Earned!',
                      style: GoogleFonts.inter(
                        color: const Color(0xFFFFD700),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 2.h),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6C63FF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: Text(
                  'Awesome!',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 12.sp,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_activePath != null) return _buildPathDetailView();
    return _buildPathCarousel();
  }

  Widget _buildPathCarousel() {
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: CustomAppBar(
        title: 'Adventure Paths',
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_awesome, color: Colors.white70),
            onPressed: () {
              setState(() {
                _isLoading = true;
                _isGenerating = true;
                _paths = [];
              });
              _generatePaths();
            },
          ),
        ],
      ),
      body: _isLoading || _isGenerating
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(color: Color(0xFF6C63FF)),
                  SizedBox(height: 2.h),
                  Text(
                    _isGenerating
                        ? 'Generating personalized paths with AI...'
                        : 'Loading paths...',
                    style: GoogleFonts.inter(
                      color: Colors.white70,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your Adventure Paths',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    'AI-curated journeys tailored to your interests',
                    style: GoogleFonts.inter(
                      color: Colors.white54,
                      fontSize: 12.sp,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  ..._paths.map((path) => _buildPathCard(path)),
                ],
              ),
            ),
    );
  }

  Widget _buildPathCard(AdventurePath path) {
    return Card(
      color: const Color(0xFF1E1E2E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(path.pathIcon, style: TextStyle(fontSize: 16.sp)),
                SizedBox(width: 2.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        path.pathName,
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        path.themeDescription,
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 11.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (path.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50).withAlpha(30),
                      borderRadius: BorderRadius.circular(6.0),
                    ),
                    child: Text(
                      'Done',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF4CAF50),
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 1.5.h),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${path.completedItems}/${path.totalItems} items',
                        style: GoogleFonts.inter(
                          color: Colors.white54,
                          fontSize: 11.sp,
                        ),
                      ),
                      SizedBox(height: 0.5.h),
                      LinearProgressIndicator(
                        value: path.progress,
                        backgroundColor: const Color(0xFF2A2A3E),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          path.isCompleted
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFF6C63FF),
                        ),
                        minHeight: 6,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 3.w),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _activePath = path;
                      _activeItemIndex = path.completedItems;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF6C63FF),
                    padding: EdgeInsets.symmetric(
                      horizontal: 4.w,
                      vertical: 1.h,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                  ),
                  child: Text(
                    path.isCompleted
                        ? 'View'
                        : path.isStarted
                        ? 'Continue'
                        : 'Start',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPathDetailView() {
    final path = _activePath!;
    return Scaffold(
      backgroundColor: const Color(0xFF0F0F1A),
      appBar: CustomAppBar(
        title: path.pathName,
        onBackPressed: () => setState(() => _activePath = null),
      ),
      body: Column(
        children: [
          Container(
            margin: EdgeInsets.all(3.w),
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF3F3D56)],
              ),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Text(path.pathIcon, style: TextStyle(fontSize: 16.sp)),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        path.themeDescription,
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 11.sp,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 1.5.h),
                // Step indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: path.contentItems
                      .asMap()
                      .entries
                      .map(
                        (e) => Container(
                          margin: EdgeInsets.symmetric(horizontal: 1.w),
                          width: e.key == _activeItemIndex ? 20 : 10,
                          height: 8,
                          decoration: BoxDecoration(
                            color: e.key < path.completedItems
                                ? const Color(0xFF4CAF50)
                                : e.key == _activeItemIndex
                                ? Colors.white
                                : Colors.white24,
                            borderRadius: BorderRadius.circular(4.0),
                          ),
                        ),
                      )
                      .toList(),
                ),
                SizedBox(height: 1.h),
                Text(
                  '${path.completedItems}/${path.totalItems} completed',
                  style: GoogleFonts.inter(
                    color: Colors.white70,
                    fontSize: 11.sp,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 3.w),
              itemCount: path.contentItems.length,
              itemBuilder: (ctx, i) {
                final item = path.contentItems[i];
                final isCompleted = i < path.completedItems;
                final isCurrent = i == _activeItemIndex;
                final isLocked = i > _activeItemIndex;

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (i > 0 && item['narrative_connector'] != null)
                      Padding(
                        padding: EdgeInsets.symmetric(vertical: 1.h),
                        child: Row(
                          children: [
                            Container(
                              width: 2,
                              height: 3.h,
                              color: isCompleted
                                  ? const Color(0xFF4CAF50)
                                  : Colors.white12,
                              margin: EdgeInsets.only(left: 5.w),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Text(
                                item['narrative_connector']?.toString() ?? '',
                                style: GoogleFonts.inter(
                                  color: Colors.white38,
                                  fontSize: 11.sp,
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    Card(
                      color: isCurrent
                          ? const Color(0xFF2A2A3E)
                          : const Color(0xFF1E1E2E),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10.0),
                        side: BorderSide(
                          color: isCurrent
                              ? const Color(0xFF6C63FF)
                              : isCompleted
                              ? const Color(0xFF4CAF50)
                              : Colors.transparent,
                        ),
                      ),
                      margin: EdgeInsets.only(bottom: 1.h),
                      child: Padding(
                        padding: EdgeInsets.all(3.w),
                        child: Row(
                          children: [
                            Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: isCompleted
                                    ? const Color(0xFF4CAF50).withAlpha(30)
                                    : isCurrent
                                    ? const Color(0xFF6C63FF).withAlpha(30)
                                    : const Color(0xFF2A2A3E),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: isCompleted
                                    ? const Icon(
                                        Icons.check,
                                        color: Color(0xFF4CAF50),
                                        size: 18,
                                      )
                                    : isLocked
                                    ? const Icon(
                                        Icons.lock,
                                        color: Colors.white38,
                                        size: 18,
                                      )
                                    : Text(
                                        _getItemIcon(
                                          item['type']?.toString() ?? 'post',
                                        ),
                                        style: TextStyle(fontSize: 14.sp),
                                      ),
                              ),
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item['title']?.toString() ??
                                        'Complete task',
                                    style: GoogleFonts.inter(
                                      color: isLocked
                                          ? Colors.white38
                                          : Colors.white,
                                      fontSize: 12.sp,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    _getItemTypeLabel(
                                      item['type']?.toString() ?? 'post',
                                    ),
                                    style: GoogleFonts.inter(
                                      color: Colors.white38,
                                      fontSize: 10.sp,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCurrent)
                              ElevatedButton(
                                onPressed: () => _completeItem(path, i),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF6C63FF),
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 3.w,
                                    vertical: 0.8.h,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(6.0),
                                  ),
                                ),
                                child: Text(
                                  '+5 VP',
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 10.sp,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              )
                            else if (isCompleted)
                              Text(
                                '+5 VP',
                                style: GoogleFonts.inter(
                                  color: const Color(0xFF4CAF50),
                                  fontSize: 10.sp,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _getItemIcon(String type) {
    switch (type) {
      case 'election':
        return '\\u{1F5F3}';
      case 'prediction':
        return '\\u{1F52E}';
      case 'jolt':
        return '\\u26A1';
      case 'ad':
        return '\\u{1F4E2}';
      case 'post':
        return '\\u{1F4DD}';
      default:
        return '\\u2728';
    }
  }

  String _getItemTypeLabel(String type) {
    switch (type) {
      case 'election':
        return 'Vote in election';
      case 'prediction':
        return 'Make prediction';
      case 'jolt':
        return 'Watch Jolt';
      case 'ad':
        return 'Engage with ad';
      case 'post':
        return 'Social post';
      default:
        return 'Complete task';
    }
  }
}