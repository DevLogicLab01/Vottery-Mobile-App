import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/election_permission_service.dart';
import '../../../theme/app_theme.dart';

/// Widget for selecting election permission type and configuring access controls
class PermissionControlsWidget extends StatefulWidget {
  final String selectedPermissionType;
  final List<String> selectedCountries;
  final String? selectedGroupId;
  final Function(String) onPermissionTypeChanged;
  final Function(List<String>) onSelectedCountriesChanged;
  final Function(String?) onSelectedGroupChanged;

  const PermissionControlsWidget({
    super.key,
    required this.selectedPermissionType,
    required this.selectedCountries,
    this.selectedGroupId,
    required this.onPermissionTypeChanged,
    required this.onSelectedCountriesChanged,
    required this.onSelectedGroupChanged,
  });

  @override
  State<PermissionControlsWidget> createState() =>
      _PermissionControlsWidgetState();
}

class _PermissionControlsWidgetState extends State<PermissionControlsWidget> {
  final ElectionPermissionService _permissionService =
      ElectionPermissionService.instance;
  List<Map<String, dynamic>> _creatorGroups = [];
  bool _isLoadingGroups = false;

  @override
  void initState() {
    super.initState();
    _loadCreatorGroups();
  }

  Future<void> _loadCreatorGroups() async {
    setState(() => _isLoadingGroups = true);
    final groups = await _permissionService.getCreatorGroups();
    if (mounted) {
      setState(() {
        _creatorGroups = groups;
        _isLoadingGroups = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: AppTheme.backgroundLight,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Election Permission Controls',
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryLight,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            'Control who can vote in this election',
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
          ),
          SizedBox(height: 2.h),
          _buildPermissionTypeSelector(),
          SizedBox(height: 2.h),
          if (widget.selectedPermissionType == 'country_specific')
            _buildCountrySelector(),
          if (widget.selectedPermissionType == 'group_only')
            _buildGroupSelector(),
        ],
      ),
    );
  }

  Widget _buildPermissionTypeSelector() {
    return Column(
      children: [
        _buildPermissionOption(
          'public',
          'Open to World',
          'Any registered Vottery user can vote in this election',
          Icons.public,
        ),
        SizedBox(height: 1.h),
        _buildPermissionOption(
          'country_specific',
          'Specific Countries',
          'Only users from selected countries can vote',
          Icons.flag,
        ),
        SizedBox(height: 1.h),
        _buildPermissionOption(
          'group_only',
          'Group Members Only',
          'Only members of your selected group can vote',
          Icons.group,
        ),
      ],
    );
  }

  Widget _buildPermissionOption(
    String value,
    String title,
    String description,
    IconData icon,
  ) {
    final isSelected = widget.selectedPermissionType == value;

    return InkWell(
      onTap: () => widget.onPermissionTypeChanged(value),
      child: Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.accentLight.withAlpha(26) : Colors.white,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: isSelected ? AppTheme.accentLight : Colors.grey.shade300,
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? AppTheme.accentLight : Colors.grey,
              size: 8.w,
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: isSelected
                          ? AppTheme.accentLight
                          : AppTheme.primaryLight,
                    ),
                  ),
                  SizedBox(height: 0.5.h),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
            if (isSelected)
              Icon(Icons.check_circle, color: AppTheme.accentLight, size: 6.w),
          ],
        ),
      ),
    );
  }

  Widget _buildCountrySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Allowed Countries',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        Text(
          '${widget.selectedCountries.length} countries selected',
          style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade600),
        ),
        SizedBox(height: 1.h),
        ElevatedButton.icon(
          onPressed: () => _showCountryPickerDialog(),
          icon: Icon(Icons.add),
          label: Text('Add Countries'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryLight,
            foregroundColor: Colors.white,
          ),
        ),
        if (widget.selectedCountries.isNotEmpty) ...[
          SizedBox(height: 1.h),
          Wrap(
            spacing: 2.w,
            runSpacing: 1.h,
            children: widget.selectedCountries.map((countryCode) {
              final country = _permissionService.getAllCountries().firstWhere(
                (c) => c['code'] == countryCode,
              );
              return Chip(
                label: Text(
                  '${country['flag']} ${country['name']}',
                  style: TextStyle(fontSize: 11.sp),
                ),
                deleteIcon: Icon(Icons.close, size: 4.w),
                onDeleted: () {
                  final updated = List<String>.from(widget.selectedCountries)
                    ..remove(countryCode);
                  widget.onSelectedCountriesChanged(updated);
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildGroupSelector() {
    if (_isLoadingGroups) {
      return Center(child: CircularProgressIndicator());
    }

    if (_creatorGroups.isEmpty) {
      return Container(
        padding: EdgeInsets.all(3.w),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(color: Colors.orange.shade200),
        ),
        child: Row(
          children: [
            Icon(Icons.info_outline, color: Colors.orange.shade700, size: 6.w),
            SizedBox(width: 2.w),
            Expanded(
              child: Text(
                'You need to create a group first to use this option.',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: Colors.orange.shade700,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Group',
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w600,
            color: AppTheme.primaryLight,
          ),
        ),
        SizedBox(height: 1.h),
        ..._creatorGroups.map((group) {
          final groupId = group['id'] as String;
          final isSelected = widget.selectedGroupId == groupId;

          return Padding(
            padding: EdgeInsets.only(bottom: 1.h),
            child: InkWell(
              onTap: () => widget.onSelectedGroupChanged(groupId),
              child: Container(
                padding: EdgeInsets.all(3.w),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppTheme.accentLight.withAlpha(26)
                      : Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.accentLight
                        : Colors.grey.shade300,
                    width: isSelected ? 2.0 : 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.group,
                      color: isSelected ? AppTheme.accentLight : Colors.grey,
                      size: 6.w,
                    ),
                    SizedBox(width: 3.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            group['name'] as String,
                            style: TextStyle(
                              fontSize: 13.sp,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.accentLight
                                  : AppTheme.primaryLight,
                            ),
                          ),
                          if (group['description'] != null) ...[
                            SizedBox(height: 0.5.h),
                            Text(
                              group['description'] as String,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.grey.shade600,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                          SizedBox(height: 0.5.h),
                          Text(
                            '${group['member_count'] ?? 0} members',
                            style: TextStyle(
                              fontSize: 10.sp,
                              color: Colors.grey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isSelected)
                      Icon(
                        Icons.check_circle,
                        color: AppTheme.accentLight,
                        size: 6.w,
                      ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  void _showCountryPickerDialog() {
    final allCountries = _permissionService.getAllCountries();
    final TextEditingController searchController = TextEditingController();
    List<Map<String, String>> filteredCountries = allCountries;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text('Select Countries'),
              content: SizedBox(
                width: double.maxFinite,
                height: 60.h,
                child: Column(
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search countries...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                      ),
                      onChanged: (query) {
                        setDialogState(() {
                          if (query.isEmpty) {
                            filteredCountries = allCountries;
                          } else {
                            filteredCountries = allCountries
                                .where(
                                  (c) => c['name']!.toLowerCase().contains(
                                    query.toLowerCase(),
                                  ),
                                )
                                .toList();
                          }
                        });
                      },
                    ),
                    SizedBox(height: 2.h),
                    Expanded(
                      child: ListView.builder(
                        itemCount: filteredCountries.length,
                        itemBuilder: (context, index) {
                          final country = filteredCountries[index];
                          final isSelected = widget.selectedCountries.contains(
                            country['code'],
                          );

                          return CheckboxListTile(
                            title: Text(
                              '${country['flag']} ${country['name']}',
                              style: TextStyle(fontSize: 12.sp),
                            ),
                            value: isSelected,
                            onChanged: (checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  widget.onSelectedCountriesChanged([
                                    ...widget.selectedCountries,
                                    country['code']!,
                                  ]);
                                } else {
                                  widget.onSelectedCountriesChanged(
                                    widget.selectedCountries
                                        .where((c) => c != country['code'])
                                        .toList(),
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text('Done'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
