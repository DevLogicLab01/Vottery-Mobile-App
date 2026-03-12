import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../framework/web_mobile_sync_validator.dart';

class SyncValidatorPanelWidget extends StatefulWidget {
  const SyncValidatorPanelWidget({super.key});

  @override
  State<SyncValidatorPanelWidget> createState() =>
      _SyncValidatorPanelWidgetState();
}

class _SyncValidatorPanelWidgetState extends State<SyncValidatorPanelWidget> {
  ValidationResult? _result;
  bool _isValidating = false;

  Future<void> _runValidation() async {
    setState(() => _isValidating = true);
    await Future.delayed(const Duration(milliseconds: 800));
    final result = WebMobileSyncValidator.validateAll();
    WebMobileSyncValidator.logValidationResult(result);
    setState(() {
      _result = result;
      _isValidating = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _runValidation();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Expanded(
              child: Text(
                'Web/Mobile Sync Validation',
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            ElevatedButton.icon(
              onPressed: _isValidating ? null : _runValidation,
              icon: _isValidating
                  ? SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: theme.colorScheme.onPrimary,
                      ),
                    )
                  : const Icon(Icons.refresh, size: 16),
              label: Text(
                _isValidating ? 'Validating...' : 'Run Validation',
                style: GoogleFonts.inter(fontSize: 11.sp),
              ),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        if (_result != null) ..._buildResults(context),
        if (_result == null && !_isValidating)
          Center(
            child: Text(
              'Press Run Validation to check sync status',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface.withAlpha(128),
              ),
            ),
          ),
      ],
    );
  }

  List<Widget> _buildResults(BuildContext context) {
    final theme = Theme.of(context);
    final result = _result!;
    return [
      // Status card
      Container(
        width: double.infinity,
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: result.isValid
              ? Colors.green.withAlpha(26)
              : Colors.red.withAlpha(26),
          borderRadius: BorderRadius.circular(12.0),
          border: Border.all(
            color: result.isValid
                ? Colors.green.withAlpha(102)
                : Colors.red.withAlpha(102),
          ),
        ),
        child: Row(
          children: [
            Icon(
              result.isValid ? Icons.check_circle : Icons.error,
              color: result.isValid ? Colors.green : Colors.red,
              size: 28,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result.isValid
                        ? '✅ All Constants Synchronized'
                        : '❌ Sync Validation Failed',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w700,
                      color: result.isValid ? Colors.green : Colors.red,
                    ),
                  ),
                  Text(
                    '${result.totalChecked} constants checked · ${result.errors.length} errors · ${result.warnings.length} warnings',
                    style: GoogleFonts.inter(
                      fontSize: 11.sp,
                      color: theme.colorScheme.onSurface.withAlpha(153),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      SizedBox(height: 2.h),
      // Validation categories
      ..._buildCategoryChecks(context),
      if (result.errors.isNotEmpty) ..._buildErrorList(context),
    ];
  }

  List<Widget> _buildCategoryChecks(BuildContext context) {
    final categories = [
      {'name': 'Database Tables', 'icon': Icons.table_chart, 'count': '8'},
      {'name': 'Route Paths', 'icon': Icons.route, 'count': '6'},
      {'name': 'Stripe Products', 'icon': Icons.payment, 'count': '3'},
      {'name': 'VP Multipliers', 'icon': Icons.trending_up, 'count': '3'},
      {'name': 'Error Codes', 'icon': Icons.error_outline, 'count': '3'},
      {'name': 'Edge Functions', 'icon': Icons.functions, 'count': '4'},
      {'name': 'Election Columns', 'icon': Icons.view_column, 'count': '3'},
    ];

    return [
      Text(
        'Validation Categories',
        style: GoogleFonts.inter(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      SizedBox(height: 1.h),
      ...categories.map(
        (cat) => _ValidationCategoryRow(
          name: cat['name'] as String,
          icon: cat['icon'] as IconData,
          count: cat['count'] as String,
          isValid: _result?.isValid ?? true,
        ),
      ),
      SizedBox(height: 1.h),
    ];
  }

  List<Widget> _buildErrorList(BuildContext context) {
    return [
      Text(
        'Errors (${_result!.errors.length})',
        style: GoogleFonts.inter(
          fontSize: 13.sp,
          fontWeight: FontWeight.w600,
          color: Colors.red,
        ),
      ),
      SizedBox(height: 0.5.h),
      ..._result!.errors.map(
        (e) => Container(
          margin: EdgeInsets.only(bottom: 0.5.h),
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: Colors.red.withAlpha(13),
            borderRadius: BorderRadius.circular(6.0),
            border: Border.all(color: Colors.red.withAlpha(51)),
          ),
          child: Text(
            e,
            style: GoogleFonts.inter(
              fontSize: 10.sp,
              color: Colors.red.shade700,
            ),
          ),
        ),
      ),
    ];
  }
}

class _ValidationCategoryRow extends StatelessWidget {
  final String name;
  final IconData icon;
  final String count;
  final bool isValid;

  const _ValidationCategoryRow({
    required this.name,
    required this.icon,
    required this.count,
    required this.isValid,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              name,
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
          Text(
            '$count constants',
            style: GoogleFonts.inter(
              fontSize: 11.sp,
              color: theme.colorScheme.onSurface.withAlpha(128),
            ),
          ),
          SizedBox(width: 2.w),
          Icon(
            isValid ? Icons.check_circle : Icons.warning,
            size: 16,
            color: isValid ? Colors.green : Colors.orange,
          ),
        ],
      ),
    );
  }
}
