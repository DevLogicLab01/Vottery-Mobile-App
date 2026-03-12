import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../services/supabase_service.dart';
import '../../../services/auth_service.dart';
import '../../../widgets/shimmer_skeleton_loader.dart';
import '../../../widgets/enhanced_empty_state_widget.dart';

class GuidesTabWidget extends StatefulWidget {
  final VoidCallback onRefresh;

  const GuidesTabWidget({super.key, required this.onRefresh});

  @override
  State<GuidesTabWidget> createState() => _GuidesTabWidgetState();
}

class _GuidesTabWidgetState extends State<GuidesTabWidget> {
  final _client = SupabaseService.instance.client;
  final _auth = AuthService.instance;

  List<Map<String, dynamic>> _guides = [];
  Map<String, int> _categoryProgress = {};
  bool _isLoading = true;

  final Map<String, IconData> _categoryIcons = {
    'getting_started': Icons.school,
    'content_creation': Icons.create,
    'audience_growth': Icons.trending_up,
    'monetization': Icons.attach_money,
    'analytics': Icons.analytics,
    'best_practices': Icons.stars,
  };

  @override
  void initState() {
    super.initState();
    _loadGuides();
  }

  Future<void> _loadGuides() async {
    setState(() => _isLoading = true);

    try {
      // Load all guides
      final guides = await _client.from('guides').select().order('category');

      // Load user progress
      final progress = await _client
          .from('guide_progress')
          .select()
          .eq('user_id', _auth.currentUser!.id);

      // Calculate category progress
      final categoryProgress = <String, int>{};
      for (final guide in guides) {
        final category = guide['category'] as String;
        final completed = progress.any(
          (p) => p['guide_id'] == guide['id'] && p['completed'] == true,
        );
        categoryProgress[category] =
            (categoryProgress[category] ?? 0) + (completed ? 1 : 0);
      }

      setState(() {
        _guides = List<Map<String, dynamic>>.from(guides);
        _categoryProgress = categoryProgress;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load guides error: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return const SkeletonList(itemCount: 6);
    }

    if (_guides.isEmpty) {
      return NoDataEmptyState(
        title: 'No Guides Available',
        description: 'Check back later for creator success guides.',
        onRefresh: _loadGuides,
      );
    }

    // Group guides by category
    final categories = <String>{};
    for (final guide in _guides) {
      categories.add(guide['category'] as String);
    }

    return RefreshIndicator(
      onRefresh: _loadGuides,
      child: GridView.count(
        crossAxisCount: 2,
        padding: EdgeInsets.all(4.w),
        mainAxisSpacing: 3.w,
        crossAxisSpacing: 3.w,
        childAspectRatio: 0.85,
        children: categories.map((category) {
          final categoryGuides = _guides
              .where((g) => g['category'] == category)
              .toList();
          final completedCount = _categoryProgress[category] ?? 0;
          final totalCount = categoryGuides.length;
          final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

          return _buildCategoryCard(category, categoryGuides.length, progress);
        }).toList(),
      ),
    );
  }

  Widget _buildCategoryCard(String category, int guideCount, double progress) {
    final theme = Theme.of(context);
    final icon = _categoryIcons[category] ?? Icons.help;
    final title = _formatCategoryTitle(category);

    return Card(
      child: InkWell(
        onTap: () => _showCategoryGuides(category),
        borderRadius: BorderRadius.circular(12.0),
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withValues(alpha: 0.7),
              ],
            ),
            borderRadius: BorderRadius.circular(12.0),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 40.sp, color: Colors.white),
              SizedBox(height: 2.h),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1.h),
              Text(
                '$guideCount guides',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              SizedBox(height: 2.h),
              LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.white.withValues(alpha: 0.3),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              ),
              SizedBox(height: 1.h),
              Text(
                '${(progress * 100).toInt()}% complete',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatCategoryTitle(String category) {
    return category
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  void _showCategoryGuides(String category) {
    final categoryGuides = _guides
        .where((g) => g['category'] == category)
        .toList();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        builder: (context, scrollController) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(20.0),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(4.w),
                child: Column(
                  children: [
                    Container(
                      width: 40.w,
                      height: 0.5.h,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(10.0),
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      _formatCategoryTitle(category),
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  padding: EdgeInsets.all(4.w),
                  itemCount: categoryGuides.length,
                  itemBuilder: (context, index) {
                    return _buildGuideCard(categoryGuides[index]);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideCard(Map<String, dynamic> guide) {
    final theme = Theme.of(context);
    final difficulty = guide['difficulty'] as String;
    final difficultyColor = _getDifficultyColor(difficulty);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: InkWell(
        onTap: () => _showGuideDetail(guide),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      guide['title'],
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.w,
                      vertical: 0.5.h,
                    ),
                    decoration: BoxDecoration(
                      color: difficultyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: Text(
                      difficulty.toUpperCase(),
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        fontWeight: FontWeight.w600,
                        color: difficultyColor,
                      ),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                guide['description'] ?? '',
                style: GoogleFonts.inter(fontSize: 12.sp, color: Colors.grey),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 1.h),
              Row(
                children: [
                  Icon(Icons.access_time, size: 14.sp, color: Colors.grey),
                  SizedBox(width: 1.w),
                  Text(
                    '${guide['estimated_minutes']} min',
                    style: GoogleFonts.inter(
                      fontSize: 12.sp,
                      color: Colors.grey,
                    ),
                  ),
                  const Spacer(),
                  if (guide['reward_vp'] != null && guide['reward_vp'] > 0)
                    Row(
                      children: [
                        Icon(Icons.stars, size: 14.sp, color: Colors.amber),
                        SizedBox(width: 1.w),
                        Text(
                          '${guide['reward_vp']} VP',
                          style: GoogleFonts.inter(
                            fontSize: 12.sp,
                            color: Colors.amber,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'beginner':
        return Colors.green;
      case 'intermediate':
        return Colors.yellow[700]!;
      case 'advanced':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  void _showGuideDetail(Map<String, dynamic> guide) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening guide: ${guide['title']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
