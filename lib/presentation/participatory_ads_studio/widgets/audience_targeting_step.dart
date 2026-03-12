import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AudienceTargetingStep extends StatefulWidget {
  final List<int> targetZones;
  final List<String> tags;
  final ValueChanged<List<int>> onZonesChanged;
  final ValueChanged<List<String>> onTagsChanged;

  const AudienceTargetingStep({
    super.key,
    required this.targetZones,
    required this.tags,
    required this.onZonesChanged,
    required this.onTagsChanged,
  });

  @override
  State<AudienceTargetingStep> createState() => _AudienceTargetingStepState();
}

class _AudienceTargetingStepState extends State<AudienceTargetingStep> {
  late List<int> _selectedZones;
  late List<String> _tags;
  final TextEditingController _tagController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selectedZones = List.from(widget.targetZones);
    _tags = List.from(widget.tags);
  }

  @override
  void dispose() {
    _tagController.dispose();
    super.dispose();
  }

  String _getZoneName(int zone) {
    const names = {
      1: 'US & Canada',
      2: 'Western Europe',
      3: 'Eastern Europe',
      4: 'Africa',
      5: 'Latin America',
      6: 'Middle East & Asia',
      7: 'Australasia',
      8: 'China & HK',
    };
    return names[zone] ?? 'Zone $zone';
  }

  String _getZoneDescription(int zone) {
    const desc = {
      1: 'High purchasing power',
      2: 'Affluent market',
      3: 'Mid-tier growth',
      4: 'Emerging market',
      5: 'High growth',
      6: 'Diverse market',
      7: 'Premium segment',
      8: 'Large scale market',
    };
    return desc[zone] ?? '';
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Audience Targeting',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          SizedBox(height: 0.5.h),
          Text(
            'Select purchasing power zones and audience tags',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
          ),
          SizedBox(height: 2.h),
          // Zone selection
          Text(
            'Purchasing Power Zones',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: 8,
            itemBuilder: (context, index) {
              final zone = index + 1;
              final isSelected = _selectedZones.contains(zone);
              return AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: EdgeInsets.only(bottom: 1.h),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.primaryLight.withValues(alpha: 0.07)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(10.0),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.primaryLight
                        : Colors.grey.shade300,
                  ),
                ),
                child: CheckboxListTile(
                  title: Text(
                    'Zone $zone – ${_getZoneName(zone)}',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    _getZoneDescription(zone),
                    style: TextStyle(fontSize: 10.sp),
                  ),
                  value: isSelected,
                  activeColor: AppTheme.primaryLight,
                  onChanged: (val) {
                    setState(() {
                      if (val == true) {
                        _selectedZones.add(zone);
                      } else {
                        _selectedZones.remove(zone);
                      }
                    });
                    widget.onZonesChanged(List.from(_selectedZones));
                  },
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                ),
              );
            },
          ),
          SizedBox(height: 2.h),
          // Tags input
          Text(
            'Audience Tags',
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          TextField(
            controller: _tagController,
            decoration: InputDecoration(
              hintText:
                  'Enter tags, comma-separated (e.g. tech, fashion, food)',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10.0),
              ),
              suffixIcon: IconButton(
                icon: const Icon(Icons.add),
                onPressed: _addTags,
              ),
            ),
            onSubmitted: (_) => _addTags(),
          ),
          SizedBox(height: 1.h),
          if (_tags.isNotEmpty)
            Wrap(
              spacing: 2.w,
              runSpacing: 0.8.h,
              children: _tags.map((tag) {
                return Chip(
                  label: Text(tag, style: TextStyle(fontSize: 10.sp)),
                  deleteIcon: const Icon(Icons.close, size: 14),
                  onDeleted: () {
                    setState(() => _tags.remove(tag));
                    widget.onTagsChanged(List.from(_tags));
                  },
                  backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.1),
                );
              }).toList(),
            ),
        ],
      ),
    );
  }

  void _addTags() {
    final input = _tagController.text.trim();
    if (input.isEmpty) return;
    final newTags = input
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty && !_tags.contains(t))
        .toList();
    setState(() {
      _tags.addAll(newTags);
      _tagController.clear();
    });
    widget.onTagsChanged(List.from(_tags));
  }
}
