import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../theme/app_theme.dart';

class TemplateMarketplaceROIWidget extends StatelessWidget {
  final Map<String, dynamic> templateROI;

  const TemplateMarketplaceROIWidget({super.key, required this.templateROI});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final totalRevenue =
        (templateROI['total_template_revenue'] as num?)?.toDouble() ?? 0.0;
    final creatorShare =
        (templateROI['creator_share'] as num?)?.toDouble() ?? 0.0;
    final roiPercentage =
        (templateROI['roi_percentage'] as num?)?.toDouble() ?? 0.0;
    final templateCount = (templateROI['template_count'] as num?)?.toInt() ?? 0;
    final bestSelling = templateROI['best_selling_templates'] as List? ?? [];

    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF8B5CF6).withAlpha(26),
            const Color(0xFF3B82F6).withAlpha(26),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: const Color(0xFF8B5CF6).withAlpha(77)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.store, color: const Color(0xFF8B5CF6), size: 5.w),
              SizedBox(width: 2.w),
              Text(
                'Template Marketplace ROI',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Row(
            children: [
              Expanded(
                child: _ROIStat(
                  label: 'Total Revenue',
                  value: '\$${totalRevenue.toStringAsFixed(2)}',
                  color: const Color(0xFF8B5CF6),
                ),
              ),
              Expanded(
                child: _ROIStat(
                  label: 'Your Share (70%)',
                  value: '\$${creatorShare.toStringAsFixed(2)}',
                  color: const Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: _ROIStat(
                  label: 'ROI',
                  value: '${roiPercentage.toStringAsFixed(0)}%',
                  color: AppTheme.vibrantYellow,
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Text(
            'Templates Sold: $templateCount',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (bestSelling.isNotEmpty) ...[
            SizedBox(height: 1.h),
            Text(
              'Best Sellers',
              style: GoogleFonts.inter(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 0.5.h),
            ...bestSelling
                .take(3)
                .map(
                  (t) => Padding(
                    padding: EdgeInsets.only(bottom: 0.5.h),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          color: AppTheme.vibrantYellow,
                          size: 3.5.w,
                        ),
                        SizedBox(width: 1.w),
                        Text(
                          t['template_id']?.toString() ?? 'Template',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '\$${(t['amount'] as num?)?.toStringAsFixed(2) ?? '0.00'}',
                          style: GoogleFonts.inter(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ],
      ),
    );
  }
}

class _ROIStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ROIStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 9.sp,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
