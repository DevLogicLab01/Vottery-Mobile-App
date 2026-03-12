import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../services/brand_onboarding_service.dart';

class CompanyRegistrationStepWidget extends StatefulWidget {
  final Map<String, dynamic>? onboardingData;
  final VoidCallback onNext;

  const CompanyRegistrationStepWidget({
    super.key,
    this.onboardingData,
    required this.onNext,
  });

  @override
  State<CompanyRegistrationStepWidget> createState() =>
      _CompanyRegistrationStepWidgetState();
}

class _CompanyRegistrationStepWidgetState
    extends State<CompanyRegistrationStepWidget> {
  final _formKey = GlobalKey<FormState>();
  final BrandOnboardingService _service = BrandOnboardingService.instance;

  late TextEditingController _businessNameController;
  late TextEditingController _registrationNumberController;
  late TextEditingController _industryController;
  late TextEditingController _taxIdController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final companyInfo =
        widget.onboardingData?['company_info'] as Map<String, dynamic>?;

    _businessNameController = TextEditingController(
      text: companyInfo?['business_name'] ?? '',
    );
    _registrationNumberController = TextEditingController(
      text: companyInfo?['registration_number'] ?? '',
    );
    _industryController = TextEditingController(
      text: companyInfo?['industry'] ?? '',
    );
    _taxIdController = TextEditingController(
      text: companyInfo?['tax_id'] ?? '',
    );
    _emailController = TextEditingController(
      text: companyInfo?['contact_email'] ?? '',
    );
    _phoneController = TextEditingController(
      text: companyInfo?['contact_phone'] ?? '',
    );
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _registrationNumberController.dispose();
    _industryController.dispose();
    _taxIdController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _handleNext() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final success = await _service.completeCompanyRegistration(
        businessName: _businessNameController.text,
        registrationNumber: _registrationNumberController.text,
        industry: _industryController.text,
        taxId: _taxIdController.text,
        contactEmail: _emailController.text,
        contactPhone: _phoneController.text,
      );

      if (success && mounted) {
        widget.onNext();
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save company information')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SingleChildScrollView(
      padding: EdgeInsets.all(4.w),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Company Registration',
              style: GoogleFonts.inter(
                fontSize: 18.sp,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Provide your business details for verification',
              style: GoogleFonts.inter(
                fontSize: 12.sp,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 3.h),
            TextFormField(
              controller: _businessNameController,
              decoration: InputDecoration(
                labelText: 'Business Name',
                hintText: 'Enter your company name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Business name is required';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _registrationNumberController,
              decoration: InputDecoration(
                labelText: 'Registration Number',
                hintText: 'Company registration number',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Registration number is required';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _industryController,
              decoration: InputDecoration(
                labelText: 'Industry Classification',
                hintText: 'e.g., Technology, Retail, Healthcare',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Industry is required';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _taxIdController,
              decoration: InputDecoration(
                labelText: 'Tax Identification Number',
                hintText: 'EIN or Tax ID',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Tax ID is required';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Contact Email',
                hintText: 'business@company.com',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              keyboardType: TextInputType.emailAddress,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Email is required';
                }
                if (!value.contains('@')) {
                  return 'Enter a valid email';
                }
                return null;
              },
            ),
            SizedBox(height: 2.h),
            TextFormField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Contact Phone',
                hintText: '+1 (555) 123-4567',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
              ),
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Phone number is required';
                }
                return null;
              },
            ),
            SizedBox(height: 4.h),
            SizedBox(
              width: double.infinity,
              height: 6.h,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                ),
                child: _isSaving
                    ? SizedBox(
                        height: 2.h,
                        width: 2.h,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : Text(
                        'Continue to Verification',
                        style: GoogleFonts.inter(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
