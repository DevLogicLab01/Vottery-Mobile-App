import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class OptimizationActionPanelWidget extends StatelessWidget {
  final Function(String action, Map<String, dynamic> params) onActionTapped;

  const OptimizationActionPanelWidget({
    super.key,
    required this.onActionTapped,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Optimization Actions',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.w700,
          ),
        ),
        SizedBox(height: 2.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 3.w,
          mainAxisSpacing: 2.h,
          childAspectRatio: 2,
          children: [
            _buildActionButton(
              'Increase Budget +20%',
              Icons.add_circle,
              Colors.green,
              () => onActionTapped('increase_budget', {'percentage': 20}),
            ),
            _buildActionButton(
              'Expand Audience',
              Icons.group_add,
              Colors.blue,
              () => onActionTapped('expand_audience', {'zone': 'new'}),
            ),
            _buildActionButton(
              'Rotate Creative',
              Icons.refresh,
              Colors.purple,
              () => onActionTapped('rotate_creative', {}),
            ),
            _buildActionButton(
              'Pause Campaign',
              Icons.pause_circle,
              Colors.red,
              () => onActionTapped('pause_campaign', {}),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withAlpha(26),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(color: color, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 6.w),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
