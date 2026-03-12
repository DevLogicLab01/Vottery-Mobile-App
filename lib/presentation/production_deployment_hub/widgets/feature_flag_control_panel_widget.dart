import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class FeatureFlagControlPanelWidget extends StatefulWidget {
  const FeatureFlagControlPanelWidget({super.key});

  @override
  State<FeatureFlagControlPanelWidget> createState() =>
      _FeatureFlagControlPanelWidgetState();
}

class _FeatureFlagControlPanelWidgetState
    extends State<FeatureFlagControlPanelWidget> {
  final List<Map<String, dynamic>> _flags = [
    {
      'name': 'jolts_video_analytics',
      'description': 'Enable Jolts video tracking dashboard',
      'enabled': true,
      'percentage': 100,
      'segments': ['all'],
      'created_by': 'admin',
      'deployed_at': '2026-02-27',
    },
    {
      'name': 'adaptive_layout_v2',
      'description': 'New 14.5cm adaptive content boxes',
      'enabled': true,
      'percentage': 50,
      'segments': ['beta_users'],
      'created_by': 'dev',
      'deployed_at': '2026-02-26',
    },
    {
      'name': 'production_security_hardening',
      'description': 'SSL/TLS enforcement and DDoS protection',
      'enabled': false,
      'percentage': 10,
      'segments': ['internal'],
      'created_by': 'security',
      'deployed_at': '2026-02-25',
    },
  ];

  void _showCreateFlagDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    double percentage = 10;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Create Feature Flag',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Flag Name (snake_case)',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(height: 1.5.h),
              TextField(
                controller: descController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Description',
                  labelStyle: const TextStyle(color: Colors.grey),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
              SizedBox(height: 1.5.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rollout: ${percentage.toInt()}%',
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12.sp,
                    ),
                  ),
                ],
              ),
              Slider(
                value: percentage,
                min: 0,
                max: 100,
                divisions: 10,
                activeColor: const Color(0xFF6366F1),
                onChanged: (v) => setDialogState(() => percentage = v),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF6366F1),
              ),
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  setState(() {
                    _flags.insert(0, {
                      'name': nameController.text,
                      'description': descController.text,
                      'enabled': false,
                      'percentage': percentage.toInt(),
                      'segments': ['all'],
                      'created_by': 'current_user',
                      'deployed_at': DateTime.now().toString().substring(0, 10),
                    });
                  });
                  Navigator.pop(ctx);
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
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
                'Feature Flags',
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6366F1),
                  padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
                ),
                onPressed: _showCreateFlagDialog,
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                label: Text(
                  'New Flag',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          ..._flags.map(
            (flag) => Container(
              margin: EdgeInsets.only(bottom: 1.5.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: flag['enabled']
                      ? Colors.green.withAlpha(77)
                      : Colors.grey.withAlpha(51),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              flag['name'],
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 12.sp,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              flag['description'],
                              style: GoogleFonts.inter(
                                color: Colors.grey,
                                fontSize: 10.sp,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: flag['enabled'],
                        activeThumbColor: Colors.green,
                        onChanged: (v) => setState(() => flag['enabled'] = v),
                      ),
                    ],
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 2.w,
                          vertical: 0.3.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withAlpha(51),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${flag['percentage']}% rollout',
                          style: GoogleFonts.inter(
                            color: const Color(0xFF6366F1),
                            fontSize: 9.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      SizedBox(width: 2.w),
                      Text(
                        'by ${flag['created_by']} • ${flag['deployed_at']}',
                        style: GoogleFonts.inter(
                          color: Colors.grey.shade600,
                          fontSize: 9.sp,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
