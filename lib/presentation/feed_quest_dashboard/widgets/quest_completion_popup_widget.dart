import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lottie/lottie.dart';
import 'package:sizer/sizer.dart';

class QuestCompletionPopupWidget extends StatefulWidget {
  final String questTitle;
  final int vpEarned;
  final VoidCallback onDismiss;

  const QuestCompletionPopupWidget({
    super.key,
    required this.questTitle,
    required this.vpEarned,
    required this.onDismiss,
  });

  @override
  State<QuestCompletionPopupWidget> createState() =>
      _QuestCompletionPopupWidgetState();
}

class _QuestCompletionPopupWidgetState extends State<QuestCompletionPopupWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );

    _controller.forward();

    // Auto-dismiss after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        widget.onDismiss();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Container(
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF6A11CB), Color(0xFF2575FC)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6A11CB).withAlpha(128),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Confetti Animation
              SizedBox(
                height: 20.h,
                child: Lottie.network(
                  'https://assets2.lottiefiles.com/packages/lf20_touohxv0.json',
                  repeat: false,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.celebration,
                      size: 80,
                      color: Colors.white,
                    );
                  },
                ),
              ),

              SizedBox(height: 2.h),

              // Success Icon
              Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 50,
                ),
              ),

              SizedBox(height: 2.h),

              // Quest Completed Text
              Text(
                'Quest Completed!',
                style: GoogleFonts.inter(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 1.h),

              // Quest Title
              Text(
                widget.questTitle,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withAlpha(230),
                ),
                textAlign: TextAlign.center,
              ),

              SizedBox(height: 2.h),

              // VP Earned
              Container(
                padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.5.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.stars, color: Color(0xFF6A11CB), size: 24),
                    SizedBox(width: 2.w),
                    Text(
                      '+${widget.vpEarned} VP',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF6A11CB),
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 3.h),

              // Dismiss Button
              TextButton(
                onPressed: widget.onDismiss,
                child: Text(
                  'Continue',
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
