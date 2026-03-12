import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import '../../../services/revenue_split_admin_service.dart';

class GlobalSplitConfigWidget extends StatefulWidget {
  final Map<String, dynamic>? globalSplit;
  final VoidCallback onUpdate;

  const GlobalSplitConfigWidget({
    super.key,
    required this.globalSplit,
    required this.onUpdate,
  });

  @override
  State<GlobalSplitConfigWidget> createState() =>
      _GlobalSplitConfigWidgetState();
}

class _GlobalSplitConfigWidgetState extends State<GlobalSplitConfigWidget> {
  final RevenueSplitAdminService _service = RevenueSplitAdminService.instance;

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (context) => _EditGlobalSplitDialog(
        currentSplit: widget.globalSplit,
        onSave: () {
          widget.onUpdate();
          Navigator.pop(context);
        },
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
          // Current Split Card
          Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(3.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Active Global Split',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _showEditDialog,
                        icon: Icon(Icons.edit, size: 16.sp),
                        label: Text('Edit Split'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 2.h),
                  _buildInfoRow(
                    'Creator Percentage',
                    '${widget.globalSplit?['creator_percentage'] ?? 70}%',
                    Colors.green,
                  ),
                  _buildInfoRow(
                    'Platform Percentage',
                    '${widget.globalSplit?['platform_percentage'] ?? 30}%',
                    Colors.blue,
                  ),
                  _buildInfoRow(
                    'Effective Date',
                    widget.globalSplit?['effective_date'] ?? 'N/A',
                    Colors.grey,
                  ),
                  _buildInfoRow(
                    'Last Modified By',
                    widget.globalSplit?['user_profiles']?['full_name'] ??
                        'System',
                    Colors.grey,
                  ),
                  _buildInfoRow(
                    'Reason',
                    widget.globalSplit?['reason'] ?? 'N/A',
                    Colors.grey,
                  ),
                ],
              ),
            ),
          ),

          SizedBox(height: 2.h),

          // Impact Preview
          Text(
            'Impact Preview',
            style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 1.h),
          _buildImpactCard(100),
          _buildImpactCard(1000),
          _buildImpactCard(10000),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color color) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 0.5.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpactCard(double amount) {
    final creatorPercentage = widget.globalSplit?['creator_percentage'] ?? 70;
    final creatorAmount = amount * (creatorPercentage / 100);
    final platformAmount = amount - creatorAmount;

    return Card(
      margin: EdgeInsets.only(bottom: 1.h),
      child: Padding(
        padding: EdgeInsets.all(2.w),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '\$${amount.toStringAsFixed(0)} Transaction',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            Row(
              children: [
                Text(
                  'Creator: \$${creatorAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11.sp, color: Colors.green),
                ),
                SizedBox(width: 2.w),
                Text(
                  'Platform: \$${platformAmount.toStringAsFixed(2)}',
                  style: TextStyle(fontSize: 11.sp, color: Colors.blue),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EditGlobalSplitDialog extends StatefulWidget {
  final Map<String, dynamic>? currentSplit;
  final VoidCallback onSave;

  const _EditGlobalSplitDialog({
    required this.currentSplit,
    required this.onSave,
  });

  @override
  State<_EditGlobalSplitDialog> createState() => _EditGlobalSplitDialogState();
}

class _EditGlobalSplitDialogState extends State<_EditGlobalSplitDialog> {
  final RevenueSplitAdminService _service = RevenueSplitAdminService.instance;
  final _reasonController = TextEditingController();

  late double _creatorPercentage;
  DateTime _effectiveDate = DateTime.now();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _creatorPercentage = (widget.currentSplit?['creator_percentage'] ?? 70)
        .toDouble();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please provide a reason for the change')),
      );
      return;
    }

    setState(() => _isSaving = true);

    final success = await _service.updateGlobalSplit(
      creatorPercentage: _creatorPercentage.round(),
      platformPercentage: 100 - _creatorPercentage.round(),
      effectiveDate: _effectiveDate,
      reason: _reasonController.text.trim(),
    );

    setState(() => _isSaving = false);

    if (success) {
      widget.onSave();
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update split')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformPercentage = 100 - _creatorPercentage.round();

    return AlertDialog(
      title: Text('Edit Global Split'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Creator Percentage: ${_creatorPercentage.round()}%',
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
            SizedBox(height: 1.h),
            Text(
              'Platform Percentage: $platformPercentage%',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
            ),
            SizedBox(height: 2.h),
            Text(
              'Effective Date',
              style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
            ),
            SizedBox(height: 0.5.h),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _effectiveDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(Duration(days: 365)),
                );
                if (date != null) {
                  setState(() => _effectiveDate = date);
                }
              },
              child: Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_effectiveDate.year}-${_effectiveDate.month.toString().padLeft(2, '0')}-${_effectiveDate.day.toString().padLeft(2, '0')}',
                      style: TextStyle(fontSize: 12.sp),
                    ),
                    Icon(Icons.calendar_today, size: 16.sp),
                  ],
                ),
              ),
            ),
            SizedBox(height: 2.h),
            TextField(
              controller: _reasonController,
              decoration: InputDecoration(
                labelText: 'Reason for Change *',
                hintText: 'e.g., Competitive adjustment',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 16.sp),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'This will affect all future payouts',
                      style: TextStyle(fontSize: 11.sp),
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
              : Text('Save'),
        ),
      ],
    );
  }
}
