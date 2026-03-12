import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../services/revenue_share_service.dart';

class CountryConfigurationMatrixWidget extends StatefulWidget {
  final List<Map<String, dynamic>> revenueSplits;
  final VoidCallback onUpdate;

  const CountryConfigurationMatrixWidget({
    super.key,
    required this.revenueSplits,
    required this.onUpdate,
  });

  @override
  State<CountryConfigurationMatrixWidget> createState() =>
      _CountryConfigurationMatrixWidgetState();
}

class _CountryConfigurationMatrixWidgetState
    extends State<CountryConfigurationMatrixWidget> {
  final RevenueShareService _revenueService = RevenueShareService.instance;
  String _searchQuery = '';
  String? _editingCountryCode;
  double _tempPlatformPercentage = 30.0;
  double _tempCreatorPercentage = 70.0;

  List<Map<String, dynamic>> get _filteredSplits {
    if (_searchQuery.isEmpty) return widget.revenueSplits;

    return widget.revenueSplits.where((split) {
      final countryName = (split['country_name'] as String? ?? '')
          .toLowerCase();
      final countryCode = (split['country_code'] as String? ?? '')
          .toLowerCase();
      final query = _searchQuery.toLowerCase();

      return countryName.contains(query) || countryCode.contains(query);
    }).toList();
  }

  void _startEditing(Map<String, dynamic> split) {
    setState(() {
      _editingCountryCode = split['country_code'];
      _tempPlatformPercentage = (split['platform_percentage'] as num? ?? 30.0)
          .toDouble();
      _tempCreatorPercentage = (split['creator_percentage'] as num? ?? 70.0)
          .toDouble();
    });
  }

  Future<void> _saveChanges(String countryCode) async {
    final success = await _revenueService.updateRevenueSplit(
      countryCode: countryCode,
      platformPercentage: _tempPlatformPercentage,
      creatorPercentage: _tempCreatorPercentage,
      changeReason: 'Manual update from admin panel',
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Revenue split updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      setState(() => _editingCountryCode = null);
      widget.onUpdate();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update revenue split'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _cancelEditing() {
    setState(() => _editingCountryCode = null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: EdgeInsets.all(4.w),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search countries...',
              prefixIcon: Icon(Icons.search, size: 20.sp),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 4.w,
                vertical: 1.5.h,
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.symmetric(horizontal: 4.w),
            itemCount: _filteredSplits.length,
            itemBuilder: (context, index) {
              final split = _filteredSplits[index];
              final countryCode = split['country_code'] as String;
              final isEditing = _editingCountryCode == countryCode;

              return _buildCountryCard(split, isEditing);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCountryCard(Map<String, dynamic> split, bool isEditing) {
    final countryCode = split['country_code'] as String;
    final countryName = split['country_name'] as String;
    final platformPercentage = (split['platform_percentage'] as num? ?? 30.0)
        .toDouble();
    final creatorPercentage = (split['creator_percentage'] as num? ?? 70.0)
        .toDouble();

    return Card(
      margin: EdgeInsets.only(bottom: 2.h),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      child: Padding(
        padding: EdgeInsets.all(4.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 12.w,
                  height: 12.w,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Center(
                    child: Text(
                      countryCode,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        countryName,
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        countryCode,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isEditing)
                  IconButton(
                    icon: Icon(Icons.edit, size: 20.sp),
                    onPressed: () => _startEditing(split),
                  ),
              ],
            ),
            SizedBox(height: 2.h),
            if (isEditing)
              ..._buildEditingControls()
            else
              ..._buildDisplayMode(platformPercentage, creatorPercentage),
            if (isEditing) ..._buildActionButtons(countryCode),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildDisplayMode(
    double platformPercentage,
    double creatorPercentage,
  ) {
    return [
      Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Platform',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
                Text(
                  '${platformPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFFEF4444),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Creator',
                  style: TextStyle(fontSize: 11.sp, color: Colors.grey[600]),
                ),
                Text(
                  '${creatorPercentage.toStringAsFixed(1)}%',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      SizedBox(height: 2.h),
      _buildSplitVisualization(platformPercentage, creatorPercentage),
    ];
  }

  List<Widget> _buildEditingControls() {
    return [
      Text(
        'Platform: ${_tempPlatformPercentage.toStringAsFixed(1)}%',
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
      ),
      Slider(
        value: _tempPlatformPercentage,
        min: 0,
        max: 100,
        divisions: 100,
        label: '${_tempPlatformPercentage.toStringAsFixed(1)}%',
        onChanged: (value) {
          setState(() {
            _tempPlatformPercentage = value;
            _tempCreatorPercentage = (100 - value).toDouble();
          });
        },
      ),
      SizedBox(height: 1.h),
      Text(
        'Creator: ${_tempCreatorPercentage.toStringAsFixed(1)}%',
        style: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w600),
      ),
      Slider(
        value: _tempCreatorPercentage,
        min: 0,
        max: 100,
        divisions: 100,
        label: '${_tempCreatorPercentage.toStringAsFixed(1)}%',
        onChanged: (value) {
          setState(() {
            _tempCreatorPercentage = value;
            _tempPlatformPercentage = (100 - value).toDouble();
          });
        },
      ),
      SizedBox(height: 1.h),
      _buildSplitVisualization(_tempPlatformPercentage, _tempCreatorPercentage),
    ];
  }

  Widget _buildSplitVisualization(double platform, double creator) {
    return Container(
      height: 4.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Row(
        children: [
          Expanded(
            flex: platform.toInt(),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFFEF4444),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(7.0),
                  bottomLeft: Radius.circular(7.0),
                ),
              ),
              child: Center(
                child: Text(
                  '${platform.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            flex: creator.toInt(),
            child: Container(
              decoration: BoxDecoration(
                color: Color(0xFF10B981),
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(7.0),
                  bottomRight: Radius.circular(7.0),
                ),
              ),
              child: Center(
                child: Text(
                  '${creator.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(String countryCode) {
    return [
      SizedBox(height: 2.h),
      Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _cancelEditing,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey[400]!),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text('Cancel'),
            ),
          ),
          SizedBox(width: 3.w),
          Expanded(
            child: ElevatedButton(
              onPressed: () => _saveChanges(countryCode),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF3B82F6),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              child: Text('Save Changes'),
            ),
          ),
        ],
      ),
    ];
  }
}
