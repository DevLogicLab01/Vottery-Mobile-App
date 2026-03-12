import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import 'package:video_player/video_player.dart';

import '../../../core/app_export.dart';
import '../../../services/moments_service.dart';
import '../../../widgets/custom_image_widget.dart';

/// Full-screen moment viewer with tap-to-advance, long-press to pause
class MomentViewerWidget extends StatefulWidget {
  final List<Map<String, dynamic>> moments;
  final int initialIndex;
  final VoidCallback onClose;

  const MomentViewerWidget({
    super.key,
    required this.moments,
    this.initialIndex = 0,
    required this.onClose,
  });

  @override
  State<MomentViewerWidget> createState() => _MomentViewerWidgetState();
}

class _MomentViewerWidgetState extends State<MomentViewerWidget> {
  final MomentsService momentsService = MomentsService.instance;
  late PageController pageController;
  int currentIndex = 0;
  Timer? progressTimer;
  double progress = 0.0;
  bool isPaused = false;
  VideoPlayerController? videoController;
  bool showReactions = false;
  List<Map<String, dynamic>> reactions = [];

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    pageController = PageController(initialPage: currentIndex);
    startProgress();
    recordView();
  }

  @override
  void dispose() {
    progressTimer?.cancel();
    videoController?.dispose();
    pageController.dispose();
    super.dispose();
  }

  Future<void> recordView() async {
    if (currentIndex < widget.moments.length) {
      final momentId = widget.moments[currentIndex]['id'] as String;
      await momentsService.recordView(momentId);
    }
  }

  void startProgress() {
    progressTimer?.cancel();
    progress = 0.0;

    final duration =
        widget.moments[currentIndex]['duration_seconds'] as int? ?? 5;

    progressTimer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
      if (!isPaused) {
        setState(() {
          progress += 0.05 / duration;
          if (progress >= 1.0) {
            nextMoment();
          }
        });
      }
    });
  }

  void nextMoment() {
    if (currentIndex < widget.moments.length - 1) {
      setState(() {
        currentIndex++;
        pageController.animateToPage(
          currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
      startProgress();
      recordView();
    } else {
      widget.onClose();
    }
  }

  void previousMoment() {
    if (currentIndex > 0) {
      setState(() {
        currentIndex--;
        pageController.animateToPage(
          currentIndex,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      });
      startProgress();
      recordView();
    }
  }

  void togglePause() {
    setState(() => isPaused = !isPaused);
  }

  Future<void> reactToMoment(String emoji) async {
    final momentId = widget.moments[currentIndex]['id'] as String;
    await momentsService.reactToMoment(momentId: momentId, emoji: emoji);
    setState(() => showReactions = false);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.moments.isEmpty) return const SizedBox.shrink();

    final moment = widget.moments[currentIndex];
    final creator = moment['creator'] as Map<String, dynamic>?;

    return GestureDetector(
      onTapDown: (details) {
        final width = MediaQuery.of(context).size.width;
        if (details.localPosition.dx < width / 3) {
          previousMoment();
        } else if (details.localPosition.dx > width * 2 / 3) {
          nextMoment();
        }
      },
      onLongPress: togglePause,
      onLongPressEnd: (_) => togglePause(),
      child: Stack(
        children: [
          PageView.builder(
            controller: pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: widget.moments.length,
            itemBuilder: (context, index) {
              final m = widget.moments[index];
              final mediaType = m['media_type'] as String? ?? 'image';
              final mediaUrl = m['media_url'] as String;

              return mediaType == 'video'
                  ? buildVideoMoment(mediaUrl)
                  : buildImageMoment(mediaUrl);
            },
          ),
          buildProgressBar(),
          buildHeader(creator),
          buildActionButtons(),
          if (showReactions) buildReactionPicker(),
        ],
      ),
    );
  }

  Widget buildImageMoment(String imageUrl) {
    return CustomImageWidget(
      imageUrl: imageUrl,
      width: double.infinity,
      height: double.infinity,
      fit: BoxFit.cover,
      semanticLabel: 'Moment image',
    );
  }

  Widget buildVideoMoment(String videoUrl) {
    return Container(
      color: Colors.black,
      child: Center(
        child: Icon(Icons.play_circle_outline, size: 20.w, color: Colors.white),
      ),
    );
  }

  Widget buildProgressBar() {
    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
        child: Row(
          children: List.generate(
            widget.moments.length,
            (index) => Expanded(
              child: Container(
                height: 0.3.h,
                margin: EdgeInsets.symmetric(horizontal: 0.5.w),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(77),
                  borderRadius: BorderRadius.circular(2.0),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: index == currentIndex
                      ? progress
                      : index < currentIndex
                      ? 1.0
                      : 0.0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(2.0),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHeader(Map<String, dynamic>? creator) {
    final username = creator?['username'] as String? ?? 'User';
    final avatarUrl = creator?['avatar_url'] as String?;
    final createdAt = widget.moments[currentIndex]['created_at'] as String?;

    return Positioned(
      top: 5.h,
      left: 4.w,
      right: 4.w,
      child: Row(
        children: [
          CircleAvatar(
            radius: 5.w,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            backgroundColor: Colors.grey[800],
            child: avatarUrl == null
                ? Icon(Icons.person, color: Colors.white, size: 5.w)
                : null,
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  username,
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                if (createdAt != null)
                  Text(
                    getTimeAgo(createdAt),
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: Colors.white.withAlpha(179),
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: Colors.white, size: 6.w),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget buildActionButtons() {
    return Positioned(
      bottom: 10.h,
      right: 4.w,
      child: Column(
        children: [
          buildActionButton(
            Icons.favorite_border,
            () => setState(() => showReactions = true),
          ),
          SizedBox(height: 2.h),
          buildActionButton(Icons.send_outlined, () {}),
          SizedBox(height: 2.h),
          buildActionButton(Icons.more_vert, () {}),
        ],
      ),
    );
  }

  Widget buildActionButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(2.w),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(128),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 6.w),
      ),
    );
  }

  Widget buildReactionPicker() {
    final emojis = ['❤️', '😂', '😮', '😢', '👏', '🔥'];

    return Positioned(
      bottom: 20.h,
      left: 4.w,
      right: 4.w,
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.black.withAlpha(204),
          borderRadius: BorderRadius.circular(25.0),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: emojis
              .map(
                (emoji) => GestureDetector(
                  onTap: () => reactToMoment(emoji),
                  child: Text(emoji, style: TextStyle(fontSize: 24.sp)),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  String getTimeAgo(String timestamp) {
    final dateTime = DateTime.parse(timestamp);
    final difference = DateTime.now().difference(dateTime);

    if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }
}
