import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart' as google_fonts;

class BulkActionBarWidget extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onAcceptAll;
  final VoidCallback onDeclineAll;
  final VoidCallback onCancel;

  const BulkActionBarWidget({
    super.key,
    required this.selectedCount,
    required this.onAcceptAll,
    required this.onDeclineAll,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow,
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Text(
                '$selectedCount selected',
                style: google_fonts.GoogleFonts.inter(
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            TextButton.icon(
              onPressed: onAcceptAll,
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: Text(
                'Accept All',
                style: google_fonts.GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.green,
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            TextButton.icon(
              onPressed: onDeclineAll,
              icon: const Icon(Icons.cancel, color: Colors.white),
              label: Text(
                'Decline',
                style: google_fonts.GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                backgroundColor: Colors.red,
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
            ),
            SizedBox(width: 2.w),
            IconButton(
              onPressed: onCancel,
              icon: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
