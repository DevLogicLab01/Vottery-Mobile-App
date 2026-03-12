import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../services/tie_resolution_service.dart';
import '../../../theme/app_theme.dart';

/// Dialog for manually resolving ties
class ManualResolutionDialogWidget extends StatefulWidget {
  final Map<String, dynamic> tieResult;
  final VoidCallback onResolved;

  const ManualResolutionDialogWidget({
    super.key,
    required this.tieResult,
    required this.onResolved,
  });

  @override
  State<ManualResolutionDialogWidget> createState() =>
      _ManualResolutionDialogWidgetState();
}

class _ManualResolutionDialogWidgetState
    extends State<ManualResolutionDialogWidget> {
  final TieResolutionService _tieService = TieResolutionService.instance;
  final TextEditingController _justificationController =
      TextEditingController();
  String? _selectedWinnerId;
  bool _isResolving = false;

  @override
  void dispose() {
    _justificationController.dispose();
    super.dispose();
  }

  Future<void> _resolveTie() async {
    if (_selectedWinnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a winner'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_justificationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide justification'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isResolving = true);

    final success = await _tieService.manuallyResolveTie(
      tieResultId: widget.tieResult['id'],
      winnerOptionId: _selectedWinnerId!,
      justification: _justificationController.text.trim(),
    );

    setState(() => _isResolving = false);

    if (success) {
      Navigator.pop(context);
      widget.onResolved();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to resolve tie'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tiedCandidates = List<Map<String, dynamic>>.from(
      widget.tieResult['tied_candidates'] ?? [],
    );

    return AlertDialog(
      title: Text(
        'Manual Tie Resolution',
        style: GoogleFonts.inter(fontSize: 16.sp, fontWeight: FontWeight.w600),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Select Winner',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            ...tiedCandidates.map((candidate) {
              final optionId = candidate['option_id'];
              return RadioListTile<String>(
                value: optionId,
                groupValue: _selectedWinnerId,
                onChanged: (value) {
                  setState(() => _selectedWinnerId = value);
                },
                title: Text(
                  candidate['option_title'] ?? 'Unknown',
                  style: GoogleFonts.inter(fontSize: 13.sp),
                ),
                activeColor: AppTheme.primaryLight,
              );
            }),
            SizedBox(height: 2.h),
            Text(
              'Justification (Required)',
              style: GoogleFonts.inter(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            TextField(
              controller: _justificationController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Explain why this candidate should win...',
                hintStyle: GoogleFonts.inter(fontSize: 12.sp),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                contentPadding: EdgeInsets.all(3.w),
              ),
              style: GoogleFonts.inter(fontSize: 13.sp),
            ),
            SizedBox(height: 1.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber, color: Colors.amber.shade800),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'This action will be recorded in audit logs',
                      style: GoogleFonts.inter(
                        fontSize: 11.sp,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _isResolving ? null : _resolveTie,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryLight,
            foregroundColor: Colors.white,
          ),
          child: _isResolving
              ? const SizedBox(
                  height: 20.0,
                  width: 20.0,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2,
                  ),
                )
              : Text(
                  'Resolve Tie',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
        ),
      ],
    );
  }
}
