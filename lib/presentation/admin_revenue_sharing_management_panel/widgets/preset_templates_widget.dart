import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/revenue_share_service.dart';

class PresetTemplatesWidget extends StatefulWidget {
  final VoidCallback onUpdate;

  const PresetTemplatesWidget({super.key, required this.onUpdate});

  @override
  State<PresetTemplatesWidget> createState() => _PresetTemplatesWidgetState();
}

class _PresetTemplatesWidgetState extends State<PresetTemplatesWidget> {
  final RevenueShareService _revenueService = RevenueShareService.instance;

  final List<Map<String, dynamic>> _templates = [
    {
      'name': 'Standard 70/30',
      'platform': 30.0,
      'creator': 70.0,
      'description': 'Balanced split for established markets',
      'icon': Icons.balance,
      'color': const Color(0xFF3B82F6),
    },
    {
      'name': 'Premium Markets 60/40',
      'platform': 40.0,
      'creator': 60.0,
      'description': 'Higher platform share for premium markets',
      'icon': Icons.star,
      'color': const Color(0xFFF59E0B),
    },
    {
      'name': 'Emerging Markets 75/25',
      'platform': 25.0,
      'creator': 75.0,
      'description': 'Creator-friendly split for growth markets',
      'icon': Icons.trending_up,
      'color': const Color(0xFF10B981),
    },
    {
      'name': 'High Growth 80/20',
      'platform': 20.0,
      'creator': 80.0,
      'description': 'Maximum creator incentive for expansion',
      'icon': Icons.rocket_launch,
      'color': const Color(0xFF8B5CF6),
    },
  ];

  bool _isProcessing = false;

  Future<void> _applyTemplate(Map<String, dynamic> template) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Apply Template'),
        content: Text(
          'Apply "${template['name']}" template (${template['platform']}% / ${template['creator']}%) to all countries?\n\nThis will update all configured revenue splits.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: template['color']),
            child: Text('Apply'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);

      // Get all country codes
      final allSplits = await _revenueService.getAllRevenueSplits();
      final countryCodes = allSplits
          .map((s) => s['country_code'] as String)
          .toList();

      final success = await _revenueService.applyPresetTemplate(
        templateName: template['name'],
        countryCodes: countryCodes,
      );

      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Template applied successfully'
                  : 'Failed to apply template',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );

        if (success) widget.onUpdate();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: EdgeInsets.all(4.w),
      itemCount: _templates.length,
      itemBuilder: (context, index) {
        final template = _templates[index];
        return _buildTemplateCard(template);
      },
    );
  }

  Widget _buildTemplateCard(Map<String, dynamic> template) {
    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: InkWell(
        onTap: _isProcessing ? null : () => _applyTemplate(template),
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: EdgeInsets.all(4.w),
          child: Row(
            children: [
              Container(
                width: 15.w,
                height: 15.w,
                decoration: BoxDecoration(
                  color: (template['color'] as Color).withAlpha(26),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Icon(
                  template['icon'],
                  color: template['color'],
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      template['name'],
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 0.5.h),
                    Text(
                      template['description'],
                      style: TextStyle(
                        fontSize: 11.sp,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: 1.h),
                    Row(
                      children: [
                        _buildPercentageBadge(
                          'Platform',
                          template['platform'],
                          Color(0xFFEF4444),
                        ),
                        SizedBox(width: 2.w),
                        _buildPercentageBadge(
                          'Creator',
                          template['creator'],
                          Color(0xFF10B981),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16.sp,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPercentageBadge(String label, double percentage, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
      decoration: BoxDecoration(
        color: color.withAlpha(26),
        borderRadius: BorderRadius.circular(6.0),
        border: Border.all(color: color.withAlpha(51)),
      ),
      child: Text(
        '$label ${percentage.toStringAsFixed(0)}%',
        style: TextStyle(
          fontSize: 10.sp,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
