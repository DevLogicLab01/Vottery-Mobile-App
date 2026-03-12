import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../services/creator_verification_service.dart';
import '../../../theme/app_theme.dart';

class PersonalInfoStepWidget extends StatefulWidget {
  final VoidCallback onNext;
  final Map<String, dynamic>? initialData;

  const PersonalInfoStepWidget({
    super.key,
    required this.onNext,
    this.initialData,
  });

  @override
  State<PersonalInfoStepWidget> createState() => _PersonalInfoStepWidgetState();
}

class _PersonalInfoStepWidgetState extends State<PersonalInfoStepWidget> {
  final _formKey = GlobalKey<FormState>();
  final CreatorVerificationService _verificationService =
      CreatorVerificationService.instance;

  late TextEditingController _fullNameController;
  late TextEditingController _addressLine1Controller;
  late TextEditingController _addressLine2Controller;
  late TextEditingController _cityController;
  late TextEditingController _stateController;
  late TextEditingController _postalCodeController;
  late TextEditingController _countryController;
  late TextEditingController _phoneController;

  DateTime? _dateOfBirth;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _fullNameController = TextEditingController(
      text: widget.initialData?['full_name'] ?? '',
    );
    _addressLine1Controller = TextEditingController(
      text: widget.initialData?['address_line1'] ?? '',
    );
    _addressLine2Controller = TextEditingController(
      text: widget.initialData?['address_line2'] ?? '',
    );
    _cityController = TextEditingController(
      text: widget.initialData?['city'] ?? '',
    );
    _stateController = TextEditingController(
      text: widget.initialData?['state'] ?? '',
    );
    _postalCodeController = TextEditingController(
      text: widget.initialData?['postal_code'] ?? '',
    );
    _countryController = TextEditingController(
      text: widget.initialData?['country'] ?? 'US',
    );
    _phoneController = TextEditingController(
      text: widget.initialData?['phone'] ?? '',
    );

    if (widget.initialData?['date_of_birth'] != null) {
      _dateOfBirth = DateTime.parse(widget.initialData!['date_of_birth']);
    }
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _addressLine1Controller.dispose();
    _addressLine2Controller.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Step 1: Personal Information',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: AppTheme.textPrimaryLight,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Please provide your personal details for verification',
              style: TextStyle(
                fontSize: 14.sp,
                color: AppTheme.textSecondaryLight,
              ),
            ),
            SizedBox(height: 3.h),
            TextFormField(
              controller: _fullNameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                prefixIcon: Icon(Icons.person),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your full name';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            InkWell(
              onTap: () => _selectDateOfBirth(context),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: 'Date of Birth',
                  prefixIcon: Icon(Icons.calendar_today),
                ),
                child: Text(
                  _dateOfBirth != null
                      ? '${_dateOfBirth!.month}/${_dateOfBirth!.day}/${_dateOfBirth!.year}'
                      : 'Select date',
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: _dateOfBirth != null
                        ? AppTheme.textPrimaryLight
                        : AppTheme.textSecondaryLight,
                  ),
                ),
              ),
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _addressLine1Controller,
              decoration: InputDecoration(
                labelText: 'Address Line 1',
                prefixIcon: Icon(Icons.home),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your address';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _addressLine2Controller,
              decoration: InputDecoration(
                labelText: 'Address Line 2 (Optional)',
                prefixIcon: Icon(Icons.home),
              ),
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: 'City',
                      prefixIcon: Icon(Icons.location_city),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: TextFormField(
                    controller: _stateController,
                    decoration: InputDecoration(
                      labelText: 'State',
                      prefixIcon: Icon(Icons.map),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _postalCodeController,
                    decoration: InputDecoration(
                      labelText: 'Postal Code',
                      prefixIcon: Icon(Icons.markunread_mailbox),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 2.w),
                Expanded(
                  child: TextFormField(
                    controller: _countryController,
                    decoration: InputDecoration(
                      labelText: 'Country',
                      prefixIcon: Icon(Icons.flag),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Icon(Icons.phone),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter your phone number';
                }
                return null;
              },
            ),
            SizedBox(height: 4.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitPersonalInfo,
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                ),
                child: _isSubmitting
                    ? CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Continue',
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDateOfBirth(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now().subtract(Duration(days: 365 * 18)),
    );

    if (picked != null && picked != _dateOfBirth) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _submitPersonalInfo() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dateOfBirth == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select your date of birth'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final success = await _verificationService.submitPersonalInformation(
      fullName: _fullNameController.text,
      dateOfBirth: _dateOfBirth!,
      addressLine1: _addressLine1Controller.text,
      addressLine2: _addressLine2Controller.text.isNotEmpty
          ? _addressLine2Controller.text
          : null,
      city: _cityController.text,
      state: _stateController.text,
      postalCode: _postalCodeController.text,
      country: _countryController.text,
      phone: _phoneController.text,
    );

    setState(() => _isSubmitting = false);

    if (success) {
      widget.onNext();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save personal information'),
          backgroundColor: AppTheme.errorLight,
        ),
      );
    }
  }
}
