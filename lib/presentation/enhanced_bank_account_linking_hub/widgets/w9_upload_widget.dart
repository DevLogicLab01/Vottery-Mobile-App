import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';
import '../../../theme/app_theme.dart';

class W9UploadWidget extends StatelessWidget {
  final bool isUploading;
  final double uploadProgress;
  final String? uploadedFileName;
  final String verificationStatus;
  final VoidCallback onPickFile;
  final VoidCallback? onPreview;

  const W9UploadWidget({
    super.key,
    required this.isUploading,
    required this.uploadProgress,
    this.uploadedFileName,
    required this.verificationStatus,
    required this.onPickFile,
    this.onPreview,
  });

  Color get _statusColor {
    switch (verificationStatus) {
      case 'verified':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData get _statusIcon {
    switch (verificationStatus) {
      case 'verified':
        return Icons.verified;
      case 'rejected':
        return Icons.cancel;
      case 'pending':
        return Icons.pending;
      default:
        return Icons.upload_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.withAlpha(60)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.description, color: AppTheme.primaryLight, size: 6.w),
              SizedBox(width: 2.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'W-9 Tax Document',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                    Text(
                      'Required for US creators receiving payouts',
                      style: GoogleFonts.inter(
                        fontSize: 10.sp,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              if (uploadedFileName != null)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withAlpha(20),
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(color: _statusColor.withAlpha(80)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_statusIcon, color: _statusColor, size: 3.5.w),
                      SizedBox(width: 1.w),
                      Text(
                        verificationStatus.toUpperCase(),
                        style: GoogleFonts.inter(
                          fontSize: 9.sp,
                          color: _statusColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SizedBox(height: 2.h),
          if (uploadedFileName != null) ...[
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey.withAlpha(20),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, color: Colors.red, size: 5.w),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      uploadedFileName!,
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: AppTheme.textPrimaryLight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (onPreview != null)
                    IconButton(
                      icon: Icon(
                        Icons.visibility,
                        color: AppTheme.primaryLight,
                        size: 5.w,
                      ),
                      onPressed: onPreview,
                    ),
                ],
              ),
            ),
            SizedBox(height: 1.h),
          ],
          if (isUploading) ...[
            Text(
              'Uploading to secure storage...',
              style: GoogleFonts.inter(
                fontSize: 10.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 0.5.h),
            LinearProgressIndicator(
              value: uploadProgress,
              backgroundColor: Colors.grey.withAlpha(50),
              valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
            ),
            SizedBox(height: 1.h),
          ],
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isUploading ? null : onPickFile,
              icon: Icon(
                Icons.upload_file,
                size: 4.w,
                color: AppTheme.primaryLight,
              ),
              label: Text(
                uploadedFileName == null
                    ? 'Select W-9 PDF Document'
                    : 'Replace Document',
                style: GoogleFonts.inter(
                  fontSize: 11.sp,
                  color: AppTheme.primaryLight,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppTheme.primaryLight),
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10.0),
                ),
              ),
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            '🔒 Stored securely: tax-documents/{user_id}/w9_{timestamp}.pdf',
            style: GoogleFonts.inter(
              fontSize: 9.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }
}
