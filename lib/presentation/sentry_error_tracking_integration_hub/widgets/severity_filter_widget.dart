import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class SeverityFilterWidget extends StatelessWidget {
  final String? selectedSeverity;
  final List<String> severityLevels;
  final Function(String?) onSeverityChanged;

  const SeverityFilterWidget({
    super.key,
    required this.selectedSeverity,
    required this.severityLevels,
    required this.onSeverityChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.all(4.w),
      color: theme.cardColor,
      child: Row(
        children: [
          Text(
            'Severity:',
            style: GoogleFonts.inter(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: Wrap(
              spacing: 2.w,
              children: [
                FilterChip(
                  label: Text('All'),
                  selected: selectedSeverity == null,
                  onSelected: (selected) => onSeverityChanged(null),
                ),
                ...severityLevels.map((severity) {
                  return FilterChip(
                    label: Text(severity.toUpperCase()),
                    selected: selectedSeverity == severity,
                    onSelected: (selected) => onSeverityChanged(severity),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
