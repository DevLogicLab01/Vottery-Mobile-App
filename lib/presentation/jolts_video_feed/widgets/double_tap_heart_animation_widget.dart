import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Double Tap Heart Animation - Visual feedback for like gesture
class DoubleTapHeartAnimationWidget extends StatefulWidget {
  const DoubleTapHeartAnimationWidget({super.key});

  @override
  State<DoubleTapHeartAnimationWidget> createState() =>
      _DoubleTapHeartAnimationWidgetState();
}

class _DoubleTapHeartAnimationWidgetState
    extends State<DoubleTapHeartAnimationWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.elasticOut));

    _opacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Opacity(
            opacity: _opacityAnimation.value,
            child: Transform.scale(
              scale: _scaleAnimation.value,
              child: Icon(Icons.favorite, size: 30.w, color: Colors.white),
            ),
          );
        },
      ),
    );
  }
}
