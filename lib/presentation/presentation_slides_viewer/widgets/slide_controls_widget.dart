import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Slide controls widget with navigation and view options
class SlideControlsWidget extends StatelessWidget {
  final int currentPage;
  final int totalPages;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToggleThumbnails;
  final VoidCallback onToggleSpeakerNotes;
  final VoidCallback onToggleFullscreen;
  final bool showThumbnails;
  final bool showSpeakerNotes;

  const SlideControlsWidget({
    super.key,
    required this.currentPage,
    required this.totalPages,
    required this.onPrevious,
    required this.onNext,
    required this.onToggleThumbnails,
    required this.onToggleSpeakerNotes,
    required this.onToggleFullscreen,
    required this.showThumbnails,
    required this.showSpeakerNotes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4.0,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Navigation buttons
          Row(
            children: [
              IconButton(
                onPressed: currentPage > 1 ? onPrevious : null,
                icon: const Icon(Icons.arrow_back),
                color: theme.colorScheme.primary,
                disabledColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.3,
                ),
              ),
              SizedBox(width: 2.w),
              IconButton(
                onPressed: currentPage < totalPages ? onNext : null,
                icon: const Icon(Icons.arrow_forward),
                color: theme.colorScheme.primary,
                disabledColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.3,
                ),
              ),
            ],
          ),

          // View options
          Row(
            children: [
              IconButton(
                onPressed: onToggleThumbnails,
                icon: Icon(
                  showThumbnails ? Icons.grid_view : Icons.grid_view_outlined,
                ),
                color: showThumbnails
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              IconButton(
                onPressed: onToggleSpeakerNotes,
                icon: Icon(
                  showSpeakerNotes ? Icons.notes : Icons.notes_outlined,
                ),
                color: showSpeakerNotes
                    ? theme.colorScheme.primary
                    : theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
              IconButton(
                onPressed: onToggleFullscreen,
                icon: const Icon(Icons.fullscreen),
                color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
