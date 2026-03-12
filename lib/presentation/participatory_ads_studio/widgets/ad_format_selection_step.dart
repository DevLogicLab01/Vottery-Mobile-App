import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

enum AdFormatType { marketResearch, hypePrediction, csrVote }

class AdFormatSelectionStep extends StatefulWidget {
  final AdFormatType? selectedFormat;
  final ValueChanged<AdFormatType> onFormatSelected;

  const AdFormatSelectionStep({
    super.key,
    required this.selectedFormat,
    required this.onFormatSelected,
  });

  @override
  State<AdFormatSelectionStep> createState() => _AdFormatSelectionStepState();
}

class _AdFormatSelectionStepState extends State<AdFormatSelectionStep> {
  AdFormatType? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selectedFormat;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ad Format',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Choose the type of participatory ad campaign',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          SizedBox(height: 3.h),
          _buildFormatCard(
            type: AdFormatType.marketResearch,
            title: 'Market Research',
            subtitle: 'Get audience feedback on products/services',
            icon: Icons.poll,
            color: Colors.blue,
          ),
          SizedBox(height: 2.h),
          _buildFormatCard(
            type: AdFormatType.hypePrediction,
            title: 'Hype Prediction',
            subtitle: 'Predict excitement for upcoming launches',
            icon: Icons.trending_up,
            color: Colors.orange,
          ),
          SizedBox(height: 2.h),
          _buildFormatCard(
            type: AdFormatType.csrVote,
            title: 'CSR Vote',
            subtitle: 'Corporate social responsibility initiatives',
            icon: Icons.volunteer_activism,
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildFormatCard({
    required AdFormatType type,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selected == type;
    return GestureDetector(
      onTap: () {
        setState(() => _selected = type);
        widget.onFormatSelected(type);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.all(4.w),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.15),
                    blurRadius: 8.0,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10.0),
              ),
              child: Icon(icon, color: color, size: 22.sp),
            ),
            SizedBox(width: 4.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? color : AppTheme.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 0.3.h),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Radio<AdFormatType>(
              value: type,
              groupValue: _selected,
              activeColor: color,
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selected = val);
                  widget.onFormatSelected(val);
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
