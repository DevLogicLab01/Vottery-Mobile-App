import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class OneClickRemediationPanelWidget extends StatefulWidget {
  final Future<void> Function() onRollback;
  final Future<void> Function() onScaleUp;
  final Future<void> Function() onPauseElections;

  const OneClickRemediationPanelWidget({
    super.key,
    required this.onRollback,
    required this.onScaleUp,
    required this.onPauseElections,
  });

  @override
  State<OneClickRemediationPanelWidget> createState() =>
      _OneClickRemediationPanelWidgetState();
}

class _OneClickRemediationPanelWidgetState
    extends State<OneClickRemediationPanelWidget> {
  bool _rollbackLoading = false;
  bool _scaleLoading = false;
  bool _pauseLoading = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12.0),
        side: BorderSide(color: Colors.red[200]!, width: 1),
      ),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.emergency, color: Colors.red[600], size: 20),
                SizedBox(width: 2.w),
                Text(
                  'One-Click Remediation',
                  style: GoogleFonts.inter(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.red[700],
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            _buildRemediationButton(
              label: 'Production Rollback',
              icon: Icons.undo,
              color: Colors.red,
              description: 'Mark deployment as rollback candidate',
              isLoading: _rollbackLoading,
              onPressed: () async {
                setState(() => _rollbackLoading = true);
                await widget.onRollback();
                if (mounted) setState(() => _rollbackLoading = false);
              },
            ),
            SizedBox(height: 1.5.h),
            _buildRemediationButton(
              label: 'Scale Up Database',
              icon: Icons.expand,
              color: Colors.orange,
              description: 'Auto-scale connections by 1.5x (max 200)',
              isLoading: _scaleLoading,
              onPressed: () async {
                setState(() => _scaleLoading = true);
                await widget.onScaleUp();
                if (mounted) setState(() => _scaleLoading = false);
              },
            ),
            SizedBox(height: 1.5.h),
            _buildRemediationButton(
              label: 'Pause High-Risk Elections',
              icon: Icons.pause_circle,
              color: Colors.amber[700]!,
              description: 'Pause elections with risk_score > 0.7',
              isLoading: _pauseLoading,
              onPressed: () async {
                setState(() => _pauseLoading = true);
                await widget.onPauseElections();
                if (mounted) setState(() => _pauseLoading = false);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRemediationButton({
    required String label,
    required IconData icon,
    required Color color,
    required String description,
    required bool isLoading,
    required VoidCallback onPressed,
  }) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(10.0),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: color.withAlpha(13),
          borderRadius: BorderRadius.circular(10.0),
          border: Border.all(color: color.withAlpha(77)),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withAlpha(26),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: isLoading
                  ? Padding(
                      padding: const EdgeInsets.all(10),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: color,
                      ),
                    )
                  : Icon(icon, color: color, size: 20),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      fontSize: 10.sp,
                      color: Colors.grey[600],
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color, size: 20),
          ],
        ),
      ),
    );
  }
}
