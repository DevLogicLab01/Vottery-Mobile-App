import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class VerificationToolsWidget extends StatefulWidget {
  final Function(String) onVerify;

  const VerificationToolsWidget({super.key, required this.onVerify});

  @override
  State<VerificationToolsWidget> createState() =>
      _VerificationToolsWidgetState();
}

class _VerificationToolsWidgetState extends State<VerificationToolsWidget> {
  final TextEditingController _hashController = TextEditingController();
  bool _isVerifying = false;

  @override
  void dispose() {
    _hashController.dispose();
    super.dispose();
  }

  Future<void> _verifyHash() async {
    if (_hashController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please enter a hash to verify'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
      return;
    }

    setState(() => _isVerifying = true);

    try {
      await widget.onVerify(_hashController.text.trim());
    } finally {
      if (mounted) {
        setState(() => _isVerifying = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Independent Vote Verification',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Verify vote integrity by checking hash against blockchain',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 3.h),
          TextField(
            controller: _hashController,
            decoration: InputDecoration(
              labelText: 'Enter Vote Hash or Transaction Hash',
              hintText: '0x...',
              prefixIcon: Icon(Icons.tag),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            maxLines: 3,
          ),
          SizedBox(height: 3.h),
          ElevatedButton.icon(
            onPressed: _isVerifying ? null : _verifyHash,
            icon: _isVerifying
                ? SizedBox(
                    width: 5.w,
                    height: 5.w,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Icon(Icons.verified, size: 5.w),
            label: Text(_isVerifying ? 'Verifying...' : 'Verify Hash'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryLight,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 6.h),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
          ),
          SizedBox(height: 4.h),
          Container(
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: AppTheme.accentLight.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: AppTheme.accentLight,
                      size: 5.w,
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      'How Verification Works',
                      style: GoogleFonts.inter(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 2.h),
                _buildInfoPoint(
                  '1. Each vote is encrypted with RSA-2048',
                  theme,
                ),
                SizedBox(height: 1.h),
                _buildInfoPoint(
                  '2. Digital signature is generated for verification',
                  theme,
                ),
                SizedBox(height: 1.h),
                _buildInfoPoint(
                  '3. Vote is recorded on immutable blockchain',
                  theme,
                ),
                SizedBox(height: 1.h),
                _buildInfoPoint(
                  '4. Hash comparison ensures vote integrity',
                  theme,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoPoint(String text, ThemeData theme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.check_circle, color: AppTheme.accentLight, size: 4.w),
        SizedBox(width: 2.w),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
