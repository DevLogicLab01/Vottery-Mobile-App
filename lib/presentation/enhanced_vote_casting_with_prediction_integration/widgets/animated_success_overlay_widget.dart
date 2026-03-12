import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Animated success overlay shown after prediction is locked in
class AnimatedSuccessOverlayWidget extends StatefulWidget {
  final VoidCallback onDismiss;

  const AnimatedSuccessOverlayWidget({super.key, required this.onDismiss});

  @override
  State<AnimatedSuccessOverlayWidget> createState() =>
      _AnimatedSuccessOverlayWidgetState();
}

class _AnimatedSuccessOverlayWidgetState
    extends State<AnimatedSuccessOverlayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  final List<_ConfettiParticle> _particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeIn);

    // Generate confetti particles
    for (int i = 0; i < 20; i++) {
      _particles.add(
        _ConfettiParticle(
          x: (i * 0.05) % 1.0,
          color: [
            Colors.blue,
            Colors.red,
            Colors.green,
            Colors.yellow,
            Colors.purple,
            Colors.orange,
          ][i % 6],
          size: 6.0 + (i % 4) * 2.0,
        ),
      );
    }

    _controller.forward();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: Center(
          child: ScaleTransition(
            scale: _scaleAnimation,
            child: Container(
              margin: EdgeInsets.symmetric(horizontal: 8.w),
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(24.0),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 30,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Confetti animation
                  SizedBox(
                    height: 15.h,
                    child: Stack(
                      children: [
                        ..._particles.map(
                          (p) => AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Positioned(
                                left: p.x * 80.w,
                                top: _controller.value * 15.h - p.size,
                                child: Transform.rotate(
                                  angle: _controller.value * 3.14 * 2,
                                  child: Container(
                                    width: p.size,
                                    height: p.size,
                                    decoration: BoxDecoration(
                                      color: p.color.withValues(
                                        alpha: 1.0 - _controller.value * 0.5,
                                      ),
                                      borderRadius: BorderRadius.circular(2.0),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        Center(
                          child: Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.check,
                              color: theme.colorScheme.onPrimary,
                              size: 10.w,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Prediction Locked!',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Text(
                    'Good luck! Your prediction has been recorded.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 2.h),
                  TextButton(
                    onPressed: widget.onDismiss,
                    child: const Text('Continue'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ConfettiParticle {
  final double x;
  final Color color;
  final double size;

  _ConfettiParticle({required this.x, required this.color, required this.size});
}
