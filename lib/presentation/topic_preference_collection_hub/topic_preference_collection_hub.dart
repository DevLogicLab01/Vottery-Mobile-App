import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../routes/app_routes.dart';
import '../../services/topic_preference_service.dart';
import './widgets/preference_summary_widget.dart';
import './widgets/progress_indicator_widget.dart';
import './widgets/swipeable_topic_card_widget.dart';

/// Topic Preference Collection Hub
/// Swipeable onboarding cards for cold-start recommendation system.
/// When opened with [fromOnboarding] (e.g. after signup), finishes to social feed; otherwise to vote dashboard.
class TopicPreferenceCollectionHub extends StatefulWidget {
  const TopicPreferenceCollectionHub({super.key});

  @override
  State<TopicPreferenceCollectionHub> createState() =>
      _TopicPreferenceCollectionHubState();
}

class _TopicPreferenceCollectionHubState
    extends State<TopicPreferenceCollectionHub> {
  final TopicPreferenceService _service = TopicPreferenceService.instance;

  List<Map<String, dynamic>> _categories = [];
  int _currentIndex = 0;
  final List<String> _selectedCategories = [];
  bool _isLoading = true;
  bool _showSummary = false;
  final DateTime _startTime = DateTime.now();
  int _skipCount = 0;
  int _backCount = 0;
  int _totalInteractions = 0;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    setState(() => _isLoading = true);

    final categories = await _service.getTopicCategories();

    setState(() {
      _categories = categories;
      _isLoading = false;
    });
  }

  void _handleSwipe(String direction, double velocity, int dwellTimeMs) async {
    if (_currentIndex >= _categories.length) return;

    final category = _categories[_currentIndex];
    _totalInteractions++;

    // Track swipe
    await _service.trackSwipe(
      topicCategoryId: category['id'],
      swipeDirection: direction,
      swipeVelocity: velocity,
      dwellTimeMs: dwellTimeMs,
    );

    // Add to selected if positive swipe
    if (direction == 'right' || direction == 'up') {
      if (!_selectedCategories.contains(category['id'])) {
        _selectedCategories.add(category['id']);
      }
    }

    // Move to next card
    if (_currentIndex < _categories.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _completeOnboarding();
    }
  }

  void _handleSkip() {
    _skipCount++;
    _totalInteractions++;

    if (_currentIndex < _categories.length - 1) {
      setState(() => _currentIndex++);
    } else {
      _completeOnboarding();
    }
  }

  void _handleBack() {
    if (_currentIndex > 0) {
      _backCount++;
      _totalInteractions++;
      setState(() => _currentIndex--);
    }
  }

  Future<void> _completeOnboarding() async {
    final completionTime = DateTime.now().difference(_startTime).inSeconds;
    final completionPercentage =
        (_selectedCategories.length / _categories.length) * 100;

    // Get user preferences for persona clustering
    final preferences = await _service.getUserTopicPreferences();
    final personaCluster = _service.calculatePersonaCluster(preferences);

    // Update preference summary
    await _service.updatePreferenceSummary(
      selectedCategories: _selectedCategories,
      completionPercentage: completionPercentage,
      onboardingCompleted: true,
      personaCluster: personaCluster,
      confidenceScore: completionPercentage / 100,
    );

    // Track analytics
    await _service.trackOnboardingAnalytics(
      variant: 'swipe_based',
      completionTimeSeconds: completionTime,
      skipCount: _skipCount,
      backNavigationCount: _backCount,
      totalInteractions: _totalInteractions,
      completed: true,
    );

    setState(() => _showSummary = true);
  }

  void _finishOnboarding() {
    final fromOnboarding = ModalRoute.of(context)?.settings.arguments
        is Map
        ? (ModalRoute.of(context)!.settings.arguments as Map)['fromOnboarding'] == true
        : false;

    _service.markTopicOnboardingCompleted();

    if (fromOnboarding) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.socialMediaHomeFeed);
    } else {
      Navigator.of(context).pushReplacementNamed(AppRoutes.voteDashboard);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: Center(
          child: CircularProgressIndicator(color: theme.colorScheme.primary),
        ),
      );
    }

    if (_showSummary) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: PreferenceSummaryWidget(
          selectedCategories: _selectedCategories,
          categories: _categories,
          onFinish: _finishOnboarding,
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Discover Your Interests',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w700,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                  TextButton(
                    onPressed: _handleSkip,
                    child: Text(
                      'Skip',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress Indicator
            ProgressIndicatorWidget(
              current: _currentIndex + 1,
              total: _categories.length,
            ),

            SizedBox(height: 2.h),

            // Instructions
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                'Swipe right if interested, left if not. Swipe up for super like!',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 13.sp,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ),

            SizedBox(height: 3.h),

            // Swipeable Card
            Expanded(
              child: _currentIndex < _categories.length
                  ? SwipeableTopicCardWidget(
                      category: _categories[_currentIndex],
                      onSwipe: _handleSwipe,
                    )
                  : const SizedBox.shrink(),
            ),

            // Navigation Controls
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Back Button
                  IconButton(
                    onPressed: _currentIndex > 0 ? _handleBack : null,
                    icon: Icon(
                      Icons.arrow_back,
                      size: 8.w,
                      color: _currentIndex > 0
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.3),
                    ),
                  ),

                  // Dislike Button
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.red, width: 2),
                    ),
                    child: IconButton(
                      onPressed: () => _handleSwipe('left', 500, 1000),
                      icon: Icon(Icons.close, size: 8.w, color: Colors.red),
                    ),
                  ),

                  // Like Button
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.green, width: 2),
                    ),
                    child: IconButton(
                      onPressed: () => _handleSwipe('right', 1000, 2000),
                      icon: Icon(
                        Icons.favorite,
                        size: 8.w,
                        color: Colors.green,
                      ),
                    ),
                  ),

                  // Super Like Button
                  Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 2),
                    ),
                    child: IconButton(
                      onPressed: () => _handleSwipe('up', 1500, 3000),
                      icon: Icon(Icons.star, size: 8.w, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}