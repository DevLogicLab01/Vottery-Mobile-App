import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/revenue_share_service.dart';

class BulkUpdateToolsWidget extends StatefulWidget {
  final VoidCallback onUpdate;

  const BulkUpdateToolsWidget({super.key, required this.onUpdate});

  @override
  State<BulkUpdateToolsWidget> createState() => _BulkUpdateToolsWidgetState();
}

class _BulkUpdateToolsWidgetState extends State<BulkUpdateToolsWidget> {
  final RevenueShareService _revenueService = RevenueShareService.instance;

  final Map<String, List<String>> _regions = {
    'North America': ['US', 'CA', 'MX'],
    'Europe': ['GB', 'DE', 'FR', 'IT', 'ES'],
    'Asia': ['JP', 'CN', 'IN', 'SG'],
    'Middle East': ['AE', 'SA'],
    'Africa': ['ZA', 'NG', 'KE'],
    'Oceania': ['AU', 'NZ'],
    'South America': ['BR', 'AR', 'CL'],
  };

  String? _selectedRegion;
  double _platformPercentage = 30.0;
  double _creatorPercentage = 70.0;
  bool _isProcessing = false;

  Future<void> _applyBulkUpdate() async {
    if (_selectedRegion == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Bulk Update'),
        content: Text(
          'Apply ${_platformPercentage.toStringAsFixed(1)}% / ${_creatorPercentage.toStringAsFixed(1)}% split to all countries in $_selectedRegion?\n\nCountries: ${_regions[_selectedRegion]!.join(", ")}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Apply'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isProcessing = true);

      final success = await _revenueService.bulkUpdateByRegion(
        countryCodes: _regions[_selectedRegion]!,
        platformPercentage: _platformPercentage,
        creatorPercentage: _creatorPercentage,
      );

      setState(() => _isProcessing = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Bulk update applied successfully'
                  : 'Failed to apply bulk update',
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
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Bulk Regional Update',
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 2.h),
          DropdownButtonFormField<String>(
            initialValue: _selectedRegion,
            decoration: InputDecoration(
              labelText: 'Select Region',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
            ),
            items: _regions.keys.map((region) {
              return DropdownMenuItem(value: region, child: Text(region));
            }).toList(),
            onChanged: (value) => setState(() => _selectedRegion = value),
          ),
          if (_selectedRegion != null) ...[
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(3.w),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.blue[200]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Countries in $_selectedRegion:',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Wrap(
                    spacing: 2.w,
                    runSpacing: 1.h,
                    children: _regions[_selectedRegion]!
                        .map(
                          (code) => Chip(
                            label: Text(code),
                            backgroundColor: Colors.white,
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
          ],
          SizedBox(height: 3.h),
          Text(
            'Platform: ${_platformPercentage.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _platformPercentage,
            min: 0,
            max: 100,
            divisions: 100,
            label: '${_platformPercentage.toStringAsFixed(1)}%',
            onChanged: (value) {
              setState(() {
                _platformPercentage = value;
                _creatorPercentage = (100 - value).toDouble();
              });
            },
          ),
          SizedBox(height: 2.h),
          Text(
            'Creator: ${_creatorPercentage.toStringAsFixed(1)}%',
            style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
          ),
          Slider(
            value: _creatorPercentage,
            min: 0,
            max: 100,
            divisions: 100,
            label: '${_creatorPercentage.toStringAsFixed(1)}%',
            onChanged: (value) {
              setState(() {
                _creatorPercentage = value;
                _platformPercentage = (100 - value).toDouble();
              });
            },
          ),
          SizedBox(height: 3.h),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _selectedRegion == null || _isProcessing
                  ? null
                  : _applyBulkUpdate,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3B82F6),
                padding: EdgeInsets.symmetric(vertical: 2.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
              child: _isProcessing
                  ? SizedBox(
                      height: 20.sp,
                      width: 20.sp,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      'Apply Bulk Update',
                      style: TextStyle(fontSize: 14.sp),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
