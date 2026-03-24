import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/creator_academy_service.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/achievement_badge_widget.dart';
import './widgets/module_card_widget.dart';
import './widgets/progress_header_widget.dart';
import './widgets/tier_progression_widget.dart';
import './widgets/video_tutorial_card_widget.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';

/// Creator Success Academy - Progressive 5-tier onboarding system
/// Provides video tutorials, interactive quizzes, achievement tracking,
/// and certifications for content creators in the ecosystem
class CreatorSuccessAcademy extends StatefulWidget {
  const CreatorSuccessAcademy({super.key});

  @override
  State<CreatorSuccessAcademy> createState() => _CreatorSuccessAcademyState();
}

class _CreatorSuccessAcademyState extends State<CreatorSuccessAcademy>
    with SingleTickerProviderStateMixin {
  final CreatorAcademyService _academyService = CreatorAcademyService.instance;

  late TabController _tabController;

  bool _isLoading = true;
  Map<String, dynamic>? _creatorProgress;
  List<Map<String, dynamic>> _tiers = [];
  List<Map<String, dynamic>> _currentTierModules = [];
  List<Map<String, dynamic>> _achievements = [];
  List<Map<String, dynamic>> _unlockedAchievements = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
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
      final results = await Future.wait([
        _academyService.getCreatorProgress(),
        _academyService.getAcademyTiers(),
        _academyService.getAcademyAchievements(),
        _academyService.getUnlockedAchievements(),
      ]);

      final progress = results[0] as Map<String, dynamic>?;
      final tiers = results[1] as List<Map<String, dynamic>>;
      final achievements = results[2] as List<Map<String, dynamic>>;
      final unlocked = results[3] as List<Map<String, dynamic>>;

      if (progress != null) {
        final currentTier = progress['current_tier'] as String? ?? 'beginner';
        final modules = await _academyService.getModulesByTier(currentTier);

        setState(() {
          _creatorProgress = progress;
          _tiers = tiers;
          _currentTierModules = modules;
          _achievements = achievements;
          _unlockedAchievements = unlocked;
        });
      }
    } catch (e) {
      debugPrint('Load academy data error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshData() async {
    await _loadData();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ErrorBoundaryWrapper(
      screenName: 'CreatorSuccessAcademy',
      onRetry: _loadData,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: CustomAppBar(
            title: 'Creator Success Academy',
            variant: CustomAppBarVariant.standard,
            actions: [
              IconButton(
                icon: Icon(
                  Icons.refresh,
                  color: theme.appBarTheme.foregroundColor,
                ),
                onPressed: _refreshData,
              ),
            ],
          ),
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 6)
            : _currentTierModules.isEmpty
            ? Center(
                child: Padding(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school_outlined,
                        size: 20.w,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        'No Learning Modules',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 1.h),
                      Text(
                        'Educational content and tutorials will appear here.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 11.sp,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 2.h),
                      TextButton(onPressed: _loadData, child: Text('Refresh')),
                    ],
                  ),
                ),
              )
            : RefreshIndicator(
                onRefresh: _refreshData,
                color: theme.colorScheme.primary,
                child: Column(
                  children: [
                    if (_creatorProgress != null)
                      ProgressHeaderWidget(progress: _creatorProgress!),
                    TabBar(
                      controller: _tabController,
                      labelColor: theme.colorScheme.primary,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      indicatorColor: theme.colorScheme.primary,
                      isScrollable: true,
                      tabs: const [
                        Tab(text: 'Modules'),
                        Tab(text: 'Progression'),
                        Tab(text: 'Achievements'),
                        Tab(text: 'Certificates'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildModulesTab(theme),
                          _buildProgressionTab(theme),
                          _buildAchievementsTab(theme),
                          _buildCertificatesTab(theme),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildModulesTab(ThemeData theme) {
    if (_currentTierModules.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.school_outlined,
                size: 20.w,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              SizedBox(height: 2.h),
              Text(
                'No Modules Available',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 1.h),
              Text(
                'Complete your current tier to unlock more modules',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 11.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _currentTierModules.length,
      itemBuilder: (context, index) {
        final module = _currentTierModules[index];
        return ModuleCardWidget(
          module: module,
          onTap: () => _openModule(module),
        );
      },
    );
  }

  Widget _buildProgressionTab(ThemeData theme) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your Learning Path',
            style: theme.textTheme.titleLarge?.copyWith(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 2.h),
          TierProgressionWidget(
            tiers: _tiers,
            currentProgress: _creatorProgress,
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementsTab(ThemeData theme) {
    if (_achievements.isEmpty) {
      return Center(
        child: Text(
          'No achievements available',
          style: theme.textTheme.bodyMedium?.copyWith(fontSize: 12.sp),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(4.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 3.w,
        mainAxisSpacing: 2.h,
        childAspectRatio: 0.85,
      ),
      itemCount: _achievements.length,
      itemBuilder: (context, index) {
        final achievement = _achievements[index];
        final isUnlocked = _unlockedAchievements.any(
          (unlocked) => unlocked['achievement_id'] == achievement['id'],
        );
        return AchievementBadgeWidget(
          achievement: achievement,
          isUnlocked: isUnlocked,
        );
      },
    );
  }

  Widget _buildCertificatesTab(ThemeData theme) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _academyService.getCreatorCertifications(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: theme.colorScheme.primary),
          );
        }

        final certifications = snapshot.data ?? [];

        if (certifications.isEmpty) {
          return Center(
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.workspace_premium_outlined,
                    size: 20.w,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'No Certificates Yet',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Complete tier modules and pass quizzes to earn certificates',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 11.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(4.w),
          itemCount: certifications.length,
          itemBuilder: (context, index) {
            final cert = certifications[index];
            return _buildCertificateCard(theme, cert);
          },
        );
      },
    );
  }

  Widget _buildCertificateCard(ThemeData theme, Map<String, dynamic> cert) {
    final tierLevel = cert['tier_level'] as String? ?? 'beginner';
    final status = cert['certification_status'] as String? ?? 'not_earned';
    final issuedAt = cert['issued_at'] as String?;

    return Card(
      elevation: 2,
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Row(
          children: [
            Icon(
              status == 'certified'
                  ? Icons.verified
                  : Icons.workspace_premium_outlined,
              size: 12.w,
              color: status == 'certified'
                  ? Colors.amber
                  : theme.colorScheme.onSurfaceVariant,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_formatTierName(tierLevel)} Certificate',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    status == 'certified'
                        ? 'Issued: ${_formatDate(issuedAt)}'
                        : 'Status: ${_formatStatus(status)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 10.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            if (status == 'certified')
              IconButton(
                icon: const Icon(Icons.download),
                onPressed: () => _downloadCertificate(cert),
              ),
          ],
        ),
      ),
    );
  }

  void _openModule(Map<String, dynamic> module) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ModuleDetailScreen(module: module),
      ),
    );
  }

  void _downloadCertificate(Map<String, dynamic> cert) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Certificate download started'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatTierName(String tier) {
    return tier[0].toUpperCase() + tier.substring(1);
  }

  String _formatStatus(String status) {
    return status
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1))
        .join(' ');
  }

  String _formatDate(String? dateString) {
    if (dateString == null) return 'N/A';
    try {
      final date = DateTime.parse(dateString);
      return '${date.day}/${date.month}/${date.year}';
    } catch (e) {
      return 'N/A';
    }
  }
}

/// Module Detail Screen
class ModuleDetailScreen extends StatefulWidget {
  final Map<String, dynamic> module;

  const ModuleDetailScreen({super.key, required this.module});

  @override
  State<ModuleDetailScreen> createState() => _ModuleDetailScreenState();
}

class _ModuleDetailScreenState extends State<ModuleDetailScreen> {
  final CreatorAcademyService _academyService = CreatorAcademyService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _videos = [];
  Map<String, dynamic>? _quiz;

  @override
  void initState() {
    super.initState();
    _loadModuleContent();
  }

  Future<void> _loadModuleContent() async {
    setState(() => _isLoading = true);

    try {
      final moduleId = widget.module['id'] as String;
      final videos = await _academyService.getVideoTutorials(moduleId);
      final quiz = await _academyService.getModuleQuiz(moduleId);

      setState(() {
        _videos = videos;
        _quiz = quiz;
      });
    } catch (e) {
      debugPrint('Load module content error: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight),
        child: CustomAppBar(
          title: widget.module['module_title'] as String? ?? 'Module',
          variant: CustomAppBarVariant.standard,
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModuleInfo(theme),
                  SizedBox(height: 2.h),
                  if (_videos.isNotEmpty) ...[
                    Text(
                      'Video Tutorials',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 1.h),
                    ..._videos.map(
                      (video) => VideoTutorialCardWidget(
                        video: video,
                        onTap: () => _playVideo(video),
                      ),
                    ),
                    SizedBox(height: 2.h),
                  ],
                  if (_quiz != null) _buildQuizSection(theme),
                ],
              ),
            ),
    );
  }

  Widget _buildModuleInfo(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.module['module_title'] as String? ?? 'Module',
              style: theme.textTheme.titleLarge?.copyWith(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              widget.module['module_description'] as String? ??
                  'No description available',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  size: 4.w,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 1.w),
                Text(
                  '${widget.module['estimated_duration_minutes'] ?? 10} minutes',
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 10.sp,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuizSection(ThemeData theme) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  Icons.quiz_outlined,
                  size: 6.w,
                  color: theme.colorScheme.primary,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    _quiz!['quiz_title'] as String? ?? 'Module Quiz',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              _quiz!['quiz_description'] as String? ?? 'Test your knowledge',
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 11.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Passing Score: ${_quiz!['passing_score_percentage'] ?? 80}%',
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 10.sp,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 2.h),
            ElevatedButton(
              onPressed: () => _startQuiz(),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: Text(
                'Start Quiz',
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _playVideo(Map<String, dynamic> video) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Playing: ${video['video_title']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _startQuiz() {
    Navigator.of(
      context,
      rootNavigator: true,
    ).pushNamed(AppRoutes.mcqAbTestingAnalyticsDashboard);
  }
}
