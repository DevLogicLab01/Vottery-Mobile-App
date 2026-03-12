import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

class ElectionCreatorControlsWidget extends StatefulWidget {
  const ElectionCreatorControlsWidget({super.key});

  @override
  State<ElectionCreatorControlsWidget> createState() =>
      _ElectionCreatorControlsWidgetState();
}

class _ElectionCreatorControlsWidgetState
    extends State<ElectionCreatorControlsWidget> {
  bool _requireAgeVerification = false;
  final List<String> _selectedMethods = [];

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: EdgeInsets.all(3.w),
      children: [
        Text(
          'Election Creator Controls',
          style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
        ),
        SizedBox(height: 2.h),
        Card(
          elevation: 2.0,
          child: Padding(
            padding: EdgeInsets.all(3.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Age Verification Toggle',
                  style: TextStyle(
                    fontSize: 12.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 1.h),
                Text(
                  'Enable age verification for voters in election creation wizard. Default setting is "No Age Verification".',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey.shade700,
                  ),
                ),
                SizedBox(height: 2.h),
                SwitchListTile(
                  title: Text(
                    'Require Age Verification',
                    style: TextStyle(fontSize: 11.sp),
                  ),
                  value: _requireAgeVerification,
                  onChanged: (value) {
                    setState(() => _requireAgeVerification = value);
                  },
                ),
                if (_requireAgeVerification) ...[
                  SizedBox(height: 2.h),
                  Text(
                    'Verification Methods',
                    style: TextStyle(
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  CheckboxListTile(
                    title: Text(
                      'Facial Age Estimation',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    value: _selectedMethods.contains('facial'),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedMethods.add('facial');
                        } else {
                          _selectedMethods.remove('facial');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text(
                      'Government ID Verification',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    value: _selectedMethods.contains('government_id'),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedMethods.add('government_id');
                        } else {
                          _selectedMethods.remove('government_id');
                        }
                      });
                    },
                  ),
                  CheckboxListTile(
                    title: Text(
                      'Digital Identity Wallet',
                      style: TextStyle(fontSize: 11.sp),
                    ),
                    value: _selectedMethods.contains('digital_wallet'),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedMethods.add('digital_wallet');
                        } else {
                          _selectedMethods.remove('digital_wallet');
                        }
                      });
                    },
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
