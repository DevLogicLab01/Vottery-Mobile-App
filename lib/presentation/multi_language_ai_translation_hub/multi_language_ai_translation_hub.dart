import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../services/auth_service.dart';
import '../../services/language_service.dart';
import '../../services/supabase_service.dart';
import './widgets/language_configuration_widget.dart';
import './widgets/real_time_translation_engine_widget.dart';
import './widgets/rtl_language_support_widget.dart';
import './widgets/translation_cache_management_widget.dart';
import './widgets/translation_status_overview_widget.dart';
import './widgets/auto_detection_system_widget.dart';

class MultiLanguageAiTranslationHub extends StatefulWidget {
  const MultiLanguageAiTranslationHub({super.key});

  @override
  State<MultiLanguageAiTranslationHub> createState() =>
      _MultiLanguageAiTranslationHubState();
}

class _MultiLanguageAiTranslationHubState
    extends State<MultiLanguageAiTranslationHub>
    with SingleTickerProviderStateMixin {
  final AuthService _auth = AuthService.instance;
  final LanguageService _languageService = LanguageService.instance;
  final _client = SupabaseService.instance.client;

  late TabController _tabController;
  bool _isLoading = true;
  Map<String, dynamic> _translationMetrics = {};
  List<Map<String, dynamic>> _activeLanguages = [];
  Map<String, dynamic>? _cacheStats;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    _loadTranslationData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadTranslationData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      // Load translation metrics
      final metricsResponse = await _client
          .from('translation_metrics')
          .select()
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();

      // Load active languages
      final languagesResponse = await _client
          .from('active_translation_languages')
          .select()
          .eq('is_enabled', true)
          .order('usage_count', ascending: false);

      // Load cache statistics
      final cacheResponse = await _client.rpc('get_translation_cache_stats');

      if (mounted) {
        setState(() {
          _translationMetrics = metricsResponse ?? {};
          _activeLanguages = List<Map<String, dynamic>>.from(languagesResponse);
          _cacheStats = cacheResponse;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Load translation data error: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Multi-Language AI Translation Hub',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Language Config'),
            Tab(text: 'Translation Engine'),
            Tab(text: 'RTL Support'),
            Tab(text: 'Cache Management'),
            Tab(text: 'Auto-Detection'),
          ],
        ),
      ),
      drawer: _buildNavigationDrawer(),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Loading translation hub...',
                    style: TextStyle(
                      fontSize: 14.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildLanguageConfigTab(),
                _buildTranslationEngineTab(),
                _buildRtlSupportTab(),
                _buildCacheManagementTab(),
                _buildAutoDetectionTab(),
              ],
            ),
    );
  }

  Widget _buildNavigationDrawer() {
    final theme = Theme.of(context);

    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withAlpha(179),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Icon(Icons.translate, color: Colors.white, size: 40.sp),
                SizedBox(height: 2.h),
                Text(
                  'Translation Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Content Administrator',
                  style: TextStyle(
                    color: Colors.white.withAlpha(204),
                    fontSize: 12.sp,
                  ),
                ),
              ],
            ),
          ),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () => Navigator.pop(context),
          ),
          _buildDrawerItem(
            icon: Icons.language,
            title: 'Language Settings',
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(1);
            },
          ),
          _buildDrawerItem(
            icon: Icons.auto_awesome,
            title: 'AI Translation',
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(2);
            },
          ),
          _buildDrawerItem(
            icon: Icons.storage,
            title: 'Cache Management',
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(4);
            },
          ),
          const Divider(),
          _buildDrawerItem(
            icon: Icons.analytics,
            title: 'Analytics',
            onTap: () {},
          ),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {},
          ),
        ],
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(
        title,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w500),
      ),
      onTap: onTap,
    );
  }

  Widget _buildOverviewTab() {
    return RefreshIndicator(
      onRefresh: _loadTranslationData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TranslationStatusOverviewWidget(
              activeLanguages: _activeLanguages.length,
              cacheHitRate: _cacheStats?['hit_rate'] ?? 0.0,
              translationsToday: _translationMetrics['translations_today'] ?? 0,
              avgConfidenceScore:
                  _translationMetrics['avg_confidence_score'] ?? 0.0,
            ),
            SizedBox(height: 3.h),
            _buildMetricsGrid(),
            SizedBox(height: 3.h),
            _buildRecentTranslations(),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsGrid() {
    final theme = Theme.of(context);

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      crossAxisSpacing: 3.w,
      mainAxisSpacing: 2.h,
      childAspectRatio: 1.5,
      children: [
        _buildMetricCard(
          icon: Icons.speed,
          title: 'Avg Response Time',
          value: '${_translationMetrics['avg_response_time_ms'] ?? 0}ms',
          color: Colors.blue,
        ),
        _buildMetricCard(
          icon: Icons.check_circle,
          title: 'Success Rate',
          value:
              '${(_translationMetrics['success_rate'] ?? 0.0 * 100).toStringAsFixed(1)}%',
          color: Colors.green,
        ),
        _buildMetricCard(
          icon: Icons.error_outline,
          title: 'Failed Translations',
          value: '${_translationMetrics['failed_count'] ?? 0}',
          color: Colors.red,
        ),
        _buildMetricCard(
          icon: Icons.trending_up,
          title: 'API Usage',
          value: '${_translationMetrics['api_calls_today'] ?? 0}',
          color: Colors.orange,
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(color: color.withAlpha(51), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24.sp),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              Text(
                title,
                style: TextStyle(
                  fontSize: 11.sp,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTranslations() {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Translations',
          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
        ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(3.w),
          ),
          child: Column(
            children: [
              _buildTranslationItem(
                from: 'English',
                to: 'Arabic',
                confidence: 0.95,
                cached: true,
              ),
              Divider(height: 2.h),
              _buildTranslationItem(
                from: 'Spanish',
                to: 'Hebrew',
                confidence: 0.92,
                cached: false,
              ),
              Divider(height: 2.h),
              _buildTranslationItem(
                from: 'French',
                to: 'Urdu',
                confidence: 0.88,
                cached: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTranslationItem({
    required String from,
    required String to,
    required double confidence,
    required bool cached,
  }) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    from,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Icon(Icons.arrow_forward, size: 16.sp),
                  Text(
                    to,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 0.5.h),
              Row(
                children: [
                  Icon(Icons.verified, size: 14.sp, color: Colors.green),
                  SizedBox(width: 1.w),
                  Text(
                    '${(confidence * 100).toStringAsFixed(0)}% confidence',
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        if (cached)
          Container(
            padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
            decoration: BoxDecoration(
              color: Colors.blue.withAlpha(26),
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: Row(
              children: [
                Icon(Icons.cached, size: 12.sp, color: Colors.blue),
                SizedBox(width: 1.w),
                Text(
                  'Cached',
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildLanguageConfigTab() {
    return RefreshIndicator(
      onRefresh: _loadTranslationData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: LanguageConfigurationWidget(
          onLanguageToggled: _loadTranslationData,
        ),
      ),
    );
  }

  Widget _buildTranslationEngineTab() {
    return RefreshIndicator(
      onRefresh: _loadTranslationData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: RealTimeTranslationEngineWidget(
          onTranslationComplete: _loadTranslationData,
        ),
      ),
    );
  }

  Widget _buildRtlSupportTab() {
    return RefreshIndicator(
      onRefresh: _loadTranslationData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: const RtlLanguageSupportWidget(),
      ),
    );
  }

  Widget _buildCacheManagementTab() {
    return RefreshIndicator(
      onRefresh: _loadTranslationData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: TranslationCacheManagementWidget(
          cacheStats: _cacheStats,
          onCacheCleared: _loadTranslationData,
        ),
      ),
    );
  }

  Widget _buildAutoDetectionTab() {
    return RefreshIndicator(
      onRefresh: _loadTranslationData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.all(4.w),
        child: const AutoDetectionSystemWidget(),
      ),
    );
  }
}
