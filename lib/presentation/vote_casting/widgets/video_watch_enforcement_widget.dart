import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:video_player/video_player.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

import '../../../core/app_export.dart';
import '../../../services/video_watch_service.dart';
import '../../../theme/app_theme.dart';

/// Video Watch Enforcement Widget for vote casting
class VideoWatchEnforcementWidget extends StatefulWidget {
  final String electionId;
  final List<String> videoUrls;
  final int minWatchSeconds;
  final int minWatchPercentage;
  final String enforcementType;
  final Function(bool completed) onCompleted;

  const VideoWatchEnforcementWidget({
    super.key,
    required this.electionId,
    required this.videoUrls,
    required this.minWatchSeconds,
    required this.minWatchPercentage,
    required this.enforcementType,
    required this.onCompleted,
  });

  @override
  State<VideoWatchEnforcementWidget> createState() =>
      _VideoWatchEnforcementWidgetState();
}

class _VideoWatchEnforcementWidgetState
    extends State<VideoWatchEnforcementWidget> {
  final VideoWatchService _watchService = VideoWatchService.instance;

  int _currentVideoIndex = 0;
  VideoPlayerController? _controller;
  bool _isInitializing = true;
  int _watchedSeconds = 0;
  bool _isCompleted = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  Future<void> _initializeVideo() async {
    setState(() => _isInitializing = true);

    // Load existing progress
    final progress = await _watchService.getWatchProgress(
      electionId: widget.electionId,
      videoIndex: _currentVideoIndex,
    );

    if (progress != null) {
      _watchedSeconds = progress['watch_duration_seconds'] as int? ?? 0;
      _isCompleted = progress['completed_requirement'] as bool? ?? false;
    }

    // Initialize video player
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrls[_currentVideoIndex]),
    );

    await _controller!.initialize();

    // Start from last watched position
    if (_watchedSeconds > 0) {
      await _controller!.seekTo(Duration(seconds: _watchedSeconds));
    }

    _controller!.addListener(_onVideoProgress);

    setState(() => _isInitializing = false);

    // Auto-play
    _controller!.play();
  }

  void _onVideoProgress() {
    if (_controller == null || !_controller!.value.isInitialized) return;

    final currentPosition = _controller!.value.position.inSeconds;
    if (currentPosition > _watchedSeconds) {
      _watchedSeconds = currentPosition;
      _updateProgress();
    }
  }

  Future<void> _updateProgress() async {
    final totalDuration = _controller!.value.duration.inSeconds;

    await _watchService.updateWatchProgress(
      electionId: widget.electionId,
      videoIndex: _currentVideoIndex,
      watchDurationSeconds: _watchedSeconds,
      totalVideoDurationSeconds: totalDuration,
    );

    // Check if requirement met
    final remaining = _watchService.calculateRemainingTime(
      currentWatchSeconds: _watchedSeconds,
      totalDurationSeconds: totalDuration,
      minWatchSeconds: widget.minWatchSeconds,
      minWatchPercentage: widget.minWatchPercentage,
      enforcementType: widget.enforcementType,
    );

    if (remaining['is_completed'] == true && !_isCompleted) {
      setState(() => _isCompleted = true);

      // Check if all videos completed
      final allCompleted = await _watchService.hasCompletedAllVideos(
        widget.electionId,
      );
      if (allCompleted) {
        widget.onCompleted(true);
      }
    }
  }

  void _nextVideo() {
    if (_currentVideoIndex < widget.videoUrls.length - 1) {
      _controller?.dispose();
      setState(() {
        _currentVideoIndex++;
        _watchedSeconds = 0;
        _isCompleted = false;
      });
      _initializeVideo();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isInitializing) {
      return Center(child: CircularProgressIndicator());
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(),
        SizedBox(height: 2.h),
        _buildVideoPlayer(),
        SizedBox(height: 2.h),
        _buildProgressIndicator(),
        SizedBox(height: 2.h),
        if (_isCompleted && _currentVideoIndex < widget.videoUrls.length - 1)
          _buildNextButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.play_circle, color: AppTheme.primaryLight, size: 6.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  'Watch Required Video',
                  style: google_fonts.GoogleFonts.inter(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            'Video ${_currentVideoIndex + 1} of ${widget.videoUrls.length}',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 11.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoPlayer() {
    return AspectRatio(
      aspectRatio: _controller!.value.aspectRatio,
      child: Stack(
        alignment: Alignment.center,
        children: [
          VideoPlayer(_controller!),
          if (!_controller!.value.isPlaying)
            IconButton(
              icon: Icon(Icons.play_arrow, color: Colors.white, size: 15.w),
              onPressed: () => _controller!.play(),
            ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: VideoProgressIndicator(
              _controller!,
              allowScrubbing: false,
              colors: VideoProgressColors(
                playedColor: AppTheme.accentLight,
                bufferedColor: Colors.grey.shade400,
                backgroundColor: Colors.grey.shade800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final totalDuration = _controller!.value.duration.inSeconds;
    final remaining = _watchService.calculateRemainingTime(
      currentWatchSeconds: _watchedSeconds,
      totalDurationSeconds: totalDuration,
      minWatchSeconds: widget.minWatchSeconds,
      minWatchPercentage: widget.minWatchPercentage,
      enforcementType: widget.enforcementType,
    );

    final progressPercentage = remaining['progress_percentage'] as double;
    final isCompleted = remaining['is_completed'] as bool;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: isCompleted ? Colors.green.shade50 : Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: isCompleted ? Colors.green : Colors.orange),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isCompleted ? Icons.check_circle : Icons.access_time,
                color: isCompleted ? Colors.green : Colors.orange,
                size: 5.w,
              ),
              SizedBox(width: 2.w),
              Expanded(
                child: Text(
                  isCompleted
                      ? 'Watch requirement completed!'
                      : 'Keep watching to unlock voting',
                  style: google_fonts.GoogleFonts.inter(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                    color: isCompleted
                        ? Colors.green.shade700
                        : Colors.orange.shade700,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 1.h),
          LinearProgressIndicator(
            value: progressPercentage / 100,
            backgroundColor: Colors.grey.shade300,
            valueColor: AlwaysStoppedAnimation<Color>(
              isCompleted ? Colors.green : Colors.orange,
            ),
          ),
          SizedBox(height: 0.5.h),
          Text(
            widget.enforcementType == 'seconds'
                ? 'Watched: $_watchedSeconds / ${widget.minWatchSeconds} seconds'
                : 'Progress: ${(_watchedSeconds / totalDuration * 100).toStringAsFixed(0)}% / ${widget.minWatchPercentage}%',
            style: google_fonts.GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNextButton() {
    return ElevatedButton(
      onPressed: _nextVideo,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.accentLight,
        foregroundColor: Colors.white,
        minimumSize: Size(double.infinity, 6.h),
      ),
      child: Text(
        'Next Video',
        style: google_fonts.GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
