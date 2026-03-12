import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../../services/tie_resolution_service.dart';
import '../../../theme/app_theme.dart';

/// Widget for scheduling runoff elections
class RunoffSchedulerWidget extends StatefulWidget {
  final Map<String, dynamic> tieResult;
  final VoidCallback onScheduled;

  const RunoffSchedulerWidget({
    super.key,
    required this.tieResult,
    required this.onScheduled,
  });

  @override
  State<RunoffSchedulerWidget> createState() => _RunoffSchedulerWidgetState();
}

class _RunoffSchedulerWidgetState extends State<RunoffSchedulerWidget> {
  final TieResolutionService _tieService = TieResolutionService.instance;
  DateTime? _startDate;
  DateTime? _endDate;
  bool _isScheduling = false;

  Future<void> _selectStartDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _startDate = date);
    }
  }

  Future<void> _selectEndDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate:
          _startDate?.add(const Duration(days: 7)) ??
          DateTime.now().add(const Duration(days: 8)),
      firstDate: _startDate ?? DateTime.now().add(const Duration(days: 1)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _endDate = date);
    }
  }

  Future<void> _scheduleRunoff() async {
    if (_startDate == null || _endDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select both start and end dates'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isScheduling = true);

    final runoffId = await _tieService.createRunoffElection(
      originalElectionId: widget.tieResult['election_id'],
      tieResultId: widget.tieResult['id'],
      startDate: _startDate!,
      endDate: _endDate!,
    );

    setState(() => _isScheduling = false);

    if (runoffId != null) {
      Navigator.pop(context);
      widget.onScheduled();
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to schedule runoff election'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.0)),
      ),
      padding: EdgeInsets.all(4.w),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Text(
                '🗳️ Schedule Runoff Election',
                style: GoogleFonts.inter(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryLight,
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          // Info
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Text(
              'A runoff election will be created with only the tied candidates. Original settings will be carried over.',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: Colors.blue.shade900,
              ),
            ),
          ),
          SizedBox(height: 3.h),
          // Start Date
          Text(
            'Start Date',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          InkWell(
            onTap: _selectStartDate,
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppTheme.primaryLight),
                  SizedBox(width: 3.w),
                  Text(
                    _startDate != null
                        ? '${_startDate!.day}/${_startDate!.month}/${_startDate!.year}'
                        : 'Select start date',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: _startDate != null
                          ? AppTheme.textPrimaryLight
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 2.h),
          // End Date
          Text(
            'End Date',
            style: GoogleFonts.inter(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          InkWell(
            onTap: _selectEndDate,
            child: Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today, color: AppTheme.primaryLight),
                  SizedBox(width: 3.w),
                  Text(
                    _endDate != null
                        ? '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}'
                        : 'Select end date',
                    style: GoogleFonts.inter(
                      fontSize: 13.sp,
                      color: _endDate != null
                          ? AppTheme.textPrimaryLight
                          : Colors.grey,
                    ),
                  ),
                ],
              ),
            ),
          ),
          SizedBox(height: 3.h),
          // Schedule Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isScheduling ? null : _scheduleRunoff,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryLight,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: _isScheduling
                  ? const SizedBox(
                      height: 20.0,
                      width: 20.0,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Schedule Runoff Election',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          SizedBox(height: 2.h),
        ],
      ),
    );
  }
}
