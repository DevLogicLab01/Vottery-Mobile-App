import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class SessionPlayerControlsWidget extends StatefulWidget {
  final String sessionId;
  final VoidCallback onPlayPause;
  final Function(double) onSeek;

  const SessionPlayerControlsWidget({
    super.key,
    required this.sessionId,
    required this.onPlayPause,
    required this.onSeek,
  });

  @override
  State<SessionPlayerControlsWidget> createState() =>
      _SessionPlayerControlsWidgetState();
}

class _SessionPlayerControlsWidgetState
    extends State<SessionPlayerControlsWidget> {
  bool _isPlaying = false;
  double _currentPosition = 0.3;
  double _playbackSpeed = 1.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.control_camera,
                color: const Color(0xFF6366F1),
                size: 20.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                'Session Player Controls',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          _buildProgressBar(),
          SizedBox(height: 2.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildControlButton(Icons.replay_10, () {}),
              SizedBox(width: 4.w),
              _buildPlayPauseButton(),
              SizedBox(width: 4.w),
              _buildControlButton(Icons.forward_10, () {}),
              SizedBox(width: 4.w),
              _buildSpeedControl(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${(_currentPosition * 512).toInt()}s',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: Colors.grey[600],
              ),
            ),
            Text(
              '512s',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        SliderTheme(
          data: SliderThemeData(
            trackHeight: 0.5.h,
            thumbShape: RoundSliderThumbShape(enabledThumbRadius: 1.5.w),
            overlayShape: RoundSliderOverlayShape(overlayRadius: 3.w),
          ),
          child: Slider(
            value: _currentPosition,
            onChanged: (value) {
              setState(() => _currentPosition = value);
              widget.onSeek(value);
            },
            activeColor: const Color(0xFF6366F1),
            inactiveColor: Colors.grey[300],
          ),
        ),
      ],
    );
  }

  Widget _buildPlayPauseButton() {
    return GestureDetector(
      onTap: () {
        setState(() => _isPlaying = !_isPlaying);
        widget.onPlayPause();
      },
      child: Container(
        width: 15.w,
        height: 15.w,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          ),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isPlaying ? Icons.pause : Icons.play_arrow,
          color: Colors.white,
          size: 24.sp,
        ),
      ),
    );
  }

  Widget _buildControlButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.grey[700], size: 18.sp),
      ),
    );
  }

  Widget _buildSpeedControl() {
    return PopupMenuButton<double>(
      initialValue: _playbackSpeed,
      onSelected: (speed) {
        setState(() => _playbackSpeed = speed);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 0.5, child: Text('0.5x')),
        const PopupMenuItem(value: 1.0, child: Text('1.0x')),
        const PopupMenuItem(value: 1.5, child: Text('1.5x')),
        const PopupMenuItem(value: 2.0, child: Text('2.0x')),
      ],
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(20.0),
        ),
        child: Row(
          children: [
            Text(
              '${_playbackSpeed}x',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            SizedBox(width: 1.w),
            Icon(Icons.arrow_drop_down, color: Colors.grey[700], size: 16.sp),
          ],
        ),
      ),
    );
  }
}
