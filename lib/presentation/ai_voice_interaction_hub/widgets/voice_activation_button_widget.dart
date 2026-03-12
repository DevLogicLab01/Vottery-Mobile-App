import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

/// Voice Activation Button Widget
/// Push-to-talk button with haptic feedback and pulse animation
class VoiceActivationButtonWidget extends StatelessWidget {
  final bool isListening;
  final VoidCallback onPressed;
  final AnimationController pulseAnimation;

  const VoiceActivationButtonWidget({
    super.key,
    required this.isListening,
    required this.onPressed,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: GestureDetector(
        onTap: onPressed,
        child: AnimatedBuilder(
          animation: pulseAnimation,
          builder: (context, child) {
            final scale = isListening
                ? 1.0 + (pulseAnimation.value * 0.1)
                : 1.0;
            return Transform.scale(
              scale: scale,
              child: Container(
                width: 80.sp,
                height: 80.sp,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: isListening
                        ? [Colors.red, Colors.redAccent]
                        : [Colors.blue, Colors.blueAccent],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (isListening ? Colors.red : Colors.blue).withAlpha(
                        102,
                      ),
                      blurRadius: isListening ? 20 : 10,
                      spreadRadius: isListening ? 5 : 2,
                    ),
                  ],
                ),
                child: Icon(
                  isListening ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 40.sp,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
