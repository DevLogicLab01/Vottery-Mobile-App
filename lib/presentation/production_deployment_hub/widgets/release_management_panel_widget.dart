import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

class ReleaseManagementPanelWidget extends StatefulWidget {
  const ReleaseManagementPanelWidget({super.key});

  @override
  State<ReleaseManagementPanelWidget> createState() =>
      _ReleaseManagementPanelWidgetState();
}

class _ReleaseManagementPanelWidgetState
    extends State<ReleaseManagementPanelWidget> {
  final List<Map<String, dynamic>> _releases = [
    {
      'version': 'v2.4.1',
      'status': 'production',
      'deployer': 'admin@vottery.com',
      'timestamp': '2026-02-27 18:00',
      'result': 'success',
      'notes': 'Hotfix for VP calculation bug',
    },
    {
      'version': 'v2.4.0',
      'status': 'production',
      'deployer': 'dev@vottery.com',
      'timestamp': '2026-02-26 14:30',
      'result': 'success',
      'notes': 'Feature: Jolts video analytics',
    },
    {
      'version': 'v2.3.9',
      'status': 'rolled_back',
      'deployer': 'admin@vottery.com',
      'timestamp': '2026-02-25 10:00',
      'result': 'rolled_back',
      'notes': 'Rolled back due to payment issue',
    },
  ];

  void _showCreateReleaseDialog() {
    final versionController = TextEditingController();
    final notesController = TextEditingController();
    String selectedEnv = 'staging';
    String selectedStrategy = 'blue_green';

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          title: Text(
            'Create New Release',
            style: GoogleFonts.inter(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: versionController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Version Number',
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
                  controller: notesController,
                  maxLines: 3,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Release Notes',
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
                DropdownButtonFormField<String>(
                  initialValue: selectedEnv,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Target Environment',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  items: ['staging', 'production']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedEnv = v!),
                ),
                SizedBox(height: 1.5.h),
                DropdownButtonFormField<String>(
                  initialValue: selectedStrategy,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Deployment Strategy',
                    labelStyle: const TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.grey),
                    ),
                  ),
                  items: ['blue_green', 'rolling']
                      .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                      .toList(),
                  onChanged: (v) => setDialogState(() => selectedStrategy = v!),
                ),
              ],
            ),
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
                if (versionController.text.isNotEmpty) {
                  setState(() {
                    _releases.insert(0, {
                      'version': versionController.text,
                      'status': selectedEnv,
                      'deployer': 'current_user@vottery.com',
                      'timestamp': DateTime.now().toString().substring(0, 16),
                      'result': 'pending',
                      'notes': notesController.text,
                    });
                  });
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Release ${versionController.text} created for $selectedEnv',
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              child: const Text('Create Release'),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'success':
        return Colors.green;
      case 'rolled_back':
        return Colors.orange;
      case 'failed':
        return Colors.red;
      case 'pending':
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
                'Release Management',
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
                onPressed: _showCreateReleaseDialog,
                icon: const Icon(Icons.add, color: Colors.white, size: 16),
                label: Text(
                  'New Release',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11.sp,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 2.h),
          Container(
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green.withAlpha(77)),
            ),
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                  ),
                ),
                SizedBox(width: 2.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Production: v2.4.1',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Deployed 2026-02-27 18:00 — Healthy',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 10.sp,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 2.h),
          Text(
            'Release History',
            style: GoogleFonts.inter(
              color: Colors.grey,
              fontSize: 11.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 1.h),
          ..._releases.map(
            (release) => Container(
              margin: EdgeInsets.only(bottom: 1.h),
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              release['version'],
                              style: GoogleFonts.inter(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(width: 2.w),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 2.w,
                                vertical: 0.3.h,
                              ),
                              decoration: BoxDecoration(
                                color: _getStatusColor(
                                  release['result'],
                                ).withAlpha(51),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                release['result'].toUpperCase(),
                                style: GoogleFonts.inter(
                                  color: _getStatusColor(release['result']),
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 0.5.h),
                        Text(
                          release['notes'],
                          style: GoogleFonts.inter(
                            color: Colors.grey,
                            fontSize: 10.sp,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '${release['deployer']} • ${release['timestamp']}',
                          style: GoogleFonts.inter(
                            color: Colors.grey.shade600,
                            fontSize: 9.sp,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    release['result'] == 'success'
                        ? Icons.check_circle
                        : release['result'] == 'rolled_back'
                        ? Icons.undo
                        : Icons.pending,
                    color: _getStatusColor(release['result']),
                    size: 20,
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
