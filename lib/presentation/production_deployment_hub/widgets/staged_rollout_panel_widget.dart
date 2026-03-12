import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class StagedRolloutPanelWidget extends StatefulWidget {
  const StagedRolloutPanelWidget({super.key});

  @override
  State<StagedRolloutPanelWidget> createState() =>
      _StagedRolloutPanelWidgetState();
}

class _StagedRolloutPanelWidgetState extends State<StagedRolloutPanelWidget> {
  int _currentStageIndex = 1;
  bool _isHalted = false;
  bool _isPromoting = false;

  final List<Map<String, dynamic>> _stages = [
    {
      'name': 'Canary',
      'percentage': 10,
      'user_count': 1285,
      'success_rate': 99.8,
      'error_count': 3,
      'status': 'completed',
    },
    {
      'name': 'Beta',
      'percentage': 25,
      'user_count': 3212,
      'success_rate': 99.6,
      'error_count': 12,
      'status': 'active',
    },
    {
      'name': 'General',
      'percentage': 50,
      'user_count': 0,
      'success_rate': 0,
      'error_count': 0,
      'status': 'pending',
    },
    {
      'name': 'Full',
      'percentage': 100,
      'user_count': 0,
      'success_rate': 0,
      'error_count': 0,
      'status': 'pending',
    },
  ];

  void _promoteToNextStage() async {
    final currentStage = _stages[_currentStageIndex];
    final errorRate = 100 - currentStage['success_rate'];

    if (errorRate > 1.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Cannot promote: error rate ${errorRate.toStringAsFixed(1)}% exceeds 1% threshold',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isPromoting = true);
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _stages[_currentStageIndex]['status'] = 'completed';
        if (_currentStageIndex < _stages.length - 1) {
          _currentStageIndex++;
          _stages[_currentStageIndex]['status'] = 'active';
          _stages[_currentStageIndex]['user_count'] =
              (12847 * _stages[_currentStageIndex]['percentage'] / 100).toInt();
          _stages[_currentStageIndex]['success_rate'] = 99.5;
          _stages[_currentStageIndex]['error_count'] = 5;
        }
        _isPromoting = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Promoted to ${_stages[_currentStageIndex]['name']} stage',
          ),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _emergencyHalt() {
    setState(() => _isHalted = !_isHalted);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _isHalted
              ? 'Rollout HALTED — reverting to previous stage'
              : 'Rollout resumed',
        ),
        backgroundColor: _isHalted ? Colors.red : Colors.green,
      ),
    );
  }

  Color _getStageColor(String status) {
    switch (status) {
      case 'completed':
        return Colors.green;
      case 'active':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(3.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Staged Rollout',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isHalted ? Colors.green : Colors.red,
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                ),
                onPressed: _emergencyHalt,
                icon: Icon(
                  _isHalted ? Icons.play_arrow : Icons.stop,
                  color: Colors.white,
                  size: 16,
                ),
                label: Text(
                  _isHalted ? 'Resume' : 'Emergency Stop',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ),
          if (_isHalted)
            Container(
              margin: EdgeInsets.only(top: 1.h),
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.red.withAlpha(51),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withAlpha(128)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 16),
                  SizedBox(width: 2.w),
                  Text(
                    'ROLLOUT HALTED — Reverting to previous stage',
                    style: GoogleFonts.inter(
                      color: Colors.red,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          SizedBox(height: 2.h),
          ..._stages.asMap().entries.map((entry) {
            final i = entry.key;
            final stage = entry.value;
            final isActive = stage['status'] == 'active';
            return Container(
              margin: EdgeInsets.only(bottom: 1.5.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isActive
                      ? Colors.blue.withAlpha(128)
                      : _getStageColor(stage['status']).withAlpha(51),
                  width: isActive ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: _getStageColor(
                                stage['status'],
                              ).withAlpha(51),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Text(
                                '${i + 1}',
                                style: GoogleFonts.inter(
                                  color: _getStageColor(stage['status']),
                                  fontSize: 10.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            '${stage['name']} — ${stage['percentage']}%',
                            style: GoogleFonts.inter(
                              color: Colors.white,
                              fontSize: 13.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.3.h,
                        ),
                        decoration: BoxDecoration(
                          color: _getStageColor(stage['status']).withAlpha(51),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          stage['status'].toUpperCase(),
                          style: GoogleFonts.inter(
                            color: _getStageColor(stage['status']),
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (stage['status'] != 'pending') ...[
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        _buildStageMetric(
                          'Users',
                          stage['user_count'].toString(),
                        ),
                        SizedBox(width: 4.w),
                        _buildStageMetric(
                          'Success',
                          '${stage['success_rate']}%',
                        ),
                        SizedBox(width: 4.w),
                        _buildStageMetric(
                          'Errors',
                          stage['error_count'].toString(),
                        ),
                      ],
                    ),
                  ],
                  if (isActive && !_isHalted) ...[
                    SizedBox(height: 1.h),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          padding: EdgeInsets.symmetric(vertical: 1.h),
                        ),
                        onPressed: _isPromoting ? null : _promoteToNextStage,
                        child: _isPromoting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Promote to Next Stage',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStageMetric(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(color: Colors.grey, fontSize: 9.sp),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 11.sp,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
