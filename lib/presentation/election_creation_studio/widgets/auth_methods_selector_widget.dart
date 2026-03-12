import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class AuthMethodsSelectorWidget extends StatefulWidget {
  final List<String> selectedMethods;
  final Function(List<String>) onMethodsChanged;

  const AuthMethodsSelectorWidget({
    super.key,
    required this.selectedMethods,
    required this.onMethodsChanged,
  });

  @override
  State<AuthMethodsSelectorWidget> createState() =>
      _AuthMethodsSelectorWidgetState();
}

class _AuthMethodsSelectorWidgetState extends State<AuthMethodsSelectorWidget> {
  final List<Map<String, dynamic>> _authMethods = [
    {
      'id': 'email_password',
      'name': 'Email & Password',
      'icon': Icons.email,
      'description': 'Traditional email and password authentication',
    },
    {
      'id': 'magic_link',
      'name': 'Magic Link',
      'icon': Icons.link,
      'description': 'Passwordless email link authentication',
    },
    {
      'id': 'oauth_google',
      'name': 'Google OAuth',
      'icon': Icons.g_mobiledata,
      'description': 'Sign in with Google account',
    },
    {
      'id': 'oauth_facebook',
      'name': 'Facebook OAuth',
      'icon': Icons.facebook,
      'description': 'Sign in with Facebook account',
    },
    {
      'id': 'oauth_apple',
      'name': 'Apple OAuth',
      'icon': Icons.apple,
      'description': 'Sign in with Apple ID',
    },
    {
      'id': 'passkey',
      'name': 'Passkey',
      'icon': Icons.fingerprint,
      'description': 'Biometric passkey authentication',
    },
    {
      'id': 'biometric',
      'name': 'Biometric',
      'icon': Icons.face,
      'description': 'Face ID or Touch ID verification',
    },
  ];

  void _toggleMethod(String methodId) {
    final currentMethods = List<String>.from(widget.selectedMethods);
    if (currentMethods.contains(methodId)) {
      currentMethods.remove(methodId);
    } else {
      currentMethods.add(methodId);
    }
    widget.onMethodsChanged(currentMethods);
  }

  void _selectAll() {
    widget.onMethodsChanged(
      _authMethods.map((m) => m['id'] as String).toList(),
    );
  }

  void _clearAll() {
    widget.onMethodsChanged([]);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Authentication Methods',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            Row(
              children: [
                TextButton(
                  onPressed: _selectAll,
                  child: const Text('Select All'),
                ),
                TextButton(onPressed: _clearAll, child: const Text('Clear')),
              ],
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Text(
          'Choose which authentication methods voters can use to access this election',
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
          ),
        ),
        SizedBox(height: 2.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _authMethods.length,
          itemBuilder: (context, index) {
            final method = _authMethods[index];
            final isSelected = widget.selectedMethods.contains(method['id']);

            return Card(
              margin: EdgeInsets.only(bottom: 1.h),
              child: CheckboxListTile(
                value: isSelected,
                onChanged: (value) => _toggleMethod(method['id']),
                title: Row(
                  children: [
                    Icon(
                      method['icon'],
                      color: isSelected
                          ? theme.colorScheme.primary
                          : theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                    SizedBox(width: 2.w),
                    Text(
                      method['name'],
                      style: TextStyle(
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                subtitle: Padding(
                  padding: EdgeInsets.only(top: 0.5.h),
                  child: Text(method['description']),
                ),
                controlAffinity: ListTileControlAffinity.trailing,
              ),
            );
          },
        ),
        if (widget.selectedMethods.isEmpty)
          Container(
            padding: EdgeInsets.all(2.w),
            margin: EdgeInsets.only(top: 1.h),
            decoration: BoxDecoration(
              color: theme.colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.warning,
                  color: theme.colorScheme.error,
                  size: 20.sp,
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: Text(
                    'At least one authentication method must be selected',
                    style: TextStyle(
                      color: theme.colorScheme.error,
                      fontSize: 12.sp,
                    ),
                  ),
                ),
              ],
            ),
          ),
        SizedBox(height: 2.h),
        Container(
          padding: EdgeInsets.all(3.w),
          decoration: BoxDecoration(
            color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: theme.colorScheme.primary,
                    size: 20.sp,
                  ),
                  SizedBox(width: 2.w),
                  Text(
                    'Selected: ${widget.selectedMethods.length} method(s)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 1.h),
              Text(
                'Voters will be able to choose any of the selected authentication methods when accessing this election.',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
