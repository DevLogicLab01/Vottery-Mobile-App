import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../services/supabase_service.dart';

class InteractiveOnboardingToursHub extends StatefulWidget {
  const InteractiveOnboardingToursHub({super.key});

  @override
  State<InteractiveOnboardingToursHub> createState() =>
      _InteractiveOnboardingToursHubState();
}

class _InteractiveOnboardingToursHubState
    extends State<InteractiveOnboardingToursHub> {
  final _supabaseService = SupabaseService.instance;
  bool _isLoading = true;
  Map<String, dynamic> _tourProgress = {};

  final List<Map<String, dynamic>> _availableTours = [
    {
      'id': 'profile_menu',
      'name': 'Profile Menu Tour',
      'description':
          'Learn about profile features, tier badges, earnings tracking, and settings',
      'icon': Icons.person_outline,
      'steps': 4,
      'estimatedTime': '2 min',
    },
    {
      'id': 'voting_mechanics',
      'name': 'Voting Mechanics Tour',
      'description':
          'Understand how to vote, earn VP, and view real-time results',
      'icon': Icons.how_to_vote_outlined,
      'steps': 4,
      'estimatedTime': '2 min',
    },
    {
      'id': 'creator_tools',
      'name': 'Creator Tools Tour',
      'description':
          'Discover content creation, analytics, earnings, and tier progression',
      'icon': Icons.create_outlined,
      'steps': 4,
      'estimatedTime': '3 min',
    },
    {
      'id': 'ai_features',
      'name': 'AI Features Tour',
      'description':
          'Explore AI moderation, fraud detection, and revenue optimization',
      'icon': Icons.psychology_outlined,
      'steps': 3,
      'estimatedTime': '2 min',
    },
    {
      'id': 'carousel_usage',
      'name': 'Carousel Usage Tour',
      'description':
          'Master feed navigation with horizontal and vertical carousels',
      'icon': Icons.view_carousel_outlined,
      'steps': 3,
      'estimatedTime': '2 min',
    },
    {
      'id': 'marketplace',
      'name': 'Marketplace Tour',
      'description':
          'Browse creator services, make purchases, and manage transactions',
      'icon': Icons.store_outlined,
      'steps': 3,
      'estimatedTime': '2 min',
    },
    {
      'id': 'messaging',
      'name': 'Messaging Tour',
      'description':
          'Learn about conversations, media sharing, and communication features',
      'icon': Icons.message_outlined,
      'steps': 3,
      'estimatedTime': '2 min',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadTourProgress();
  }

  Future<void> _loadTourProgress() async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final response = await _supabaseService.client
          .from('user_onboarding_progress')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        setState(() {
          _tourProgress = {
            'profile_menu': response['profile_tour_completed'] ?? false,
            'voting_mechanics': response['voting_tour_completed'] ?? false,
            'creator_tools': response['creator_tour_completed'] ?? false,
            'ai_features': response['ai_tour_completed'] ?? false,
            'carousel_usage': response['carousel_tour_completed'] ?? false,
            'marketplace': response['marketplace_tour_completed'] ?? false,
            'messaging': response['messaging_tour_completed'] ?? false,
          };
        });
      }
    } catch (e) {
      debugPrint('Error loading tour progress: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startTour(String tourId) async {
    HapticFeedback.mediumImpact();

    // Navigate to appropriate screen based on tour
    String route = '';
    switch (tourId) {
      case 'profile_menu':
        route = '/facebookStyleProfileMenu';
        break;
      case 'voting_mechanics':
        route = '/voteDashboard';
        break;
      case 'creator_tools':
        route = '/creatorStudioDashboard';
        break;
      case 'ai_features':
        route = '/aiSecurityDashboard';
        break;
      case 'carousel_usage':
        route = '/socialMediaHomeFeed';
        break;
      case 'marketplace':
        route = '/creatorMarketplaceStore';
        break;
      case 'messaging':
        route = '/enhancedDirectMessagingScreen';
        break;
    }

    if (route.isNotEmpty) {
      await Navigator.pushNamed(
        context,
        route,
        arguments: {'startTour': true, 'tourId': tourId},
      );
      // Reload progress after returning
      _loadTourProgress();
    }
  }

  Future<void> _resetTour(String tourId) async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      final fieldName = '${tourId}_tour_completed';
      await _supabaseService.client
          .from('user_onboarding_progress')
          .update({fieldName: false})
          .eq('user_id', userId);

      HapticFeedback.lightImpact();
      _loadTourProgress();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tour reset successfully')),
        );
      }
    } catch (e) {
      debugPrint('Error resetting tour: $e');
    }
  }

  Future<void> _disableAllTours() async {
    try {
      final userId = _supabaseService.client.auth.currentUser?.id;
      if (userId == null) return;

      await _supabaseService.client
          .from('user_onboarding_progress')
          .update({'tours_disabled': true})
          .eq('user_id', userId);

      HapticFeedback.mediumImpact();

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('All tours disabled')));
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error disabling tours: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Interactive Tours'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Tour Settings'),
                  content: const Text(
                    'Disable all tutorial hints and tours? You can re-enable them later from settings.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _disableAllTours();
                      },
                      child: const Text('Disable All'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Container(
                    padding: EdgeInsets.all(4.w),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Theme.of(context).primaryColor.withAlpha(26),
                          Theme.of(context).primaryColor.withAlpha(13),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.school_outlined,
                              size: 32,
                              color: Theme.of(context).primaryColor,
                            ),
                            SizedBox(width: 3.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Welcome to Guided Tours',
                                    style: TextStyle(
                                      fontSize: 18.sp,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(height: 0.5.h),
                                  Text(
                                    'Learn platform features with interactive walkthroughs',
                                    style: TextStyle(
                                      fontSize: 14.sp,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 2.h),
                        _buildProgressSummary(),
                      ],
                    ),
                  ),
                  SizedBox(height: 3.h),

                  // Tour Cards
                  Text(
                    'Available Tours',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2.h),

                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _availableTours.length,
                    separatorBuilder: (context, index) => SizedBox(height: 2.h),
                    itemBuilder: (context, index) {
                      final tour = _availableTours[index];
                      final isCompleted = _tourProgress[tour['id']] ?? false;

                      return _buildTourCard(tour, isCompleted);
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProgressSummary() {
    final completedCount = _tourProgress.values.where((v) => v == true).length;
    final totalCount = _availableTours.length;
    final progress = totalCount > 0 ? completedCount / totalCount : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Progress',
              style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
            ),
            Text(
              '$completedCount / $totalCount completed',
              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(
              Theme.of(context).primaryColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTourCard(Map<String, dynamic> tour, bool isCompleted) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: isCompleted
            ? BorderSide(color: Colors.green, width: 2)
            : BorderSide.none,
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(2.w),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.green.withAlpha(26)
                        : Theme.of(context).primaryColor.withAlpha(26),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    tour['icon'],
                    size: 28,
                    color: isCompleted
                        ? Colors.green
                        : Theme.of(context).primaryColor,
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              tour['name'],
                              style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          if (isCompleted)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.5.h,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.check_circle,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  SizedBox(width: 1.w),
                                  Text(
                                    'Completed',
                                    style: TextStyle(
                                      fontSize: 12.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 0.5.h),
                      Text(
                        tour['description'],
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Icon(Icons.layers_outlined, size: 16, color: Colors.grey[600]),
                SizedBox(width: 1.w),
                Text(
                  '${tour['steps']} steps',
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
                SizedBox(width: 3.w),
                Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                SizedBox(width: 1.w),
                Text(
                  tour['estimatedTime'],
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                ),
                const Spacer(),
                if (isCompleted)
                  TextButton.icon(
                    onPressed: () => _resetTour(tour['id']),
                    icon: const Icon(Icons.replay, size: 18),
                    label: const Text('Replay'),
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).primaryColor,
                    ),
                  )
                else
                  ElevatedButton.icon(
                    onPressed: () => _startTour(tour['id']),
                    icon: const Icon(Icons.play_arrow, size: 18),
                    label: const Text('Start Tour'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8.0),
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
}