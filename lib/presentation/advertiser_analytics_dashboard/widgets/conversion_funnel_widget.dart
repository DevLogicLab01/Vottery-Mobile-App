import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class ConversionFunnelWidget extends StatelessWidget {
  final int impressions;
  final int clicks;
  final int participants;

  const ConversionFunnelWidget({
    super.key,
    required this.impressions,
    required this.clicks,
    required this.participants,
  });

  @override
  Widget build(BuildContext context) {
    final clickRate = impressions > 0 ? (clicks / impressions) * 100 : 0.0;
    final conversionRate = clicks > 0 ? (participants / clicks) * 100 : 0.0;

    return Container(
      padding: EdgeInsets.all(4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(13),
            blurRadius: 10.0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Conversion Funnel',
            style: GoogleFonts.inter(
              fontSize: 14.0,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 2.0),
          _buildFunnelStage('Impressions', impressions, 1.0, Colors.blue, null),
          SizedBox(height: 1.0),
          _buildFunnelStage(
            'Clicks',
            clicks,
            impressions > 0 ? clicks / impressions : 0,
            Colors.purple,
            clickRate,
          ),
          SizedBox(height: 1.0),
          _buildFunnelStage(
            'Participants',
            participants,
            impressions > 0 ? participants / impressions : 0,
            Colors.green,
            conversionRate,
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelStage(
    String label,
    int value,
    double percentage,
    Color color,
    double? conversionFromPrevious,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 11.0,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            Row(
              children: [
                Text(
                  _formatNumber(value),
                  style: GoogleFonts.inter(
                    fontSize: 12.0,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
                if (conversionFromPrevious != null) ...[
                  SizedBox(width: 2.0),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 2.0,
                      vertical: 0.5,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(26),
                      borderRadius: BorderRadius.circular(4.0),
                    ),
                    child: Text(
                      '${conversionFromPrevious.toStringAsFixed(1)}%',
                      style: GoogleFonts.inter(
                        fontSize: 9.0,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        SizedBox(height: 0.5),
        ClipRRect(
          borderRadius: BorderRadius.circular(4.0),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: color.withAlpha(26),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 1.5,
          ),
        ),
      ],
    );
  }

  String _formatNumber(int number) {
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(1)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    }
    return number.toString();
  }
}
