import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../theme/app_theme.dart';

class AddFamilyMemberDialogWidget extends StatefulWidget {
  const AddFamilyMemberDialogWidget({super.key});

  @override
  State<AddFamilyMemberDialogWidget> createState() =>
      _AddFamilyMemberDialogWidgetState();
}

class _AddFamilyMemberDialogWidgetState
    extends State<AddFamilyMemberDialogWidget> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  String _selectedRelationship = 'Spouse';
  bool _fullPremiumAccess = false;
  final Map<String, bool> _permissions = {
    'ad_free': false,
    'priority_support': false,
    'creator_tools': false,
    'analytics_dashboard': false,
    'api_access': false,
  };

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
      child: Container(
        constraints: BoxConstraints(maxHeight: 80.h),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(6.w),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Add Family Member',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email Address',
                      hintText: 'member@example.com',
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an email address';
                      }
                      if (!RegExp(
                        r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}\$',
                      ).hasMatch(value)) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 2.h),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRelationship,
                    decoration: InputDecoration(
                      labelText: 'Relationship',
                      prefixIcon: const Icon(Icons.people),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    items:
                        [
                              'Spouse',
                              'Partner',
                              'Parent',
                              'Child',
                              'Sibling',
                              'Other',
                            ]
                            .map(
                              (rel) => DropdownMenuItem(
                                value: rel,
                                child: Text(rel),
                              ),
                            )
                            .toList(),
                    onChanged: (value) {
                      setState(() => _selectedRelationship = value!);
                    },
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    'Permissions Configuration',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryLight,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  SwitchListTile(
                    title: const Text('Full Premium Access'),
                    subtitle: const Text('Grant all premium features'),
                    value: _fullPremiumAccess,
                    onChanged: (value) {
                      setState(() {
                        _fullPremiumAccess = value;
                        if (value) {
                          _permissions.updateAll((key, _) => true);
                        }
                      });
                    },
                  ),
                  if (!_fullPremiumAccess) ...[
                    SizedBox(height: 1.h),
                    Text(
                      'Selective Permissions',
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w500,
                        color: AppTheme.textSecondaryLight,
                      ),
                    ),
                    _buildPermissionCheckbox(
                      'Ad-Free Experience',
                      'ad_free',
                      Icons.block,
                    ),
                    _buildPermissionCheckbox(
                      'Priority Support',
                      'priority_support',
                      Icons.support_agent,
                    ),
                    _buildPermissionCheckbox(
                      'Creator Tools',
                      'creator_tools',
                      Icons.create,
                    ),
                    _buildPermissionCheckbox(
                      'Analytics Dashboard',
                      'analytics_dashboard',
                      Icons.analytics,
                    ),
                    _buildPermissionCheckbox(
                      'API Access',
                      'api_access',
                      Icons.api,
                    ),
                  ],
                  SizedBox(height: 3.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                      SizedBox(width: 2.w),
                      ElevatedButton(
                        onPressed: _submitForm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryLight,
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 1.5.h,
                          ),
                        ),
                        child: const Text('Send Invitation'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPermissionCheckbox(String title, String key, IconData icon) {
    return CheckboxListTile(
      title: Row(
        children: [
          Icon(icon, size: 5.w, color: AppTheme.primaryLight),
          SizedBox(width: 2.w),
          Text(title),
        ],
      ),
      value: _permissions[key],
      onChanged: (value) {
        setState(() => _permissions[key] = value!);
      },
      controlAffinity: ListTileControlAffinity.leading,
    );
  }

  void _submitForm() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'email': _emailController.text.trim(),
        'relationship': _selectedRelationship,
        'permissions': {
          'full_premium_access': _fullPremiumAccess,
          ..._permissions,
        },
      });
    }
  }
}
