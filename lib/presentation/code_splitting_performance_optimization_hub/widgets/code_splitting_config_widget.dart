import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class CodeSplittingConfigWidget extends StatefulWidget {
  const CodeSplittingConfigWidget({super.key});

  @override
  State<CodeSplittingConfigWidget> createState() =>
      _CodeSplittingConfigWidgetState();
}

class _CodeSplittingConfigWidgetState extends State<CodeSplittingConfigWidget> {
  bool _enableTreeShaking = true;
  bool _enableFontSubsetting = true;
  bool _enableCodeMinification = true;
  bool _enableAssetCompression = true;
  double _imageQuality = 85.0;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(4.w),
      children: [
        Text(
          'Optimization Configuration',
          style: GoogleFonts.inter(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
        SizedBox(height: 2.h),
        _buildToggleCard(
          'Tree Shaking',
          'Remove unused code during build',
          _enableTreeShaking,
          (value) => setState(() => _enableTreeShaking = value),
        ),
        _buildToggleCard(
          'Font Subsetting',
          'Include only used font glyphs',
          _enableFontSubsetting,
          (value) => setState(() => _enableFontSubsetting = value),
        ),
        _buildToggleCard(
          'Code Minification',
          'Compress JavaScript/Dart code',
          _enableCodeMinification,
          (value) => setState(() => _enableCodeMinification = value),
        ),
        _buildToggleCard(
          'Asset Compression',
          'Compress images and videos',
          _enableAssetCompression,
          (value) => setState(() => _enableAssetCompression = value),
        ),
        SizedBox(height: 2.h),
        _buildImageQualitySlider(),
        SizedBox(height: 2.h),
        _buildApplyButton(),
      ],
    );
  }

  Widget _buildToggleCard(
    String title,
    String description,
    bool value,
    Function(bool) onChanged,
  ) {
    return Container(
      margin: EdgeInsets.only(bottom: 2.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 11.sp,
                    color: AppTheme.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppTheme.accentLight,
          ),
        ],
      ),
    );
  }

  Widget _buildImageQualitySlider() {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppTheme.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Image Quality',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          Row(
            children: [
              Expanded(
                child: Slider(
                  value: _imageQuality,
                  min: 50,
                  max: 100,
                  divisions: 10,
                  label: '${_imageQuality.toInt()}%',
                  activeColor: AppTheme.primaryLight,
                  onChanged: (value) {
                    setState(() => _imageQuality = value);
                  },
                ),
              ),
              Text(
                '${_imageQuality.toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryLight,
                ),
              ),
            ],
          ),
          Text(
            'Higher quality = larger file size',
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: AppTheme.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildApplyButton() {
    return ElevatedButton(
      onPressed: () {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Optimization settings applied successfully',
              style: GoogleFonts.inter(),
            ),
            backgroundColor: AppTheme.accentLight,
          ),
        );
      },
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryLight,
        minimumSize: Size(double.infinity, 6.h),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      child: Text(
        'Apply Configuration',
        style: GoogleFonts.inter(
          fontSize: 14.sp,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}
