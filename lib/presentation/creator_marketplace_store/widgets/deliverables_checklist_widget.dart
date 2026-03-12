import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class DeliverablesChecklistWidget extends StatefulWidget {
  final Map<String, dynamic> service;

  const DeliverablesChecklistWidget({super.key, required this.service});

  @override
  State<DeliverablesChecklistWidget> createState() =>
      _DeliverablesChecklistWidgetState();
}

class _DeliverablesChecklistWidgetState
    extends State<DeliverablesChecklistWidget> {
  bool _includedExpanded = true;
  bool _timelineExpanded = false;
  bool _requirementsExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Deliverables Checklist',
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 2.h),
        _buildExpandableSection(
          title: 'What\'s Included',
          icon: Icons.check_circle_outline,
          isExpanded: _includedExpanded,
          onToggle: () =>
              setState(() => _includedExpanded = !_includedExpanded),
          content: _buildIncludedContent(),
        ),
        SizedBox(height: 1.h),
        _buildExpandableSection(
          title: 'Timeline',
          icon: Icons.schedule,
          isExpanded: _timelineExpanded,
          onToggle: () =>
              setState(() => _timelineExpanded = !_timelineExpanded),
          content: _buildTimelineContent(),
        ),
        SizedBox(height: 1.h),
        _buildExpandableSection(
          title: 'Requirements',
          icon: Icons.assignment,
          isExpanded: _requirementsExpanded,
          onToggle: () =>
              setState(() => _requirementsExpanded = !_requirementsExpanded),
          content: _buildRequirementsContent(),
        ),
      ],
    );
  }

  Widget _buildExpandableSection({
    required String title,
    required IconData icon,
    required bool isExpanded,
    required VoidCallback onToggle,
    required Widget content,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: AppTheme.textSecondaryLight.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: onToggle,
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Icon(icon, color: AppTheme.primaryLight, size: 6.w),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: AppTheme.textSecondaryLight,
                    size: 6.w,
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Container(
              padding: EdgeInsets.all(4.w),
              decoration: BoxDecoration(
                color: AppTheme.backgroundLight,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12.0),
                ),
              ),
              child: content,
            ),
        ],
      ),
    );
  }

  Widget _buildIncludedContent() {
    final deliverables = [
      {'icon': Icons.design_services, 'text': '2 design concepts'},
      {'icon': Icons.edit, 'text': '3 rounds of revisions'},
      {'icon': Icons.folder, 'text': 'Source files included'},
      {'icon': Icons.copyright, 'text': 'Commercial usage rights'},
      {'icon': Icons.priority_high, 'text': 'Priority support'},
    ];

    return Column(
      children: deliverables.map((item) {
        return Padding(
          padding: EdgeInsets.only(bottom: 1.5.h),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Icon(
                  item['icon'] as IconData,
                  color: AppTheme.primaryLight,
                  size: 5.w,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  item['text'] as String,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.textPrimaryLight,
                  ),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTimelineContent() {
    final milestones = [
      {'day': 'Day 1', 'task': 'Initial consultation & requirements gathering'},
      {'day': 'Day 2-3', 'task': 'First draft delivery'},
      {'day': 'Day 4', 'task': 'Revision round 1'},
      {'day': 'Day 5', 'task': 'Final delivery & handoff'},
    ];

    return Column(
      children: milestones.asMap().entries.map((entry) {
        final index = entry.key;
        final milestone = entry.value;
        final isLast = index == milestones.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 8.w,
                  height: 8.w,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: TextStyle(
                        fontSize: 11.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2.0,
                    height: 6.h,
                    color: AppTheme.textSecondaryLight.withValues(alpha: 0.3),
                  ),
              ],
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : 2.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      milestone['day'] as String,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryLight,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      milestone['task'] as String,
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: AppTheme.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }

  Widget _buildRequirementsContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What the creator needs from you:',
          style: TextStyle(
            fontSize: 12.sp,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        _buildRequirementItem('Brand guidelines or style preferences'),
        _buildRequirementItem('Target audience information'),
        _buildRequirementItem('Any existing assets or references'),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: AppTheme.primaryLight.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8.0),
            border: Border.all(
              color: AppTheme.primaryLight.withValues(alpha: 0.3),
              style: BorderStyle.solid,
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.upload_file, color: AppTheme.primaryLight, size: 6.w),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'Upload files after purchase',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRequirementItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 1.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 0.5.h),
            width: 1.5.w,
            height: 1.5.w,
            decoration: BoxDecoration(
              color: AppTheme.textSecondaryLight,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: 2.w),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11.sp,
                color: AppTheme.textPrimaryLight,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
