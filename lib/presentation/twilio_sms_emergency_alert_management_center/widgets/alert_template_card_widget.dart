import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AlertTemplateCardWidget extends StatelessWidget {
  final Map<String, dynamic> template;

  const AlertTemplateCardWidget({super.key, required this.template});

  @override
  Widget build(BuildContext context) {
    final templateName = template['name'] ?? 'Unknown Template';
    final category = template['category'] ?? 'general';
    final message = template['message'] ?? '';
    final variables = List<String>.from(template['variables'] ?? []);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2.0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    _buildCategoryIcon(category),
                    SizedBox(width: 2.w),
                    Text(
                      templateName,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: Icon(
                    Icons.copy,
                    size: 5.w,
                    color: AppTheme.primaryLight,
                  ),
                  onPressed: () => _copyTemplate(context, message),
                  tooltip: 'Copy Template',
                ),
              ],
            ),
            SizedBox(height: 1.h),
            _buildCategoryBadge(category),
            SizedBox(height: 2.h),
            // Message Preview
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8.0),
                border: Border.all(color: AppTheme.borderLight),
              ),
              child: Text(
                message,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: AppTheme.textPrimaryLight,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 2.h),
            // Variables
            Text(
              'Variables:',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Wrap(
              spacing: 2.w,
              runSpacing: 1.h,
              children: variables
                  .map((variable) => _buildVariableChip(variable))
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryIcon(String category) {
    IconData icon;
    Color color;

    switch (category) {
      case 'fraud':
        icon = Icons.security;
        color = Colors.red;
        break;
      case 'failover':
        icon = Icons.autorenew;
        color = Colors.orange;
        break;
      case 'security':
        icon = Icons.shield;
        color = Colors.purple;
        break;
      case 'performance':
        icon = Icons.speed;
        color = Colors.blue;
        break;
      default:
        icon = Icons.info;
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Icon(icon, size: 5.w, color: color),
    );
  }

  Widget _buildCategoryBadge(String category) {
    Color color;

    switch (category) {
      case 'fraud':
        color = Colors.red;
        break;
      case 'failover':
        color = Colors.orange;
        break;
      case 'security':
        color = Colors.purple;
        break;
      case 'performance':
        color = Colors.blue;
        break;
      default:
        color = Colors.grey;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(4.0),
        border: Border.all(color: color),
      ),
      child: Text(
        category.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 10.sp,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildVariableChip(String variable) {
    return Chip(
      label: Text(
        '{$variable}',
        style: GoogleFonts.inter(fontSize: 11.sp, fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.blue.shade50,
      side: BorderSide(color: Colors.blue.shade200),
      padding: EdgeInsets.symmetric(horizontal: 1.w),
    );
  }

  void _copyTemplate(BuildContext context, String message) {
    Clipboard.setData(ClipboardData(text: message));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Template copied to clipboard'),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ),
    );
  }
}
