import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../services/auth_service.dart';
import '../../services/moments_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/error_boundary_wrapper.dart';
import '../../widgets/shimmer_skeleton_loader.dart';
import '../../widgets/enhanced_empty_state_widget.dart';
import './widgets/moment_viewer_widget.dart' hide State;
import './widgets/moments_carousel_widget.dart';

/// Moments & Stories Hub - Full-screen ephemeral content sharing
/// Implements 24-hour story-like moments with camera integration, filters, and reactions
class MomentsStoriesHub extends StatefulWidget {
  const MomentsStoriesHub({super.key});

  @override
  State<MomentsStoriesHub> createState() => _MomentsStoriesHubState();
}

class _MomentsStoriesHubState extends State<MomentsStoriesHub> {
  final MomentsService _momentsService = MomentsService.instance;
  final AuthService _authService = AuthService.instance;

  bool _isLoading = true;
  List<Map<String, dynamic>> _moments = [];
  List<Map<String, dynamic>> _myMoments = [];
  int _currentMomentIndex = 0;
  bool _showCreator = false;
  List<CameraDescription>? _cameras;

  @override
  void initState() {
    super.initState();
    _initializeCameras();
    _loadMoments();
  }

  Future<void> _initializeCameras() async {
    try {
      _cameras = await availableCameras();
    } catch (e) {
      debugPrint('Initialize cameras error: $e');
    }
  }

  Future<void> _loadMoments() async {
    setState(() => _isLoading = true);

    try {
      final results = await Future.wait([
        _momentsService.getFollowingMoments(),
        _momentsService.getMyMoments(),
      ]);

      setState(() {
        _moments = results[0];
        _myMoments = results[1];
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Load moments error: $e');
      setState(() => _isLoading = false);
    }
  }

  void _openCreator() {
    setState(() => _showCreator = true);
  }

  void _closeCreator() {
    setState(() => _showCreator = false);
    _loadMoments();
  }

  void _viewMoment(int index) {
    setState(() => _currentMomentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return ErrorBoundaryWrapper(
      screenName: 'MomentsStoriesHub',
      onRetry: _loadMoments,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: Text('Moments'),
          actions: [
            IconButton(
              icon: Icon(
                Icons.add_circle_outline,
                color: AppTheme.vibrantYellow,
              ),
              onPressed: _openCreator,
            ),
          ],
        ),
        body: _isLoading
            ? const SkeletonList(itemCount: 6)
            : _moments.isEmpty
            ? NoDataEmptyState(
                title: 'No Moments',
                description: 'Create and share moments with your followers.',
                onRefresh: _loadMoments,
              )
            : RefreshIndicator(
                onRefresh: _loadMoments,
                child: _moments.isEmpty && _myMoments.isEmpty
                    ? _buildEmptyState()
                    : Column(
                        children: [
                          _buildHeader(),
                          MomentsCarouselWidget(
                            myMoments: _myMoments,
                            followingMoments: _moments,
                            onCreateTap: _openCreator,
                            onMomentTap: _viewMoment,
                          ),
                          Expanded(
                            child: _moments.isNotEmpty
                                ? MomentViewerWidget(
                                    moments: _moments,
                                    initialIndex: _currentMomentIndex,
                                    onClose: () => Navigator.pop(context),
                                  )
                                : _buildNoMomentsView(),
                          ),
                        ],
                      ),
              ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white, size: 6.w),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            'Moments',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.add_circle_outline,
              color: AppTheme.vibrantYellow,
              size: 6.w,
            ),
            onPressed: _openCreator,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.auto_stories_outlined,
            size: 20.w,
            color: Colors.white.withAlpha(128),
          ),
          SizedBox(height: 2.h),
          Text(
            'No Moments Yet',
            style: TextStyle(
              fontSize: 18.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Share your first moment with friends',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withAlpha(179),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: _openCreator,
            icon: Icon(Icons.add, size: 5.w),
            label: Text('Create Moment'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.vibrantYellow,
              foregroundColor: Colors.black,
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 1.5.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoMomentsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.visibility_off_outlined,
            size: 15.w,
            color: Colors.white.withAlpha(128),
          ),
          SizedBox(height: 2.h),
          Text(
            'No Active Moments',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Follow more people to see their moments',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white.withAlpha(179),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
