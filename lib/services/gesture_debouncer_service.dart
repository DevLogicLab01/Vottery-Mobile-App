import 'dart:async';
import 'package:flutter/widgets.dart';

/// Gesture Debouncer Service
/// Prevents rapid-fire gesture events for better performance
class GestureDebouncer {
  final Duration tapDebounce;
  final Duration swipeDebounce;

  Timer? _tapTimer;
  Timer? _swipeTimer;
  DateTime? _lastTap;
  DateTime? _lastSwipe;

  GestureDebouncer({
    this.tapDebounce = const Duration(milliseconds: 300),
    this.swipeDebounce = const Duration(milliseconds: 100),
  });

  /// Debounced tap handler - max 1 event per 300ms
  void onTap(VoidCallback callback) {
    final now = DateTime.now();
    if (_lastTap != null && now.difference(_lastTap!) < tapDebounce) {
      return; // Ignore rapid taps
    }
    _lastTap = now;
    _tapTimer?.cancel();
    _tapTimer = Timer(Duration.zero, callback);
  }

  /// Debounced swipe handler - max 1 event per 100ms
  void onSwipe(VoidCallback callback) {
    final now = DateTime.now();
    if (_lastSwipe != null && now.difference(_lastSwipe!) < swipeDebounce) {
      return; // Ignore rapid swipes
    }
    _lastSwipe = now;
    _swipeTimer?.cancel();
    _swipeTimer = Timer(Duration.zero, callback);
  }

  void dispose() {
    _tapTimer?.cancel();
    _swipeTimer?.cancel();
  }
}

/// Debounced GestureDetector widget wrapper
class DebouncedGestureDetector extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final Duration tapDebounce;
  final Duration swipeDebounce;

  const DebouncedGestureDetector({
    super.key,
    required this.child,
    this.onTap,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onSwipeUp,
    this.onSwipeDown,
    this.tapDebounce = const Duration(milliseconds: 300),
    this.swipeDebounce = const Duration(milliseconds: 100),
  });

  @override
  State<DebouncedGestureDetector> createState() =>
      _DebouncedGestureDetectorState();
}

class _DebouncedGestureDetectorState extends State<DebouncedGestureDetector> {
  late final GestureDebouncer _debouncer;
  Offset? _dragStart;

  @override
  void initState() {
    super.initState();
    _debouncer = GestureDebouncer(
      tapDebounce: widget.tapDebounce,
      swipeDebounce: widget.swipeDebounce,
    );
  }

  @override
  void dispose() {
    _debouncer.dispose();
    super.dispose();
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragStart == null) return;
    final velocity = details.velocity.pixelsPerSecond;
    if (velocity.dx.abs() > velocity.dy.abs()) {
      if (velocity.dx > 0 && widget.onSwipeRight != null) {
        _debouncer.onSwipe(widget.onSwipeRight!);
      } else if (velocity.dx < 0 && widget.onSwipeLeft != null) {
        _debouncer.onSwipe(widget.onSwipeLeft!);
      }
    } else {
      if (velocity.dy > 0 && widget.onSwipeDown != null) {
        _debouncer.onSwipe(widget.onSwipeDown!);
      } else if (velocity.dy < 0 && widget.onSwipeUp != null) {
        _debouncer.onSwipe(widget.onSwipeUp!);
      }
    }
    _dragStart = null;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap != null
          ? () => _debouncer.onTap(widget.onTap!)
          : null,
      onPanStart: (details) => _dragStart = details.globalPosition,
      onPanEnd: _handleDragEnd,
      child: widget.child,
    );
  }
}
