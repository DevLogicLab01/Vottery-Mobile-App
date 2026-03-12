import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class TrendingSoundsPanelWidget extends StatelessWidget {
  final String? selectedSoundId;
  final Function(String soundId, String soundName) onSoundSelected;

  const TrendingSoundsPanelWidget({
    super.key,
    this.selectedSoundId,
    required this.onSoundSelected,
  });

  static final List<Map<String, dynamic>> _trendingSounds = [
    {
      'id': 'sound_1',
      'name': 'Upbeat Energy',
      'use_count': 125000,
      'trending': true,
    },
    {
      'id': 'sound_2',
      'name': 'Chill Vibes',
      'use_count': 89000,
      'trending': true,
    },
    {
      'id': 'sound_3',
      'name': 'Epic Moment',
      'use_count': 67000,
      'trending': false,
    },
    {
      'id': 'sound_4',
      'name': 'Vote Anthem',
      'use_count': 45000,
      'trending': true,
    },
    {
      'id': 'sound_5',
      'name': 'Democracy Beat',
      'use_count': 32000,
      'trending': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.music_note, color: Colors.pink, size: 5.w),
            SizedBox(width: 2.w),
            Text(
              'Trending Sounds',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _trendingSounds.length,
          itemBuilder: (context, index) {
            final sound = _trendingSounds[index];
            final isSelected = selectedSoundId == sound['id'];
            return GestureDetector(
              onTap: () => onSoundSelected(sound['id'], sound['name']),
              child: Container(
                margin: EdgeInsets.only(bottom: 1.h),
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.pink.withAlpha(20) : Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: isSelected ? Colors.pink : Colors.grey.withAlpha(60),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected ? Icons.pause_circle : Icons.play_circle,
                      color: isSelected ? Colors.pink : Colors.grey,
                      size: 6.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                sound['name'],
                                style: GoogleFonts.inter(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.textPrimaryLight,
                                ),
                              ),
                              if (sound['trending'] == true) ...[
                                SizedBox(width: 1.w),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 1.5.w,
                                    vertical: 0.2.h,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.orange,
                                    borderRadius: BorderRadius.circular(4.0),
                                  ),
                                  child: Text(
                                    'TRENDING',
                                    style: GoogleFonts.inter(
                                      fontSize: 7.sp,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          Text(
                            '${_formatCount(sound['use_count'])} uses',
                            style: GoogleFonts.inter(
                              fontSize: 10.sp,
                              color: AppTheme.textSecondaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(Icons.check_circle, color: Colors.pink, size: 5.w),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(0)}K';
    return count.toString();
  }
}
