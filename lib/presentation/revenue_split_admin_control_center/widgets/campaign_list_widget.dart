import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/revenue_split_admin_service.dart';

class CampaignListWidget extends StatelessWidget {
  final List<Map<String, dynamic>> campaigns;
  final VoidCallback onUpdate;

  const CampaignListWidget({
    super.key,
    required this.campaigns,
    required this.onUpdate,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(3.w),
          child: ElevatedButton.icon(
            onPressed: () => _showCreateCampaignDialog(context),
            icon: Icon(Icons.add),
            label: Text('Create Campaign'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
              foregroundColor: Colors.white,
              minimumSize: Size(double.infinity, 5.h),
            ),
          ),
        ),
        Expanded(
          child: campaigns.isEmpty
              ? Center(
                  child: Text(
                    'No campaigns yet',
                    style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                  ),
                )
              : ListView.builder(
                  padding: EdgeInsets.symmetric(horizontal: 3.w),
                  itemCount: campaigns.length,
                  itemBuilder: (context, index) {
                    final campaign = campaigns[index];
                    return _CampaignCard(
                      campaign: campaign,
                      onUpdate: onUpdate,
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showCreateCampaignDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => _CreateCampaignDialog(onSave: onUpdate),
    );
  }
}

class _CampaignCard extends StatelessWidget {
  final Map<String, dynamic> campaign;
  final VoidCallback onUpdate;

  const _CampaignCard({required this.campaign, required this.onUpdate});

  @override
  Widget build(BuildContext context) {
    final status = campaign['status'] as String;
    final statusColor = _getStatusColor(status);

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      child: Padding(
        padding: EdgeInsets.all(3.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    campaign['campaign_name'] ?? 'Unnamed Campaign',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 2.w,
                    vertical: 0.5.h,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withAlpha(51),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    status.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 1.h),
            Text(
              campaign['campaign_description'] ?? '',
              style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: 1.h),
            Row(
              children: [
                Icon(Icons.percent, size: 14.sp, color: Colors.green),
                SizedBox(width: 1.w),
                Text(
                  'Creator Split: ${campaign['creator_split_percentage']}%',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14.sp, color: Colors.grey),
                SizedBox(width: 1.w),
                Text(
                  '${campaign['start_date']} - ${campaign['end_date'] ?? 'Ongoing'}',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            SizedBox(height: 0.5.h),
            Row(
              children: [
                Icon(Icons.people, size: 14.sp, color: Colors.grey),
                SizedBox(width: 1.w),
                Text(
                  'Enrolled: ${campaign['enrolled_creator_count'] ?? 0} creators',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
              ],
            ),
            if (status == 'active') ...[
              SizedBox(height: 1.h),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _endCampaign(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                      ),
                      child: Text('End Campaign'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'scheduled':
        return Colors.blue;
      case 'paused':
        return Colors.orange;
      case 'ended':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  Future<void> _endCampaign(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('End Campaign'),
        content: Text('Are you sure you want to end this campaign?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text('End'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final service = RevenueSplitAdminService.instance;
      final success = await service.updateCampaign(
        campaignId: campaign['campaign_id'] as String,
        status: 'ended',
      );
      if (success) {
        onUpdate();
      }
    }
  }
}

class _CreateCampaignDialog extends StatefulWidget {
  final VoidCallback onSave;

  const _CreateCampaignDialog({required this.onSave});

  @override
  State<_CreateCampaignDialog> createState() => _CreateCampaignDialogState();
}

class _CreateCampaignDialogState extends State<_CreateCampaignDialog> {
  final _service = RevenueSplitAdminService.instance;
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _type = 'temporary';
  double _creatorPercentage = 75;
  final DateTime _startDate = DateTime.now();
  DateTime? _endDate;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please enter campaign name')));
      return;
    }

    setState(() => _isSaving = true);

    final campaignId = await _service.createCampaign(
      campaignName: _nameController.text.trim(),
      campaignDescription: _descriptionController.text.trim(),
      campaignType: _type,
      creatorSplitPercentage: _creatorPercentage.round(),
      eligibilityCriteria: {
        'tier': ['All'],
        'category': ['All'],
        'min_earnings': 0,
      },
      startDate: _startDate,
      endDate: _endDate,
    );

    setState(() => _isSaving = false);

    if (campaignId != null) {
      widget.onSave();
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to create campaign')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Campaign'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Campaign Name *',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: 'Description',
                border: OutlineInputBorder(),
              ),
              maxLines: 2,
            ),
            SizedBox(height: 2.h),
            Text(
              'Campaign Type',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Temporary', style: TextStyle(fontSize: 11.sp)),
                    value: 'temporary',
                    groupValue: _type,
                    onChanged: (value) {
                      setState(() => _type = value!);
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: Text('Permanent', style: TextStyle(fontSize: 11.sp)),
                    value: 'permanent',
                    groupValue: _type,
                    onChanged: (value) {
                      setState(() => _type = value!);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Text(
              'Creator Split: ${_creatorPercentage.round()}%',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _creatorPercentage,
              min: 50,
              max: 90,
              divisions: 40,
              label: '${_creatorPercentage.round()}%',
              onChanged: (value) {
                setState(() => _creatorPercentage = value);
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _save,
          child: _isSaving
              ? SizedBox(
                  width: 16.sp,
                  height: 16.sp,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text('Create'),
        ),
      ],
    );
  }
}